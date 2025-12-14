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
                Text("Deine Aktionen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if api.actions.isEmpty {
                    Text("Noch keine Aktionen 🎯")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 30)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(groupedActions.keys.sorted(), id: \.self) { key in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(key)
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(.leading)

                                    ForEach(groupedActions[key] ?? [], id: \.id) { action in
                                        actionRow(action)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Button("Schließen") {
                    isPresented = false
                    dismiss()
                }
                .buttonStyle(SidebarButtonStyle())
                .padding(.top, 20)
            }
            .padding()
            .frame(maxWidth: 400)
            .background(Color(hex: "#3c0d1f").opacity(0.92))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(actionLabel(for: action.action_type))
                    .foregroundColor(.white)
                    .fontWeight(.medium)

                Spacer()

                Text(partner(for: action))
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func actionLabel(for type: String) -> String {
        switch type {
        case "bjob": return "Blow-Job"
        case "hjob": return "Hand-Job"
        case "ljob": return "Lick-Job"
        default: return type.capitalized
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
