import XCTest
@testable import Coloring_PaintTheNumber

@MainActor
final class Coloring_PaintTheNumberTests: XCTestCase {

    /// Every catalog entry must have a decodable template, matching counts and a thumbnail.
    func testCatalogMatchesBundledTemplates() async throws {
        let catalog = Catalog.shared
        XCTAssertFalse(catalog.templates.isEmpty)
        XCTAssertFalse(catalog.challenges.isEmpty)
        for e in catalog.templates {
            XCTAssertNotNil(catalog.theme(e.theme), "\(e.id): unknown theme")
        }
        for e in catalog.all {
            XCTAssertNotNil(UIImage(named: e.thumb), "\(e.id): thumbnail missing")
            XCTAssertNotNil(Bundle.main.path(forResource: "\(e.id)_art", ofType: "jpg"), "\(e.id): artwork missing")
            let result = await Template.load(e.id)
            let loaded = try XCTUnwrap(result, "\(e.id): template missing")
            XCTAssertEqual(loaded.template.regions.count, e.regions, e.id)
            XCTAssertEqual(loaded.template.palette.count, e.colors, e.id)
            XCTAssertEqual(loaded.paths.count, e.regions, e.id)
            let ids = Set(loaded.template.palette.map(\.id))
            XCTAssertTrue(loaded.template.regions.allSatisfy { ids.contains($0.color) }, "\(e.id): region color not in palette")
        }
        for t in catalog.themes { XCTAssertNotNil(catalog.entry(t.cover), "\(t.id): cover missing") }

        let store = Store.shared
        for (i, expected) in catalog.challenges.enumerated() {
            let day = Calendar.current.date(byAdding: .day, value: i, to: store.installDay)!
            XCTAssertEqual(store.challenge(on: day).id, expected.id)
        }
    }

    func testStreakForgivesOneMissedDayPerWeek() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1
        func day(_ d: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: d))! }
        func keys(_ days: [Int]) -> Set<String> { Set(days.map { Day.key(day($0), cal) }) }
        // Oct 2026: Sun 4 ... Sat 10. Installed Thu Oct 1.
        let install = day(1)

        // Done 1, 3, 5, 6, 7; missed 2 (first miss of week 1 = rest) and 4 (first miss of week 2 = rest).
        var s = Streak(done: keys([1, 3, 5, 6, 7]), install: install, today: day(8), cal: cal)
        XCTAssertEqual(s.state(day(2)), .rest)
        XCTAssertEqual(s.state(day(4)), .rest)
        XCTAssertEqual(s.state(day(8)), .today)
        XCTAssertEqual(s.state(day(9)), .future)
        XCTAssertEqual(s.current, 7, "1...7 with two rest days, today still open")
        XCTAssertFalse(s.restLeftThisWeek)

        // A second miss in the same week breaks the run.
        s = Streak(done: keys([5, 7]), install: install, today: day(8), cal: cal)
        XCTAssertEqual(s.state(day(4)), .rest)
        XCTAssertEqual(s.state(day(6)), .missed)
        XCTAssertEqual(s.current, 1)

        // Only rest days, nothing done: no streak.
        s = Streak(done: [], install: day(7), today: day(8), cal: cal)
        XCTAssertEqual(s.state(day(7)), .rest)
        XCTAssertEqual(s.current, 0)
        XCTAssertEqual(s.state(day(6)), .before)

        // Today done counts.
        s = Streak(done: keys([7, 8]), install: day(7), today: day(8), cal: cal)
        XCTAssertEqual(s.current, 2)
        XCTAssertTrue(s.restLeftThisWeek)
    }

    /// A near miss next to a shape of the selected color still fills it; a far miss does not.
    func testTapToleranceFillsNearMiss() async throws {
        let entry = try XCTUnwrap(Catalog.shared.templates.first { $0.difficulty == .easy })
        let result = await Template.load(entry.id)
        let loaded = try XCTUnwrap(result)
        let model = PaintModel(entry: entry, loaded: loaded)
        model.reset()
        defer { model.reset() }

        // biggest shape: walk right from its label until we leave it, then step 2 units further
        let i = try XCTUnwrap(loaded.template.regions.indices.max { loaded.template.regions[$0].area < loaded.template.regions[$1].area })
        let r = loaded.template.regions[i]
        model.selected = r.color
        var p = CGPoint(x: r.label.x, y: r.label.y)
        XCTAssertTrue(loaded.paths[i].contains(p, using: .evenOdd))
        while loaded.paths[i].contains(p, using: .evenOdd) { p.x += 1 }
        p.x += 2

        XCTAssertEqual(model.tap(CGPoint(x: -500, y: -500), tolerance: 12, autoNext: false), .none)
        guard case .filled = model.tap(p, tolerance: 12, autoNext: false) else { return XCTFail("near miss should fill") }
        XCTAssertEqual(model.filled.count, 1)
    }

    /// Launch content is never NEW; pictures added after install are, for two weeks.
    func testNewBadgeOnlyForContentAddedAfterInstall() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "test.isNew"))
        defaults.removePersistentDomain(forName: "test.isNew")
        let installed = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        defaults.set(installed, forKey: "installDay")
        let store = Store(defaults: defaults)
        func entry(added: Date) -> Catalog.Entry {
            Catalog.Entry(id: "x", title: "x", theme: "t", thumb: "x.jpg", added: Day.key(added),
                          difficulty: .easy, free: true, regions: 10, colors: 3)
        }
        XCTAssertFalse(store.isNew(entry(added: installed)), "shipped with the install")
        XCTAssertTrue(store.isNew(entry(added: Calendar.current.date(byAdding: .day, value: -3, to: .now)!)))
        XCTAssertFalse(store.isNew(entry(added: Calendar.current.date(byAdding: .day, value: -20, to: .now)!)), "older than two weeks")
    }

    func testDayKeyRoundTrip() {
        let d = Day.date("2026-10-08")!
        XCTAssertEqual(Day.key(d), "2026-10-08")
    }

    func testSwatchLuminanceAndTotalCount() async throws {
        XCTAssertEqual(Template.Swatch(id: 1, hex: "#FFFFFF").luminance, 1.0, accuracy: 0.001)
        XCTAssertEqual(Template.Swatch(id: 2, hex: "#000000").luminance, 0.0, accuracy: 0.001)
        // Mid-gray #808080 sRGB has WCAG relative luminance ~0.216 (below 0.22 crossover -> prefers white text)
        XCTAssertEqual(Template.Swatch(id: 3, hex: "#808080").luminance, 0.216, accuracy: 0.01)

        let entry = try XCTUnwrap(Catalog.shared.templates.first { $0.difficulty == .easy })
        let res = await Template.load(entry.id)
        let loaded = try XCTUnwrap(res)
        let model = PaintModel(entry: entry, loaded: loaded)
        let sumTotals = loaded.template.palette.reduce(0) { $0 + model.total($1.id) }
        XCTAssertEqual(sumTotals, entry.regions)
    }

    func testCleanArchitectureUseCasesAndInMemoryRepository() {
        final class InMemoryProgressRepository: ProgressRepository {
            var meta: [String: WorkMeta] = [:]
            var filled: [String: Set<Int>] = [:]
            var challengeDays: Set<String> = []
            var bestStreak = 0
            var premium = false
            var installDay = Calendar.current.startOfDay(for: .now)

            func loadMeta() -> [String: WorkMeta] { meta }
            func saveMeta(_ meta: [String: WorkMeta]) { self.meta = meta }
            func loadFilled(_ id: String) -> Set<Int> { filled[id] ?? [] }
            func saveFilled(_ set: Set<Int>, for id: String) { filled[id] = set }
            func removeFilled(_ id: String) { filled[id] = nil }
            func loadChallengeDays() -> Set<String> { challengeDays }
            func saveChallengeDays(_ days: Set<String>) { challengeDays = days }
            func loadBestStreak() -> Int { bestStreak }
            func saveBestStreak(_ streak: Int) { bestStreak = streak }
            func loadPremium() -> Bool { premium }
            func savePremium(_ premium: Bool) { self.premium = premium }
            func loadOrCreateInstallDay(calendar: Calendar) -> Date { installDay }
            func resetChallengeProgress() { challengeDays = []; bestStreak = 0 }
        }

        let repo = InMemoryProgressRepository()
        let store = Store(repository: repo)
        let starters = LibraryUseCases.starterPictures(catalog: .shared, isUnlocked: store.isUnlocked)
        XCTAssertEqual(starters.count, 4)
        XCTAssertTrue(starters.allSatisfy { $0.difficulty == .easy && store.isUnlocked($0) })

        let chosenStarter = starters.last!
        let topFirst = LibraryUseCases.topShelf(
            catalog: .shared,
            meta: store.meta,
            favorites: "",
            starterID: chosenStarter.id,
            status: store.status,
            isUnlocked: store.isUnlocked
        )?.entries.first
        XCTAssertEqual(topFirst?.id, chosenStarter.id)

        let todayEntry = store.challenge(on: .now)
        XCTAssertEqual(store.status(todayEntry), .new)

        store.save(todayEntry, filled: Set(1...todayEntry.regions), total: todayEntry.regions)
        XCTAssertEqual(store.status(todayEntry), .done)
        XCTAssertTrue(repo.challengeDays.contains(Day.key(.now)))
        XCTAssertEqual(store.bestStreak, 1)

        let works = LibraryUseCases.myWorks(catalog: Catalog.shared, meta: store.meta, status: store.status)
        XCTAssertEqual(works.completed.map(\.id), [todayEntry.id])
        XCTAssertTrue(works.inProgress.isEmpty)
    }
}

