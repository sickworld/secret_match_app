import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var api: APIService
    var secondsRemaining: Int
    var pauseInactivity: () -> Void
    var logout: () -> Void
    var showMatches: () -> Void
    var showActions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 170)

            Text("Deine Nummer:")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))

            Text(api.number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Button("Deine Matches") {
                pauseInactivity()
                showMatches()
            }
            .buttonStyle(SidebarButtonStyle())
            
            Button("Deine Aktionen") {
                pauseInactivity()
                showActions()
            }
            .buttonStyle(SidebarButtonStyle())

            Button("Spielregeln") {
                pauseInactivity()
            }
            .buttonStyle(SidebarButtonStyle())

            Button("Logout") {
                logout()
            }
            .buttonStyle(SidebarButtonStyle())

            Text("⏳ Auto-Logout in \(secondsRemaining)s")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))

            Spacer()
        }
        .padding()
        .frame(width: 240)
        .background(Color.black.opacity(0.6))
    }
}
