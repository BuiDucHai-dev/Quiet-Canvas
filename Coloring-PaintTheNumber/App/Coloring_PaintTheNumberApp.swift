//
//  Coloring_PaintTheNumberApp.swift
//  Coloring-PaintTheNumber
//

import SwiftUI

@main
struct Coloring_PaintTheNumberApp: App {
    @State private var store = Store.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.store, store)
        }
    }
}
