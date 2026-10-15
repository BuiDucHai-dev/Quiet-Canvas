//
//  PaintModel.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

@Observable
final class PaintModel {
    typealias TapResult = PaintUseCases.TapResult

    let entry: Catalog.Entry
    let template: Template
    let paths: [CGPath]
    private(set) var filled: Set<Int>
    var selected: Int?
    /// color id -> region indices
    @ObservationIgnored private let byColor: [Int: [Int]]
    @ObservationIgnored private let store: Store

    init(entry: Catalog.Entry, loaded: Template.Loaded, store: Store = .shared) {
        self.entry = entry
        self.store = store
        template = loaded.template
        paths = loaded.paths
        filled = store.filled(entry.id)
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
        PaintUseCases.nextColor(after: color, palette: template.palette, remaining: remaining)
    }

    /// Fills the shape under `pt` (template coordinates) if it has the selected color.
    func tap(_ pt: CGPoint, tolerance: CGFloat, autoNext: Bool) -> TapResult {
        let result = PaintUseCases.resolveTap(
            at: pt,
            selected: selected,
            regions: template.regions,
            paths: paths,
            byColor: byColor,
            filled: filled,
            tolerance: tolerance
        )
        if case .filled(let i) = result {
            let r = template.regions[i]
            filled.insert(r.id)
            store.save(entry, filled: filled, total: template.regions.count)
            if autoNext, remaining(r.color) == 0 { selected = nextColor(after: r.color) }
        }
        return result
    }

    /// Smallest unfilled shape of the selected color: the one that is hardest to spot.
    func hintRegion() -> Template.Region? {
        if selected.map({ remaining($0) == 0 }) ?? true { selected = nextColor(after: selected) }
        return PaintUseCases.hintRegion(selected: selected, regions: template.regions, byColor: byColor, filled: filled)
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
        store.reset(entry.id)
        selected = nextColor(after: nil)
    }

    /// Current state as an image (white paper, filled shapes, light outlines).
    func render(side: CGFloat) -> UIImage {
        TemplateRenderer.render(template: template, paths: paths, filled: filled, side: side)
    }
}
