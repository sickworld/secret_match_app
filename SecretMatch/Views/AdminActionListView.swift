import SwiftUI

struct AdminActionListView: View {
    @EnvironmentObject var api: APIService
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 20) {
                Text("Alle Aktionen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if api.adminActions.isEmpty {
                    Text("Keine Aktionen vorhanden")
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(api.adminActions) { action in
                                actionRow(action)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button("Schließen") {
                    isPresented = false
                }
                .buttonStyle(SidebarButtonStyle())
            }
            .padding()
            .frame(maxWidth: 520)
            .background(Color(hex: "#35070D").opacity(0.96))
            .cornerRadius(24)
        }
        .task {
            await api.loadAdminActions()
        }
    }

    // MARK: - Einzelne Action-Zeile

    @ViewBuilder
    private func actionRow(_ action: AdminAction) -> some View {
        HStack(alignment: .top, spacing: 14) {

            // kleines Icon links
            Text(icon(for: action.action_type))
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 6) {
                Text(prettyAction(action.action_type))
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Von \(action.sender_number) → \(action.receiver_number)")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(14)
    }

    // MARK: - Icon je Action

    private func icon(for type: String) -> String {
        switch type {
        case "bjob": return "💋"
        case "hjob": return "✋"
        case "ljob": return "👅"
        default:     return "✨"
        }
    }
    
    func prettyAction(_ type: String) -> String {
        switch type {
        case "bjob": return "Blowjob 💋"
        case "hjob": return "Handjob ✋"
        case "ljob": return "Lickjob 👅"
        default:     return type.capitalized
        }
    }
}
