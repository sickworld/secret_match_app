import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject var api: APIService

    @State private var showAdminActions = false
    @State private var showAdminMatches = false

    var body: some View {
        ZStack {
            BrandBackground()

            HStack(spacing: 0) {
                AdminSidebarView(
                    showActions: $showAdminActions,
                    showMatches: $showAdminMatches,
                    logout: { api.logout() }
                )
                .environmentObject(api)

                Divider().background(Color.white.opacity(0.3))

                VStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(SecretMatchTheme.primary)
                    Text("SecretMatch Event Control")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Wähle links Aktionen oder Matches aus.")
                        .foregroundStyle(SecretMatchTheme.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
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
}
