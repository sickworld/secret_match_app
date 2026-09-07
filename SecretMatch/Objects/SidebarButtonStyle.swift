import SwiftUI

struct SidebarButtonStyle: ButtonStyle {
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
            return veryCompact ? 12 : (compact ? 15 : 19)
        }
        return metric(19, 20)
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
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .background(configuration.isPressed ? SecretMatchTheme.primary.opacity(0.20) : SecretMatchTheme.surfaceRaised)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
