import SwiftUI

@Observable
final class PaintModel {
    let entry: Catalog.Entry
    let template: Template
    let paths: [CGPath]
    private(set) var filled: Set<Int>
    var selected: Int?
    /// color id -> region indices
    @ObservationIgnored private let byColor: [Int: [Int]]

    init(entry: Catalog.Entry, loaded: Template.Loaded) {
        self.entry = entry
        template = loaded.template
        paths = loaded.paths
        filled = Store.shared.filled(entry.id)
        byColor = Dictionary(grouping: loaded.template.regions.indices) { loaded.template.regions[$0].color }
        selected = nil
        selected = nextColor(after: nil)
    }

    func total(_ color: Int) -> Int { byColor[color]?.count ?? 0 }
    func remaining(_ color: Int) -> Int {
        byColor[color, default: []].reduce(0) { $0 + (filled.contains(template.regions[$1].id) ? 0 : 1) }
    }
    var progress: Double { Double(filled.count) / Double(max(template.regions.count, 1)) }
    var done: Bool { filled.count >= template.regions.count }

    /// Next palette color that still has shapes, searching forward from `color` and wrapping around.
    func nextColor(after color: Int?) -> Int? {
        let ids = template.palette.map(\.id)
        let start = color.flatMap { ids.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        return (Array(ids[start...]) + ids[..<start]).first { remaining($0) > 0 }
    }

    enum TapResult: Equatable {
        /// Region index that was filled.
        case filled(Int)
        /// Hit an unfilled shape of another color.
        case wrong
        case none
    }

    /// Fills the shape under `pt` (template coordinates) if it has the selected color.
    /// A near miss still fills the closest matching shape within `tolerance` (template units),
    /// so thin outlines and tiny shapes don't need a perfect hit. Over a shape of another color
    /// the tolerance is reduced, so a tap clearly inside a wrong shape still counts as wrong.
    func tap(_ pt: CGPoint, tolerance: CGFloat, autoNext: Bool) -> TapResult {
        guard let sel = selected else { return .none }
        let hit = index(at: pt)
        if let i = hit, template.regions[i].color == sel, !filled.contains(template.regions[i].id) { return fill(i, autoNext) }
        let wrongHit = hit.map { !filled.contains(template.regions[$0].id) } ?? false
        if let i = nearest(to: pt, color: sel, radius: wrongHit ? tolerance * 0.65 : tolerance) { return fill(i, autoNext) }
        return wrongHit ? .wrong : .none
    }

    private func index(at pt: CGPoint) -> Int? {
        template.regions.indices.first {
            template.regions[$0].rect.insetBy(dx: -1, dy: -1).contains(pt) && paths[$0].contains(pt, using: .evenOdd)
        }
    }

    /// Samples rings around `pt` (closest first) for an unfilled shape of `color`.
    private func nearest(to pt: CGPoint, color: Int, radius: CGFloat) -> Int? {
        let candidates = byColor[color, default: []].filter {
            !filled.contains(template.regions[$0].id) && template.regions[$0].rect.insetBy(dx: -radius, dy: -radius).contains(pt)
        }
        guard !candidates.isEmpty else { return nil }
        for ring in 1...3 {
            let d = radius * CGFloat(ring) / 3
            for k in 0..<12 {
                let a = Double(k) * .pi / 6
                let p = CGPoint(x: pt.x + d * cos(a), y: pt.y + d * sin(a))
                if let i = candidates.first(where: { paths[$0].contains(p, using: .evenOdd) }) { return i }
            }
        }
        return nil
    }

    private func fill(_ i: Int, _ autoNext: Bool) -> TapResult {
        let r = template.regions[i]
        filled.insert(r.id)
        Store.shared.save(entry, filled: filled, total: template.regions.count)
        if autoNext, remaining(r.color) == 0 { selected = nextColor(after: r.color) }
        return .filled(i)
    }

    /// Smallest unfilled shape of the selected color: the one that is hardest to spot.
    func hintRegion() -> Template.Region? {
        if selected.map({ remaining($0) == 0 }) ?? true { selected = nextColor(after: selected) }
        guard let s = selected else { return nil }
        return byColor[s, default: []].map { template.regions[$0] }.filter { !filled.contains($0.id) }.min { $0.area < $1.area }
    }

    #if DEBUG
    /// Testing aid: fills everything except the largest shape (not saved until a real tap).
    func debugFillAllButOne() {
        guard let last = template.regions.max(by: { $0.area < $1.area }) else { return }
        filled = Set(template.regions.map(\.id)).subtracting([last.id])
        selected = last.color
    }
    #endif

    func reset() {
        filled = []
        Store.shared.reset(entry.id)
        selected = nextColor(after: nil)
    }

    /// Current state as an image (white paper, filled shapes, light outlines).
    func render(side: CGFloat) -> UIImage {
        let k = side / max(template.width, template.height)
        let size = CGSize(width: template.width * k, height: template.height * k)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let colors = Dictionary(uniqueKeysWithValues: template.palette.map { ($0.id, UIColor($0.color).cgColor) })
        return UIGraphicsImageRenderer(size: size, format: format).image { c in
            let g = c.cgContext
            g.setFillColor(UIColor.white.cgColor)
            g.fill(CGRect(origin: .zero, size: size))
            g.scaleBy(x: k, y: k)
            g.setStrokeColor(UIColor(white: 0.62, alpha: 1).cgColor)
            g.setLineWidth(0.8 / k)
            for (i, r) in template.regions.enumerated() {
                g.addPath(paths[i])
                if filled.contains(r.id), let col = colors[r.color] {
                    g.setFillColor(col)
                    g.drawPath(using: .eoFillStroke)
                } else {
                    g.drawPath(using: .stroke)
                }
            }
        }
    }
}
