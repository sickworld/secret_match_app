import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var api: APIService
    var secondsRemaining: Int
    var registerActivity: () -> Void
    var logout: () -> Void
    @Binding var showMatchesOverlay: Bool
    @Binding var showActionsOverlay: Bool
    @Binding var showGuideOverlay: Bool
    @Binding var showRulesOverlay: Bool
    var isCompact = false
    var isShort = false

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 14 : (isShort ? 10 : 20)) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 132 : (isShort ? 142 : 174))
                .frame(height: isCompact ? 86 : (isShort ? 86 : 142))
                .shadow(color: SecretMatchTheme.primary.opacity(0.16), radius: 18)

            HStack(spacing: 10) {
                Circle()
                    .fill(secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary)
                    .frame(width: 10, height: 10)
                    .shadow(
                        color: (secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary).opacity(0.5),
                        radius: 6
                    )

                Text("Auto-Logout in \(secondsRemaining)s")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: isShort ? 42 : 48)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("DEIN EVENT PASS")
                    .font(.caption2.bold())
                    .tracking(1.3)
                    .foregroundStyle(SecretMatchTheme.secondary)

                HStack {
                    Image(systemName: "ticket.fill")
                        .foregroundStyle(SecretMatchTheme.primary)
                    Text(api.number)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SecretMatchTheme.border))
            }

            Button {
                registerActivity()
                showMatchesOverlay = true
            } label: {
                Label("Deine Matches", systemImage: "sparkles")
            }
            .buttonStyle(SidebarButtonStyle(compact: isShort))
            
            Button {
                registerActivity()
                showActionsOverlay = true
            } label: {
                Label("Deine Aktionen", systemImage: "paperplane.fill")
            }
            .buttonStyle(SidebarButtonStyle(compact: isShort))

            Button {
                registerActivity()
                showGuideOverlay = true
            } label: {
                Label("So funktioniert's", systemImage: "questionmark.circle.fill")
            }
            .buttonStyle(SidebarButtonStyle(compact: isShort))

            Button {
                registerActivity()
                showRulesOverlay = true
            } label: {
                Label("Spielregeln", systemImage: "list.bullet.clipboard.fill")
            }
            .buttonStyle(SidebarButtonStyle(compact: isShort))

            if !isCompact {
                Spacer(minLength: isShort ? 12 : 24)
            }

            Button {
                logout()
            } label: {
                Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(LogoutButtonStyle(compact: isShort))

            HStack {
                if isCompact {
                    Spacer()
                }
                Image("hot-chili")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: isCompact ? 82 : (isShort ? 72 : 112),
                        height: isCompact ? 56 : (isShort ? 46 : 78)
                    )
                    .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 12)
                    .accessibilityLabel("Hot Chili Events")
                if isCompact {
                    Spacer()
                }
            }
        }
        .padding(isCompact ? 16 : (isShort ? 14 : 22))
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
