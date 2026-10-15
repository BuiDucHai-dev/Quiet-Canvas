//
//  Streak.swift
//  Coloring-PaintTheNumber
//

import Foundation

nonisolated enum DayState { case done, rest, missed, today, future, before }

/// Challenge streak rules: each calendar week forgives its first missed day ("rest").
nonisolated struct Streak {
    let done: Set<String>
    let install: Date
    let today: Date
    var cal = Calendar.current

    func state(_ day: Date) -> DayState {
        let d = cal.startOfDay(for: day)
        if done.contains(Day.key(d, cal)) { return .done }
        if d > today { return .future }
        if d == today { return .today }
        if d < install { return .before }
        return firstMissOfWeek(d) ? .rest : .missed
    }

    private func firstMissOfWeek(_ d: Date) -> Bool {
        guard let week = cal.dateInterval(of: .weekOfYear, for: d) else { return false }
        var x = max(week.start, install)
        while x < d {
            if !done.contains(Day.key(x, cal)) { return false }
            x = cal.date(byAdding: .day, value: 1, to: x)!
        }
        return true
    }

    /// Days in the current run (rest days included), ending today, or yesterday while today is still open.
    var current: Int {
        var d = state(today) == .done ? today : cal.date(byAdding: .day, value: -1, to: today)!
        var run: [DayState] = []
        while case let s = state(d), s == .done || s == .rest {
            run.append(s)
            d = cal.date(byAdding: .day, value: -1, to: d)!
        }
        while run.last == .rest { run.removeLast() }
        return run.contains(.done) ? run.count : 0
    }

    var restLeftThisWeek: Bool {
        guard let week = cal.dateInterval(of: .weekOfYear, for: today) else { return false }
        var x = max(week.start, install)
        while x < today {
            if state(x) == .rest { return false }
            x = cal.date(byAdding: .day, value: 1, to: x)!
        }
        return true
    }
}

struct WorkMeta: Codable, Equatable {
    var count = 0
    var edited = Date.distantPast
    var completed: Date?
    var seconds = 0.0
}

enum WorkStatus: Equatable { case new, progress(Double), done }

protocol ProgressRepository {
    func loadMeta() -> [String: WorkMeta]
    func saveMeta(_ meta: [String: WorkMeta])
    func loadFilled(_ id: String) -> Set<Int>
    func saveFilled(_ filled: Set<Int>, for id: String)
    func removeFilled(_ id: String)
    func loadChallengeDays() -> Set<String>
    func saveChallengeDays(_ days: Set<String>)
    func loadBestStreak() -> Int
    func saveBestStreak(_ streak: Int)
    func loadPremium() -> Bool
    func savePremium(_ premium: Bool)
    func loadOrCreateInstallDay(calendar: Calendar) -> Date
    func resetChallengeProgress()
}
