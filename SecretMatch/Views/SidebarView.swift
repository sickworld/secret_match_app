import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var api: APIService
    var secondsRemaining: Int
    var pauseInactivity: () -> Void
    var logout: () -> Void
    @Binding var showMatchesOverlay: Bool
    @Binding var showActionsOverlay: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image("hot-chili")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Secret Match")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Navigation")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.55))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Deine Nummer")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Text(api.number)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
            }

            Button("Deine Matches") {
                pauseInactivity()
                showMatchesOverlay = true
            }
            .buttonStyle(SidebarButtonStyle())
            
            Button("Deine Aktionen") {
                pauseInactivity()
                showActionsOverlay = true
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
