//
//  ExploreView.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

/// Tab 2 (Explore): always displays the picture grid, with search, a theme dropdown, and difficulty/free filters.
struct ExploreView: View {
    @Environment(Router.self) private var router
    @Environment(\.store) private var store
    @AppStorage("favorites") private var favorites = ""
    @State private var query = ""
    @State private var difficulty: Catalog.Difficulty?
    @State private var freeOnly = false
    @State private var favoritesOnly = false
    private let catalog = Catalog.shared

    private var activeThemeTitle: String {
        if favoritesOnly { return "Favorites" }
        if let id = router.selectedTheme, let theme = catalog.theme(id) { return theme.title }
        return "All Themes"
    }

    var body: some View {
        let items = LibraryUseCases.filterPictures(
            catalog: catalog,
            themeID: router.selectedTheme,
            favoritesOnly: favoritesOnly,
            favorites: favorites,
            freeOnly: freeOnly,
            difficulty: difficulty,
            query: query,
            isUnlocked: store.isUnlocked
        )
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header(count: items.count)
                    searchBar
                    filterBar
                    pictureGrid(items: items)
                }
                .padding(.bottom, 24)
            }
            .background(.paper)
            .paperStatusBar()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func header(count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Explore").font(.display).foregroundStyle(.ink)
            Spacer()
            Text("\(count) \(count == 1 ? "picture" : "pictures")")
                .font(.subheadline).foregroundStyle(.ink2)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.body.weight(.medium)).foregroundStyle(.ink2)
            TextField("Search pictures or themes...", text: $query)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.ink)
            if !query.isEmpty {
                Button {
                    withAnimation(.snappy(duration: 0.15)) { query = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.ink2)
                        .frame(minWidth: 48, minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, query.isEmpty ? 16 : 4)
        .frame(minHeight: 52)
        .background(.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(.line))
        .padding(.horizontal, 20)
    }

    private var filterBar: some View {
        let themeActive = router.selectedTheme != nil || favoritesOnly
        let orderedThemes = LibraryUseCases.orderedThemes(catalog: catalog, favorites: favorites)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Menu {
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            router.selectedTheme = nil
                            favoritesOnly = false
                        }
                    } label: {
                        if router.selectedTheme == nil && !favoritesOnly {
                            Label("All Themes (\(catalog.templates.count))", systemImage: "checkmark")
                        } else {
                            Text("All Themes (\(catalog.templates.count))")
                        }
                    }

                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            router.selectedTheme = nil
                            favoritesOnly = true
                        }
                    } label: {
                        Label("Favorite Themes", systemImage: favoritesOnly ? "checkmark" : "heart.fill")
                    }

                    Divider()

                    ForEach(orderedThemes) { t in
                        let count = catalog.entries(in: t.id).count
                        let isSelected = router.selectedTheme == t.id
                        let isFav = Favorites.contains(t.id, in: favorites)
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                favoritesOnly = false
                                router.selectedTheme = t.id
                            }
                        } label: {
                            if isSelected {
                                Label("\(t.title) (\(count))", systemImage: "checkmark")
                            } else if isFav {
                                Label("\(t.title) (\(count))", systemImage: "heart.fill")
                            } else {
                                Text("\(t.title) (\(count))")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: favoritesOnly ? "heart.fill" : "square.grid.2x2")
                            .font(.subheadline.weight(.semibold))
                        Text(activeThemeTitle)
                            .font(.body.weight(.semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 46)
                    .foregroundStyle(themeActive ? AnyShapeStyle(.paper) : AnyShapeStyle(.ink))
                    .background(themeActive ? AnyShapeStyle(.ink) : AnyShapeStyle(.surface), in: Capsule())
                    .overlay(Capsule().strokeBorder(themeActive ? .clear : Color.line))
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Filter by theme: \(activeThemeTitle)")

                if let themeID = router.selectedTheme {
                    let isFav = Favorites.contains(themeID, in: favorites)
                    Button {
                        withAnimation(.snappy(duration: 0.2)) { Favorites.toggle(themeID, in: &favorites) }
                    } label: {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(isFav ? .accent : .ink2)
                            .frame(width: 46, height: 46)
                            .background(.surface, in: Circle())
                            .overlay(Circle().strokeBorder(.line))
                            .frame(minWidth: 48, minHeight: 48)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(isFav ? "Unpin theme from Home" : "Pin theme to Home")
                }

                filterChip(title: "Free", icon: "lock.open.fill", active: freeOnly) {
                    freeOnly.toggle()
                }
                ForEach(Catalog.Difficulty.allCases, id: \.self) { level in
                    filterChip(title: level.label, icon: nil, active: difficulty == level) {
                        difficulty = difficulty == level ? nil : level
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    @ViewBuilder
    private func pictureGrid(items: [Catalog.Entry]) -> some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label(favoritesOnly && Favorites.ids(favorites).isEmpty ? "No favorite themes yet" : "No matching pictures",
                      systemImage: favoritesOnly && Favorites.ids(favorites).isEmpty ? "heart" : "magnifyingglass")
            } description: {
                Text(favoritesOnly && Favorites.ids(favorites).isEmpty
                     ? "Select a theme from the dropdown and tap the heart icon to pin it to Home and Favorites."
                     : "Try clearing a filter or searching for another keyword.")
            } actions: {
                Button("Reset filters") {
                    withAnimation(.snappy(duration: 0.2)) {
                        router.selectedTheme = nil
                        difficulty = nil
                        freeOnly = false
                        favoritesOnly = false
                        query = ""
                    }
                }
                .buttonStyle(SecondaryButton())
                .padding(.top, 8)
            }
            .padding(.top, 30)
        } else {
            LazyVGrid(columns: adaptiveGrid, alignment: .leading, spacing: 18) {
                ForEach(items) { e in
                    Button { router.open(e) } label: { Thumb(entry: e) }
                        .buttonStyle(.pressable)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(title: String, icon: String?, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2), action)
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon).font(.footnote.weight(.semibold))
                }
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 46)
            .foregroundStyle(active ? AnyShapeStyle(.onAccent) : AnyShapeStyle(.ink2))
            .background(active ? AnyShapeStyle(.accent) : AnyShapeStyle(.well), in: Capsule())
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}
