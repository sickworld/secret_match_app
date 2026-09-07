import SwiftUI

struct LogoutButtonStyle: ButtonStyle {
    var compact = false
    var veryCompact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: veryCompact ? 15 : (compact ? 17 : 19), weight: .bold, design: .rounded))
            .padding(.horizontal, veryCompact ? 12 : (compact ? 15 : 20))
            .frame(maxWidth: .infinity, minHeight: veryCompact ? 44 : (compact ? 52 : 66))
            .background(SecretMatchTheme.danger.opacity(configuration.isPressed ? 0.24 : 0.14))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: veryCompact ? 12 : (compact ? 14 : 17), style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: veryCompact ? 12 : (compact ? 14 : 17))
                    .stroke(SecretMatchTheme.danger.opacity(0.65), lineWidth: 1.2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
