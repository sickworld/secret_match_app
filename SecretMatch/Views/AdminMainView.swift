import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject var api: APIService

    @State private var showAdminActions = false
    @State private var showAdminMatches = false

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < proxy.size.height

            content(isCompact: isCompact)
        }
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
        }
    }

    @ViewBuilder
    private func mainLayout(isCompact: Bool) -> some View {
        if isCompact {
            ScrollView {
                VStack(spacing: 0) {
                    sidebar(isCompact: true)
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 56)
                        .padding(.horizontal, 18)
                }
            }
        } else {
            HStack(spacing: 0) {
                sidebar(isCompact: false)

                Divider().background(Color.white.opacity(0.3))

                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func sidebar(isCompact: Bool) -> some View {
        AdminSidebarView(
            showActions: $showAdminActions,
            showMatches: $showAdminMatches,
            logout: { api.logout() },
            isCompact: isCompact
        )
        .environmentObject(api)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(SecretMatchTheme.primary)
            Text("SecretMatch Event Control")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("Wähle Aktionen oder Matches aus.")
                .foregroundStyle(SecretMatchTheme.muted)
                .multilineTextAlignment(.center)
        }
    }
}
