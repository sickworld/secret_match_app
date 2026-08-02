import SwiftUI

private struct DemoActionOption: Identifiable {
    let type: String
    let title: String
    let emoji: String
    let color: Color

    var id: String { type }
}

struct HowToUseView: View {
    @Binding var isPresented: Bool
    var registerActivity: () -> Void

    @State private var step = 0
    @State private var isPlaying = true
    @State private var playbackTask: Task<Void, Never>?
    @State private var demoKeyboardNumber = ""
    @State private var isDemoKeyboardDismissed = false

    private let maxStep = 5
    private let options = [
        DemoActionOption(type: "normal", title: "Hot Match", emoji: "❤️", color: Color(hex: "#E83E8C")),
        DemoActionOption(type: "hot", title: "Fuck Match", emoji: "🍆", color: Color(hex: "#8E63D2")),
        DemoActionOption(type: "bjob", title: "Blow-Job", emoji: "👄", color: Color(hex: "#3E9ED6")),
        DemoActionOption(type: "hjob", title: "Hand-Job", emoji: "✋", color: Color(hex: "#E6923E")),
        DemoActionOption(type: "ljob", title: "Lick-Job", emoji: "👅", color: Color(hex: "#D65C8D"))
    ]

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let isCompact = proxy.size.width < proxy.size.height

                if isCompact {
                    ScrollView {
                        VStack(spacing: 18) {
                            header
                                .opacity(showsDemoKeyboard ? 0 : 1)
                            demoPlayer(isCompact: true)
                            controls
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    HStack(spacing: 24) {
                        header
                            .opacity(showsDemoKeyboard ? 0 : 1)
                            .frame(width: min(280, proxy.size.width * 0.27))

                        VStack(spacing: 12) {
                            demoPlayer(isCompact: false)
                            controls
                        }
                        .frame(maxWidth: 720)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            if showsDemoKeyboard {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissDemoKeyboard()
                    }
                    .zIndex(20)

                GeometryReader { proxy in
                    let isCompact = proxy.size.width < proxy.size.height

                    Group {
                        if isCompact {
                            VStack(spacing: 18) {
                                header
                                demoPopupKeyboard
                            }
                        } else {
                            HStack(spacing: 28) {
                                header
                                    .frame(width: min(320, proxy.size.width * 0.26))
                                demoPopupKeyboard
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(24)
                }
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .zIndex(30)
            }
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
        .onChange(of: step) { _, newStep in
            demoKeyboardNumber = newStep >= 3 ? "42" : ""
            isDemoKeyboardDismissed = false
        }
        .animation(.easeInOut(duration: 0.24), value: showsDemoKeyboard)
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
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            Text(stepText)
                .font(.system(size: 17, weight: .medium, design: .rounded))
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
        VStack(spacing: isCompact ? 18 : 10) {
            progressBar

            VStack(spacing: isCompact ? 20 : 10) {
                demoActionGrid(isCompact: isCompact)
                demoNumberInput

                demoSendButton

                if step >= 5 {
                    successMessage
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: 650)
            .secretCard(cornerRadius: 24, padding: isCompact ? 20 : 16)
        }
        .padding(.horizontal, isCompact ? 24 : 0)
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

    private func demoActionGrid(isCompact: Bool) -> some View {
        VStack(spacing: 10) {
            demoSectionTitle("Aktion auswählen", icon: "hand.tap.fill")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: isCompact ? 12 : 7) {
                ForEach(options) { option in
                    demoActionCard(option, isCompact: isCompact)
                }
            }
        }
        .highlighted(step == 1)
    }

    private func demoActionCard(_ option: DemoActionOption, isCompact: Bool) -> some View {
        let isSelected = step >= 1 && option.type == "hot"

        return HStack(spacing: 10) {
            Text(option.emoji)
                .font(.system(size: isCompact ? 22 : 18))
            Text(option.title)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 54 : 42)
        .background(isSelected ? option.color.opacity(0.92) : option.color.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(option.color.opacity(isSelected ? 1 : 0.58), lineWidth: isSelected ? 2 : 1.2)
        )
        .shadow(color: isSelected ? option.color.opacity(0.3) : .clear, radius: 12)
        .scaleEffect(isSelected ? 1.015 : 1)
    }

    private var demoNumberInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            demoSectionTitle("Event-Nummer eingeben", icon: "number")

            Text(demoKeyboardNumber.isEmpty ? "Nummer eingeben" : demoKeyboardNumber.displayEventNumber)
                .foregroundStyle(demoKeyboardNumber.isEmpty ? SecretMatchTheme.muted : .white)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .secretInput(highlighted: step == 2 || step == 3)
        }
        .highlighted(step == 2 || step == 3)
    }

    private var showsDemoKeyboard: Bool {
        (step == 2 || step == 3) && !isDemoKeyboardDismissed
    }

    private var demoPopupKeyboard: some View {
        CustomNumberKeyboard(
            text: $demoKeyboardNumber,
            onActivity: registerActivity,
            onClose: dismissDemoKeyboard
        ) {
            finishDemoKeyboardEntry()
        }
        .frame(maxWidth: 740)
        .shadow(radius: 20)
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
        .font(.system(size: 13, weight: .bold, design: .rounded))
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

    private func dismissDemoKeyboard() {
        isDemoKeyboardDismissed = true
        registerActivity()
    }

    private func finishDemoKeyboardEntry() {
        playbackTask?.cancel()
        isPlaying = false
        step = 4
        registerActivity()
    }

    private func startPlayback() {
        playbackTask?.cancel()
        isPlaying = true
        playbackTask = Task { @MainActor in
            while !Task.isCancelled && isPlaying {
                do {
                    try await Task.sleep(for: .milliseconds(2400))
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
