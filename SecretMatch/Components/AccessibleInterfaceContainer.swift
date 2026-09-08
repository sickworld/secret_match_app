import SwiftUI
import UIKit

private struct SecretMatchInterfaceScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

private struct SecretMatchHighContrastKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var secretMatchInterfaceScale: CGFloat {
        get { self[SecretMatchInterfaceScaleKey.self] }
        set { self[SecretMatchInterfaceScaleKey.self] = newValue }
    }

    var secretMatchHighContrast: Bool {
        get { self[SecretMatchHighContrastKey.self] }
        set { self[SecretMatchHighContrastKey.self] = newValue }
    }
}

struct SecretMatchScaleControlsHiddenPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct SecretMatchAccessibilityControlsHiddenPreferenceKey: PreferenceKey {
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
    @AppStorage("secretmatch.high-contrast-enabled") private var highContrastEnabled = false
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var systemHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @State private var contentOpacity = 1.0
    @State private var isChangingScale = false
    @State private var hidesControlsForScreensaver = false
    @State private var hidesControlsForOverlay = false
    @State private var showsAccessibilityControls = false
    @State private var scaleChangeTask: Task<Void, Never>?
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let level = InterfaceScaleLevel(rawValue: storedLevel) ?? .standard
            let usesHighContrast = highContrastEnabled || systemHighContrastEnabled

            ZStack(alignment: .topTrailing) {
                Color.black
                    .ignoresSafeArea()

                AccessibilityContrastTraitOverride(enabled: highContrastEnabled)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)

                content
                    .environment(\.secretMatchInterfaceScale, level.scale)
                    .environment(\.secretMatchHighContrast, usesHighContrast)
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
                        hidesControlsForScreensaver = hidden
                        if hidden {
                            showsAccessibilityControls = false
                            resetAccessibilityToDefaults()
                        }
                    }
                    .onPreferenceChange(SecretMatchAccessibilityControlsHiddenPreferenceKey.self) { hidden in
                        hidesControlsForOverlay = hidden
                        if hidden {
                            showsAccessibilityControls = false
                        }
                    }

                if !hidesControlsForScreensaver && !hidesControlsForOverlay {
                    accessibilityControlsButton(level: level, usesHighContrast: usesHighContrast)
                    .padding(.top, 14)
                    .padding(.trailing, 18)
                    .zIndex(10_000)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)) { _ in
            systemHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        .onDisappear {
            scaleChangeTask?.cancel()
            contentOpacity = 1
            isChangingScale = false
            hidesControlsForScreensaver = false
            hidesControlsForOverlay = false
            showsAccessibilityControls = false
        }
    }

    private func accessibilityControlsButton(
        level: InterfaceScaleLevel,
        usesHighContrast: Bool
    ) -> some View {
        Button {
            showsAccessibilityControls = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Text("Aa")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(usesHighContrast ? Color.black : Color.white)

                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(usesHighContrast ? SecretMatchTheme.primary : Color.white)
                    .offset(x: 8, y: 5)
            }
            .frame(width: 52, height: 44)
            .background(usesHighContrast ? Color.white : Color.black.opacity(0.94))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    usesHighContrast ? SecretMatchTheme.secondary : Color.white.opacity(0.42),
                    lineWidth: usesHighContrast ? 2 : 1.2
                )
            )
            .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isChangingScale)
        .accessibilityLabel("Darstellung anpassen")
        .accessibilityValue(
            "\(level.percentage) Prozent, hoher Kontrast \(usesHighContrast ? "ein" : "aus")"
        )
        .accessibilityHint("Öffnet Einstellungen für Textgröße und Kontrast")
        .popover(isPresented: $showsAccessibilityControls, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Darstellung")
                        .font(.headline)

                    Spacer()

                    Button {
                        showsAccessibilityControls = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Darstellung schließen")
                }

                InterfaceAccessibilityControls(
                    level: level,
                    highContrastEnabled: usesHighContrast,
                    isHighContrastForcedBySystem: systemHighContrastEnabled,
                    selectLevel: { newLevel in
                        changeScale(to: newLevel)
                    },
                    toggleHighContrast: {
                        highContrastEnabled.toggle()
                    }
                )
                .allowsHitTesting(!isChangingScale)
            }
            .padding(16)
            .presentationCompactAdaptation(.popover)
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
    private func resetAccessibilityToDefaults() {
        guard storedLevel != InterfaceScaleLevel.standard.rawValue || highContrastEnabled else { return }

        scaleChangeTask?.cancel()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            storedLevel = InterfaceScaleLevel.standard.rawValue
            highContrastEnabled = false
            contentOpacity = 1
            isChangingScale = false
            showsAccessibilityControls = false
        }
    }
}

private struct AccessibilityContrastTraitOverride: UIViewRepresentable {
    let enabled: Bool

    func makeUIView(context: Context) -> ContrastOverrideView {
        let view = ContrastOverrideView()
        view.isAccessibilityElement = false
        view.enabled = enabled
        return view
    }

    func updateUIView(_ uiView: ContrastOverrideView, context: Context) {
        uiView.enabled = enabled
        uiView.applyOverride()
    }

    static func dismantleUIView(_ uiView: ContrastOverrideView, coordinator: ()) {
        uiView.removeOverride()
    }

    final class ContrastOverrideView: UIView {
        var enabled = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyOverride()
        }

        func applyOverride() {
            guard let rootViewController = window?.rootViewController else { return }
            if enabled {
                rootViewController.traitOverrides.accessibilityContrast = .high
            } else {
                rootViewController.traitOverrides.remove(UITraitAccessibilityContrast.self)
            }
        }

        func removeOverride() {
            window?.rootViewController?.traitOverrides.remove(UITraitAccessibilityContrast.self)
        }
    }
}

private struct InterfaceAccessibilityControls: View {
    let level: InterfaceScaleLevel
    let highContrastEnabled: Bool
    let isHighContrastForcedBySystem: Bool
    let selectLevel: (InterfaceScaleLevel) -> Void
    let toggleHighContrast: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            zoomControls
            contrastButton
        }
        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
        .accessibilityElement(children: .contain)
    }

    private var zoomControls: some View {
        HStack(spacing: 3) {
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
        .background(.black.opacity(0.94))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.42), lineWidth: 1.2))
    }

    private var contrastButton: some View {
        Button(action: toggleHighContrast) {
            HStack(spacing: 6) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 17, weight: .bold))
                Text("Kontrast")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                Image(systemName: highContrastEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 15, height: 15)
            }
            .foregroundStyle(highContrastEnabled ? Color.black : Color.white)
            .padding(.horizontal, 12)
            .frame(height: 54)
            .background(highContrastEnabled ? Color.white : Color.black.opacity(0.94))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    highContrastEnabled ? SecretMatchTheme.secondary : Color.white.opacity(0.42),
                    lineWidth: highContrastEnabled ? 2 : 1.2
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isHighContrastForcedBySystem)
        .accessibilityLabel(
            isHighContrastForcedBySystem
                ? "Hoher Kontrast durch die iPad-Einstellung aktiviert"
                : "Hohen Kontrast verwenden"
        )
        .accessibilityValue(highContrastEnabled ? "Ein" : "Aus")
        .accessibilityHint(
            isHighContrastForcedBySystem
                ? "Kann in den Bedienungshilfen des iPads geändert werden"
                : "Erhöht Farbkontraste und hebt Begrenzungen deutlicher hervor"
        )
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
                .foregroundStyle(highContrastEnabled && !isDisabled ? Color.black : Color.white)
                .frame(width: 46, height: 44)
                .background(
                    isDisabled
                        ? Color.white.opacity(highContrastEnabled ? 0.16 : 0.06)
                        : (highContrastEnabled ? Color.white : SecretMatchTheme.primary.opacity(0.82))
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(highContrastEnabled ? 0.9 : 0), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Passt Texte, Schaltflächen und Inhalte gemeinsam an")
    }
}
