//
//  PaywallView.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

/// Placeholder until StoreKit 2 is wired up. The approved design is kept in Assets ("PaywallDesign")
/// and docs/design/03_paywall.png: yearly plan with 7-day trial (default) + weekly, restore, terms, privacy.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.store) private var store

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Premium is coming soon").font(.heading).foregroundStyle(.ink).padding(.top, 70)
                    Image("PaywallDesign").resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.line))
                        .padding(.horizontal, 40)
                        .accessibilityLabel("Paywall design preview")
                    #if DEBUG
                    Button("Unlock everything (debug)") { store.premium = true; dismiss() }
                        .buttonStyle(PrimaryButton()).padding(.horizontal, 20)
                    if store.premium {
                        Button("Turn Premium off (debug)") { store.premium = false; dismiss() }
                            .buttonStyle(SecondaryButton()).padding(.horizontal, 20)
                    }
                    #endif
                }
                .padding(.bottom, 24)
            }
            Button { dismiss() } label: { CircleIcon(systemName: "xmark") }
                .buttonStyle(.pressable)
                .accessibilityLabel("Close")
                .padding(20)
        }
    }
}
