import SwiftUI

struct ActionListView: View {
    @EnvironmentObject var api: APIService
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDirection = "all"
    @State private var loadErrorMessage: String?

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
                .onTapGesture { isPresented = false }

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DEINE ACTIVITY · \(filteredActions.count)")
                            .font(.caption.bold())
                            .tracking(1.8)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text("Aktionen")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Alles, was du gesendet und erhalten hast.")
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                    Spacer()
                    closeButton
                }

                HStack(spacing: 10) {
                    actionFilterButton("Alle \(api.actions.count)", direction: "all", color: SecretMatchTheme.secondary)
                    actionFilterButton("Erhalten \(receivedCount)", direction: "received", color: SecretMatchTheme.primary)
                    actionFilterButton("Gesendet \(sentCount)", direction: "sent", color: Color(hex: "#3E9ED6"))
                }

                if let loadErrorMessage {
                    loadErrorState(message: loadErrorMessage)
                } else if filteredActions.isEmpty {
                    ContentUnavailableView(
                        selectedDirection == "all" ? "Noch keine Aktionen" : "Hier ist noch nichts",
                        systemImage: "paperplane",
                        description: Text("Neue Aktionen erscheinen automatisch in dieser Übersicht.")
                    )
                    .foregroundStyle(.white)
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 14)], spacing: 14) {
                            ForEach(filteredActions) { action in
                                actionRow(action)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .refreshable { await loadActions() }
                }
            }
            .frame(maxWidth: 980, maxHeight: 760)
            .secretCard(cornerRadius: 26, padding: 28)
            .padding(24)
        }
        .task(id: isPresented) {
            guard isPresented else { return }

            await loadActions()
        }
    }

    private var closeButton: some View {
        Button {
            isPresented = false
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(Circle())
        }
    }

    private func loadErrorState(message: String) -> some View {
        ContentUnavailableView {
            Label("Aktionen konnten nicht geladen werden", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Erneut versuchen") {
                Task { await loadActions() }
            }
            .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
        }
        .foregroundStyle(.white)
        .frame(maxHeight: .infinity)
    }

    @MainActor
    private func loadActions() async {
        loadErrorMessage = nil
        do {
            api.actions = try await api.loadActions()
        } catch {
            loadErrorMessage = "Bitte prüfe die Netzwerkverbindung und versuche es erneut."
        }
    }

    private var filteredActions: [SecretAction] {
        api.actions.filter { action in
            switch selectedDirection {
            case "received": return action.sender_number != api.number
            case "sent": return action.sender_number == api.number
            default: return true
            }
        }
    }

    private var receivedCount: Int {
        api.actions.filter { $0.sender_number != api.number }.count
    }

    private var sentCount: Int {
        api.actions.filter { $0.sender_number == api.number }.count
    }

    private func actionFilterButton(_ title: String, direction: String, color: Color) -> some View {
        let isSelected = selectedDirection == direction

        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedDirection = direction
            }
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(isSelected ? color.opacity(0.9) : color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(isSelected ? 1 : 0.55), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? color.opacity(0.28) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Einzelne Action-Zeile

    @ViewBuilder
    private func actionRow(_ action: SecretAction) -> some View {
        let color = actionColor(for: action.action_type)

        HStack(spacing: 18) {
            Text(actionEmoji(for: action.action_type))
                .font(.system(size: 34))
                .frame(width: 62, height: 62)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(actionLabel(for: action.action_type))
                    .foregroundStyle(.white)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Text(action.sender_number == api.number ? "Gesendet an" : "Erhalten von")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SecretMatchTheme.muted)

                Text(displayDate(action.created_at))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
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

    private func displayDate(_ value: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = input.date(from: value) else { return value }
        let output = DateFormatter()
        output.locale = Locale(identifier: "de_DE")
        output.dateFormat = "dd.MM. · HH:mm"
        return output.string(from: date)
    }
}
