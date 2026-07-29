import SwiftUI

struct ActionListView: View {
    @EnvironmentObject var api: APIService
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    var groupedActions: [String: [SecretAction]] {
        Dictionary(
            grouping: api.actions,
            by: { $0.sender_number == api.number ? "Gesendet" : "Erhalten" }
        )
    }

    var body: some View {
        ZStack {
            // Hintergrund
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("ACTIVITY")
                    .font(.caption2.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)

                Text("Deine Aktionen")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if api.actions.isEmpty {
                    Text("Noch keine Aktionen")
                        .foregroundStyle(SecretMatchTheme.muted)
                        .padding(.top, 30)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(groupedActions.keys.sorted(), id: \.self) { key in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(key)
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                        .padding(.leading, 4)

                                    ForEach(groupedActions[key] ?? [], id: \.id) { action in
                                        actionRow(action)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }

                Button("Schließen") {
                    isPresented = false
                    dismiss()
                }
                .buttonStyle(SecretPrimaryButtonStyle())
                .padding(.top, 20)
            }
            .frame(maxWidth: 720, maxHeight: 680)
            .secretCard(cornerRadius: 24, padding: 32)
            .padding(28)
        }
        .task(id: isPresented) {
            guard isPresented else { return }

            do {
                print("🚀 loadActions triggered")
                api.actions = try await api.loadActions()
            } catch {
                print("❌ Fehler beim Laden der Aktionen:", error.localizedDescription)
                api.actions = []
            }
        }
    }

    // MARK: - Einzelne Action-Zeile

    @ViewBuilder
    private func actionRow(_ action: SecretAction) -> some View {
        let color = actionColor(for: action.action_type)

        HStack(spacing: 18) {
            actionIcon(for: action.action_type)
                .font(.system(size: 27, weight: .bold))
                .frame(width: 54, height: 54)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(actionLabel(for: action.action_type))
                    .foregroundStyle(.white)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text(action.sender_number == api.number ? "Gesendet an" : "Erhalten von")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            Spacer()

            Text("#\(partner(for: action))")
                .foregroundStyle(.white)
                .font(.system(size: 19, weight: .bold, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.24))
                .clipShape(Capsule())
        }
        .padding(18)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    // MARK: - Helpers

    private func actionLabel(for type: String) -> String {
        switch type {
        case "normal": return "Hot Match"
        case "hot": return "Fuck Match"
        case "bjob": return "Blow-Job"
        case "hjob": return "Hand-Job"
        case "ljob": return "Lick-Job"
        default: return type.capitalized
        }
    }

    @ViewBuilder
    private func actionIcon(for type: String) -> some View {
        if type == "hot" {
            Text("🍆")
        } else {
            Image(systemName: actionSymbol(for: type))
        }
    }

    private func actionSymbol(for type: String) -> String {
        switch type {
        case "normal": return "heart.fill"
        case "bjob": return "wind"
        case "hjob": return "hand.raised.fill"
        case "ljob": return "mouth.fill"
        default: return "paperplane.fill"
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

    private func partner(for action: SecretAction) -> String {
        action.sender_number == api.number
            ? action.receiver_number
            : action.sender_number
    }

    private func formattedDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return iso }

        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: date)
    }
}
