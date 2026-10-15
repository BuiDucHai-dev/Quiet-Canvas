//
//  Store.swift
//  Coloring-PaintTheNumber
//

import Foundation
import SwiftUI
import UIKit

/// Per-picture progress, daily challenge history and progress previews.
/// Filled regions live in UserDefaults (`filled.<id>`), previews as PNGs in Application Support.
@Observable
final class Store {
    static let shared = Store()

    typealias Meta = WorkMeta
    typealias Status = WorkStatus

    private(set) var meta: [String: Meta]
    private(set) var challengeDays: Set<String>
    private(set) var bestStreak: Int
    /// Bumped per picture when its preview image changes, so views reading it refresh.
    private(set) var previewStamp: [String: Int] = [:]
    var premium: Bool { didSet { repository.savePremium(premium) } }
    let installDay: Date

    @ObservationIgnored private let repository: ProgressRepository
    @ObservationIgnored private let catalogRepository: CatalogRepository
    @ObservationIgnored private let previews: PreviewImageStore

    init(
        repository: ProgressRepository,
        catalogRepository: CatalogRepository = BundleCatalogRepository.shared,
        previews: PreviewImageStore = PreviewImageStore()
    ) {
        self.repository = repository
        self.catalogRepository = catalogRepository
        self.previews = previews
        meta = repository.loadMeta()
        challengeDays = repository.loadChallengeDays()
        bestStreak = repository.loadBestStreak()
        premium = repository.loadPremium()
        installDay = repository.loadOrCreateInstallDay(calendar: .current)
    }

    convenience init(defaults: UserDefaults = .standard) {
        self.init(repository: UserDefaultsProgressRepository(defaults: defaults))
    }

    // MARK: - Progress

    func filled(_ id: String) -> Set<Int> { repository.loadFilled(id) }

    func save(_ e: Catalog.Entry, filled: Set<Int>, total: Int) {
        repository.saveFilled(filled, for: e.id)
        let challengeUpdated = ChallengeUseCases.recordFill(
            entry: e,
            filledCount: filled.count,
            total: total,
            now: .now,
            todayChallengeID: challenge(on: .now).id,
            installDay: installDay,
            meta: &meta,
            challengeDays: &challengeDays,
            bestStreak: &bestStreak
        )
        if challengeUpdated {
            repository.saveChallengeDays(challengeDays)
            repository.saveBestStreak(bestStreak)
        }
        repository.saveMeta(meta)
    }

    func addTime(_ id: String, _ seconds: Double) {
        guard meta[id] != nil, seconds > 0 else { return }
        meta[id]!.seconds += seconds
        repository.saveMeta(meta)
    }

    func status(_ e: Catalog.Entry) -> Status {
        ChallengeUseCases.status(for: e, meta: meta)
    }

    func isNew(_ e: Catalog.Entry) -> Bool {
        ChallengeUseCases.isNew(e, installDay: installDay, now: .now)
    }

    func isUnlocked(_ e: Catalog.Entry) -> Bool {
        ChallengeUseCases.isUnlocked(e, premium: premium, meta: meta, todayChallengeID: challenge(on: .now).id)
    }

    func reset(_ id: String) {
        repository.removeFilled(id)
        meta[id] = nil
        repository.saveMeta(meta)
        setPreview(id, nil)
    }

    func resetAll() {
        for id in Array(meta.keys) { reset(id) }
        challengeDays = []
        bestStreak = 0
        repository.resetChallengeProgress()
    }

    // MARK: - Previews

    func preview(_ id: String) -> UIImage? {
        _ = previewStamp[id]
        return previews.image(for: id)
    }

    func setPreview(_ id: String, _ image: UIImage?) {
        previews.setImage(image, for: id)
        previewStamp[id, default: 0] += 1
    }

    // MARK: - Challenges

    var today: Date { Calendar.current.startOfDay(for: .now) }
    var streak: Streak { Streak(done: challengeDays, install: installDay, today: today) }

    func challenge(on day: Date) -> Catalog.Entry {
        ChallengeUseCases.challenge(on: day, in: catalogRepository.catalog, installDay: installDay)
    }
}

extension EnvironmentValues {
    @Entry var store: Store = .shared
}

final class UserDefaultsProgressRepository: ProgressRepository {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadMeta() -> [String: WorkMeta] {
        defaults.data(forKey: "meta").flatMap { try? JSONDecoder().decode([String: WorkMeta].self, from: $0) } ?? [:]
    }

    func saveMeta(_ meta: [String: WorkMeta]) {
        defaults.set(try? JSONEncoder().encode(meta), forKey: "meta")
    }

    func loadFilled(_ id: String) -> Set<Int> {
        Set(defaults.array(forKey: "filled.\(id)") as? [Int] ?? [])
    }

    func saveFilled(_ filled: Set<Int>, for id: String) {
        defaults.set(Array(filled), forKey: "filled.\(id)")
    }

    func removeFilled(_ id: String) {
        defaults.removeObject(forKey: "filled.\(id)")
    }

    func loadChallengeDays() -> Set<String> {
        Set(defaults.stringArray(forKey: "challengeDays") ?? [])
    }

    func saveChallengeDays(_ days: Set<String>) {
        defaults.set(Array(days), forKey: "challengeDays")
    }

    func loadBestStreak() -> Int {
        defaults.integer(forKey: "bestStreak")
    }

    func saveBestStreak(_ streak: Int) {
        defaults.set(streak, forKey: "bestStreak")
    }

    func loadPremium() -> Bool {
        defaults.bool(forKey: "premium")
    }

    func savePremium(_ premium: Bool) {
        defaults.set(premium, forKey: "premium")
    }

    func loadOrCreateInstallDay(calendar: Calendar = .current) -> Date {
        if defaults.object(forKey: "installDay") == nil {
            defaults.set(Date.now, forKey: "installDay")
        }
        return calendar.startOfDay(for: defaults.object(forKey: "installDay") as? Date ?? .now)
    }

    func resetChallengeProgress() {
        defaults.removeObject(forKey: "challengeDays")
        defaults.removeObject(forKey: "bestStreak")
    }
}

final class PreviewImageStore {
    private let cache = NSCache<NSString, UIImage>()
    private let previewDir = URL.applicationSupportDirectory.appending(path: "previews", directoryHint: .isDirectory)

    func image(for id: String) -> UIImage? {
        if let img = cache.object(forKey: id as NSString) { return img }
        guard let img = UIImage(contentsOfFile: previewDir.appending(path: "\(id).png").path) else { return nil }
        cache.setObject(img, forKey: id as NSString)
        return img
    }

    func setImage(_ image: UIImage?, for id: String) {
        let url = previewDir.appending(path: "\(id).png")
        if let image {
            try? FileManager.default.createDirectory(at: previewDir, withIntermediateDirectories: true)
            try? image.pngData()?.write(to: url)
            cache.setObject(image, forKey: id as NSString)
        } else {
            try? FileManager.default.removeItem(at: url)
            cache.removeObject(forKey: id as NSString)
        }
    }
}
