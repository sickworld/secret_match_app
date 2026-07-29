import SwiftUI

struct LogoutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .bold, design: .rounded))
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(SecretMatchTheme.danger.opacity(configuration.isPressed ? 0.24 : 0.14))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 17)
                    .stroke(SecretMatchTheme.danger.opacity(0.65), lineWidth: 1.2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
