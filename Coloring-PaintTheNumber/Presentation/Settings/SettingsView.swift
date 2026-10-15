//
//  SettingsView.swift
//  Coloring-PaintTheNumber
//

import StoreKit
import SwiftUI

struct SettingsView: View {
    private static let highlightPresets: [(name: String, hex: String)] = [
        ("Gray", "#475569"),
        ("Blue", "#2478E0"),
        ("Teal", "#0D9488"),
        ("Purple", "#7C3AED"),
        ("Terracotta", "#B4532F")
    ]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.store) private var store
    @AppStorage("numberSize") private var numberSize = 0
    @AppStorage("highlight") private var highlight = true
    @AppStorage("highlightHex") private var highlightHex = "#475569"
    @AppStorage("autoNext") private var autoNext = true
    @AppStorage("haptics") private var haptics = true
    @AppStorage("hideDone") private var hideDone = false
    @AppStorage("reminder") private var reminder = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 20 * 60
    @State private var paywall = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section { premiumCard }
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                Section("Painting") {
                    Picker(selection: $numberSize) {
                        Text("Normal").tag(0)
                        Text("Large").tag(1)
                        Text("Extra Large").tag(2)
                    } label: { row("textformat.size", .accent, "Number size") }
                    Toggle(isOn: $highlight) { row("sparkles", .orange, "Highlight matching shapes") }
                    if highlight {
                        VStack(alignment: .leading, spacing: 12) {
                            row("paintpalette", Color(hex: highlightHex), "Highlight color")
                            HStack(spacing: 10) {
                                ForEach(Self.highlightPresets, id: \.hex) { preset in
                                    let selected = highlightHex.caseInsensitiveCompare(preset.hex) == .orderedSame
                                    Button {
                                        highlightHex = preset.hex
                                    } label: {
                                        ZStack {
                                            Circle().fill(Color(hex: preset.hex))
                                            Circle().strokeBorder(.black.opacity(0.15), lineWidth: 1)
                                            if selected {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .frame(width: 38, height: 38)
                                        .padding(4)
                                        .overlay(Circle().strokeBorder(.ink, lineWidth: 2).opacity(selected ? 1 : 0))
                                        .frame(minWidth: 48, minHeight: 48)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.pressable)
                                    .accessibilityLabel(preset.name)
                                    .accessibilityAddTraits(selected ? .isSelected : [])
                                }
                                Spacer(minLength: 4)
                                ColorPicker("Custom highlight color", selection: customHighlightColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .scaleEffect(1.15)
                                    .frame(minWidth: 48, minHeight: 48)
                                    .accessibilityLabel("Custom highlight color")
                            }
                            .padding(.leading, 38)
                        }
                        .padding(.vertical, 6)
                    }
                    Toggle(isOn: $autoNext) { row("arrow.right", .green, "Auto-pick next color") }
                    Toggle(isOn: $hideDone) { row("eye.slash", .teal, "Hide finished colors") }
                    Toggle(isOn: $haptics) { row("hand.tap", .purple, "Vibration") }
                }
                Section("Challenges") {
                    Toggle(isOn: $reminder) { row("bell", .orange, "Daily reminder") }
                    if reminder {
                        DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) { row("clock", .gray, "Reminder time") }
                    }
                }
                Section("Support") {
                    Button { requestReview() } label: { row("star", .yellow, "Rate Quiet Canvas") }
                }
                Section("Account") {
                    Button(role: .destructive) { confirmReset = true } label: { row("trash", .red, "Reset all progress") }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.paper)
            .tint(.accent)
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.font(.body.weight(.semibold)) } }
            .onChange(of: reminder) { _, on in
                guard on else { Reminder.cancel(); return }
                Task { if await !Reminder.schedule(minutes: reminderMinutes) { reminder = false } }
            }
            .onChange(of: reminderMinutes) { _, m in Task { _ = await Reminder.schedule(minutes: m) } }
            .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { store.resetAll() }
            } message: { Text("Every picture, preview and challenge streak will be cleared. This can't be undone.") }
            .fullScreenCover(isPresented: $paywall) { PaywallView() }
        }
    }

    private var customHighlightColor: Binding<Color> {
        Binding(
            get: { Color(hex: highlightHex) },
            set: { highlightHex = $0.hexString }
        )
    }

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: reminderMinutes / 60, minute: reminderMinutes % 60)) ?? .now
        } set: {
            let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
            reminderMinutes = (c.hour ?? 20) * 60 + (c.minute ?? 0)
        }
    }

    private var premiumCard: some View {
        Button { paywall = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill").font(.title)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Quiet Canvas Premium").font(.title3.weight(.semibold))
                    Text(store.premium ? "Active. Thank you!" : "All pictures and past challenges").font(.subheadline).opacity(0.9)
                }
                Spacer()
                if !store.premium {
                    Text("Try free").font(.body.weight(.semibold)).foregroundStyle(.accent)
                        .padding(.horizontal, 16).padding(.vertical, 10).background(.white, in: Capsule())
                }
            }
            .foregroundStyle(.onAccent)
            .padding(18)
            .background(.accent, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.pressable)
    }

    private func row(_ icon: String, _ color: Color, _ title: String) -> some View {
        Label {
            Text(title).font(.body).foregroundStyle(color == .red ? .red : .ink)
        } icon: {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 34, height: 34).background(color, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 2)
    }
}
