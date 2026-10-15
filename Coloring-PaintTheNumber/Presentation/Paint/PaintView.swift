//
//  PaintView.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

#if DEBUG
/// TEMP for testing the finish sequence: opening an unfinished picture pre-fills every shape except the largest one.
private let debugLeaveOneShape = false
#endif

/// Full-screen painting. Loads the template off the main thread, then shows the board.
struct PaintView: View {
    @State var entry: Catalog.Entry
    @State private var model: PaintModel?
    @Environment(\.store) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            if let model {
                Board(model: model) { entry = $0 }
            } else {
                VStack(spacing: 16) {
                    Thumb(entry: entry, caption: false)
                        .frame(width: 180)
                        .opacity(0.75)
                        .accessibilityHidden(true)
                    Text(entry.title).font(.heading).foregroundStyle(.ink)
                    ProgressView().tint(.accent).controlSize(.regular)
                }
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.25), value: model != nil)
        .task(id: entry.id) {
            model = nil
            if let loaded = await Template.load(entry.id) {
                let m = PaintModel(entry: entry, loaded: loaded, store: store)
                #if DEBUG
                if debugLeaveOneShape, !m.done { m.debugFillAllButOne() }
                #endif
                model = m
            } else {
                dismiss()
            }
        }
    }
}

private struct Board: View {
    let model: PaintModel
    let next: (Catalog.Entry) -> Void
    @Environment(\.store) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase
    @AppStorage("highlight") private var highlight = true
    @AppStorage("highlightHex") private var highlightHex = "#475569"
    @AppStorage("autoNext") private var autoNext = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("numberSize") private var numberSize = 0
    @AppStorage("hideDone") private var hideDone = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var pinchBase: CGFloat = 1
    @State private var panBase: CGSize = .zero
    @State private var viewSize: CGSize = .zero
    @State private var buzz = 0
    @State private var flash: Int?
    @State private var finished: UIImage?
    @State private var confirmReset = false
    @State private var showSettings = false
    @State private var sessionStart = Date.now
    @State private var wrong = 0
    @State private var ripples: [Int: Ripple] = [:]
    @State private var lastMiss: (time: Date, at: CGPoint)?
    @State private var camera: Task<Void, Never>?
    /// Original artwork faded in over the canvas when the picture is finished.
    @State private var art: UIImage?
    @State private var revealed = false

    /// Color spreading from the tap point when a shape is filled.
    private struct Ripple {
        static let duration = 0.2
        let from: CGPoint
        let start: Date
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            canvas
            palette
        }
        .background(.paper)
        .overlay {
            if let finished {
                CompletionView(model: model, image: finished, minutes: minutesSpent, close: { dismiss() }, next: next)
                    .transition(.opacity)
            }
        }
        .onAppear {
            sessionStart = .now
            if model.done { finished = finalImage() }
        }
        .onDisappear(perform: persist)
        .onChange(of: phase) { _, p in if p == .background { persist() } }
        .onChange(of: model.done) { _, done in
            guard done else { return }
            persist()
            celebrate()
        }
        .sensoryFeedback(trigger: buzz) { _, _ in haptics ? .impact(weight: .light, intensity: 0.6) : nil }
        .sensoryFeedback(trigger: wrong) { _, _ in haptics ? .warning : nil }
        .sensoryFeedback(trigger: model.done) { _, done in done && haptics ? .success : nil }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .confirmationDialog("Restart this picture?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Restart", role: .destructive) {
                model.reset()
                finished = nil
                art = nil; revealed = false
                camera?.cancel()
                zoom = 1; pinchBase = 1; pan = .zero; panBase = .zero
            }
        } message: { Text("All colors you filled will be cleared.") }
    }

    private func finalImage() -> UIImage {
        BundleCatalogRepository.shared.finalArtwork(for: model.entry.id) ?? model.render(side: 1536)
    }

    /// Last shape filled: ease back to the whole picture, fade the original artwork in, then show the completion screen.
    private func celebrate() {
        let image = finalImage()
        art = image
        moveCamera(zoom: 1, pan: .zero, duration: 0.6)
        Task {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.7))
            withAnimation(.easeInOut(duration: 1.2)) { revealed = true }
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.smooth(duration: 0.5)) { finished = image }
        }
    }

    private var minutesSpent: Int {
        let seconds = (store.meta[model.entry.id]?.seconds ?? 0) + Date.now.timeIntervalSince(sessionStart)
        return max(1, Int(seconds / 60))
    }

    private func persist() {
        store.addTime(model.entry.id, Date.now.timeIntervalSince(sessionStart))
        sessionStart = .now
        store.setPreview(model.entry.id, model.filled.isEmpty ? nil : model.render(side: 600))
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: { CircleIcon(systemName: "chevron.left") }
                .buttonStyle(.pressable)
                .accessibilityLabel("Back")
            VStack(spacing: 5) {
                Text(model.entry.title).font(.system(.title3, design: .serif, weight: .semibold)).foregroundStyle(.ink).lineLimit(1)
                ProgressView(value: model.progress).tint(.accent).frame(maxWidth: 180).scaleEffect(x: 1, y: 1.4)
                Text("\(model.filled.count) of \(model.template.regions.count)").font(.subheadline.weight(.medium)).foregroundStyle(.ink2).monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            Button(action: hint) { CircleIcon(systemName: "lightbulb", tint: .accent) }
                .buttonStyle(.pressable)
                .accessibilityLabel("Hint")
            Menu {
                if zoom > 1.05 || hypot(pan.width, pan.height) > 10 {
                    Button("Fit to screen", systemImage: "arrow.down.right.and.arrow.up.left") {
                        moveCamera(zoom: 1, pan: .zero)
                    }
                }
                Button("Settings", systemImage: "gearshape") { showSettings = true }
                Button("Restart picture", systemImage: "arrow.counterclockwise", role: .destructive) { confirmReset = true }
            } label: { CircleIcon(systemName: "ellipsis") }
                .accessibilityLabel("More")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(.line).frame(height: 1) }
    }

    // MARK: - Canvas

    private func layout(_ size: CGSize) -> (fit: CGFloat, origin: CGPoint) {
        let t = model.template
        let fit = min((size.width - 12) / t.width, (size.height - 12) / t.height)
        return (fit, CGPoint(x: (size.width - t.width * fit) / 2, y: (size.height - t.height * fit) / 2))
    }

    /// Keeps any point of the picture reachable at center while preventing the sheet from drifting off-screen.
    private func clampPan(_ p: CGSize, zoom z: CGFloat, fit: CGFloat) -> CGSize {
        guard z > 1 else { return .zero }
        let w = model.template.width * fit, h = model.template.height * fit
        return CGSize(width: min(max(p.width, w * (0.5 - z)), w * 0.5),
                      height: min(max(p.height, h * (0.5 - z)), h * 0.5))
    }

    private var canvas: some View {
        GeometryReader { geo in
            let (fit, origin) = layout(geo.size)
            TimelineView(.animation(paused: ripples.isEmpty)) { timeline in
                Canvas { ctx, size in draw(&ctx, size: size, fit: fit, origin: origin, now: timeline.date) }
            }
                .overlay(alignment: .topLeading) {
                    if let art {
                        Image(uiImage: art).resizable()
                            .frame(width: model.template.width * fit, height: model.template.height * fit)
                            .offset(x: origin.x, y: origin.y)
                            .opacity(revealed ? 1 : 0)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if zoom > 1.05 && !model.done {
                        Button { moveCamera(zoom: 1, pan: .zero) } label: {
                            Label("\(Int((zoom * 100).rounded()))%", systemImage: "arrow.down.right.and.arrow.up.left")
                                .font(.subheadline.weight(.semibold)).monospacedDigit()
                                .foregroundStyle(.ink)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 48)
                                .background(.surface.opacity(0.95), in: Capsule())
                                .overlay(Capsule().strokeBorder(.line))
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        }
                        .buttonStyle(.pressable)
                        .padding(14)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Reset zoom, currently \(Int((zoom * 100).rounded())) percent")
                    }
                }
                .animation(.snappy(duration: 0.2), value: zoom > 1.05)
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { tapped($0.location, fit: fit, origin: origin) })
                .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged {
                    camera?.cancel()
                    let raw = CGSize(width: panBase.width + $0.translation.width, height: panBase.height + $0.translation.height)
                    pan = clampPan(raw, zoom: zoom, fit: fit)
                }.onEnded { _ in panBase = pan })
                .simultaneousGesture(MagnifyGesture().onChanged { v in
                    camera?.cancel()
                    let z = min(max(pinchBase * v.magnification, 1), 12)
                    // keep the content under the pinch point fixed
                    let a = CGPoint(x: v.startLocation.x - origin.x, y: v.startLocation.y - origin.y), k = z / zoom
                    let raw = CGSize(width: a.x - (a.x - pan.width) * k, height: a.y - (a.y - pan.height) * k)
                    pan = clampPan(raw, zoom: z, fit: fit)
                    zoom = z
                }.onEnded { _ in
                    pinchBase = zoom; panBase = pan
                    if zoom == 1 { withAnimation { pan = .zero }; panBase = .zero }
                })
        }
        .onGeometryChange(for: CGSize.self, of: \.size) { viewSize = $0 }
        .allowsHitTesting(!model.done)
        .clipped()
        .background(.well)
    }

    private func tapped(_ loc: CGPoint, fit: CGFloat, origin: CGPoint) {
        let s = fit * zoom
        let pt = CGPoint(x: (loc.x - origin.x - pan.width) / s, y: (loc.y - origin.y - pan.height) / s)
        let result = model.tap(pt, tolerance: 18 / s, autoNext: autoNext)
        if case .filled(let i) = result {
            buzz += 1
            lastMiss = nil
            if !reduceMotion { addRipple(model.template.regions[i].id, from: pt) }
            return
        }
        // two quick taps that paint nothing toggle zoom, so painting taps are never delayed
        if let m = lastMiss, Date.now.timeIntervalSince(m.time) < 0.35, hypot(m.at.x - loc.x, m.at.y - loc.y) < 30 {
            lastMiss = nil
            toggleZoom(at: loc, fit: fit, origin: origin)
        } else {
            lastMiss = (.now, loc)
            if result == .wrong { wrong += 1 }
        }
    }

    private func toggleZoom(at loc: CGPoint, fit: CGFloat, origin: CGPoint) {
        if zoom > 1.5 { moveCamera(zoom: 1, pan: .zero); return }
        let z: CGFloat = 2.5, k = z / zoom
        let a = CGPoint(x: loc.x - origin.x, y: loc.y - origin.y)
        let target = clampPan(CGSize(width: a.x - (a.x - pan.width) * k, height: a.y - (a.y - pan.height) * k), zoom: z, fit: fit)
        moveCamera(zoom: z, pan: target)
    }

    /// Eases zoom and pan to a target; Canvas content can't use SwiftUI's implicit animation.
    private func moveCamera(zoom z: CGFloat, pan p: CGSize, duration: Double = 0.4) {
        camera?.cancel()
        pinchBase = z; panBase = p
        guard !reduceMotion else { zoom = z; pan = p; return }
        let z0 = zoom, p0 = pan, start = Date.now
        camera = Task {
            while !Task.isCancelled {
                let t = min(Date.now.timeIntervalSince(start) / duration, 1)
                let e = 1 - pow(1 - t, 3)
                zoom = z0 + (z - z0) * e
                pan = CGSize(width: p0.width + (p.width - p0.width) * e, height: p0.height + (p.height - p0.height) * e)
                if t >= 1 { break }
                try? await Task.sleep(for: .milliseconds(8))
            }
        }
    }

    private func addRipple(_ id: Int, from pt: CGPoint) {
        ripples[id] = Ripple(from: pt, start: .now)
        Task {
            try? await Task.sleep(for: .seconds(Ripple.duration + 0.05))
            ripples[id] = nil
        }
    }

    // ponytail: redraws visible shapes each frame; highlight stripes are batched into a single clip layer.
    private func draw(_ ctx: inout GraphicsContext, size: CGSize, fit: CGFloat, origin: CGPoint, now: Date) {
        let t = model.template, s = fit * zoom
        let visible = CGRect(x: (-origin.x - pan.width) / s, y: (-origin.y - pan.height) / s, width: size.width / s, height: size.height / s)
        ctx.translateBy(x: origin.x + pan.width, y: origin.y + pan.height)
        ctx.scaleBy(x: s, y: s)

        let sheet = Path(CGRect(x: 0, y: 0, width: t.width, height: t.height))
        ctx.drawLayer { l in
            l.addFilter(.shadow(color: .black.opacity(0.1), radius: 6 / s, y: 2 / s))
            l.fill(sheet, with: .color(.white))
        }

        let swatch = Dictionary(uniqueKeysWithValues: t.palette.map { ($0.id, $0.color) })
        let eo = FillStyle(eoFill: true)
        let outline = GraphicsContext.Shading.color(Color(white: 0.62))
        let guideColor = Color(hex: highlightHex)
        let highlightFill = GraphicsContext.Shading.color(guideColor.opacity(0.12))
        let highlightStroke = GraphicsContext.Shading.color(guideColor.opacity(0.85))
        let stripe = GraphicsContext.Shading.color(guideColor.opacity(0.42))
        var highlightPath = Path()
        var highlightBounds = CGRect.null

        for (i, r) in t.regions.enumerated() where r.rect.intersects(visible) {
            let path = Path(model.paths[i])
            if model.filled.contains(r.id) {
                let color = GraphicsContext.Shading.color(swatch[r.color] ?? .gray)
                if let rp = ripples[r.id], now.timeIntervalSince(rp.start) < Ripple.duration {
                    let t = max(now.timeIntervalSince(rp.start) / Ripple.duration, 0)
                    let b = r.rect
                    let far = [CGPoint(x: b.minX, y: b.minY), CGPoint(x: b.maxX, y: b.minY), CGPoint(x: b.minX, y: b.maxY), CGPoint(x: b.maxX, y: b.maxY)]
                        .map { hypot($0.x - rp.from.x, $0.y - rp.from.y) }.max() ?? 0
                    let rad = far * (1 - pow(1 - t, 2))
                    ctx.drawLayer { l in
                        l.clip(to: path, style: eo)
                        l.fill(Path(ellipseIn: CGRect(x: rp.from.x - rad, y: rp.from.y - rad, width: rad * 2, height: rad * 2)), with: color)
                    }
                } else {
                    ctx.fill(path, with: color, style: eo)
                }
                ctx.stroke(path, with: outline, lineWidth: 0.7 / s)
            } else if highlight, r.color == model.selected {
                ctx.fill(path, with: highlightFill, style: eo)
                highlightPath.addPath(path)
                highlightBounds = highlightBounds.union(r.rect.intersection(visible))
            } else {
                ctx.stroke(path, with: outline, lineWidth: 0.7 / s)
            }
        }

        if !highlightPath.isEmpty {
            ctx.drawLayer { l in
                l.clip(to: highlightPath, style: eo)
                l.stroke(stripes(highlightBounds, spacing: 11 / s), with: stripe, lineWidth: 4 / s)
            }
            ctx.stroke(highlightPath, with: highlightStroke, lineWidth: 1.1 / s)
        }

        if let f = flash, let i = t.regions.firstIndex(where: { $0.id == f }) {
            ctx.stroke(Path(model.paths[i]), with: .color(guideColor), lineWidth: 3 / s)
        }

        // numbers only where they are readable on screen
        let scale: CGFloat = switch numberSize {
        case 2: 1.65
        case 1: 1.38
        default: 1.15
        }
        let normalInk = Color(white: 0.22).opacity(0.72)
        let activeInk = Color.ink
        for r in t.regions where !model.filled.contains(r.id) {
            let size = r.label.size * scale
            guard size * s >= 6, visible.contains(CGPoint(x: r.label.x, y: r.label.y)) else { continue }
            let isSelected = highlight && r.color == model.selected
            ctx.draw(Text("\(r.color)").font(.system(size: size, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? activeInk : normalInk),
                     at: CGPoint(x: r.label.x, y: r.label.y))
        }
    }

    /// Canvas-anchored 45° stripes (x + y = k * spacing) so stripes never swim when panning or filling shapes.
    private func stripes(_ r: CGRect, spacing: CGFloat) -> Path {
        var p = Path()
        guard !r.isNull, !r.isEmpty, spacing > 0 else { return p }
        let start = floor((r.minX + r.minY) / spacing) * spacing
        let end = r.maxX + r.maxY
        var c = start
        while c <= end {
            p.move(to: CGPoint(x: c - r.maxY, y: r.maxY))
            p.addLine(to: CGPoint(x: c - r.minY, y: r.minY))
            c += spacing
        }
        return p
    }

    /// Zooms to the smallest unfilled shape of the selected color and outlines it briefly.
    private func hint() {
        guard let r = model.hintRegion(), viewSize != .zero else { return }
        let (fit, origin) = layout(viewSize)
        let b = r.rect
        // zoom so the shape spans ~30% of the view, capped at 6x to keep some context
        let z = min(max(min(viewSize.width, viewSize.height) * 0.3 / (max(b.width, b.height, 1) * fit), 1), 6)
        let s = fit * z
        let rawPan = CGSize(width: viewSize.width / 2 - origin.x - b.midX * s, height: viewSize.height / 2 - origin.y - b.midY * s)
        moveCamera(zoom: z, pan: clampPan(rawPan, zoom: z, fit: fit))
        flash = r.id
        Task {
            try? await Task.sleep(for: .seconds(2))
            if flash == r.id { flash = nil }
        }
    }

    // MARK: - Palette

    private var palette: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(model.template.palette.filter { !hideDone || model.remaining($0.id) > 0 }) { swatch($0).id($0.id) }
                }
                .animation(.smooth(duration: 0.3), value: hideDone ? model.filled.count : 0)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .onAppear { proxy.scrollTo(model.selected, anchor: .center) }
            .onChange(of: model.selected) { _, s in withAnimation { proxy.scrollTo(s, anchor: .center) } }
        }
        .overlay(alignment: .top) { Rectangle().fill(.line).frame(height: 1) }
    }

    private func swatch(_ sw: Template.Swatch) -> some View {
        let left = model.remaining(sw.id), total = max(model.total(sw.id), 1), on = model.selected == sw.id
        let pct = 1 - Double(left) / Double(total)
        let fg = sw.luminance > 0.22 ? Color(white: 0.17) : .white
        return Button { model.selected = sw.id } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(sw.color)
                    Circle().strokeBorder(.black.opacity(0.12), lineWidth: 1)
                    if left == 0 {
                        Image(systemName: "checkmark").font(.system(size: 20, weight: .bold)).foregroundStyle(fg)
                    } else {
                        Text("\(sw.id)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(fg)
                    }
                }
                .frame(width: 60, height: 60)
                .padding(6)
                .overlay {
                    if on {
                        Circle().strokeBorder(.accent, lineWidth: 3.5)
                    } else if pct > 0 && left > 0 {
                        Circle().trim(from: 0, to: pct)
                            .stroke(.accent.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                }
                .scaleEffect(on ? 1.06 : 1)
                .animation(.snappy(duration: 0.2), value: on)
                Text("\(left) left").font(.subheadline.weight(.semibold)).foregroundStyle(.accent)
                    .monospacedDigit().opacity(on && left > 0 ? 1 : 0)
            }
        }
        .buttonStyle(.pressable)
        .disabled(left == 0)
        .opacity(left == 0 ? 0.45 : 1)
        .accessibilityLabel(left == 0 ? "Color \(sw.id), done" : "Color \(sw.id), \(left) of \(total) left")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
