//
//  Template.swift
//  Coloring-PaintTheNumber
//

import Foundation
import CoreGraphics

/// One paint-by-number template, decoded from `<id>.json`.
nonisolated struct Template: Decodable {
    nonisolated struct Swatch: Decodable, Identifiable {
        let id: Int
        let hex: String
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
}
