//
//  LibraryUseCases.swift
//  Coloring-PaintTheNumber
//

import Foundation

enum LibraryUseCases {
    struct ShelfContent {
        let title: String
        let note: String?
        let entries: [Catalog.Entry]
    }

    /// "Continue painting" when something is in progress, "Start here" for a brand-new user.
    static func topShelf(
        catalog: Catalog,
        meta: [String: WorkMeta],
        favorites: String,
        status: (Catalog.Entry) -> WorkStatus,
        isUnlocked: (Catalog.Entry) -> Bool
    ) -> ShelfContent? {
        let started = catalog.templates
            .filter { if case .progress = status($0) { true } else { false } }
            .sorted { (meta[$0.id]?.edited ?? .distantPast) > (meta[$1.id]?.edited ?? .distantPast) }
        if !started.isEmpty {
            return ShelfContent(title: "Continue painting", note: "\(started.count) in progress", entries: Array(started.prefix(10)))
        }
        guard meta.isEmpty else { return nil }
        let pool = catalog.templates.filter { $0.difficulty == .easy && isUnlocked($0) }
        let fav = Favorites.ids(favorites)
        let liked = pool.filter { fav.contains($0.theme) }
        return ShelfContent(title: "Start here", note: nil, entries: Array((liked + pool.filter { !liked.contains($0) }).prefix(5)))
    }

    /// 8 untouched pictures rotated deterministically each calendar day, with unlocked picks up front.
    static func dailyPicks(
        catalog: Catalog,
        excluding shown: Set<String>,
        now: Date = .now,
        status: (Catalog.Entry) -> WorkStatus,
        isUnlocked: (Catalog.Entry) -> Bool
    ) -> [Catalog.Entry] {
        let pool = catalog.templates.filter { status($0) == .new && !shown.contains($0.id) }
        guard !pool.isEmpty else { return [] }
        let day = Int(Calendar.current.startOfDay(for: now).timeIntervalSinceReferenceDate / 86_400)
        func score(_ e: Catalog.Entry) -> Int {
            abs(e.id.unicodeScalars.reduce(day &* 1_103_515_245) { ($0 &* 31) &+ Int($1.value) })
        }
        let rotated = pool.sorted { score($0) < score($1) }
        let unlocked = rotated.filter { isUnlocked($0) }.prefix(3)
        let unlockedIDs = Set(unlocked.map(\.id))
        return Array((unlocked + rotated.filter { !unlockedIDs.contains($0.id) }).prefix(8))
    }

    static func quickPicks(
        catalog: Catalog,
        excluding shown: Set<String>,
        status: (Catalog.Entry) -> WorkStatus
    ) -> [Catalog.Entry] {
        Array(catalog.templates.filter { $0.difficulty == .easy && status($0) == .new && !shown.contains($0.id) }.prefix(10))
    }

    static func deepFocusPicks(
        catalog: Catalog,
        excluding shown: Set<String>,
        status: (Catalog.Entry) -> WorkStatus
    ) -> [Catalog.Entry] {
        Array(
            catalog.templates
                .filter { $0.difficulty == .hard && status($0) == .new && !shown.contains($0.id) }
                .sorted { $0.regions > $1.regions }
                .prefix(10)
        )
    }

    /// Only pinned favorite themes appear as shelves on Home (falls back to top 2 themes if none pinned yet).
    static func pinnedThemes(catalog: Catalog, favorites: String) -> [Catalog.Theme] {
        let fav = Favorites.ids(favorites)
        let matched = fav.compactMap { catalog.theme($0) }
        return matched.isEmpty ? Array(catalog.themes.prefix(2)) : matched
    }

    static func orderedThemes(catalog: Catalog, favorites: String) -> [Catalog.Theme] {
        let fav = Favorites.ids(favorites)
        return catalog.themes.sorted { (fav.firstIndex(of: $0.id) ?? .max) < (fav.firstIndex(of: $1.id) ?? .max) }
    }

    static func filterPictures(
        catalog: Catalog,
        themeID: String?,
        favoritesOnly: Bool,
        favorites: String,
        freeOnly: Bool,
        difficulty: Catalog.Difficulty?,
        query: String,
        isUnlocked: (Catalog.Entry) -> Bool
    ) -> [Catalog.Entry] {
        let fav = Set(Favorites.ids(favorites))
        let base: [Catalog.Entry]
        if let themeID {
            base = catalog.entries(in: themeID)
        } else if favoritesOnly {
            base = catalog.templates.filter { fav.contains($0.theme) }
        } else {
            base = catalog.templates
        }
        return base.filter { e in
            if freeOnly && !isUnlocked(e) { return false }
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

    static func myWorks(
        catalog: Catalog,
        meta: [String: WorkMeta],
        status: (Catalog.Entry) -> WorkStatus
    ) -> (inProgress: [Catalog.Entry], completed: [Catalog.Entry]) {
        let started = catalog.all.filter { meta[$0.id].map { $0.count > 0 } ?? false }
        let done = started.filter { status($0) == .done }
            .sorted { (meta[$0.id]?.completed ?? .distantPast) > (meta[$1.id]?.completed ?? .distantPast) }
        let progress = started.filter { status($0) != .done }
            .sorted { (meta[$0.id]?.edited ?? .distantPast) > (meta[$1.id]?.edited ?? .distantPast) }
        return (progress, done)
    }
}
