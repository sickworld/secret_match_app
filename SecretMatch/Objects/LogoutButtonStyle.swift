import SwiftUI

struct LogoutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .frame(minHeight: 46)
            .background(SecretMatchTheme.surfaceRaised)
            .foregroundStyle(SecretMatchTheme.muted)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
