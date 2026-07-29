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
        let color = actionColor(for: action.action_type)

        HStack(alignment: .top, spacing: 14) {
            Text(actionEmoji(for: action.action_type))
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(prettyAction(action.action_type))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Von \(action.sender_number) → \(action.receiver_number)")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    private func actionEmoji(for type: String) -> String {
        switch type {
        case "normal": return "❤️"
        case "hot": return "🍆"
        case "bjob": return "👄"
        case "hjob": return "✋"
        case "ljob": return "👅"
        default: return "💌"
        }
    }
    
    private func prettyAction(_ type: String) -> String {
        switch type {
        case "normal": return "Hot Match"
        case "hot": return "Fuck Match"
        case "bjob": return "Blow-Job"
        case "hjob": return "Hand-Job"
        case "ljob": return "Lick-Job"
        default: return type.capitalized
        }
    }

    private func actionColor(for type: String) -> Color {
        switch type {
        case "normal": return Color(hex: "#E83E8C")
        case "hot": return Color(hex: "#8E63D2")
        case "bjob": return Color(hex: "#3E9ED6")
        case "hjob": return Color(hex: "#E6923E")
        case "ljob": return Color(hex: "#D65C8D")
        default: return SecretMatchTheme.primary
        }
    }
}
