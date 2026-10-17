//
//  LegalLinks.swift
//  Coloring-PaintTheNumber
//
//  The paywall and the settings sheet both have to show these, and App
//  Review checks that the two agree. One source so they cannot drift.
//

import Foundation

nonisolated enum LegalLinks: Sendable {
    static let terms = URL(string: "https://quiet-canvas.netlify.app/terms")!
    static let privacy = URL(string: "https://quiet-canvas.netlify.app/privacy")!
}
