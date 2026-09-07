import SwiftUI

struct ActionListView: View {
    @EnvironmentObject var api: APIService
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType = "all"
    @State private var senderQuery = ""
    @State private var loadErrorMessage: String?

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
                        Text("Nur Aktionen, die du erhalten hast – nach Kategorie und Nummer filterbar.")
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                    Spacer()
                    closeButton
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        actionFilterButton("Alle", type: "all", color: SecretMatchTheme.secondary)
                        actionFilterButton("❤️ Hot", type: "normal", color: Color(hex: "#E83E8C"))
                        actionFilterButton("🍆 Fuck", type: "hot", color: Color(hex: "#8E63D2"))
                        actionFilterButton("👄 Blow", type: "bjob", color: Color(hex: "#3E9ED6"))
                        actionFilterButton("✋ Hand", type: "hjob", color: Color(hex: "#E6923E"))
                        actionFilterButton("👅 Lick", type: "ljob", color: Color(hex: "#D65C8D"))
                    }
                }

                TextField("Absender-Nummer filtern", text: $senderQuery)
                    .keyboardType(.numberPad)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(SecretMatchTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                if let loadErrorMessage {
                    loadErrorState(message: loadErrorMessage)
                } else if filteredActions.isEmpty {
                    ContentUnavailableView(
                        "Keine erhaltenen Aktionen",
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
            action.receiver_number.normalizedEventNumber == api.number.normalizedEventNumber
                && (selectedType == "all" || action.action_type == selectedType)
                && (senderQuery.isEmpty || action.sender_number.contains(senderQuery))
        }
    }

    private func actionFilterButton(_ title: String, type: String, color: Color) -> some View {
        let isSelected = selectedType == type

        return Button {
            withAnimation(.easeOut(duration: 0.18)) {
                selectedType = type
            }
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 130, minHeight: 64)
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

            Text(actionLabel(for: action.action_type))
                .foregroundStyle(.white)
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Spacer()

            Text(action.sender_number.displayEventNumber)
                .foregroundStyle(.white)
                .font(.system(size: 40, weight: .heavy, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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

}
