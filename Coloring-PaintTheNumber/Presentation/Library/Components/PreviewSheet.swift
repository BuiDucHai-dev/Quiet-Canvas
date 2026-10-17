//
//  PreviewSheet.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

/// Sheet for previewing a picture (either an unlocked starter recommendation or a locked picture).
struct PreviewSheet: View {
    let entry: Catalog.Entry
    @Environment(Router.self) private var router
    @Environment(\.store) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var paywall = false

    var body: some View {
        let unlocked = store.isUnlocked(entry)
        VStack(spacing: 0) {
            if unlocked {
                Text("READY TO COLOR")
                    .font(.eyebrow)
                    .tracking(1)
                    .foregroundStyle(.accent)
                    .padding(.top, 24)
            }
            if let img = UIImage(named: entry.thumb) {
                Image(uiImage: img).resizable().aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(6).background(.white, in: RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    .frame(maxWidth: 300)
                    .padding(.top, unlocked ? 14 : 28)
            }
            Text(entry.title).font(.system(.title, design: .serif, weight: .semibold)).foregroundStyle(.ink).padding(.top, 20)
            HStack(spacing: 6) {
                DifficultyDots(difficulty: entry.difficulty)
                Text("· \(entry.regions) shapes · \(entry.colors) colors · about \(entry.minutes) min")
            }
            .font(.subheadline).foregroundStyle(.ink2).padding(.top, 6)
            if unlocked {
                Button {
                    router.afterPreview = entry
                    dismiss()
                } label: {
                    Label("Start painting", systemImage: "paintbrush.pointed.fill")
                }
                .buttonStyle(PrimaryButton())
                .padding(.top, 24)

                Button("Browse library first") {
                    dismiss()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.ink2)
                .frame(minHeight: 48)
                .contentShape(Rectangle())
                .padding(.top, 10)
            } else {
                Button { paywall = true } label: { Label("Unlock with Premium", systemImage: "crown.fill") }
                    .buttonStyle(PrimaryButton()).padding(.top, 24)
                Button("Try today's free challenge instead") {
                    router.afterPreview = store.challenge(on: .now)
                    dismiss()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.accent)
                .frame(minHeight: 48)
                .contentShape(Rectangle())
                .padding(.top, 10)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(.paper)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $paywall) { PaywallView() }
        .onChange(of: store.premium) { _, isPremium in
            if isPremium { router.afterPreview = entry; dismiss() }
        }
    }
}
