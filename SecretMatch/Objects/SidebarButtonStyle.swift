import SwiftUI

struct SidebarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
            .padding(.horizontal, 19)
            .background(configuration.isPressed ? SecretMatchTheme.primary.opacity(0.20) : SecretMatchTheme.surfaceRaised)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(configuration.isPressed ? SecretMatchTheme.primary.opacity(0.7) : SecretMatchTheme.border, lineWidth: 1.2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct MatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 140)
            .buttonStyle(SecretPrimaryButtonStyle())
    }
}

struct FMatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 140)
            .buttonStyle(SecretPrimaryButtonStyle())
    }
}
