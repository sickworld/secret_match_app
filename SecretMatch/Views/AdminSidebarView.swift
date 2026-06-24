import SwiftUI

struct AdminSidebarView: View {
    @EnvironmentObject var api: APIService

    @Binding var showActions: Bool
    @Binding var showMatches: Bool
    var logout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 174)
                .frame(height: 142)
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

            Spacer()

            HStack {
                Spacer()
                Image("hot-chili")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 72)
                    .accessibilityLabel("Hot Chili Events")
            }
        }
        .padding(22)
        .frame(width: 260)
        .background(SecretMatchTheme.surface.opacity(0.97))
        .overlay(alignment: .trailing) {
            Rectangle().fill(SecretMatchTheme.border).frame(width: 1)
        }
    }
}
