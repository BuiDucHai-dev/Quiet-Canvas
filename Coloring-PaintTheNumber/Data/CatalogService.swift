//
//  CatalogService.swift
//  Coloring-PaintTheNumber
//

import Foundation
import CoreGraphics
import UIKit

final class BundleCatalogRepository: CatalogRepository {
    static let shared = BundleCatalogRepository()

    let catalog: Catalog = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json") else { fatalError("catalog.json missing") }
        do { return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url)) }
        catch { fatalError("catalog.json: \(error)") }
    }()

    /// Decodes and parses off the main thread; hard templates have 1000+ regions.
    func loadTemplate(_ id: String) async -> Template.Loaded? {
        await Task.detached(priority: .userInitiated) {
            guard let url = Bundle.main.url(forResource: id, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let t = try? JSONDecoder().decode(Template.self, from: data) else { return nil }
            return Template.Loaded(template: t, paths: t.regions.map { parseSVGPath($0.path) })
        }.value
    }

    func finalArtwork(for id: String) -> UIImage? {
        Bundle.main.path(forResource: "\(id)_art", ofType: "jpg").flatMap(UIImage.init(contentsOfFile:))
    }
}

extension Catalog {
    static var shared: Catalog { BundleCatalogRepository.shared.catalog }
}

extension Template {
    static func load(_ id: String) async -> Loaded? {
        await BundleCatalogRepository.shared.loadTemplate(id)
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
