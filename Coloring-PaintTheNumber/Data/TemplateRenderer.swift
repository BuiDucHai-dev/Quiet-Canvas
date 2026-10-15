//
//  TemplateRenderer.swift
//  Coloring-PaintTheNumber
//

import CoreGraphics
import UIKit

enum TemplateRenderer {
    /// Current state as an image (white paper, filled shapes, light outlines).
    static func render(template: Template, paths: [CGPath], filled: Set<Int>, side: CGFloat) -> UIImage {
        let k = side / max(template.width, template.height)
        let size = CGSize(width: template.width * k, height: template.height * k)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let colors = Dictionary(uniqueKeysWithValues: template.palette.map { sw -> (Int, CGColor) in
            let v = UInt32(sw.hex.dropFirst(), radix: 16) ?? 0
            let uiColor = UIColor(
                red: CGFloat(v >> 16 & 255) / 255,
                green: CGFloat(v >> 8 & 255) / 255,
                blue: CGFloat(v & 255) / 255,
                alpha: 1
            )
            return (sw.id, uiColor.cgColor)
        })
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
