import SwiftUI

struct AdminSidebarView: View {
    @EnvironmentObject var api: APIService

    @Binding var showActions: Bool
    @Binding var showMatches: Bool
    @Binding var showBillboard: Bool
    @Binding var showLiveFeed: Bool
    @Binding var dashboardSection: AdminDashboardSection
    var dismissMenu: () -> Void = {}
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

#if ADMIN_APP
            Button {
                dashboardSection = .overview
                dismissMenu()
            } label: {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                dashboardSection = .liveFeed
                dismissMenu()
            } label: {
                Label("Livefeed", systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                dashboardSection = .controls
                dismissMenu()
            } label: {
                Label("Eventsteuerung", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                dashboardSection = .participants
                dismissMenu()
            } label: {
                Label("Teilnehmer", systemImage: "person.3.fill")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
                dashboardSection = .system
                dismissMenu()
            } label: {
                Label("System & Reset", systemImage: "gearshape.2.fill")
            }
            .buttonStyle(SidebarButtonStyle())
#endif

            Button {
#if ADMIN_APP
                dashboardSection = .actions
                dismissMenu()
#else
                showActions = true
#endif
            } label: {
                Label("Alle Aktionen", systemImage: "paperplane.fill")
            }
            .buttonStyle(SidebarButtonStyle())

            Button {
#if ADMIN_APP
                dashboardSection = .matches
                dismissMenu()
#else
                showMatches = true
#endif
            } label: {
                Label("Alle Matches", systemImage: "sparkles")
            }
            .buttonStyle(SidebarButtonStyle())

#if !ADMIN_APP
            Button {
                showBillboard = true
            } label: {
                Label("Billboard Vollbild", systemImage: "rectangle.inset.filled")
            }
            .buttonStyle(SidebarButtonStyle())
#endif

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
                HStack(spacing: 12) {
                    Image("hot-chili")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isCompact ? 82 : 96, height: isCompact ? 56 : 66)
                        .accessibilityLabel("Hot Chili Events")

                    Image("ficken-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isCompact ? 94 : 104, height: isCompact ? 48 : 54)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("FICKEN Likör")
                }
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
