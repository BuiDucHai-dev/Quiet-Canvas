import SwiftUI

/// First launch: welcome, then pick favorite themes (shown first in the Library).
/// ponytail: paywall step after themes is skipped until StoreKit lands (design: docs/design/03_paywall.png).
struct OnboardingView: View {
    let finish: () -> Void
    @State private var step = 0
    @State private var picked: Set<String> = []
    @AppStorage("favorites") private var favorites = ""
    private let catalog = Catalog.shared

    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            if step == 0 { welcome.transition(.opacity) } else { themes.transition(.move(edge: .trailing)) }
        }
        .animation(.smooth(duration: 0.3), value: step)
    }

    private var welcome: some View {
        VStack(spacing: 0) {
            Text("QUIET CANVAS").font(.eyebrow).tracking(1).foregroundStyle(.ink2).padding(.top, 40)
            if let cover = catalog.themes.first.flatMap({ catalog.entry($0.cover) }), let img = UIImage(named: cover.thumb) {
                Image(uiImage: img).resizable().aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(8).background(.white, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    .frame(maxWidth: 300).padding(.top, 28)
                    .accessibilityHidden(true)
            }
            Text("Color your calm").font(.display).foregroundStyle(.ink).padding(.top, 34)
            Text("Tap a number, fill a shape, and watch a picture come to life. No skill needed.")
                .font(.title3).foregroundStyle(.ink2).multilineTextAlignment(.center).padding(.horizontal, 32).padding(.top, 12)
            Spacer()
            Button("Get started") { step = 1 }.buttonStyle(PrimaryButton()).padding(.horizontal, 20).padding(.bottom, 24)
        }
    }

    private var themes: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What do you love to color?").font(.display).foregroundStyle(.ink).padding(.top, 24)
            Text("Pick a few. We'll put them first in your library.").font(.body).foregroundStyle(.ink2).padding(.top, 8)
            ScrollView {
                LazyVGrid(columns: adaptiveGrid, spacing: 16) {
                    ForEach(catalog.themes) { t in themeCell(t) }
                }
                .padding(.vertical, 22)
            }
            .scrollIndicators(.hidden)
            Button(picked.isEmpty ? "Show me everything" : "Continue · \(picked.count) selected") {
                favorites = catalog.themes.map(\.id).filter(picked.contains).joined(separator: ",")
                finish()
            }
            .buttonStyle(PrimaryButton())
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
    }

    private func themeCell(_ t: Catalog.Theme) -> some View {
        let on = picked.contains(t.id)
        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                if on { picked.remove(t.id) } else { picked.insert(t.id) }
            }
        } label: {
            VStack(spacing: 8) {
                Group {
                    if let e = catalog.entry(t.cover), let img = UIImage(named: e.thumb) {
                        Image(uiImage: img).resizable().aspectRatio(1, contentMode: .fit)
                    } else { Color.well.aspectRatio(1, contentMode: .fit) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(4).background(.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(on ? AnyShapeStyle(.accent) : AnyShapeStyle(.clear), lineWidth: 3))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: on ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(on ? AnyShapeStyle(.accent) : AnyShapeStyle(.white))
                        .background(on ? Color.white : Color.black.opacity(0.28), in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 2)
                        .padding(10)
                }
                Text(t.title).font(.body.weight(.semibold)).foregroundStyle(.ink)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
