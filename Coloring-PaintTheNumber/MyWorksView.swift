import SwiftUI

struct MyWorksView: View {
    @Environment(Router.self) private var router
    @State private var showDone = false
    @State private var restart: Catalog.Entry?
    private var store: Store { .shared }

    var body: some View {
        let started = Catalog.shared.all.filter { store.meta[$0.id].map { $0.count > 0 } ?? false }
        let done = started.filter { store.status($0) == .done }
            .sorted { (store.meta[$0.id]?.completed ?? .distantPast) > (store.meta[$1.id]?.completed ?? .distantPast) }
        let progress = started.filter { store.status($0) != .done }
            .sorted { (store.meta[$0.id]?.edited ?? .distantPast) > (store.meta[$1.id]?.edited ?? .distantPast) }
        let items = showDone ? done : progress

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("My Works").font(.display).foregroundStyle(.ink).padding(.top, 8)
                    Picker("Show", selection: $showDone) {
                        Text("In progress · \(progress.count)").tag(false)
                        Text("Completed · \(done.count)").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                    if items.isEmpty {
                        ContentUnavailableView {
                            Label(showDone ? "Nothing finished yet" : "Nothing in progress", systemImage: "paintpalette")
                        } description: {
                            Text("Pictures you start in the Library show up here.")
                        } actions: {
                            Button("Explore Library") { router.tab = 0 }
                                .buttonStyle(PrimaryButton())
                                .padding(.top, 8)
                        }
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: adaptiveGrid, alignment: .leading, spacing: 18) {
                            ForEach(items) { e in
                                Button { router.open(e) } label: { Thumb(entry: e, subtitle: subtitle(e)) }
                                    .buttonStyle(.pressable)
                                    .contextMenu {
                                        Button("Restart picture", systemImage: "arrow.counterclockwise", role: .destructive) { restart = e }
                                    }
                                    .accessibilityAction(named: "Restart picture") { restart = e }
                            }
                        }
                        Text("Touch and hold a picture to restart it").font(.subheadline).foregroundStyle(.ink2)
                            .frame(maxWidth: .infinity).padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(.paper)
            .paperStatusBar()
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Restart \(restart?.title ?? "")?", isPresented: Binding(get: { restart != nil }, set: { if !$0 { restart = nil } }),
                                titleVisibility: .visible) {
                Button("Restart", role: .destructive) { if let r = restart { store.reset(r.id) } }
            } message: { Text("All colors you filled will be cleared.") }
        }
    }

    private func subtitle(_ e: Catalog.Entry) -> String {
        guard let m = store.meta[e.id] else { return "" }
        if let c = m.completed { return "Completed \(c.formatted(.dateTime.month(.abbreviated).day()))" }
        let pct = Int(Double(m.count) / Double(max(e.regions, 1)) * 100)
        return "\(pct)% · \(m.edited.formatted(.relative(presentation: .named)))"
    }
}
