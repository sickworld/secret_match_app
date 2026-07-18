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

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 18) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 132 : 174)
                .frame(height: isCompact ? 86 : 142)
                .shadow(color: SecretMatchTheme.primary.opacity(0.16), radius: 18)

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
            .buttonStyle(SidebarButtonStyle())
            
            Button {
                registerActivity()
                showActionsOverlay = true
            } label: {
                Label("Deine Aktionen", systemImage: "paperplane.fill")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                registerActivity()
                showGuideOverlay = true
            } label: {
                Label("So funktioniert's", systemImage: "questionmark.circle.fill")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                registerActivity()
                showRulesOverlay = true
            } label: {
                Label("Spielregeln", systemImage: "list.bullet.clipboard.fill")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                logout()
            } label: {
                Label("Event verlassen", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(LogoutButtonStyle())

            HStack(spacing: 7) {
                Circle()
                    .fill(secondsRemaining <= 10 ? SecretMatchTheme.secondary : SecretMatchTheme.primary)
                    .frame(width: 7, height: 7)
                Text("Auto-Logout in \(secondsRemaining)s")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            if !isCompact {
                Spacer()
            }

            VStack(alignment: isCompact ? .center : .leading, spacing: 18) {
                Spacer()
                Image("hot-chili")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isCompact ? 82 : 112, height: isCompact ? 56 : 78)
                    .shadow(color: SecretMatchTheme.primary.opacity(0.18), radius: 12)
                    .accessibilityLabel("Hot Chili Events")
            }
            .frame(maxWidth: isCompact ? .infinity : nil)
        }
        .padding(isCompact ? 16 : 22)
        .frame(width: isCompact ? nil : 260)
        .frame(maxWidth: isCompact ? .infinity : nil)
        .background(SecretMatchTheme.surface.opacity(0.97))
        .overlay(alignment: isCompact ? .bottom : .trailing) {
            Rectangle()
                .fill(SecretMatchTheme.border)
                .frame(width: isCompact ? nil : 1, height: isCompact ? 1 : nil)
        }
    }
}
