//
//  DesignSystem.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

// Quiet Canvas design tokens, direction A "Paper & Terracotta". Reference: docs/design/board.png
// Light mode only (Info.plist UIUserInterfaceStyle = Light). `.accent` (terracotta #B4532F) comes from the AccentColor asset.

extension ShapeStyle where Self == Color {
    static var paper: Color { Color(rgb: 0xFAF6F0) }
    static var well: Color { Color(rgb: 0xF1ECE4) }
    static var surface: Color { .white }
    static var ink: Color { Color(rgb: 0x2B2622) }
    static var ink2: Color { Color(rgb: 0x6B625A) }
    static var onAccent: Color { .white }
    static var accentSoft: Color { Color(rgb: 0xF9EDE7) }
    static var line: Color { Color(rgb: 0xE8E1D7) }
    static var success: Color { Color(rgb: 0x4E8B5F) }
    static var flame: Color { Color(rgb: 0xC86428) }
}

extension Font {
    static let display = Font.system(.largeTitle, design: .serif, weight: .semibold)
    static let heading = Font.system(.title2, design: .serif, weight: .semibold)
    static let eyebrow = Font.subheadline.weight(.semibold)
}

/// Adaptive grid columns: 2 columns on portrait iPhone, 3–4+ in landscape and iPad.
let adaptiveGrid = [GridItem(.adaptive(minimum: 160), spacing: 16)]

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(.onAccent)
            .background(.accent, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(.ink)
            .background(.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(.line))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Subtle tactile scale and opacity feedback for cards, thumbnails, and swatches.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

/// 48pt round icon button used in custom top bars.
struct CircleIcon: View {
    let systemName: String
    var tint: Color = .ink
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 48, height: 48)
            .background(.surface, in: Circle())
            .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
    }
}

struct DifficultyDots: View {
    let difficulty: Catalog.Difficulty
    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { i in
                    Circle().fill(i <= difficulty.level ? AnyShapeStyle(.accent) : AnyShapeStyle(.ink2.opacity(0.32))).frame(width: 7.5, height: 7.5)
                }
            }
            Text(difficulty.label)
        }
        .font(.subheadline)
        .foregroundStyle(.ink2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(difficulty.label)
    }
}

struct ProgressRing: View {
    let value: Double
    var body: some View {
        ZStack {
            Circle().stroke(.ink2.opacity(0.25), lineWidth: 3.5)
            Circle().trim(from: 0, to: value).stroke(.accent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round)).rotationEffect(.degrees(-90))
            Text("\(Int(value * 100))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 2)
        }
        .frame(width: 36, height: 36)
        .padding(3)
        .background(.surface, in: Circle())
        .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(value * 100)) percent complete")
    }
}

/// Artwork tile: grayscale artwork until started, then the in-progress preview, then full color; lock / progress / done badges.
struct Thumb: View {
    let entry: Catalog.Entry
    var caption = true
    var subtitle: String?
    @Environment(\.store) private var store

    var body: some View {
        let status = store.status(entry)
        VStack(alignment: .leading, spacing: 6) {
            art(status)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .saturation(status == .new ? 0 : 1)  // not started: grayscale, so finished pictures stand out
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(4)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
                .overlay(alignment: .topTrailing) { badge(status).padding(8) }
            if caption {
                MarqueeText(text: entry.title).foregroundStyle(.ink)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(.ink2).lineLimit(1)
                } else {
                    DifficultyDots(difficulty: entry.difficulty)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func art(_ status: Store.Status) -> Image {
        if case .progress = status, let p = store.preview(entry.id) { return Image(uiImage: p) }
        if let img = UIImage(named: entry.thumb) { return Image(uiImage: img) }
        return Image(systemName: "photo")
    }

    @ViewBuilder private func badge(_ status: Store.Status) -> some View {
        if !store.isUnlocked(entry) {
            Image(systemName: "lock.fill").font(.system(size: 14, weight: .semibold)).foregroundStyle(.ink2)
                .frame(width: 34, height: 34).background(.surface.opacity(0.94), in: Circle())
                .accessibilityLabel("Locked")
        } else if case .progress(let v) = status {
            ProgressRing(value: v)
        } else if status == .done {
            Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                .frame(width: 34, height: 34).background(.success, in: Circle())
                .accessibilityLabel("Completed")
        }
    }
}

/// One-line text that slowly scrolls sideways when it doesn't fit; truncates instead under Reduce Motion.
struct MarqueeText: View {
    let text: String
    var font: Font = .body.weight(.semibold)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var textWidth: CGFloat = 0
    @State private var boxWidth: CGFloat = 0
    @State private var scrolled = false
    private let gap: CGFloat = 28

    var body: some View {
        let scrolls = textWidth > boxWidth + 1 && boxWidth > 0 && !reduceMotion
        Text(text).font(font).lineLimit(1)
            .opacity(scrolls ? 0 : 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { boxWidth = $0 }
            .overlay(alignment: .leading) {
                if scrolls {
                    HStack(spacing: gap) { label; label }
                        .offset(x: scrolled ? -(textWidth + gap) : 0)
                }
            }
            .background(alignment: .leading) {
                label.hidden().onGeometryChange(for: CGFloat.self, of: \.size.width) { textWidth = $0 }
            }
            .clipped()
            .task(id: scrolls) {
                scrolled = false
                guard scrolls else { return }
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.linear(duration: Double(textWidth + gap) / 30).repeatForever(autoreverses: false)) { scrolled = true }
            }
            .accessibilityElement()
            .accessibilityLabel(text)
    }

    private var label: some View { Text(text).font(font).lineLimit(1).fixedSize() }
}

/// Horizontal shelf of thumbnails with a serif section header.
struct Shelf<Trailing: View>: View {
    let title: String
    let entries: [Catalog.Entry]
    var size: CGFloat = 168
    @ViewBuilder var trailing: Trailing
    @Environment(Router.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.heading).foregroundStyle(.ink)
                Spacer()
                trailing
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(entries) { e in
                        Button { router.open(e) } label: { Thumb(entry: e).frame(width: size) }
                            .buttonStyle(.pressable)
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
        }
    }
}

extension Shelf where Trailing == EmptyView {
    init(title: String, entries: [Catalog.Entry], size: CGFloat = 168) {
        self.init(title: title, entries: entries, size: size) { EmptyView() }
    }
}

extension View {
    /// Solid paper strip behind the status bar for screens that hide the navigation bar.
    func paperStatusBar() -> some View {
        safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 0).background(.paper) }
    }
}
