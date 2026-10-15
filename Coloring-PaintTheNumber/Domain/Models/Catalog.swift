//
//  Catalog.swift
//  Coloring-PaintTheNumber
//

import Foundation

/// App content index, decoded from `catalog.json` (written by `tools/import_templates.py`).
struct Catalog: Decodable {
    struct Theme: Decodable, Identifiable, Hashable {
        let id, title, cover: String
    }
    struct Entry: Decodable, Identifiable, Hashable {
        let id, title, theme, thumb, added: String
        let difficulty: Difficulty
        let free: Bool
        let regions, colors: Int

        /// Rough painting time, about 4 seconds per shape, rounded to 5 minutes.
        var minutes: Int { max(5, (regions * 4 / 60 + 4) / 5 * 5) }
    }
    enum Difficulty: String, Decodable, CaseIterable {
        case easy, normal, hard
        var level: Int { switch self { case .easy: 1; case .normal: 2; case .hard: 3 } }
        var label: String { switch self { case .easy: "Easy"; case .normal: "Medium"; case .hard: "Hard" } }
    }

    let themes: [Theme]
    let templates: [Entry]
    let challenges: [Entry]
    var all: [Entry] { templates + challenges }
    private let byTheme: [String: [Entry]]
    private let byID: [String: Entry]

    private enum CodingKeys: String, CodingKey { case themes, templates, challenges }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        themes = try c.decode([Theme].self, forKey: .themes)
        templates = try c.decode([Entry].self, forKey: .templates)
        challenges = try c.decodeIfPresent([Entry].self, forKey: .challenges) ?? []
        byTheme = Dictionary(grouping: templates, by: \.theme)
        byID = Dictionary(uniqueKeysWithValues: (templates + challenges).map { ($0.id, $0) })
    }

    func entries(in theme: String) -> [Entry] { byTheme[theme] ?? [] }
    func entry(_ id: String) -> Entry? { byID[id] }
    func theme(_ id: String) -> Theme? { themes.first { $0.id == id } }
}

enum Favorites {
    static func ids(_ raw: String) -> [String] { raw.split(separator: ",").map(String.init) }
    static func contains(_ id: String, in raw: String) -> Bool { ids(raw).contains(id) }
    static func toggle(_ id: String, in raw: inout String) {
        var list = ids(raw)
        if let i = list.firstIndex(of: id) { list.remove(at: i) } else { list.insert(id, at: 0) }
        raw = list.joined(separator: ",")
    }
}

protocol CatalogRepository {
    var catalog: Catalog { get }
    func loadTemplate(_ id: String) async -> Template.Loaded?
}
