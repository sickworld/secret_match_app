import SwiftUI

enum SecretMatchTheme {
    static let primary = Color(hex: "#E83E8C")
    static let primaryHover = Color(hex: "#FF5FA8")
    static let secondary = Color(hex: "#F4B400")
    static let background = Color(hex: "#121212")
    static let surface = Color(hex: "#1E1E1E")
    static let surfaceRaised = Color(hex: "#262326")
    static let text = Color.white
    static let muted = Color(hex: "#BDBDBD")
    static let border = Color(hex: "#333333")
    static let danger = Color(hex: "#FF667A")
}

struct SecretCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SecretMatchTheme.surface.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(SecretMatchTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.42), radius: 24, y: 14)
            .shadow(color: SecretMatchTheme.primary.opacity(0.10), radius: 28)
    }
}

extension View {
    func secretCard(cornerRadius: CGFloat = 20, padding: CGFloat = 24) -> some View {
        modifier(SecretCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

struct SecretPrimaryButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 54)
            .padding(.horizontal, 20)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [SecretMatchTheme.primaryHover, SecretMatchTheme.primary]
                        : [SecretMatchTheme.primary, Color(hex: "#C92F79")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: SecretMatchTheme.primary.opacity(configuration.isPressed ? 0.18 : 0.30), radius: 14, y: 7)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SecretSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 18)
            .foregroundStyle(SecretMatchTheme.text)
            .background(configuration.isPressed ? SecretMatchTheme.surfaceRaised : SecretMatchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(SecretMatchTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SecretInputModifier: ViewModifier {
    var highlighted = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Color.black.opacity(0.28))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        highlighted ? SecretMatchTheme.primary.opacity(0.85) : SecretMatchTheme.border,
                        lineWidth: highlighted ? 1.5 : 1
                    )
            )
            .shadow(color: highlighted ? SecretMatchTheme.primary.opacity(0.16) : .clear, radius: 12)
    }
}

extension View {
    func secretInput(highlighted: Bool = false) -> some View {
        modifier(SecretInputModifier(highlighted: highlighted))
    }
}
