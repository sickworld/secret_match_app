import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject var api: APIService

    @State private var showBillboard = false
    @State private var showAdminMenu = false
    @State private var showNumberLookup = false
    @State private var dashboardSection: AdminDashboardSection = .overview

    var body: some View {
        content(isCompact: usesCompactNavigation)
        .fullScreenCover(isPresented: $showBillboard) {
            AdminBillboardView(isPresented: $showBillboard)
                .environmentObject(api)
        }
        .sheet(isPresented: $showAdminMenu) {
            ScrollView {
                sidebar(isCompact: true)
            }
            .background(SecretMatchTheme.surface)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNumberLookup) {
            AdminNumberLookupView()
                .environmentObject(api)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: dashboardSection) { _, _ in
            showAdminMenu = false
        }
        .task {
            await AdminPushNotifications.requestAuthorizationAndRegister()
        }
        .preference(
            key: SecretMatchAccessibilityControlsHiddenPreferenceKey.self,
            value: true
        )
        .buttonBorderShape(.roundedRectangle(radius: SecretMatchTheme.cornerRadius))
        .tint(SecretMatchTheme.primary)
    }

    private func content(isCompact: Bool) -> some View {
        ZStack {
            BrandBackground()

            mainLayout(isCompact: isCompact)
        }
    }

    @ViewBuilder
    private func mainLayout(isCompact: Bool) -> some View {
        if isCompact {
            VStack(spacing: 0) {
                adminToolbar(showsMenu: true)

                adminPage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            VStack(spacing: 0) {
                adminToolbar(showsMenu: false)

                adminPage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var adminPage: some View {
        switch dashboardSection {
        case .readiness:
            AdminEventCheckView()
                .environmentObject(api)
        case .diagnostics:
            AdminDeliveryDiagnosticsView()
                .environmentObject(api)
        case .liveFeed:
            AdminLiveFeedView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        case .announcements:
            AdminEventAnnouncementsView()
                .environmentObject(api)
        case .eventLog:
            AdminEventLogView()
                .environmentObject(api)
        case .statistics:
            AdminStatisticsView()
                .environmentObject(api)
        case .actions:
            AdminActionListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        case .requests:
            AdminMatchRequestListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        case .matches:
            AdminMatchListView(isPresented: .constant(true), isEmbedded: true)
                .environmentObject(api)
        case .feedback:
            AdminFeedbackView()
                .environmentObject(api)
        default:
            AdminDashboardView(
                showBillboard: $showBillboard,
                selectedSection: $dashboardSection,
                showsFeatureOverview: !usesCompactNavigation
            )
                .environment(\.adminDashboardSection, dashboardSection)
                .environmentObject(api)
        }
    }

    private func adminToolbar(showsMenu: Bool) -> some View {
        HStack(spacing: 14) {
            if showsMenu {
                Button {
                    showAdminMenu = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
                }
                .accessibilityLabel("Admin-Menü öffnen")
            } else if dashboardSection != .overview {
                Button {
                    dashboardSection = .overview
                } label: {
                    Label("Aktionen", systemImage: "chevron.left")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(SecretMatchTheme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
                }
                .accessibilityHint("Kehrt zur Übersicht der Admin-Aktionen zurück")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("MATCH&PLAY")
                    .font(.caption2.bold())
                    .tracking(1.5)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text(toolbarTitle(showsMenu: showsMenu))
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                showNumberLookup = true
            } label: {
                ViewThatFits(in: .horizontal) {
                    Label("Nummer suchen", systemImage: "magnifyingglass")
                    Image(systemName: "magnifyingglass")
                }
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .frame(minWidth: 48, minHeight: 48)
                .background(SecretMatchTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
            }
            .accessibilityLabel("Nummer suchen")
            .accessibilityHint("Öffnet die globale Suche nach einer Eventnummer")

            if !showsMenu {
                Button {
                    api.logout()
                } label: {
                    Label("Admin Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline.bold())
                        .foregroundStyle(SecretMatchTheme.danger)
                        .padding(.horizontal, 15)
                        .frame(height: 48)
                        .background(SecretMatchTheme.danger.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius, style: .continuous)
                                .stroke(SecretMatchTheme.danger.opacity(0.6), lineWidth: 1)
                        )
                }
                .accessibilityHint("Beendet die Admin-Sitzung und kehrt zum Teilnehmer-Login zurück")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(SecretMatchTheme.surface.opacity(0.97))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SecretMatchTheme.border)
                .frame(height: 1)
        }
    }

    private func sidebar(isCompact: Bool) -> some View {
        AdminSidebarView(
            showBillboard: $showBillboard,
            dashboardSection: $dashboardSection,
            dismissMenu: { showAdminMenu = false },
            logout: { api.logout() },
            isCompact: isCompact
        )
        .environmentObject(api)
    }

    private var usesCompactNavigation: Bool {
#if ADMIN_APP
        true
#else
        false
#endif
    }

    private func toolbarTitle(showsMenu: Bool) -> String {
        showsMenu && dashboardSection == .overview ? "Dashboard" : dashboardSection.title
    }

}
