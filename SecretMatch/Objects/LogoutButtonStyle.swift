import SwiftUI

struct LogoutButtonStyle: ButtonStyle {
    var compact = false
    var veryCompact = false
    var stabilizedScale: CGFloat?

    private var normalizedScale: CGFloat {
        max(stabilizedScale ?? 1, 1)
    }

    private var zoomProgress: CGFloat {
        min(max((normalizedScale - 1) / 0.30, 0), 1)
    }

    private func metric(_ standard: CGFloat, _ extraLarge: CGFloat) -> CGFloat {
        let renderedValue = standard + (extraLarge - standard) * zoomProgress
        return renderedValue / normalizedScale
    }

    private var fontSize: CGFloat {
        guard stabilizedScale != nil else {
            return veryCompact ? 15 : (compact ? 17 : 19)
        }
        return metric(19, 21)
    }

    private var minHeight: CGFloat {
        guard stabilizedScale != nil else {
            return veryCompact ? 44 : (compact ? 52 : 66)
        }
        return metric(66, 70)
    }

    private var horizontalPadding: CGFloat {
        guard stabilizedScale != nil else {
            return veryCompact ? 12 : (compact ? 15 : 20)
        }
        return metric(20, 21)
    }

    private var cornerRadius: CGFloat {
        guard stabilizedScale != nil else {
            return veryCompact ? 12 : (compact ? 14 : 17)
        }
        return metric(17, 18)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(SecretMatchTheme.danger.opacity(configuration.isPressed ? 0.24 : 0.14))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(SecretMatchTheme.danger.opacity(0.65), lineWidth: 1.2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
