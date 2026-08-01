import SwiftUI

private struct RuleSlide: Identifiable {
    let icon: String
    let eyebrow: String
    let title: String
    let text: String
    let highlights: [String]

    var id: String { title }
}

struct RulesSlideshowView: View {
    @Binding var isPresented: Bool
    var registerActivity: () -> Void

    @State private var selectedIndex = 0
    @State private var isPlaying = true
    @State private var playbackTask: Task<Void, Never>?

    private let slides = [
        RuleSlide(
            icon: "ticket.fill",
            eyebrow: "START",
            title: "Deine Nummer ist dein Event-Pass",
            text: "Jede Person bekommt eine Nummer. Alles, was du in der App sendest, läuft über diese Nummer.",
            highlights: ["Nummern statt Namen", "Diskret", "Nur im Event"]
        ),
        RuleSlide(
            icon: "sparkles",
            eyebrow: "MATCHES",
            title: "Matches zeigen Interesse",
            text: "Mit einem Match verteilst du ein Signal. Wenn beide Seiten matchen, erscheint es bei euren Matches.",
            highlights: ["Interesse senden", "Gegenseitigkeit zählt", "Matches prüfen"]
        ),
        RuleSlide(
            icon: "paperplane.fill",
            eyebrow: "AKTIONEN",
            title: "Aktionen sind Vorschläge",
            text: "Aktionen sind direkter als Matches. Du kannst damit zeigen, worauf du Lust hast.",
            highlights: ["Aktion wählen", "Nummer eingeben", "Absenden"]
        ),
        RuleSlide(
            icon: "hand.raised.fill",
            eyebrow: "CONSENT",
            title: "Ein Nein gilt immer",
            text: "Auch wenn jemand eine Aktion sendet, entscheidet die andere Person frei. Kein Match und keine Aktion ersetzt Zustimmung.",
            highlights: ["Nein respektieren", "Keine Diskussion", "Nur wenn beide wollen"]
        ),
        RuleSlide(
            icon: "heart.text.square.fill",
            eyebrow: "FAIR PLAY",
            title: "Bleib respektvoll",
            text: "Nutze die App als Einladung, nicht als Druckmittel. Sprich freundlich, achte Grenzen und lass anderen Raum.",
            highlights: ["Freundlich bleiben", "Grenzen achten", "Spaß ohne Druck"]
        )
    ]

    private var selectedSlide: RuleSlide {
        slides[selectedIndex]
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < proxy.size.height

            if isCompact {
                ScrollView {
                    VStack(spacing: 18) {
                        header(isLeading: false)
                        slideCard(isCompact: true)
                        controls
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: 20) {
                    header(isLeading: true)
                        .frame(width: min(210, proxy.size.width * 0.22))

                    VStack(spacing: 16) {
                        ScrollView {
                            slideCard(isCompact: false)
                                .padding(.vertical, 4)
                        }
                        controls
                    }
                    .frame(maxWidth: 760)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onTapGesture {
            registerActivity()
        }
        .onAppear {
            startPlayback()
        }
        .onDisappear {
            playbackTask?.cancel()
        }
    }

    private func header(isLeading: Bool) -> some View {
        VStack(alignment: isLeading ? .leading : .center, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.clipboard.fill")
                Text("SPIELREGELN")
            }
            .font(.caption2.bold())
            .tracking(2)
            .foregroundStyle(SecretMatchTheme.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(SecretMatchTheme.secondary.opacity(0.12))
            .clipShape(Capsule())

            Text("So funktioniert das Event")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(isLeading ? .leading : .center)
        }
        .padding(.horizontal, isLeading ? 0 : 24)
    }

    @ViewBuilder
    private func slideCard(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 18 : 24) {
            slideProgress

            if isCompact {
                ruleIcon(size: 112, iconSize: 48)
                ruleCopy(isCompact: true)
                highlights(isCompact: true)
            } else {
                ruleIcon(size: 116, iconSize: 50)
                ruleCopy(isCompact: false)
                highlights(isCompact: false)
            }
        }
        .frame(maxWidth: isCompact ? 720 : 640)
        .secretCard(cornerRadius: 24, padding: isCompact ? 22 : 28)
        .padding(.horizontal, isCompact ? 24 : 0)
        .animation(.easeOut(duration: 0.24), value: selectedIndex)
    }

    private func ruleIcon(size: CGFloat, iconSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(SecretMatchTheme.primary.opacity(0.14))
                .frame(width: size, height: size)

            Image(systemName: selectedSlide.icon)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(SecretMatchTheme.secondary)
        }
        .padding(.top, 4)
    }

    private func ruleCopy(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 10 : 12) {
            Text(selectedSlide.eyebrow)
                .font(.caption2.bold())
                .tracking(2)
                .foregroundStyle(SecretMatchTheme.secondary)

            Text(selectedSlide.title)
                .font(.system(size: isCompact ? 25 : 32, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.82)

            Text(selectedSlide.text)
                .font(.system(size: isCompact ? 18 : 19, weight: .medium, design: .rounded))
                .foregroundStyle(SecretMatchTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 540)
        }
    }

    private func highlights(isCompact: Bool) -> some View {
        VStack(spacing: 10) {
            ForEach(selectedSlide.highlights, id: \.self) { highlight in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SecretMatchTheme.primary)
                    Text(highlight)
                        .font(.system(size: isCompact ? 16 : 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: isCompact ? 44 : 50)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
            }
        }
    }

    private var slideProgress: some View {
        HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selectedIndex ? SecretMatchTheme.primary : SecretMatchTheme.surfaceRaised)
                    .frame(width: index == selectedIndex ? 34 : 9, height: 9)
                    .onTapGesture {
                        stopPlayback()
                        selectedIndex = index
                        registerActivity()
                    }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                previousSlide()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(RuleIconButtonStyle())
            .disabled(selectedIndex == 0)
            .opacity(selectedIndex == 0 ? 0.45 : 1)

            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(RuleIconButtonStyle())
            .accessibilityLabel(isPlaying ? "Automatischen Ablauf pausieren" : "Automatischen Ablauf starten")

            Button {
                nextSlide()
            } label: {
                HStack {
                    Text(selectedIndex == slides.count - 1 ? "Fertig" : "Weiter")
                    Image(systemName: selectedIndex == slides.count - 1 ? "checkmark.circle.fill" : "chevron.right")
                }
            }
            .buttonStyle(SecretPrimaryButtonStyle())

            Button {
                isPresented = false
                registerActivity()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(RuleIconButtonStyle())
        }
        .frame(maxWidth: 650)
        .padding(.horizontal, 24)
    }

    private func nextSlide() {
        stopPlayback()
        registerActivity()

        if selectedIndex == slides.count - 1 {
            isPresented = false
        } else {
            selectedIndex += 1
        }
    }

    private func previousSlide() {
        stopPlayback()
        selectedIndex = max(selectedIndex - 1, 0)
        registerActivity()
    }

    private func startPlayback() {
        playbackTask?.cancel()

        if selectedIndex == slides.count - 1 {
            selectedIndex = 0
        }

        isPlaying = true
        playbackTask = Task { @MainActor in
            while !Task.isCancelled && isPlaying {
                do {
                    try await Task.sleep(for: .seconds(6))
                } catch {
                    return
                }

                guard !Task.isCancelled, isPlaying else { return }
                if selectedIndex < slides.count - 1 {
                    selectedIndex += 1
                    registerActivity()
                } else {
                    isPlaying = false
                    return
                }
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        playbackTask?.cancel()
    }

    private func togglePlayback() {
        registerActivity()
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
}

private struct RuleIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(width: 54, height: 56)
            .foregroundStyle(.white)
            .background(configuration.isPressed ? SecretMatchTheme.primary.opacity(0.8) : SecretMatchTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(SecretMatchTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
