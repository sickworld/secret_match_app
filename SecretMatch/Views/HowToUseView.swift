import SwiftUI

private struct DemoActionOption: Identifiable {
    let type: String
    let title: String
    let icon: String

    var id: String { type }
}

struct HowToUseView: View {
    @Binding var isPresented: Bool
    var registerActivity: () -> Void

    @State private var step = 0
    @State private var isPlaying = true
    @State private var playbackTask: Task<Void, Never>?

    private let maxStep = 5
    private let options = [
        DemoActionOption(type: "normal", title: "Hot Match", icon: "flame.fill"),
        DemoActionOption(type: "hot", title: "Fuck Match", icon: "heart.fill"),
        DemoActionOption(type: "bjob", title: "Blow-Job", icon: "wind"),
        DemoActionOption(type: "hjob", title: "Hand-Job", icon: "hand.raised.fill"),
        DemoActionOption(type: "ljob", title: "Lick-Job", icon: "mouth.fill")
    ]

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < proxy.size.height

            ScrollView {
                VStack(spacing: isCompact ? 18 : 22) {
                    header
                    demoPlayer(isCompact: isCompact)
                    controls
                }
                .padding(isCompact ? 18 : 30)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startPlayback()
        }
        .onDisappear {
            playbackTask?.cancel()
        }
        .onTapGesture {
            registerActivity()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                Text("GEFÜHRTE DEMO")
            }
            .font(.caption2.bold())
            .tracking(2)
            .foregroundStyle(SecretMatchTheme.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(SecretMatchTheme.secondary.opacity(0.12))
            .clipShape(Capsule())

            Text(stepTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            Text(stepText)
                .font(.subheadline)
                .foregroundStyle(SecretMatchTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 540)
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .animation(.easeOut(duration: 0.24), value: step)
    }

    private func demoPlayer(isCompact: Bool) -> some View {
        VStack(spacing: 18) {
            progressBar

            VStack(spacing: 20) {
                demoActionGrid
                demoNumberInput

                if step >= 2 && step <= 3 {
                    demoKeyboard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                demoSendButton

                if step >= 5 {
                    successMessage
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: 650)
            .secretCard(cornerRadius: 24, padding: isCompact ? 20 : 28)
        }
        .padding(.horizontal, 24)
        .animation(.easeOut(duration: 0.26), value: step)
    }

    private var progressBar: some View {
        HStack(spacing: 7) {
            ForEach(0...maxStep, id: \.self) { item in
                Capsule()
                    .fill(item <= step ? SecretMatchTheme.primary : SecretMatchTheme.surfaceRaised)
                    .frame(height: 6)
            }
        }
        .frame(maxWidth: 650)
        .overlay(alignment: .leading) {
            Text("\(step + 1)/\(maxStep + 1)")
                .font(.caption2.bold())
                .foregroundStyle(SecretMatchTheme.muted)
                .offset(y: 18)
        }
        .padding(.bottom, 16)
    }

    private var demoActionGrid: some View {
        VStack(spacing: 10) {
            demoSectionTitle("Aktion auswählen", icon: "hand.tap.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(options) { option in
                    demoActionCard(option)
                }
            }
        }
        .highlighted(step == 1)
    }

    private func demoActionCard(_ option: DemoActionOption) -> some View {
        let isSelected = step >= 1 && option.type == "hot"

        return HStack(spacing: 10) {
            Image(systemName: option.icon)
            Text(option.title)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(isSelected ? SecretMatchTheme.primary.opacity(0.92) : SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(isSelected ? SecretMatchTheme.primaryHover : SecretMatchTheme.border, lineWidth: 1.2)
        )
        .shadow(color: isSelected ? SecretMatchTheme.primary.opacity(0.25) : .clear, radius: 12)
        .scaleEffect(isSelected ? 1.015 : 1)
    }

    private var demoNumberInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            demoSectionTitle("Event-Nummer eingeben", icon: "number")

            Text(demoNumber)
                .foregroundStyle(demoNumber == "Nummer eingeben" ? SecretMatchTheme.muted : .white)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .secretInput(highlighted: step == 2 || step == 3)
        }
        .highlighted(step == 2 || step == 3)
    }

    private var demoNumber: String {
        switch step {
        case 3...maxStep: return "42"
        default: return "Nummer eingeben"
        }
    }

    private var demoKeyboard: some View {
        VStack(spacing: 12) {
            ForEach([["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["←", "0", "✓"]], id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Text(key)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(key == "✓" ? SecretMatchTheme.primary : SecretMatchTheme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(keyHighlight(for: key) ? SecretMatchTheme.secondary : SecretMatchTheme.border, lineWidth: keyHighlight(for: key) ? 2 : 1)
                            )
                    }
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var demoSendButton: some View {
        HStack {
            Text("Aktion senden")
            Spacer()
            Image(systemName: "paperplane.fill")
        }
        .font(.system(size: 16, weight: .bold, design: .rounded))
        .frame(maxWidth: .infinity, minHeight: 54)
        .padding(.horizontal, 20)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: step >= 4
                    ? [SecretMatchTheme.primary, Color(hex: "#C92F79")]
                    : [SecretMatchTheme.surfaceRaised, SecretMatchTheme.surfaceRaised],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(step == 4 ? SecretMatchTheme.secondary : SecretMatchTheme.border, lineWidth: step == 4 ? 2 : 1)
        )
        .opacity(step >= 4 ? 1 : 0.55)
        .highlighted(step == 4)
    }

    private var successMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(SecretMatchTheme.secondary)
            Text("Demo erfolgreich. Im echten Modus erscheint die gesendete Aktion danach unter \"Deine Aktionen\".")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SecretMatchTheme.primary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.primary.opacity(0.3)))
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button {
                previousStep()
            } label: {
                Image(systemName: "backward.fill")
            }
            .buttonStyle(SecretIconButtonStyle())

            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(SecretIconButtonStyle())

            Button {
                nextStep()
            } label: {
                Image(systemName: "forward.fill")
            }
            .buttonStyle(SecretIconButtonStyle())

            Button {
                restart()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(SecretIconButtonStyle())

            Button {
                isPresented = false
                registerActivity()
            } label: {
                HStack {
                    Text("Schließen")
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .buttonStyle(SecretSecondaryButtonStyle())
        }
        .frame(maxWidth: 650)
        .padding(.horizontal, 24)
    }

    private func demoSectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(title)
            Spacer()
        }
        .font(.caption2.bold())
        .tracking(1.2)
        .foregroundStyle(SecretMatchTheme.muted)
    }

    private var stepTitle: String {
        switch step {
        case 0: return "So läuft es ab"
        case 1: return "Aktion auswählen"
        case 2: return "Nummer antippen"
        case 3: return "Nummer eingeben"
        case 4: return "Aktion senden"
        default: return "Fertig"
        }
    }

    private var stepText: String {
        switch step {
        case 0: return "Die Demo spielt den Ablauf automatisch vor."
        case 1: return "Zuerst wird ausgewählt, was gesendet werden soll."
        case 2: return "Danach wird das Nummernfeld geöffnet."
        case 3: return "Die Event-Nummer der anderen Person wird eingetippt."
        case 4: return "Wenn Aktion und Nummer gesetzt sind, wird der Button aktiv."
        default: return "Die Demo ist nur eine Vorschau und verschickt nichts."
        }
    }

    private func keyHighlight(for key: String) -> Bool {
        (step == 3 && (key == "4" || key == "2")) || (step == 4 && key == "✓")
    }

    private func startPlayback() {
        playbackTask?.cancel()
        isPlaying = true
        playbackTask = Task { @MainActor in
            while !Task.isCancelled && isPlaying {
                do {
                    try await Task.sleep(for: .milliseconds(1450))
                } catch {
                    return
                }

                guard !Task.isCancelled, isPlaying else { return }
                if step < maxStep {
                    step += 1
                    registerActivity()
                } else {
                    isPlaying = false
                    return
                }
            }
        }
    }

    private func togglePlayback() {
        registerActivity()
        if isPlaying {
            isPlaying = false
            playbackTask?.cancel()
        } else {
            startPlayback()
        }
    }

    private func nextStep() {
        playbackTask?.cancel()
        isPlaying = false
        step = min(step + 1, maxStep)
        registerActivity()
    }

    private func previousStep() {
        playbackTask?.cancel()
        isPlaying = false
        step = max(step - 1, 0)
        registerActivity()
    }

    private func restart() {
        step = 0
        registerActivity()
        startPlayback()
    }
}

private struct SecretIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .frame(width: 48, height: 50)
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

private extension View {
    func highlighted(_ isActive: Bool) -> some View {
        padding(2)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isActive ? SecretMatchTheme.secondary.opacity(0.95) : .clear, lineWidth: 2)
            )
            .shadow(color: isActive ? SecretMatchTheme.secondary.opacity(0.18) : .clear, radius: 16)
    }
}
