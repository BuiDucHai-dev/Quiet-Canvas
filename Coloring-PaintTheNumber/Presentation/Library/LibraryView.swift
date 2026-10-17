//
//  LibraryView.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

/// Tab 1 (Home): calm daily feed with in-progress works, mood shelves, and pinned favorite themes.
struct LibraryView: View {
    @Environment(Router.self) private var router
    @Environment(\.store) private var store
    @AppStorage("favorites") private var favorites = ""
    @AppStorage("starterID") private var starterID = ""
    @State private var settings = false
    private let catalog = Catalog.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 30) {
                    header
                    if !store.premium { premiumBanner }
                    let top = LibraryUseCases.topShelf(
                        catalog: catalog,
                        meta: store.meta,
                        favorites: favorites,
                        starterID: starterID,
                        status: store.status,
                        isUnlocked: store.isUnlocked
                    )
                    if let top {
                        Shelf(title: top.title, entries: top.entries) {
                            if let note = top.note { Text(note).font(.subheadline).foregroundStyle(.ink2) }
                        }
                    }
                    // suggestion shelves only offer untouched pictures that aren't already shown above
                    let daily = LibraryUseCases.dailyPicks(
                        catalog: catalog,
                        excluding: Set((top?.entries ?? []).map(\.id)),
                        status: store.status,
                        isUnlocked: store.isUnlocked
                    )
                    if !daily.isEmpty {
                        Shelf(title: "Daily picks", entries: daily) {
                            Text("Refreshes daily").font(.subheadline).foregroundStyle(.ink2)
                        }
                    }
                    let shown = Set((top?.entries ?? []).map(\.id) + daily.map(\.id))
                    let quick = LibraryUseCases.quickPicks(catalog: catalog, excluding: shown, status: store.status)
                    if !quick.isEmpty {
                        Shelf(title: "Quick 10-minute picks", entries: quick)
                    }
                    let deep = LibraryUseCases.deepFocusPicks(catalog: catalog, excluding: shown, status: store.status)
                    if !deep.isEmpty {
                        Shelf(title: "Deep focus", entries: deep) {
                            Text("20+ min").font(.subheadline).foregroundStyle(.ink2)
                        }
                    }
                    ForEach(LibraryUseCases.pinnedThemes(catalog: catalog, favorites: favorites)) { t in
                        Shelf(title: t.title, entries: catalog.entries(in: t.id)) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.accent)
                                    .accessibilityHidden(true)
                                Button("See all") { router.explore(theme: t.id) }
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.accent)
                                    .frame(minHeight: 48)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    explorePrompt
                }
                .padding(.bottom, 24)
            }
            .background(.paper)
            .paperStatusBar()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $settings) { SettingsView() }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("QUIET CANVAS").font(.eyebrow).tracking(1).foregroundStyle(.ink2)
                Text(greeting).font(.display).foregroundStyle(.ink)
            }
            Spacer()
            Button { settings = true } label: { CircleIcon(systemName: "gearshape") }
                .buttonStyle(.pressable)
                .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    private var premiumBanner: some View {
        Button { router.paywall = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill").font(.system(size: 20, weight: .semibold)).foregroundStyle(.accent)
                    .frame(width: 44, height: 44).background(.accentSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock every picture").font(.title3.weight(.semibold)).foregroundStyle(.ink)
                    Text("Try Premium free for 7 days").font(.subheadline).foregroundStyle(.ink2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundStyle(.ink2)
            }
            .padding(14)
            .background(.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.pressable)
        .padding(.horizontal, 20)
    }

    private var explorePrompt: some View {
        Button { router.explore(theme: nil) } label: {
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.accent)
                    .frame(width: 44, height: 44)
                    .background(.accentSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Explore all \(catalog.themes.count) themes").font(.title3.weight(.semibold)).foregroundStyle(.ink)
                    Text("Search and filter \(catalog.templates.count) pictures by theme or difficulty")
                        .font(.subheadline).foregroundStyle(.ink2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundStyle(.ink2)
            }
            .padding(14)
            .background(.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.pressable)
        .padding(.horizontal, 20)
    }
}
