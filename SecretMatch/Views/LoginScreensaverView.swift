import SwiftUI

struct LoginScreensaverView: View {
    var dismiss: () -> Void

    @State private var selectedLogo = 0

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 34) {
                Spacer()

                logo
                    .id(selectedLogo)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))

                Text(sponsorLine)
                    .id("sponsor-\(selectedLogo)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)

                Spacer()

                Label("Zum Starten Bildschirm berühren", systemImage: "hand.tap.fill")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.bottom, 42)
            }
            .padding(32)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: dismiss)
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(6))
                } catch {
                    return
                }

                withAnimation(.easeInOut(duration: 1.1)) {
                    selectedLogo = (selectedLogo + 1) % 3
                }
            }
        }
    }

    private var sponsorLine: String {
        switch selectedLogo {
        case 0:
            "Hier funkt’s ganz ohne Algorithmus."
        case 1:
            "Heiß gemacht von Hot Chili Events."
        default:
            "Flüssiger Mut von FICKEN Likör."
        }
    }

    @ViewBuilder
    private var logo: some View {
        switch selectedLogo {
        case 0:
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 620, maxHeight: 420)
                .shadow(color: SecretMatchTheme.primary.opacity(0.28), radius: 30)
                .accessibilityLabel("Match&Play")
        case 1:
            Image("hot-chili")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 520, maxHeight: 360)
                .shadow(color: SecretMatchTheme.primary.opacity(0.24), radius: 26)
                .accessibilityLabel("Hot Chili Events")
        default:
            Image("ficken-logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 560, maxHeight: 360)
                .padding(34)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 28, y: 12)
                .accessibilityLabel("FICKEN Likör")
        }
    }
}
