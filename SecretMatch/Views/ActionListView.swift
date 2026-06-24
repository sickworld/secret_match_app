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
                                        .font(.headline)
                                        .foregroundStyle(SecretMatchTheme.muted)
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
                .buttonStyle(SecretPrimaryButtonStyle())
                .padding(.top, 20)
            }
            .frame(maxWidth: 400)
            .secretCard(cornerRadius: 24, padding: 28)
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
                    .foregroundStyle(.white)
                    .fontWeight(.medium)

                Spacer()

                Text(partner(for: action))
                    .foregroundStyle(SecretMatchTheme.muted)
                    .font(.caption)
            }
        }
        .padding()
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SecretMatchTheme.border))
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
