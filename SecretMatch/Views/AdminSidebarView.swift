import SwiftUI

struct AdminSidebarView: View {
    @EnvironmentObject var api: APIService

    @Binding var showActions: Bool
    @Binding var showMatches: Bool
    var logout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 170)

            Text("Admin Mode")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Divider().background(Color.white.opacity(0.3))

            Button("Alle Aktionen") {
                showActions = true
            }
            .buttonStyle(SidebarButtonStyle())

            Button("Alle Matches") {
                showMatches = true
            }
            .buttonStyle(SidebarButtonStyle())

            Divider().background(Color.white.opacity(0.3))

            Button("Admin Logout") {
                logout()
            }
            .buttonStyle(SidebarButtonStyle())

            Spacer()
        }
        .padding()
        .frame(width: 240)
        .background(Color.black.opacity(0.7))
    }
}
