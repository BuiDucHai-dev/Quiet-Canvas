//
//  CompletionView.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

/// Shown when the last shape is filled (or when opening a finished picture).
struct CompletionView: View {
    let model: PaintModel
    let image: UIImage
    let minutes: Int
    let close: () -> Void
    let next: (Catalog.Entry) -> Void
    @Environment(\.store) private var store
    @State private var saved = false
    @State private var saveError = false
    @State private var paywall = false
    @AppStorage("reminder") private var reminder = false
    @AppStorage("reminderAsked") private var reminderAsked = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 20 * 60

    var body: some View {
        let entry = model.entry
        let isChallenge = entry.id == store.challenge(on: .now).id && store.challengeDays.contains(Day.key(.now))
        let picture = Image(uiImage: image)
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: close) { CircleIcon(systemName: "xmark") }
                        .buttonStyle(.pressable)
                        .accessibilityLabel("Close")
                }
                if isChallenge {
                    Label("\(store.streak.current) day streak", systemImage: "flame.fill")
                        .font(.body.weight(.semibold)).foregroundStyle(.accent)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.accentSoft, in: Capsule())
                }
                Text("Beautiful work").font(.display).foregroundStyle(.ink).padding(.top, 14)
                Text("\(entry.title) · \(model.template.regions.count) shapes · \(minutes) min")
                    .font(.body).foregroundStyle(.ink2).padding(.top, 6)
                picture.resizable().aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(8).background(.white, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    .frame(maxWidth: 360).padding(.top, 22)
                    .accessibilityLabel(entry.title)
                HStack(spacing: 12) {
                    ShareLink(item: picture, preview: SharePreview(entry.title, image: picture)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButton())
                    Button(action: saveToPhotos) {
                        Label(saved ? "Saved" : "Save", systemImage: saved ? "checkmark" : "arrow.down.to.line")
                    }
                    .buttonStyle(SecondaryButton())
                    .disabled(saved)
                }
                .padding(.top, 22)
                if isChallenge && !reminder && !reminderAsked { reminderCard.padding(.top, 22) }
                suggestions.padding(.top, 30)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(.paper)
        .alert("Unable to Save Photo", isPresented: $saveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please allow Photos access in Settings to save your finished artwork.")
        }
        .fullScreenCover(isPresented: $paywall) { PaywallView() }
    }

    private func saveToPhotos() {
        Task {
            if await PhotoSaver.save(image) {
                withAnimation(.snappy(duration: 0.2)) { saved = true }
            } else {
                saveError = true
            }
        }
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Come back tomorrow?", systemImage: "bell").font(.title3.weight(.semibold)).foregroundStyle(.ink)
            Text("A gentle reminder each evening keeps your streak going.").font(.body).foregroundStyle(.ink2)
            HStack {
                Button("Remind me") {
                    reminderAsked = true
                    Task { reminder = await Reminder.schedule(minutes: reminderMinutes) }
                }
                .buttonStyle(PrimaryButton())
                Button("Not now") { reminderAsked = true }.buttonStyle(SecondaryButton())
            }
        }
        .padding(16)
        .background(.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder private var suggestions: some View {
        let more = ChallengeUseCases.suggestions(
            after: model.entry,
            in: Catalog.shared,
            status: store.status,
            isUnlocked: store.isUnlocked
        )
        if !more.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Paint another").font(.heading).foregroundStyle(.ink)
                    Spacer()
                    Button("Library", action: close)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.accent)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                }
                HStack(alignment: .top, spacing: 12) {
                    ForEach(more) { e in
                        Button { store.isUnlocked(e) ? next(e) : (paywall = true) } label: { Thumb(entry: e) }
                            .buttonStyle(.pressable)
                    }
                }
            }
        }
    }
}
