import SwiftUI
import UIKit

enum SecretMatchTheme {
    /// The product uses one deliberately compact radius for interactive controls
    /// and content panels. Capsules remain reserved for short status badges.
    static let cornerRadius: CGFloat = 8
    static let primary = adaptiveColor(standard: "#E83E8C", increased: "#FF5FA8")
    static let primaryHover = adaptiveColor(standard: "#FF5FA8", increased: "#FF8FC4")
    static let secondary = adaptiveColor(standard: "#F4B400", increased: "#FFD60A")
    static let background = adaptiveColor(standard: "#121212", increased: "#000000")
    static let surface = adaptiveColor(standard: "#1E1E1E", increased: "#000000")
    static let surfaceRaised = adaptiveColor(standard: "#262326", increased: "#151515")
    static let text = Color.white
    static let muted = adaptiveColor(standard: "#BDBDBD", increased: "#FFFFFF")
    static let border = adaptiveColor(standard: "#333333", increased: "#FFFFFF")
    static let danger = adaptiveColor(standard: "#FF667A", increased: "#FF6B81")

    private static func adaptiveColor(standard: String, increased: String) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(secretMatchHex: traits.accessibilityContrast == .high ? increased : standard)
        })
    }
}

struct SecretBinaryStatusIcon: View {
    let isPositive: Bool
    var size: CGFloat = 15

    var body: some View {
        Image(systemName: isPositive ? "checkmark.circle.fill" : "xmark.octagon.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(isPositive ? Color.green : Color.red)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct SecretCardModifier: ViewModifier {
    @Environment(\.secretMatchHighContrast) private var highContrast
    var cornerRadius: CGFloat = SecretMatchTheme.cornerRadius
    var padding: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SecretMatchTheme.surface.opacity(highContrast ? 1 : 0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(SecretMatchTheme.border.opacity(highContrast ? 0.9 : 1), lineWidth: highContrast ? 2 : 1)
                    )
            )
            .shadow(color: .black.opacity(0.42), radius: 24, y: 14)
            .shadow(color: SecretMatchTheme.primary.opacity(0.10), radius: 28)
    }
}

extension View {
    func secretCard(cornerRadius: CGFloat = SecretMatchTheme.cornerRadius, padding: CGFloat = 24) -> some View {
        modifier(SecretCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

struct SecretPrimaryButtonStyle: ButtonStyle {
    @Environment(\.secretMatchHighContrast) private var highContrast
    var fullWidth = true
    var fontSize: CGFloat = 16
    var minHeight: CGFloat = 60

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: minHeight)
            .padding(.horizontal, 20)
            .foregroundStyle(highContrast ? Color.black : Color.white)
            .background(
                LinearGradient(
                    colors: highContrast
                        ? [Color.white.opacity(configuration.isPressed ? 0.82 : 1), Color.white]
                        : (configuration.isPressed
                            ? [SecretMatchTheme.primaryHover, SecretMatchTheme.primary]
                            : [SecretMatchTheme.primary, Color(hex: "#C92F79")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(highContrast ? 0.9 : 0.12), lineWidth: highContrast ? 2 : 1)
            )
            .shadow(
                color: highContrast
                    ? Color.clear
                    : SecretMatchTheme.primary.opacity(configuration.isPressed ? 0.18 : 0.30),
                radius: 14,
                y: 7
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SecretSecondaryButtonStyle: ButtonStyle {
    @Environment(\.secretMatchHighContrast) private var highContrast

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 18)
            .foregroundStyle(SecretMatchTheme.text)
            .background(configuration.isPressed ? SecretMatchTheme.surfaceRaised : SecretMatchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                    .stroke(SecretMatchTheme.border.opacity(highContrast ? 0.9 : 1), lineWidth: highContrast ? 2 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SecretInputModifier: ViewModifier {
    @Environment(\.secretMatchHighContrast) private var highContrast
    var highlighted = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(Color.black.opacity(highContrast ? 1 : 0.28))
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                    .stroke(
                        highlighted ? SecretMatchTheme.primary : SecretMatchTheme.border.opacity(highContrast ? 0.9 : 1),
                        lineWidth: highContrast ? 2.5 : (highlighted ? 1.5 : 1)
                    )
            )
            .shadow(color: highlighted ? SecretMatchTheme.primary.opacity(0.16) : .clear, radius: 12)
    }
}

struct SecretAdminFeatureButtonStyle: ButtonStyle {
    @Environment(\.secretMatchHighContrast) private var highContrast
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .padding(16)
            .foregroundStyle(SecretMatchTheme.text)
            .background(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? tint.opacity(0.24) : SecretMatchTheme.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                    .stroke(tint.opacity(highContrast ? 0.95 : 0.55), lineWidth: highContrast ? 2 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension View {
    func secretInput(highlighted: Bool = false) -> some View {
        modifier(SecretInputModifier(highlighted: highlighted))
    }

    func secretAdminInput(highlighted: Bool = false) -> some View {
        modifier(SecretAdminInputModifier(highlighted: highlighted))
    }
}

struct SecretAdminInputModifier: ViewModifier {
    @Environment(\.secretMatchHighContrast) private var highContrast
    var highlighted = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.black.opacity(highContrast ? 1 : 0.28))
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                    .stroke(
                        highlighted ? SecretMatchTheme.primary : SecretMatchTheme.border,
                        lineWidth: highContrast ? 2 : 1
                    )
            )
    }
}

private extension UIColor {
    convenience init(secretMatchHex hex: String) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
