import SwiftUI

struct SplashScreenView: View {
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.paper
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(0.14),
                            Color.accentColor.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: -40)

            VStack(spacing: 24) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.line, lineWidth: 1)
                    )
                    .shadow(color: Color.accentColor.opacity(0.22), radius: 24, x: 0, y: 12)

                VStack(spacing: 8) {
                    Text("Quiet Canvas")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(.ink)

                    Text("Paint by Number")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.ink2)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isShowing = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isShowing: .constant(true))
}
