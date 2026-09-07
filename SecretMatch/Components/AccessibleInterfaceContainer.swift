import SwiftUI

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
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let level = InterfaceScaleLevel(rawValue: storedLevel) ?? .standard

            ZStack(alignment: .topTrailing) {
                content
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

                InterfaceScaleControls(level: level) { newLevel in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        storedLevel = newLevel.rawValue
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 12)
                .zIndex(10_000)
            }
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
