import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var api: APIService
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

    private var isVeryShort: Bool {
        !isCompact && (availableHeight ?? .infinity) < 800
    }

    private var usesCondensedLayout: Bool {
        isShort || isVeryShort
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 132 : (isVeryShort ? 112 : (usesCondensedLayout ? 142 : 174)))
                .frame(height: isCompact ? 86 : (isVeryShort ? 64 : (usesCondensedLayout ? 86 : 142)))
                .shadow(color: SecretMatchTheme.primary.opacity(0.16), radius: 18)

            Spacer(minLength: isCompact ? 14 : (isVeryShort ? 4 : (usesCondensedLayout ? 8 : 14)))

            HStack(spacing: 10) {
                Circle()
                    .fill(secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary)
                    .frame(width: 10, height: 10)
                    .shadow(
                        color: (secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary).opacity(0.5),
                        radius: 6
                    )

                Text("Auto-Logout in \(secondsRemaining)s")
                    .font(.system(size: isVeryShort ? 15 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, isVeryShort ? 12 : 16)
            .frame(maxWidth: .infinity, minHeight: isVeryShort ? 38 : (usesCondensedLayout ? 42 : 48))
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

            Spacer(minLength: isCompact ? 18 : (isVeryShort ? 8 : (usesCondensedLayout ? 16 : 24)))

            VStack(alignment: .leading, spacing: 8) {
                Text("DEIN EVENT PASS")
                    .font(.caption2.bold())
                    .tracking(1.3)
                    .foregroundStyle(SecretMatchTheme.secondary)

                HStack {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(SecretMatchTheme.primary)
                    Text(api.number.displayEventNumber)
                        .font(.system(size: isVeryShort ? 24 : 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, isVeryShort ? 12 : 14)
                .frame(maxWidth: .infinity, minHeight: isVeryShort ? 48 : 58, alignment: .leading)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SecretMatchTheme.border))
            }

            Spacer(minLength: isCompact ? 18 : (isVeryShort ? 8 : (usesCondensedLayout ? 16 : 24)))

            Button {
                registerActivity()
                showOverviewOverlay = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.grid.1x2.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deine Übersicht")
                        Text("Matches · Interesse · Aktionen")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                }
            }
            .buttonStyle(SidebarButtonStyle(compact: usesCondensedLayout, veryCompact: isVeryShort))
            .accessibilityLabel("Deine Übersicht: Matches, Interesse und Aktionen")

            Spacer(minLength: isCompact ? 12 : (isVeryShort ? 4 : (usesCondensedLayout ? 8 : 12)))

            Button {
                registerActivity()
                showGuideOverlay = true
            } label: {
                Label("So funktioniert's", systemImage: "questionmark.circle.fill")
            }
            .buttonStyle(SidebarButtonStyle(compact: usesCondensedLayout, veryCompact: isVeryShort))

            Spacer(minLength: isCompact ? 12 : (isVeryShort ? 4 : (usesCondensedLayout ? 8 : 12)))

            Button {
                registerActivity()
                showRulesOverlay = true
            } label: {
                Label("Spielregeln", systemImage: "list.bullet.clipboard.fill")
            }
            .buttonStyle(SidebarButtonStyle(compact: usesCondensedLayout, veryCompact: isVeryShort))

            Spacer(minLength: isCompact ? 12 : (isVeryShort ? 4 : (usesCondensedLayout ? 8 : 12)))

            Button {
                registerActivity()
                showInfoOverlay = true
            } label: {
                Label("Info & Support", systemImage: "info.circle.fill")
            }
            .buttonStyle(SidebarButtonStyle(compact: usesCondensedLayout, veryCompact: isVeryShort))
            .accessibilityHint("Öffnet Feedback, Datenschutz und Impressum")

            if !isCompact {
                Spacer(minLength: isVeryShort ? 8 : (usesCondensedLayout ? 16 : 28))
            } else {
                Spacer(minLength: 18)
            }

            Button {
                logout()
            } label: {
                Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(LogoutButtonStyle(compact: usesCondensedLayout, veryCompact: isVeryShort))

            Spacer(minLength: isCompact ? 14 : (isVeryShort ? 4 : (usesCondensedLayout ? 8 : 14)))

            HStack {
                if isCompact {
                    Spacer()
                }
                HStack(alignment: .center, spacing: usesCondensedLayout ? 4 : 5) {
                    Image("hot-chili")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isVeryShort ? 44 : (usesCondensedLayout ? 58 : 64),
                            height: isVeryShort ? 32 : (usesCondensedLayout ? 42 : 48)
                        )
                        .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 12)
                        .accessibilityLabel("Hot Chili Events")

                    Image("ficken-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isVeryShort ? 46 : (usesCondensedLayout ? 62 : 68),
                            height: isVeryShort ? 26 : (usesCondensedLayout ? 34 : 38)
                        )
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("FICKEN Likör")

                    Image("club2020")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isCompact ? 112 : (isVeryShort ? 62 : (usesCondensedLayout ? 88 : 98)),
                            height: isCompact ? 76 : (isVeryShort ? 42 : (usesCondensedLayout ? 62 : 68))
                        )
                        .accessibilityLabel("Club 2020")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                if isCompact {
                    Spacer()
                }
            }
        }
        .padding(isCompact ? 16 : (isVeryShort ? 10 : (usesCondensedLayout ? 14 : 22)))
        .frame(width: isCompact ? nil : 304)
        .frame(maxWidth: isCompact ? .infinity : nil)
        .background(SecretMatchTheme.surface.opacity(0.97))
        .overlay(alignment: isCompact ? .bottom : .trailing) {
            Rectangle()
                .fill(SecretMatchTheme.border)
                .frame(width: isCompact ? nil : 1, height: isCompact ? 1 : nil)
        }
    }
}
