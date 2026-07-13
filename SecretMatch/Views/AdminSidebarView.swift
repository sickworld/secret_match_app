import SwiftUI

struct AdminSidebarView: View {
    @EnvironmentObject var api: APIService

    @Binding var showActions: Bool
    @Binding var showMatches: Bool
    var logout: () -> Void
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 18) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: isCompact ? 132 : 174)
                .frame(height: isCompact ? 86 : 142)
                .shadow(color: SecretMatchTheme.primary.opacity(0.16), radius: 18)

            Text("EVENT CONTROL")
                .font(.caption2.bold())
                .tracking(1.8)
                .foregroundStyle(SecretMatchTheme.secondary)

            Divider().background(Color.white.opacity(0.3))

            Button {
                showActions = true
            } label: {
                Label("Alle Aktionen", systemImage: "paperplane.fill")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                showMatches = true
            } label: {
                Label("Alle Matches", systemImage: "sparkles")
            }
            .buttonStyle(SidebarButtonStyle())

            Divider().background(Color.white.opacity(0.3))

            Button {
                logout()
            } label: {
                Label("Admin Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(LogoutButtonStyle())

            if !isCompact {
                Spacer()
            }

            HStack {
                Spacer()
                Image("hot-chili")
                    .resizable()
                    .scaledToFit()
                    .frame(width: isCompact ? 82 : 104, height: isCompact ? 56 : 72)
                    .accessibilityLabel("Hot Chili Events")
            }
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
