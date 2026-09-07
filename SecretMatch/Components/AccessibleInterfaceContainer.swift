import SwiftUI

private struct SecretMatchInterfaceScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    var secretMatchInterfaceScale: CGFloat {
        get { self[SecretMatchInterfaceScaleKey.self] }
        set { self[SecretMatchInterfaceScaleKey.self] = newValue }
    }
}

struct SecretMatchScaleControlsHiddenPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

private enum InterfaceScaleLevel: Int, CaseIterable {
    case standard
    case large
    case extraLarge

    var scale: CGFloat {
        switch self {
        case .standard: return 1
        case .large: return 1.15
        case .extraLarge: return 1.30
        }
    }

    var percentage: Int {
        Int((scale * 100).rounded())
    }
}

struct AccessibleInterfaceContainer<Content: View>: View {
    @AppStorage("secretmatch.interface-scale-level") private var storedLevel = InterfaceScaleLevel.standard.rawValue
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var contentOpacity = 1.0
    @State private var isChangingScale = false
    @State private var hidesScaleControls = false
    @State private var scaleChangeTask: Task<Void, Never>?
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let level = InterfaceScaleLevel(rawValue: storedLevel) ?? .standard

            ZStack(alignment: .topTrailing) {
                Color.black
                    .ignoresSafeArea()

                content
                    .environment(\.secretMatchInterfaceScale, level.scale)
                    .frame(
                        width: proxy.size.width / level.scale,
                        height: proxy.size.height / level.scale
                    )
                    .scaleEffect(level.scale, anchor: .topLeading)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        alignment: .topLeading
                    )
                    .opacity(contentOpacity)
                    .onPreferenceChange(SecretMatchScaleControlsHiddenPreferenceKey.self) { hidden in
                        hidesScaleControls = hidden
                        if hidden {
                            resetScaleToStandard()
                        }
                    }

                if !hidesScaleControls {
                    InterfaceScaleControls(level: level) { newLevel in
                        changeScale(to: newLevel)
                    }
                    .allowsHitTesting(!isChangingScale)
                    .padding(.top, 8)
                    .padding(.trailing, 12)
                    .zIndex(10_000)
                }
            }
        }
        .onDisappear {
            scaleChangeTask?.cancel()
            contentOpacity = 1
            isChangingScale = false
            hidesScaleControls = false
        }
    }

    @MainActor
    private func changeScale(to newLevel: InterfaceScaleLevel) {
        guard newLevel.rawValue != storedLevel, !isChangingScale else { return }

        if accessibilityReduceMotion {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                storedLevel = newLevel.rawValue
            }
            return
        }

        isChangingScale = true
        scaleChangeTask?.cancel()

        withAnimation(.easeOut(duration: 0.08)) {
            contentOpacity = 0
        }

        scaleChangeTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(80))
            } catch {
                return
            }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                storedLevel = newLevel.rawValue
            }

            withAnimation(.easeIn(duration: 0.14)) {
                contentOpacity = 1
            }

            do {
                try await Task.sleep(for: .milliseconds(140))
            } catch {
                return
            }
            isChangingScale = false
        }
    }

    @MainActor
    private func resetScaleToStandard() {
        guard storedLevel != InterfaceScaleLevel.standard.rawValue else { return }

        scaleChangeTask?.cancel()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            storedLevel = InterfaceScaleLevel.standard.rawValue
            contentOpacity = 1
            isChangingScale = false
        }
    }
}

private struct InterfaceScaleControls: View {
    let level: InterfaceScaleLevel
    let selectLevel: (InterfaceScaleLevel) -> Void

    var body: some View {
        HStack(spacing: 4) {
            scaleButton(
                title: "A−",
                accessibilityLabel: "Darstellung verkleinern",
                isDisabled: level == .standard
            ) {
                guard let smaller = InterfaceScaleLevel(rawValue: level.rawValue - 1) else { return }
                selectLevel(smaller)
            }

            Text("\(level.percentage)%")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.white)
                .frame(minWidth: 48)
                .accessibilityLabel("Darstellungsgröße \(level.percentage) Prozent")

            scaleButton(
                title: "A+",
                accessibilityLabel: "Darstellung vergrößern",
                isDisabled: level == .extraLarge
            ) {
                guard let larger = InterfaceScaleLevel(rawValue: level.rawValue + 1) else { return }
                selectLevel(larger)
            }
        }
        .padding(5)
        .background(.black.opacity(0.9))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
        .accessibilityElement(children: .contain)
    }

    private func scaleButton(
        title: String,
        accessibilityLabel: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 46, height: 44)
                .background(isDisabled ? Color.white.opacity(0.06) : SecretMatchTheme.primary.opacity(0.82))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Passt Texte, Schaltflächen und Inhalte gemeinsam an")
    }
}
