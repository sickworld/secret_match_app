import SwiftUI

struct LoadingOverlay: View {
    var message: String = "Bitte warten..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text(message)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
        .transition(.opacity)
        .zIndex(100)
    }
}
