import SwiftUI
import UserNotifications

/// Per-picture progress, daily challenge history and progress previews.
/// Filled regions live in UserDefaults (`filled.<id>`), previews as PNGs in Application Support.
@Observable
final class Store {
    static let shared = Store()

    struct Meta: Codable {
        var count = 0
        var edited = Date.distantPast
        var completed: Date?
        var seconds = 0.0
    }
    enum Status: Equatable { case new, progress(Double), done }

    private(set) var meta: [String: Meta]
    private(set) var challengeDays: Set<String>
    private(set) var bestStreak: Int
    /// Bumped per picture when its preview image changes, so views reading it refresh.
    private(set) var previewStamp: [String: Int] = [:]
    var premium: Bool { didSet { defaults.set(premium, forKey: "premium") } }
    let installDay: Date

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let cache = NSCache<NSString, UIImage>()
    @ObservationIgnored private let previewDir = URL.applicationSupportDirectory.appending(path: "previews", directoryHint: .isDirectory)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        meta = defaults.data(forKey: "meta").flatMap { try? JSONDecoder().decode([String: Meta].self, from: $0) } ?? [:]
        challengeDays = Set(defaults.stringArray(forKey: "challengeDays") ?? [])
        bestStreak = defaults.integer(forKey: "bestStreak")
        premium = defaults.bool(forKey: "premium")
        if defaults.object(forKey: "installDay") == nil { defaults.set(Date.now, forKey: "installDay") }
        installDay = Calendar.current.startOfDay(for: defaults.object(forKey: "installDay") as? Date ?? .now)
    }

    // MARK: progress

    func filled(_ id: String) -> Set<Int> { Set(defaults.array(forKey: "filled.\(id)") as? [Int] ?? []) }

    func save(_ e: Catalog.Entry, filled: Set<Int>, total: Int) {
        defaults.set(Array(filled), forKey: "filled.\(e.id)")
        var m = meta[e.id] ?? Meta()
        m.count = filled.count
        m.edited = .now
        if filled.count >= total, m.completed == nil {
            m.completed = .now
            if e.id == challenge(on: .now).id {
                challengeDays.insert(Day.key(.now))
                defaults.set(Array(challengeDays), forKey: "challengeDays")
                bestStreak = max(bestStreak, streak.current)
                defaults.set(bestStreak, forKey: "bestStreak")
            }
        }
        meta[e.id] = m
        persistMeta()
    }

    func addTime(_ id: String, _ seconds: Double) {
        guard meta[id] != nil, seconds > 0 else { return }
        meta[id]!.seconds += seconds
        persistMeta()
    }

    func status(_ e: Catalog.Entry) -> Status {
        guard let m = meta[e.id], m.count > 0 else { return .new }
        return m.completed != nil ? .done : .progress(Double(m.count) / Double(max(e.regions, 1)))
    }

    /// Added after this user installed the app, within the last two weeks. Launch content is never "new".
    func isNew(_ e: Catalog.Entry) -> Bool {
        guard let d = Day.date(e.added) else { return false }
        return d > installDay && Date.now.timeIntervalSince(d) < 14 * 86_400
    }

    /// Free pictures, Premium, today's challenge, and anything already started stay paintable.
    func isUnlocked(_ e: Catalog.Entry) -> Bool {
        e.free || premium || e.id == challenge(on: .now).id || (meta[e.id]?.count ?? 0) > 0
    }

    func reset(_ id: String) {
        defaults.removeObject(forKey: "filled.\(id)")
        meta[id] = nil
        persistMeta()
        setPreview(id, nil)
    }

    func resetAll() {
        for id in meta.keys { reset(id) }
        challengeDays = []
        bestStreak = 0
        defaults.removeObject(forKey: "challengeDays")
        defaults.removeObject(forKey: "bestStreak")
    }

    private func persistMeta() {
        defaults.set(try? JSONEncoder().encode(meta), forKey: "meta")
    }

    // MARK: previews

    func preview(_ id: String) -> UIImage? {
        _ = previewStamp[id]
        if let img = cache.object(forKey: id as NSString) { return img }
        guard let img = UIImage(contentsOfFile: previewDir.appending(path: "\(id).png").path) else { return nil }
        cache.setObject(img, forKey: id as NSString)
        return img
    }

    func setPreview(_ id: String, _ image: UIImage?) {
        let url = previewDir.appending(path: "\(id).png")
        if let image {
            try? FileManager.default.createDirectory(at: previewDir, withIntermediateDirectories: true)
            try? image.pngData()?.write(to: url)
            cache.setObject(image, forKey: id as NSString)
        } else {
            try? FileManager.default.removeItem(at: url)
            cache.removeObject(forKey: id as NSString)
        }
        previewStamp[id, default: 0] += 1
    }

    // MARK: challenges

    var today: Date { Calendar.current.startOfDay(for: .now) }
    var streak: Streak { Streak(done: challengeDays, install: installDay, today: today) }

    /// Challenge picture for `day`: #1 on installDay, #2 on the next day, and so on.
    func challenge(on day: Date) -> Catalog.Entry {
        let pool = Catalog.shared.challenges.isEmpty ? Catalog.shared.templates : Catalog.shared.challenges
        let cal = Calendar.current
        let n = cal.dateComponents([.day], from: installDay, to: cal.startOfDay(for: day)).day ?? 0
        return pool[(n % pool.count + pool.count) % pool.count]
    }
}

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

/// Daily local notification for the challenge.
enum Reminder {
    static func schedule(minutes: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return false }
        center.removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "Today's picture is ready"
        content.body = "Take ten quiet minutes to color."
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: minutes / 60, minute: minutes % 60), repeats: true)
        try? await center.add(UNNotificationRequest(identifier: "daily", content: content, trigger: trigger))
        return true
    }

    static func cancel() { UNUserNotificationCenter.current().removeAllPendingNotificationRequests() }
}
