import SwiftUI

struct AdminMatchListView: View {
    @EnvironmentObject var api: APIService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var isPresented: Bool
    var isEmbedded = false
    @State private var searchText = ""
    @State private var selectedType = "all"
    @State private var pendingDelete: AdminMatch?
    @State private var loadErrorMessage: String?
    @State private var operationErrorMessage: String?
    @State private var editor: Editor?
    @State private var showMatchCatalog = false

    private enum Editor: Identifiable {
        case create
        case edit(AdminMatch)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let match): return "edit-\(match.id)"
            }
        }
    }

    var body: some View {
        ZStack {
            if !isEmbedded {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
            }

            VStack(spacing: 18) {
                header

                if let operationErrorMessage {
                    Label(operationErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(SecretMatchTheme.muted)
                        AdminKeyboardTextField(
                            title: "Teilnehmernummer suchen",
                            text: $searchText,
                            keyboard: .number(maxDigits: 10),
                            keyboardTitle: "Matches durchsuchen"
                        )
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 54)
                    .background(Color.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

                    Picker("Typ", selection: $selectedType) {
                        Text("Alle").tag("all")
                        ForEach(api.matchDefinitions) { definition in
                            Text(definition.displayTitle).tag(definition.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .frame(maxWidth: 330)
                }

                if let loadErrorMessage {
                    loadErrorState(message: loadErrorMessage)
                } else if filteredMatches.isEmpty {
                    ContentUnavailableView("Keine Matches", systemImage: "heart.slash",
                                           description: Text("Suche oder Filter anpassen."))
                        .foregroundStyle(.white)
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 360), spacing: 14)], spacing: 14) {
                            ForEach(filteredMatches) { match in
                                matchRow(match)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .refreshable { await loadMatches() }
                }
            }
            .frame(maxWidth: 1040, maxHeight: isEmbedded ? .infinity : 780)
            .secretCard(padding: 26)
            .padding(24)
        }
        .task {
            await loadMatches()
        }
        .alert("Match löschen?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                guard let match = pendingDelete else { return }
                pendingDelete = nil
                Task { await delete(match) }
            }
        } message: {
            Text("Dieser Match-Eintrag wird dauerhaft entfernt.")
        }
        .sheet(item: $editor) { editor in
            matchEditor(editor)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showMatchCatalog) {
            AdminMatchCatalogView(isPresented: $showMatchCatalog)
                .environmentObject(api)
        }
    }

    @ViewBuilder
    private var header: some View {
        if usesCompactHeader {
            VStack(alignment: .leading, spacing: 12) {
                headerTitle
                HStack(spacing: 10) { catalogButton; createButton; Spacer(minLength: 0); closeButton }
            }
        } else {
            HStack(alignment: .top, spacing: 12) { headerTitle; Spacer(); catalogButton; createButton; closeButton }
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("EVENT CONTROL · \(filteredMatches.count) EINTRÄGE").font(.caption.bold()).tracking(1.8).foregroundStyle(SecretMatchTheme.secondary)
            Text("Matches verwalten").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(.white)
        }
    }

    private var catalogButton: some View {
        Button { showMatchCatalog = true } label: { Label("Match-Typen", systemImage: "slider.horizontal.3") }
            .buttonStyle(SecretSecondaryButtonStyle())
    }

    private var createButton: some View {
        Button { editor = .create } label: { Label("Match anlegen", systemImage: "plus") }
            .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
    }

    @ViewBuilder private var closeButton: some View {
        if !isEmbedded {
            Button { isPresented = false } label: {
                Image(systemName: "xmark").font(.title3.bold()).frame(width: 50, height: 50).foregroundStyle(.white).background(SecretMatchTheme.surfaceRaised).clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
            }
        }
    }

    private var usesCompactHeader: Bool {
#if ADMIN_APP
        true
#else
        horizontalSizeClass == .compact
#endif
    }

    private func loadErrorState(message: String) -> some View {
        ContentUnavailableView {
            Label("Matches konnten nicht geladen werden", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Erneut versuchen") {
                Task { await loadMatches() }
            }
            .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
        }
        .foregroundStyle(.white)
        .frame(maxHeight: .infinity)
    }

    @MainActor
    private func loadMatches() async {
        loadErrorMessage = nil
        do {
            try await api.loadAdminMatchDefinitions()
            try await api.loadAdminMatches()
        } catch {
            loadErrorMessage = "Bitte Admin-Anmeldung und Netzwerkverbindung prüfen."
        }
    }

    // MARK: - Einzelnes Match

    @ViewBuilder
    private func matchRow(_ match: AdminMatch) -> some View {
        let color = matchColor(for: match.type)

        HStack(alignment: .top, spacing: 14) {
            Text(matchEmoji(for: match.type))
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

            VStack(alignment: .leading, spacing: 6) {
                Text(prettyMatchType(match.type))
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(match.number_a.displayEventNumber) ↔ \(match.number_b.displayEventNumber)")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }

            Spacer()

            Button {
                editor = .edit(match)
            } label: {
                Image(systemName: "pencil")
                    .font(.title3.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
                    .padding(10)
            }

            Button(role: .destructive) {
                pendingDelete = match
            } label: {
                Image(systemName: "trash")
                    .font(.title3.bold())
                    .foregroundStyle(.red)
                    .padding(10)
            }
        }
        .padding()
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    private var filteredMatches: [AdminMatch] {
        api.adminMatches.filter { match in
            let normalizedType = (match.type == "F-") ? "hot" : match.type
            let matchesType = selectedType == "all" || normalizedType == selectedType
            let matchesSearch = searchText.isEmpty
                || match.number_a.localizedCaseInsensitiveContains(searchText)
                || match.number_b.localizedCaseInsensitiveContains(searchText)
                || match.number_a.displayEventNumber.localizedCaseInsensitiveContains(searchText)
                || match.number_b.displayEventNumber.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }

    // MARK: - Mapping

    private func prettyMatchType(_ type: String) -> String {
        matchDefinition(type).name
    }

    private func matchEmoji(for type: String) -> String {
        matchDefinition(type).emoji
    }

    private func matchColor(for type: String) -> Color {
        Color(hex: matchDefinition(type).color)
    }

    private func matchDefinition(_ type: String) -> MatchDefinition {
        let id = MatchDefinition.normalizedID(type)
        return api.matchDefinitions.first(where: { $0.id == id }) ?? .fallback(for: id)
    }

    @ViewBuilder
    private func matchEditor(_ editor: Editor) -> some View {
        switch editor {
        case .create:
            AdminRecordEditorView(
                title: "Match anlegen",
                firstNumberLabel: "Erste Nummer",
                secondNumberLabel: "Zweite Nummer",
                typeOptions: matchTypeOptions
            ) { numberA, numberB, type in
                try await api.createAdminMatch(numberA: numberA, numberB: numberB, type: type)
            }
        case .edit(let match):
            AdminRecordEditorView(
                title: "Match bearbeiten",
                firstNumberLabel: "Erste Nummer",
                secondNumberLabel: "Zweite Nummer",
                typeOptions: matchTypeOptions,
                initialFirstNumber: match.number_a,
                initialSecondNumber: match.number_b,
                initialType: match.type == "F-" ? "hot" : match.type
            ) { numberA, numberB, type in
                try await api.updateAdminMatch(id: match.id, numberA: numberA, numberB: numberB, type: type)
            }
        }
    }

    private var matchTypeOptions: [AdminRecordTypeOption] {
        api.matchDefinitions.map { .init(value: $0.id, title: $0.displayTitle + ($0.enabled ? "" : " · ausgeblendet")) }
    }

    @MainActor
    private func delete(_ match: AdminMatch) async {
        operationErrorMessage = nil
        do {
            try await api.deleteAdminMatch(id: match.id)
        } catch {
            operationErrorMessage = "Match konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }
}
