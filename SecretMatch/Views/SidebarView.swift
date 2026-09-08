import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var api: APIService
    @Environment(\.secretMatchInterfaceScale) private var interfaceScale
    var secondsRemaining: Int
    var registerActivity: () -> Void
    var logout: () -> Void
    @Binding var showOverviewOverlay: Bool
    @Binding var showGuideOverlay: Bool
    @Binding var showRulesOverlay: Bool
    @Binding var showInfoOverlay: Bool
    var isCompact = false
    var isShort = false
    var availableHeight: CGFloat?

    private var normalizedScale: CGFloat {
        max(interfaceScale, 1)
    }

    private var zoomProgress: CGFloat {
        min(max((normalizedScale - 1) / 0.30, 0), 1)
    }

    private func metric(_ standard: CGFloat, _ extraLarge: CGFloat) -> CGFloat {
        let renderedValue = standard + (extraLarge - standard) * zoomProgress
        return renderedValue / normalizedScale
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 132 : metric(156, 170))
                .frame(height: isCompact ? 86 : metric(110, 120))
                .frame(maxWidth: .infinity, alignment: .center)
                .shadow(color: SecretMatchTheme.primary.opacity(0.16), radius: 18)

            Spacer()
                .frame(height: isCompact ? 14 : metric(12, 10))

            HStack(spacing: isCompact ? 10 : metric(10, 11)) {
                Circle()
                    .fill(secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary)
                    .frame(
                        width: isCompact ? 10 : metric(10, 11),
                        height: isCompact ? 10 : metric(10, 11)
                    )
                    .shadow(
                        color: (secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary).opacity(0.5),
                        radius: 6
                    )

                Text("Auto-Logout in \(secondsRemaining)s")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, isCompact ? 16 : metric(16, 16))
            .frame(maxWidth: .infinity, minHeight: isCompact ? 48 : metric(48, 52))
            .background(
                (secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary)
                    .opacity(0.14)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        (secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary)
                            .opacity(0.55),
                        lineWidth: 1.2
                    )
            )
            .accessibilityLabel("Automatischer Logout in \(secondsRemaining) Sekunden")

            Spacer()
                .frame(height: isCompact ? 18 : metric(18, 14))

            VStack(alignment: .leading, spacing: isCompact ? 8 : metric(8, 8)) {
                Text("DEIN EVENT PASS")
                    .font(.caption2.bold())
                    .tracking(1.3)
                    .foregroundStyle(SecretMatchTheme.secondary)

                HStack(spacing: isCompact ? 8 : metric(8, 9)) {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(SecretMatchTheme.primary)
                    Text(api.number.displayEventNumber)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, isCompact ? 14 : metric(19, 20))
                .frame(maxWidth: .infinity, minHeight: isCompact ? 52 : metric(66, 70), alignment: .leading)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: isCompact ? 16 : metric(16, 18), style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 16 : metric(16, 18))
                        .stroke(SecretMatchTheme.border)
                )
            }

            Spacer()
                .frame(height: isCompact ? 18 : metric(18, 14))

            Button {
                registerActivity()
                showOverviewOverlay = true
            } label: {
                HStack(spacing: isCompact ? 12 : metric(12, 10)) {
                    Image(systemName: "rectangle.grid.1x2.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deine Übersicht")
                            .lineLimit(1)
                        Text("Matches · Interesse · Aktionen")
                            .font(.system(
                                size: isCompact ? 12 : metric(11, 12),
                                weight: .semibold,
                                design: .rounded
                            ))
                            .foregroundStyle(SecretMatchTheme.muted)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(SidebarButtonStyle(
                compact: isCompact,
                stabilizedScale: isCompact ? nil : normalizedScale
            ))
            .accessibilityLabel("Deine Übersicht: Matches, Interesse und Aktionen")

            Spacer()
                .frame(height: isCompact ? 12 : metric(10, 10))

            Button {
                registerActivity()
                showGuideOverlay = true
            } label: {
                Label("So funktioniert's", systemImage: "questionmark.circle.fill")
            }
            .buttonStyle(SidebarButtonStyle(
                compact: isCompact,
                stabilizedScale: isCompact ? nil : normalizedScale
            ))

            Spacer()
                .frame(height: isCompact ? 12 : metric(10, 10))

            Button {
                registerActivity()
                showRulesOverlay = true
            } label: {
                Label("Spielregeln", systemImage: "list.bullet.clipboard.fill")
            }
            .buttonStyle(SidebarButtonStyle(
                compact: isCompact,
                stabilizedScale: isCompact ? nil : normalizedScale
            ))

            Spacer()
                .frame(height: isCompact ? 12 : metric(10, 10))

            Button {
                registerActivity()
                showInfoOverlay = true
            } label: {
                Label("Info & Support", systemImage: "info.circle.fill")
            }
            .buttonStyle(SidebarButtonStyle(
                compact: isCompact,
                stabilizedScale: isCompact ? nil : normalizedScale
            ))
            .accessibilityHint("Öffnet Feedback, Datenschutz und Impressum")

            if !isCompact {
                Spacer(minLength: metric(28, 12))
            } else {
                Spacer(minLength: 18)
            }

            Button {
                logout()
            } label: {
                Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(LogoutButtonStyle(
                compact: isCompact,
                stabilizedScale: isCompact ? nil : normalizedScale
            ))

            Spacer()
                .frame(height: isCompact ? 14 : metric(10, 10))

            HStack {
                if isCompact {
                    Spacer()
                }
                HStack(alignment: .center, spacing: isCompact ? 4 : metric(5, 5)) {
                    Image("hot-chili")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isCompact ? 58 : metric(64, 64),
                            height: isCompact ? 42 : metric(48, 46)
                        )
                        .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 12)
                        .accessibilityLabel("Hot Chili Events")

                    Image("ficken-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isCompact ? 62 : metric(68, 68),
                            height: isCompact ? 34 : metric(38, 36)
                        )
                        .padding(.horizontal, isCompact ? 6 : metric(6, 6))
                        .padding(.vertical, isCompact ? 4 : metric(4, 4))
                        .background(Color.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 8 : metric(8, 8)))
                        .accessibilityLabel("FICKEN Likör")

                    Image("club2020")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isCompact ? 112 : metric(98, 94),
                            height: isCompact ? 76 : metric(68, 64)
                        )
                        .accessibilityLabel("Club 2020")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                if isCompact {
                    Spacer()
                }
            }
        }
        .padding(isCompact ? 16 : metric(16, 12))
        .frame(width: isCompact ? nil : metric(304, 336))
        .frame(maxWidth: isCompact ? .infinity : nil)
        .background(SecretMatchTheme.surface.opacity(0.97))
        .overlay(alignment: isCompact ? .bottom : .trailing) {
            Rectangle()
                .fill(SecretMatchTheme.border)
                .frame(width: isCompact ? nil : 1, height: isCompact ? 1 : nil)
        }
    }
}
