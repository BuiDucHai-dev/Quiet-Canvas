//
//  PaintUseCases.swift
//  Coloring-PaintTheNumber
//

import Foundation
import CoreGraphics

enum PaintUseCases {
    enum TapResult: Equatable {
        /// Region index that was filled.
        case filled(Int)
        /// Hit an unfilled shape of another color.
        case wrong
        case none
    }

    /// Next palette color that still has shapes, searching forward from `color` and wrapping around.
    static func nextColor(after color: Int?, palette: [Template.Swatch], remaining: (Int) -> Int) -> Int? {
        let ids = palette.map(\.id)
        let start = color.flatMap { ids.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        return (Array(ids[start...]) + ids[..<start]).first { remaining($0) > 0 }
    }

    /// Smallest unfilled shape of the selected color: the one that is hardest to spot.
    static func hintRegion(selected: Int?, regions: [Template.Region], byColor: [Int: [Int]], filled: Set<Int>) -> Template.Region? {
        guard let s = selected else { return nil }
        return byColor[s, default: []].map { regions[$0] }.filter { !filled.contains($0.id) }.min { $0.area < $1.area }
    }

    static func resolveTap(
        at pt: CGPoint,
        selected: Int?,
        regions: [Template.Region],
        paths: [CGPath],
        byColor: [Int: [Int]],
        filled: Set<Int>,
        tolerance: CGFloat
    ) -> TapResult {
        guard let sel = selected else { return .none }
        let hit = index(at: pt, regions: regions, paths: paths)
        if let i = hit, regions[i].color == sel, !filled.contains(regions[i].id) {
            return .filled(i)
        }
        let wrongHit = hit.map { !filled.contains(regions[$0].id) } ?? false
        if let i = nearest(to: pt, color: sel, radius: wrongHit ? tolerance * 0.65 : tolerance, regions: regions, paths: paths, byColor: byColor, filled: filled) {
            return .filled(i)
        }
        return wrongHit ? .wrong : .none
    }

    private static func index(at pt: CGPoint, regions: [Template.Region], paths: [CGPath]) -> Int? {
        regions.indices.first {
            regions[$0].rect.insetBy(dx: -1, dy: -1).contains(pt) && paths[$0].contains(pt, using: .evenOdd)
        }
    }

    /// Samples rings around `pt` (closest first) for an unfilled shape of `color`.
    private static func nearest(
        to pt: CGPoint,
        color: Int,
        radius: CGFloat,
        regions: [Template.Region],
        paths: [CGPath],
        byColor: [Int: [Int]],
        filled: Set<Int>
    ) -> Int? {
        let candidates = byColor[color, default: []].filter {
            !filled.contains(regions[$0].id) && regions[$0].rect.insetBy(dx: -radius, dy: -radius).contains(pt)
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
}
