import SwiftUI

enum Favorites {
    static func ids(_ raw: String) -> [String] { raw.split(separator: ",").map(String.init) }
    static func contains(_ id: String, in raw: String) -> Bool { ids(raw).contains(id) }
    static func toggle(_ id: String, in raw: inout String) {
        var list = ids(raw)
        if let i = list.firstIndex(of: id) { list.remove(at: i) } else { list.insert(id, at: 0) }
        raw = list.joined(separator: ",")
    }
}

/// Tab 1 (Home): calm daily feed with in-progress works, mood shelves, and pinned favorite themes.
struct LibraryView: View {
    @Environment(Router.self) private var router
    @AppStorage("favorites") private var favorites = ""
    @State private var settings = false
    private let catalog = Catalog.shared
    private var store: Store { .shared }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 30) {
                    header
                    if !store.premium { premiumBanner }
                    let top = topShelf
                    if let top {
                        Shelf(title: top.title, entries: top.entries) {
                            if let note = top.note { Text(note).font(.subheadline).foregroundStyle(.ink2) }
                        }
                    }
                    // suggestion shelves only offer untouched pictures that aren't already shown above
                    let daily = dailyPicks(excluding: Set((top?.entries ?? []).map(\.id)))
                    if !daily.isEmpty {
                        Shelf(title: "Daily picks", entries: daily) {
                            Text("Refreshes daily").font(.subheadline).foregroundStyle(.ink2)
                        }
                    }
                    let shown = Set((top?.entries ?? []).map(\.id) + daily.map(\.id))
                    let quick = Array(catalog.templates
                        .filter { $0.difficulty == .easy && store.status($0) == .new && !shown.contains($0.id) }.prefix(10))
                    if !quick.isEmpty {
                        Shelf(title: "Quick 10-minute picks", entries: quick)
                    }
                    let deep = Array(catalog.templates
                        .filter { $0.difficulty == .hard && store.status($0) == .new && !shown.contains($0.id) }
                        .sorted { $0.regions > $1.regions }.prefix(10))
                    if !deep.isEmpty {
                        Shelf(title: "Deep focus", entries: deep) {
                            Text("20+ min").font(.subheadline).foregroundStyle(.ink2)
                        }
                    }
                    ForEach(pinnedThemes) { t in
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

    /// "Continue painting" when something is in progress, "Start here" for a brand-new user.
    private var topShelf: (title: String, note: String?, entries: [Catalog.Entry])? {
        let started = catalog.templates
            .filter { if case .progress = store.status($0) { true } else { false } }
            .sorted { (store.meta[$0.id]?.edited ?? .distantPast) > (store.meta[$1.id]?.edited ?? .distantPast) }
        if !started.isEmpty { return ("Continue painting", "\(started.count) in progress", Array(started.prefix(10))) }
        guard store.meta.isEmpty else { return nil }
        let pool = catalog.templates.filter { $0.difficulty == .easy && store.isUnlocked($0) }
        let fav = Favorites.ids(favorites)
        let liked = pool.filter { fav.contains($0.theme) }
        return ("Start here", nil, Array((liked + pool.filter { !liked.contains($0) }).prefix(5)))
    }

    /// 8 untouched pictures rotated deterministically each calendar day, with unlocked picks up front.
    private func dailyPicks(excluding shown: Set<String>) -> [Catalog.Entry] {
        let pool = catalog.templates.filter { store.status($0) == .new && !shown.contains($0.id) }
        guard !pool.isEmpty else { return [] }
        let day = Int(Calendar.current.startOfDay(for: .now).timeIntervalSinceReferenceDate / 86_400)
        func score(_ e: Catalog.Entry) -> Int {
            abs(e.id.unicodeScalars.reduce(day &* 1_103_515_245) { ($0 &* 31) &+ Int($1.value) })
        }
        let rotated = pool.sorted { score($0) < score($1) }
        let unlocked = rotated.filter { store.isUnlocked($0) }.prefix(3)
        let unlockedIDs = Set(unlocked.map(\.id))
        return Array((unlocked + rotated.filter { !unlockedIDs.contains($0.id) }).prefix(8))
    }

    /// Only pinned favorite themes appear as shelves on Home (falls back to top 2 themes if none pinned yet).
    private var pinnedThemes: [Catalog.Theme] {
        let fav = Favorites.ids(favorites)
        let matched = fav.compactMap { catalog.theme($0) }
        return matched.isEmpty ? Array(catalog.themes.prefix(2)) : matched
    }
}

/// Tab 2 (Explore): always displays the picture grid, with search, a theme dropdown, and difficulty/free filters.
struct ExploreView: View {
    @Environment(Router.self) private var router
    @AppStorage("favorites") private var favorites = ""
    @State private var query = ""
    @State private var difficulty: Catalog.Difficulty?
    @State private var freeOnly = false
    @State private var favoritesOnly = false
    private let catalog = Catalog.shared
    private var store: Store { .shared }

    private var activeThemeTitle: String {
        if favoritesOnly { return "Favorites" }
        if let id = router.selectedTheme, let theme = catalog.theme(id) { return theme.title }
        return "All Themes"
    }

    var body: some View {
        let items = filteredPictures
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

    private var orderedThemes: [Catalog.Theme] {
        let fav = Favorites.ids(favorites)
        return catalog.themes.sorted { (fav.firstIndex(of: $0.id) ?? .max) < (fav.firstIndex(of: $1.id) ?? .max) }
    }

    private var filteredPictures: [Catalog.Entry] {
        let fav = Set(Favorites.ids(favorites))
        let base: [Catalog.Entry]
        if let themeID = router.selectedTheme {
            base = catalog.entries(in: themeID)
        } else if favoritesOnly {
            base = catalog.templates.filter { fav.contains($0.theme) }
        } else {
            base = catalog.templates
        }
        return base.filter { e in
            if freeOnly && !store.isUnlocked(e) { return false }
            if let difficulty, e.difficulty != difficulty { return false }
            if !query.isEmpty {
                let themeTitle = catalog.theme(e.theme)?.title ?? ""
                if !e.title.localizedStandardContains(query) && !themeTitle.localizedStandardContains(query) {
                    return false
                }
            }
            return true
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

/// Sheet for a locked picture: big preview and the way to unlock it.
struct PreviewSheet: View {
    let entry: Catalog.Entry
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var paywall = false

    var body: some View {
        VStack(spacing: 0) {
            if let img = UIImage(named: entry.thumb) {
                Image(uiImage: img).resizable().aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(6).background(.white, in: RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    .frame(maxWidth: 300)
                    .padding(.top, 28)
            }
            Text(entry.title).font(.system(.title, design: .serif, weight: .semibold)).foregroundStyle(.ink).padding(.top, 20)
            HStack(spacing: 6) {
                DifficultyDots(difficulty: entry.difficulty)
                Text("· \(entry.regions) shapes · \(entry.colors) colors · about \(entry.minutes) min")
            }
            .font(.subheadline).foregroundStyle(.ink2).padding(.top, 6)
            Button { paywall = true } label: { Label("Unlock with Premium", systemImage: "crown.fill") }
                .buttonStyle(PrimaryButton()).padding(.top, 24)
            Button("Try today's free challenge instead") {
                router.afterPreview = Store.shared.challenge(on: .now)
                dismiss()
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.accent)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
            .padding(.top, 10)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(.paper)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $paywall) { PaywallView() }
        .onChange(of: Store.shared.premium) { _, unlocked in
            if unlocked { router.afterPreview = entry; dismiss() }
        }
    }
}
