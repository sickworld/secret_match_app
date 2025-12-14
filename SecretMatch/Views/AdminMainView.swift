import SwiftUI

struct AdminMainView: View {
    @EnvironmentObject var api: APIService

    @State private var showAdminActions = false
    @State private var showAdminMatches = false

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            HStack(spacing: 0) {
                AdminSidebarView(
                    showActions: $showAdminActions,
                    showMatches: $showAdminMatches,
                    logout: { api.logout() }
                )
                .environmentObject(api)

                Divider().background(Color.white.opacity(0.3))
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
