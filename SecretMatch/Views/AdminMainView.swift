import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject var api: APIService

    @State private var showAdminActions = false
    @State private var showAdminMatches = false
    @State private var showBillboard = false
    @State private var showAdminMenu = false
    @State private var showLiveFeed = false
    @State private var dashboardSection: AdminDashboardSection = .overview

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < proxy.size.height

            content(isCompact: isCompact)
        }
        .fullScreenCover(isPresented: $showBillboard) {
            AdminBillboardView(isPresented: $showBillboard)
                .environmentObject(api)
        }
#if ADMIN_APP
        .sheet(isPresented: $showAdminMenu) {
            ScrollView {
                sidebar(isCompact: true)
            }
            .background(SecretMatchTheme.surface)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showAdminActions) { _, isShown in
            if isShown { showAdminMenu = false }
        }
        .onChange(of: showAdminMatches) { _, isShown in
            if isShown { showAdminMenu = false }
        }
        .onChange(of: showLiveFeed) { _, isShown in
            if isShown { showAdminMenu = false }
        }
        .onChange(of: dashboardSection) { _, _ in
            showAdminMenu = false
        }
        .onChange(of: showBillboard) { _, isShown in
            if isShown { showAdminMenu = false }
        }
#endif
    }

    private func content(isCompact: Bool) -> some View {
        ZStack {
            BrandBackground()

            mainLayout(isCompact: isCompact)
            
            if showAdminActions {
                AdminActionListView(isPresented: $showAdminActions)
                    .environmentObject(api)
            }

            if showAdminMatches {
                AdminMatchListView(isPresented: $showAdminMatches)
                    .environmentObject(api)
            }

#if ADMIN_APP
            if showLiveFeed {
                AdminLiveFeedView(isPresented: $showLiveFeed)
                    .environmentObject(api)
            }
#endif
        }
    }

    @ViewBuilder
    private func mainLayout(isCompact: Bool) -> some View {
#if ADMIN_APP
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button {
                    showAdminMenu = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityLabel("Admin-Menü öffnen")

                VStack(alignment: .leading, spacing: 2) {
                    Text("SECRET MATCH")
                        .font(.caption2.bold())
                        .tracking(1.5)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text("Event Control")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(SecretMatchTheme.surface.opacity(0.97))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SecretMatchTheme.border)
                    .frame(height: 1)
            }

            AdminDashboardView(showBillboard: $showBillboard)
                .environment(\.adminDashboardSection, dashboardSection)
                .environmentObject(api)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
#else
        if isCompact {
            ScrollView {
                VStack(spacing: 0) {
                    sidebar(isCompact: true)
                    AdminDashboardView(showBillboard: $showBillboard)
                        .environmentObject(api)
                }
            }
        } else {
            HStack(spacing: 0) {
                sidebar(isCompact: false)

                Divider().background(Color.white.opacity(0.3))

                AdminDashboardView(showBillboard: $showBillboard)
                    .environmentObject(api)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
#endif
    }

    private func sidebar(isCompact: Bool) -> some View {
        AdminSidebarView(
            showActions: $showAdminActions,
            showMatches: $showAdminMatches,
            showBillboard: $showBillboard,
            showLiveFeed: $showLiveFeed,
            dashboardSection: $dashboardSection,
            dismissMenu: { showAdminMenu = false },
            logout: { api.logout() },
            isCompact: isCompact
        )
        .environmentObject(api)
    }

}
