//
//  OnboardingView.swift
//  Coloring-PaintTheNumber
//

import SwiftUI
import UIKit

/// First launch (3 calm, focused screens):
/// 1) Welcome: Before/After wipe comparing numbered vector shapes and the finished painting
/// 2) Pick Your First Picture: 2×2 grid of 4 free starter artworks
/// 3) Daily Calm Reminder (`Reminder.schedule`) + handoff to `PreviewSheet`
struct OnboardingView: View {
    let finish: (Catalog.Entry?) -> Void

    @Environment(\.store) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("starterID") private var starterID = ""
    @AppStorage("reminder") private var reminder = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 20 * 60
    @AppStorage("haptics") private var haptics = true

    @State private var step = 0
    @State private var movingForward = true
    @State private var loadedDemo: Template.Loaded?
    @State private var splitRatio: CGFloat = 0.25
    @State private var userDraggedSplit = false

    private let catalog = Catalog.shared
    private let stepCount = 3
    private static let demoTemplateID = "0101_easy_greenhouse_sanctuary_1"

    private static let reminderPresets: [(label: String, icon: String, minutes: Int)] = [
        ("Morning", "sun.horizon.fill", 9 * 60),
        ("Afternoon", "cup.and.saucer.fill", 15 * 60),
        ("Evening", "moon.stars.fill", 20 * 60)
    ]

    private var pageTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: movingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: movingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func goToStep(_ next: Int) {
        movingForward = next >= step
        withAnimation(.smooth(duration: 0.32)) {
            step = next
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            ZStack {
                switch step {
                case 0:
                    welcome.transition(pageTransition)
                case 1:
                    pickStarter.transition(pageTransition)
                default:
                    dailyCalm.transition(pageTransition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .background(Color.paper.ignoresSafeArea())
        .onAppear {
            if starterID.isEmpty, let first = starters.first {
                starterID = first.id
            }
        }
    }

    // MARK: - Top Chrome

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? AnyShapeStyle(.accent) : AnyShapeStyle(.line))
                        .frame(height: 4)
                }
            }
            .animation(.smooth(duration: 0.32), value: step)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(step + 1) of \(stepCount)")

            HStack {
                if step > 0 {
                    Button {
                        goToStep(step - 1)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.ink2)
                        .frame(minHeight: 36)
                        .contentShape(Rectangle())
                    }
                } else {
                    Text("QUIET CANVAS")
                        .font(.eyebrow)
                        .tracking(1)
                        .foregroundStyle(.ink2)
                }
                Spacer()
                if step == 1 {
                    Button("Skip") {
                        goToStep(2)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.ink2)
                    .frame(minHeight: 36)
                    .contentShape(Rectangle())
                }
            }
            .frame(height: 32)
            .animation(.smooth(duration: 0.25), value: step)
        }
    }

    // MARK: - Step 1: Welcome (Before / After Split Canvas)

    private var welcome: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            splitPreviewCard
                .frame(maxWidth: 300)
                .padding(.horizontal, 24)

            Text("Color your calm")
                .font(.display)
                .foregroundStyle(.ink)
                .padding(.top, 28)

            Text("Tap a number, fill a shape, and watch a picture come to life. No skill needed.")
                .font(.title3)
                .foregroundStyle(.ink2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 10)

            Spacer(minLength: 16)

            Button("Get started") {
                goToStep(1)
            }
            .buttonStyle(PrimaryButton())
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .task {
            if loadedDemo == nil {
                loadedDemo = await Template.load(Self.demoTemplateID)
            }
            guard !reduceMotion, !userDraggedSplit else {
                splitRatio = 0.52
                return
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard !userDraggedSplit, step == 0 else { return }
            withAnimation(.easeInOut(duration: 1.4)) {
                splitRatio = 0.78
            }
            try? await Task.sleep(for: .milliseconds(1500))
            guard !userDraggedSplit, step == 0 else { return }
            withAnimation(.easeInOut(duration: 1.1)) {
                splitRatio = 0.48
            }
        }
    }

    private var splitPreviewCard: some View {
        GeometryReader { geo in
            let side = geo.size.width
            let splitX = side * splitRatio
            ZStack {
                // Base layer: Crisp numbered vector line-art (Before)
                if let loaded = loadedDemo {
                    numberedBlueprintCanvas(loaded: loaded)
                } else {
                    Color.surface
                }

                // Top layer: Full-color artwork revealed up to `splitX` (After)
                if let img = BundleCatalogRepository.shared.finalArtwork(for: Self.demoTemplateID) ?? UIImage(named: "0101_easy_greenhouse_sanctuary_1_thumb") {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: splitX)
                        }
                }

                // Corner Labels
                VStack {
                    HStack {
                        Text("Colored")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.45), in: Capsule())
                        Spacer()
                        Text("By number")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.92), in: Capsule())
                            .overlay(Capsule().strokeBorder(.line, lineWidth: 1))
                    }
                    .padding(12)
                    Spacer()
                }
                .allowsHitTesting(false)

                // Vertical Divider Line + Drag Knob
                Rectangle()
                    .fill(.white)
                    .frame(width: 2.5)
                    .shadow(color: .black.opacity(0.25), radius: 3)
                    .overlay {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.accent, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
                    }
                    .position(x: splitX, y: side / 2)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        userDraggedSplit = true
                        let clamped = max(0.12, min(0.88, value.location.x / max(side, 1)))
                        splitRatio = clamped
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(8)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .accessibilityLabel("Interactive comparison between numbered shapes and colored artwork")
    }

    private func numberedBlueprintCanvas(loaded: Template.Loaded) -> some View {
        Canvas { context, size in
            let scale = size.width / max(loaded.template.width, loaded.template.height)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(rgb: 0xFAF6F0)))

            var scaled = context
            scaled.scaleBy(x: scale, y: scale)

            for (index, region) in loaded.template.regions.enumerated() {
                let path = Path(loaded.paths[index])
                let isHighlighted = region.color == 7
                scaled.fill(
                    path,
                    with: .color(isHighlighted ? Color(rgb: 0xF9EDE7) : .white),
                    style: FillStyle(eoFill: true)
                )
                scaled.stroke(
                    path,
                    with: .color(isHighlighted ? Color(rgb: 0xB4532F) : Color(rgb: 0x9A9086)),
                    lineWidth: (isHighlighted ? 1.4 : 0.9) / scale
                )

                if region.label.size >= 14 {
                    let pt = CGPoint(x: region.label.x, y: region.label.y)
                    let fontSize = max(11, min(17, region.label.size * 0.48)) / scale
                    let label = Text("\(region.color)")
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(isHighlighted ? Color(rgb: 0xB4532F) : Color(rgb: 0x4A433C))
                    scaled.draw(label, at: pt, anchor: .center)
                }
            }
        }
    }

    // MARK: - Step 2: Pick Your First Picture

    private var starters: [Catalog.Entry] {
        LibraryUseCases.starterPictures(catalog: catalog, isUnlocked: store.isUnlocked)
    }

    private var pickStarter: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pick your first picture")
                .font(.display)
                .foregroundStyle(.ink)
                .padding(.top, 4)
            Text("Choose one to start with — it's free and ready to color right away.")
                .font(.body)
                .foregroundStyle(.ink2)
                .padding(.top, 6)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 18) {
                    ForEach(starters) { entry in
                        starterCell(entry)
                    }
                }
                .padding(.vertical, 20)
            }
            .scrollIndicators(.hidden)

            Button("Continue") {
                goToStep(2)
            }
            .buttonStyle(PrimaryButton())
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
    }

    private func starterCell(_ entry: Catalog.Entry) -> some View {
        let isSelected = starterEntry?.id == entry.id
        return Button {
            if haptics { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
            withAnimation(.snappy(duration: 0.2)) {
                starterID = entry.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let img = UIImage(named: entry.thumb) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        Color.well.aspectRatio(1, contentMode: .fit)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(5)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(isSelected ? AnyShapeStyle(.accent) : AnyShapeStyle(.clear), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(isSelected ? AnyShapeStyle(.accent) : AnyShapeStyle(.white))
                        .background(isSelected ? Color.white : Color.black.opacity(0.28), in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 2)
                        .padding(12)
                }

                Text(entry.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.ink)
                    .lineLimit(1)

                Text("Easy · about \(entry.minutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.ink2)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Step 3: Daily Calm Reminder

    private var dailyCalm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Make time for calm")
                .font(.display)
                .foregroundStyle(.ink)
                .padding(.top, 4)
            Text("Ten quiet minutes a day helps you unwind and keep your daily coloring streak alive.")
                .font(.body)
                .foregroundStyle(.ink2)
                .padding(.top, 6)

            Spacer(minLength: 16)

            reminderCard

            Spacer(minLength: 16)

            Button {
                Task {
                    let granted = await Reminder.schedule(minutes: reminderMinutes)
                    reminder = granted
                    completeOnboarding()
                }
            } label: {
                Label("Remind me at \(formattedReminderTime)", systemImage: "bell.fill")
            }
            .buttonStyle(PrimaryButton())

            Button("Maybe later") {
                completeOnboarding()
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.ink2)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
            .padding(.top, 6)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let starter = starterEntry {
                HStack(spacing: 14) {
                    if let img = UIImage(named: starter.thumb) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR FIRST PICTURE")
                            .font(.caption.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(.accent)
                        Text(starter.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.ink)
                            .lineLimit(1)
                        Text("Easy · \(starter.regions) shapes · about \(starter.minutes) min")
                            .font(.subheadline)
                            .foregroundStyle(.ink2)
                    }
                    Spacer(minLength: 0)
                }
                Divider().overlay(.line)
            }

            Text("Choose a daily quiet time")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.ink2)

            HStack(spacing: 10) {
                ForEach(Self.reminderPresets, id: \.minutes) { preset in
                    let isSelected = reminderMinutes == preset.minutes
                    Button {
                        if haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                        withAnimation(.snappy(duration: 0.2)) {
                            reminderMinutes = preset.minutes
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(preset.label)
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .foregroundStyle(isSelected ? .onAccent : .ink)
                        .background(isSelected ? AnyShapeStyle(.accent) : AnyShapeStyle(.well), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            HStack {
                Label("Reminder time", systemImage: "clock")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.ink)
                Spacer()
                DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(.accent)
            }
            .padding(.top, 2)
        }
        .padding(20)
        .background(.surface, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    // MARK: - Helpers

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: reminderMinutes / 60, minute: reminderMinutes % 60)) ?? .now
        } set: {
            let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
            reminderMinutes = (c.hour ?? 20) * 60 + (c.minute ?? 0)
        }
    }

    private var formattedReminderTime: String {
        let date = Calendar.current.date(from: DateComponents(hour: reminderMinutes / 60, minute: reminderMinutes % 60)) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var starterEntry: Catalog.Entry? {
        starters.first(where: { $0.id == starterID }) ?? starters.first ?? store.challenge(on: .now)
    }

    private func completeOnboarding() {
        finish(starterEntry)
    }
}
