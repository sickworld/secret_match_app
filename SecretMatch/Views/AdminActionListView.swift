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
                Text("EVENT CONTROL")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Alle Aktionen")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if api.adminActions.isEmpty {
                    Text("Keine Aktionen vorhanden")
                        .foregroundStyle(SecretMatchTheme.muted)
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
                .buttonStyle(SecretPrimaryButtonStyle())
            }
            .frame(maxWidth: 520)
            .secretCard(cornerRadius: 24, padding: 28)
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
            Image(systemName: icon(for: action.action_type))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SecretMatchTheme.primary)
                .frame(width: 44, height: 44)
                .background(SecretMatchTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(prettyAction(action.action_type))
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Von \(action.sender_number) → \(action.receiver_number)")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
    }

    // MARK: - Icon je Action

    private func icon(for type: String) -> String {
        switch type {
        case "bjob": return "mouth.fill"
        case "hjob": return "hand.raised.fill"
        case "ljob": return "sparkles"
        default:     return "paperplane.fill"
        }
    }
    
    func prettyAction(_ type: String) -> String {
        switch type {
        case "bjob": return "Blowjob"
        case "hjob": return "Handjob"
        case "ljob": return "Lickjob"
        default:     return type.capitalized
        }
    }
}
