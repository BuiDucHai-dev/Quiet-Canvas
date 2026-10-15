import SwiftUI

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

    static let shared: Catalog = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else { fatalError("catalog.json missing") }
        do { return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url)) }
        catch { fatalError("catalog.json: \(error)") }
    }()

    func entries(in theme: String) -> [Entry] { byTheme[theme] ?? [] }
    func entry(_ id: String) -> Entry? { byID[id] }
    func theme(_ id: String) -> Theme? { themes.first { $0.id == id } }
}

/// One paint-by-number template, decoded from `<id>.json`.
nonisolated struct Template: Decodable {
    nonisolated struct Swatch: Decodable, Identifiable {
        let id: Int
        let hex: String
        var color: Color { Color(hex: hex) }
        var luminance: Double {
            let v = UInt32(hex.dropFirst(), radix: 16) ?? 0
            func lin(_ c: UInt32) -> Double {
                let s = Double(c & 255) / 255
                return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * lin(v >> 16) + 0.7152 * lin(v >> 8) + 0.0722 * lin(v)
        }
    }
    nonisolated struct Label: Decodable { let x, y, size: Double }
    nonisolated struct Region: Decodable, Identifiable {
        let id: Int
        let color: Int
        let area: Double
        /// x, y, width, height
        let bbox: [Double]
        let label: Label
        let path: String
        var rect: CGRect { CGRect(x: bbox[0], y: bbox[1], width: bbox[2], height: bbox[3]) }
    }

    let width: Double
    let height: Double
    let palette: [Swatch]
    let regions: [Region]

    /// Template plus its parsed region paths (index-aligned with `regions`).
    struct Loaded: @unchecked Sendable {
        let template: Template
        let paths: [CGPath]
    }

    /// Decodes and parses off the main thread; hard templates have 1000+ regions.
    static func load(_ id: String) async -> Loaded? {
        await Task.detached(priority: .userInitiated) {
            guard let url = Bundle.main.url(forResource: id, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let t = try? JSONDecoder().decode(Template.self, from: data) else { return nil }
            return Loaded(template: t, paths: t.regions.map { parseSVGPath($0.path) })
        }.value
    }
}

/// Local calendar day helpers ("yyyy-MM-dd" keys, never UTC).
nonisolated enum Day {
    static func key(_ d: Date, _ cal: Calendar = .current) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    static func date(_ key: String, _ cal: Calendar = .current) -> Date? {
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return cal.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }
}

nonisolated extension Color {
    init(hex: String) {
        let v = UInt32(hex.dropFirst(), radix: 16) ?? 0
        self.init(red: Double(v >> 16 & 255) / 255, green: Double(v >> 8 & 255) / 255, blue: Double(v & 255) / 255)
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }
}

/// Parses SVG path data. Data only contains absolute M / L / C / Z.
nonisolated func parseSVGPath(_ d: String) -> CGPath {
    let p = CGMutablePath()
    var nums: [CGFloat] = []
    var cmd: Character = "M"
    func flush() {
        switch cmd {
        case "M" where nums.count >= 2:
            p.move(to: CGPoint(x: nums[0], y: nums[1]))
            // implicit lineto after the first pair
            for i in stride(from: 2, to: nums.count - 1, by: 2) { p.addLine(to: CGPoint(x: nums[i], y: nums[i + 1])) }
        case "L":
            for i in stride(from: 0, to: nums.count - 1, by: 2) { p.addLine(to: CGPoint(x: nums[i], y: nums[i + 1])) }
        case "C":
            for i in stride(from: 0, to: nums.count - 5, by: 6) {
                p.addCurve(to: CGPoint(x: nums[i + 4], y: nums[i + 5]),
                           control1: CGPoint(x: nums[i], y: nums[i + 1]),
                           control2: CGPoint(x: nums[i + 2], y: nums[i + 3]))
            }
        case "Z": p.closeSubpath()
        default: break
        }
        nums.removeAll()
    }
    var token = ""
    func pushToken() { if let v = Double(token) { nums.append(CGFloat(v)) }; token = "" }
    for ch in d {
        if ch.isLetter { pushToken(); flush(); cmd = ch; if ch == "Z" { flush() } }
        else if ch == " " || ch == "," { pushToken() }
        else if ch == "-" { pushToken(); token = "-" }
        else { token.append(ch) }
    }
    pushToken(); flush()
    return p
}
