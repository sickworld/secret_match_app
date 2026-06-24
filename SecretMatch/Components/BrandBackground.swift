import SwiftUI

struct BrandBackground: View {
    var body: some View {
        ZStack {
            SecretMatchTheme.background

            RadialGradient(
                colors: [SecretMatchTheme.primary.opacity(0.24), .clear],
                center: UnitPoint(x: 0.86, y: 0.08),
                startRadius: 10,
                endRadius: 520
            )

            RadialGradient(
                colors: [SecretMatchTheme.secondary.opacity(0.09), .clear],
                center: UnitPoint(x: 0.08, y: 0.92),
                startRadius: 20,
                endRadius: 560
            )

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.34)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}
