import SwiftUI

struct LoginScreensaverView: View {
    @EnvironmentObject private var api: APIService
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
        .task(id: slideIdentity) {
            do {
                try await Task.sleep(for: .seconds(slideDuration))
            } catch {
                return
            }
            withAnimation(.easeInOut(duration: 1.1)) {
                selectedLogo = (selectedLogo + 1) % slideCount
            }
        }
    }

    private var remoteItems: [ScreensaverMediaItem] {
        api.screensaverItems.filter { $0.enabled && $0.showInScreensaver }
    }

    private var selectedRemoteItem: ScreensaverMediaItem? {
        guard !remoteItems.isEmpty else { return nil }
        return remoteItems[selectedLogo % remoteItems.count]
    }

    private var slideCount: Int { max(1, remoteItems.isEmpty ? 4 : remoteItems.count) }

    private var slideDuration: Int {
        max(3, min(30, selectedRemoteItem?.displaySeconds ?? 6))
    }

    private var slideIdentity: String {
        if let item = selectedRemoteItem {
            return "\(item.id)-\(item.revision)-\(selectedLogo)"
        }
        return "bundled-\(selectedLogo)"
    }

    private var sponsorLine: String {
        if let item = selectedRemoteItem {
            return item.title.isEmpty ? "Match&Play" : item.title
        }
        switch selectedLogo {
        case 0:
            return "Hier funkt’s ganz ohne Algorithmus."
        case 1:
            return "Heiß gemacht von Hot Chili Events."
        case 2:
            return "Flüssiger Mut von FICKEN Likör."
        default:
            return "Heute funkt’s im Club 2020."
        }
    }

    @ViewBuilder
    private var logo: some View {
        if let item = selectedRemoteItem,
           let image = api.cachedScreensaverImage(for: item) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 620, maxHeight: 420)
                .managedMediaBackdrop(
                    item.useLightBackground,
                    insets: EdgeInsets(top: 28, leading: 34, bottom: 28, trailing: 34)
                )
                .shadow(color: SecretMatchTheme.primary.opacity(0.24), radius: 28)
                .accessibilityLabel(item.title.isEmpty ? "Sponsorbild" : item.title)
        } else {
            bundledLogo
        }
    }

    @ViewBuilder
    private var bundledLogo: some View {
        switch selectedLogo % 4 {
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
        case 2:
            Image("ficken-logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 560, maxHeight: 360)
                .padding(34)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 28, y: 12)
                .accessibilityLabel("FICKEN Likör")
        default:
            Image("club2020")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 600, maxHeight: 390)
                .shadow(color: SecretMatchTheme.secondary.opacity(0.24), radius: 28)
                .accessibilityLabel("Club 2020")
        }
    }
}
