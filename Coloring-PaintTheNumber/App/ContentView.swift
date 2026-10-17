//
//  ContentView.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

/// App-wide presentation state: the painting cover, locked-picture preview and paywall.
@Observable
final class Router {
    var tab = 0
    var selectedTheme: String?
    var painting: Catalog.Entry?
    var preview: Catalog.Entry?
    var paywall = false
    /// Painting to open once the preview sheet has finished dismissing.
    var afterPreview: Catalog.Entry?
    @ObservationIgnored private let store: Store

    init(store: Store = .shared) {
        self.store = store
    }

    func open(_ e: Catalog.Entry) {
        if store.isUnlocked(e) { painting = e } else { preview = e }
    }

    func explore(theme: String? = nil) {
        selectedTheme = theme
        tab = 1
    }
}

struct ContentView: View {
//    @AppStorage("onboarded") private var onboarded = false
    @State private var onboarded = false
    @State private var router = Router()
    @Environment(\.store) private var store

    var body: some View {
        if !onboarded {
            OnboardingView { starter in
                withAnimation(.smooth(duration: 0.32)) {
                    onboarded = true
                }
                if let starter {
                    Task { router.preview = starter }
                }
            }
            .transition(.opacity)
        } else {
            TabView(selection: $router.tab) {
                Tab("Home", systemImage: "house", value: 0) { LibraryView() }
                Tab("Explore", systemImage: "magnifyingglass", value: 1) { ExploreView() }
                Tab("Challenges", systemImage: "flame", value: 2) { ChallengesView() }
                    .badge(store.streak.state(.now) == .done ? 0 : 1)
                Tab("My Works", systemImage: "photo.on.rectangle.angled", value: 3) { MyWorksView() }
            }
            .tint(.accent)
            .environment(router)
            .fullScreenCover(item: $router.painting) { PaintView(entry: $0) }
            .sheet(item: $router.preview, onDismiss: {
                if let next = router.afterPreview { router.afterPreview = nil; router.painting = next }
            }) { PreviewSheet(entry: $0).environment(router) }
            .fullScreenCover(isPresented: $router.paywall) { PaywallView() }
        }
    }
}

#Preview { ContentView() }
