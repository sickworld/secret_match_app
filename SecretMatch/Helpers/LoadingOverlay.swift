import SwiftUI

struct LoadingOverlay: View {
    var message: String = "Bitte warten..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: SecretMatchTheme.primary))
                    .scaleEffect(1.5)

                Text(message)
                    .foregroundStyle(.white)
                    .font(.headline.weight(.semibold))
            }
            .secretCard(cornerRadius: 18, padding: 24)
        }
        .transition(.opacity)
        .zIndex(100)
    }
}
