import SwiftUI

struct AdminActionListView: View {
    @EnvironmentObject var api: APIService
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var selectedType = "all"
    @State private var pendingDelete: AdminAction?
    @State private var loadErrorMessage: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("EVENT CONTROL · \(filteredActions.count) EINTRÄGE")
                            .font(.caption.bold())
                            .tracking(1.8)
                            .foregroundStyle(SecretMatchTheme.secondary)
                        Text("Aktionen verwalten")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.bold())
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.white)
                            .background(SecretMatchTheme.surfaceRaised)
                            .clipShape(Circle())
                    }
                }

                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(SecretMatchTheme.muted)
                        TextField("Sender- oder Zielnummer suchen", text: $searchText)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 54)
                    .background(Color.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Picker("Typ", selection: $selectedType) {
                        Text("Alle").tag("all")
                        Text("❤️ Hot").tag("normal")
                        Text("🍆 Fuck").tag("hot")
                        Text("👄 Blow").tag("bjob")
                        Text("✋ Hand").tag("hjob")
                        Text("👅 Lick").tag("ljob")
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .frame(minWidth: 150, minHeight: 54)
                    .background(SecretMatchTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if let loadErrorMessage {
                    loadErrorState(message: loadErrorMessage)
                } else if filteredActions.isEmpty {
                    ContentUnavailableView("Keine Aktionen", systemImage: "paperplane",
                                           description: Text("Suche oder Filter anpassen."))
                        .foregroundStyle(.white)
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: 14)], spacing: 14) {
                            ForEach(filteredActions) { action in
                                actionRow(action)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .refreshable { await loadActions() }
                }
            }
            .frame(maxWidth: 1040, maxHeight: 780)
            .secretCard(cornerRadius: 26, padding: 26)
            .padding(24)
        }
        .task {
            await loadActions()
        }
        .alert("Aktion löschen?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                guard let action = pendingDelete else { return }
                pendingDelete = nil
                Task { try? await api.deleteAdminAction(id: action.id) }
            }
        } message: {
            Text("Dieser Eintrag wird dauerhaft entfernt.")
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
            try await api.loadAdminActions()
        } catch {
            loadErrorMessage = "Bitte Admin-Anmeldung und Netzwerkverbindung prüfen."
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

                Text(action.created_at)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer()

            Button(role: .destructive) {
                pendingDelete = action
            } label: {
                Image(systemName: "trash")
                    .font(.title3.bold())
                    .foregroundStyle(.red)
                    .padding(10)
            }
        }
        .padding()
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    private var filteredActions: [AdminAction] {
        api.adminActions.filter { action in
            let matchesType = selectedType == "all" || action.action_type == selectedType
            let matchesSearch = searchText.isEmpty
                || action.sender_number.localizedCaseInsensitiveContains(searchText)
                || action.receiver_number.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
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
