//
//  ChallengeUseCases.swift
//  Coloring-PaintTheNumber
//

import Foundation

enum ChallengeUseCases {
    static func status(for entry: Catalog.Entry, meta: [String: WorkMeta]) -> WorkStatus {
        guard let m = meta[entry.id], m.count > 0 else { return .new }
        return m.completed != nil ? .done : .progress(Double(m.count) / Double(max(entry.regions, 1)))
    }

    /// Added after this user installed the app, within the last two weeks. Launch content is never "new".
    static func isNew(_ entry: Catalog.Entry, installDay: Date, now: Date = .now) -> Bool {
        guard let d = Day.date(entry.added) else { return false }
        return d > installDay && now.timeIntervalSince(d) < 14 * 86_400
    }

    /// Free pictures, Premium, today's challenge, and anything already started stay paintable.
    static func isUnlocked(_ entry: Catalog.Entry, premium: Bool, meta: [String: WorkMeta], todayChallengeID: String) -> Bool {
        entry.free || premium || entry.id == todayChallengeID || (meta[entry.id]?.count ?? 0) > 0
    }

    /// Challenge picture for `day`: #1 on installDay, #2 on the next day, and so on.
    static func challenge(on day: Date, in catalog: Catalog, installDay: Date, calendar: Calendar = .current) -> Catalog.Entry {
        let pool = catalog.challenges.isEmpty ? catalog.templates : catalog.challenges
        let n = calendar.dateComponents([.day], from: installDay, to: calendar.startOfDay(for: day)).day ?? 0
        return pool[(n % pool.count + pool.count) % pool.count]
    }

    /// Updates picture metadata and daily challenge streak when regions are filled.
    static func recordFill(
        entry: Catalog.Entry,
        filledCount: Int,
        total: Int,
        now: Date = .now,
        todayChallengeID: String,
        installDay: Date,
        meta: inout [String: WorkMeta],
        challengeDays: inout Set<String>,
        bestStreak: inout Int
    ) -> Bool {
        var m = meta[entry.id] ?? WorkMeta()
        m.count = filledCount
        m.edited = now
        var challengeUpdated = false
        if filledCount >= total, m.completed == nil {
            m.completed = now
            if entry.id == todayChallengeID {
                challengeDays.insert(Day.key(now))
                let today = Calendar.current.startOfDay(for: now)
                let streak = Streak(done: challengeDays, install: installDay, today: today)
                bestStreak = max(bestStreak, streak.current)
                challengeUpdated = true
            }
        }
        meta[entry.id] = m
        return challengeUpdated
    }

    static func suggestions(
        after entry: Catalog.Entry,
        in catalog: Catalog,
        status: (Catalog.Entry) -> WorkStatus,
        isUnlocked: (Catalog.Entry) -> Bool
    ) -> [Catalog.Entry] {
        Array(
            catalog.entries(in: entry.theme)
                .filter { $0.id != entry.id && status($0) != .done }
                .sorted { isUnlocked($0) && !isUnlocked($1) }
                .prefix(3)
        )
    }
}
