import SwiftUI

struct AdminActionListView: View {
    @EnvironmentObject var api: APIService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var isPresented: Bool
    var isEmbedded = false
    @State private var searchText = ""
    @State private var selectedType = "all"
    @State private var pendingDelete: AdminAction?
    @State private var loadErrorMessage: String?
    @State private var operationErrorMessage: String?
    @State private var editor: Editor?
    @State private var showActionCatalog = false

    private enum Editor: Identifiable {
        case create
        case edit(AdminAction)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let action): return "edit-\(action.id)"
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

            VStack(spacing: usesCompactLayout ? 14 : 18) {
                header

                if let operationErrorMessage {
                    Label(operationErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                filters

                if let loadErrorMessage {
                    loadErrorState(message: loadErrorMessage)
                } else if filteredActions.isEmpty {
                    ContentUnavailableView("Keine Aktionen", systemImage: "paperplane",
                                           description: Text("Suche oder Filter anpassen."))
                        .foregroundStyle(.white)
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: actionGridColumns, spacing: 14) {
                            ForEach(filteredActions) { action in
                                actionRow(action)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .refreshable { await loadActions() }
                }
            }
            .frame(maxWidth: 1040, maxHeight: isEmbedded ? .infinity : 780)
            .secretCard(padding: usesCompactLayout ? 14 : 26)
            .padding(usesCompactLayout ? 10 : 24)
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
                Task { await delete(action) }
            }
        } message: {
            Text("Dieser Eintrag wird dauerhaft entfernt.")
        }
        .sheet(item: $editor) { editor in
            actionEditor(editor)
                .presentationDetents(editorPresentationDetents)
        }
        .sheet(isPresented: $showActionCatalog) {
            AdminActionCatalogView(isPresented: $showActionCatalog)
                .environmentObject(api)
                .presentationDetents([.large])
        }
    }

    private var editorPresentationDetents: Set<PresentationDetent> {
#if ADMIN_APP
        [.medium, .large]
#else
        [.fraction(0.72), .large]
#endif
    }

    private var usesCompactLayout: Bool {
#if ADMIN_APP
        true
#else
        horizontalSizeClass == .compact
#endif
    }

    private var actionGridColumns: [GridItem] {
        usesCompactLayout
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 360), spacing: 14)]
    }

    @ViewBuilder
    private var header: some View {
        if usesCompactLayout {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    titleBlock
                    Spacer(minLength: 0)
                    closeButton
                }

                HStack(spacing: 10) {
                    catalogButton
                    createButton
                }
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                titleBlock
                Spacer()
                catalogButton
                createButton
                closeButton
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("EVENT CONTROL · \(filteredActions.count) EINTRÄGE")
                .font(.caption.bold())
                .tracking(usesCompactLayout ? 1.2 : 1.8)
                .foregroundStyle(SecretMatchTheme.secondary)
            Text("Aktionen verwalten")
                .font(.system(size: usesCompactLayout ? 27 : 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var catalogButton: some View {
        Button {
            showActionCatalog = true
        } label: {
            Label("Aktionsarten", systemImage: "slider.horizontal.3")
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .buttonStyle(SecretSecondaryButtonStyle())
        .frame(width: usesCompactLayout ? nil : 170)
        .frame(maxWidth: usesCompactLayout ? .infinity : nil)
    }

    private var createButton: some View {
        Button {
            editor = .create
        } label: {
            Label(usesCompactLayout ? "Neue Aktion" : "Aktion anlegen", systemImage: "plus")
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .buttonStyle(SecretPrimaryButtonStyle(fullWidth: usesCompactLayout))
        .frame(maxWidth: usesCompactLayout ? .infinity : nil)
    }

    @ViewBuilder
    private var closeButton: some View {
        if !isEmbedded {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.bold())
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.white)
                    .background(SecretMatchTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
            }
            .accessibilityLabel("Aktionen schließen")
        }
    }

    @ViewBuilder
    private var filters: some View {
        if usesCompactLayout {
            VStack(spacing: 10) {
                searchField
                typePicker
            }
        } else {
            HStack(spacing: 12) {
                searchField
                typePicker
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SecretMatchTheme.muted)
            AdminKeyboardTextField(
                title: "Sender- oder Zielnummer suchen",
                text: $searchText,
                keyboard: .number(maxDigits: 10),
                keyboardTitle: "Aktionen durchsuchen"
            )
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
    }

    private var typePicker: some View {
        Picker("Typ", selection: $selectedType) {
            Text("Alle Aktionsarten").tag("all")
            ForEach(api.actionDefinitions) { definition in
                Text(definition.displayTitle).tag(definition.id)
            }
        }
        .pickerStyle(.menu)
        .tint(.white)
        .frame(maxWidth: usesCompactLayout ? .infinity : nil, minHeight: 52)
        .frame(minWidth: usesCompactLayout ? nil : 150)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
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
            try? await api.loadAdminActionDefinitions()
        } catch {
            loadErrorMessage = "Bitte Admin-Anmeldung und Netzwerkverbindung prüfen."
        }
    }

    // MARK: - Einzelne Action-Zeile

    @ViewBuilder
    private func actionRow(_ action: AdminAction) -> some View {
        let color = actionColor(for: action.action_type)

        Group {
            if usesCompactLayout {
                VStack(alignment: .leading, spacing: 12) {
                    actionSummary(action, color: color, compact: true)
                    Rectangle()
                        .fill(SecretMatchTheme.border.opacity(0.8))
                        .frame(height: 1)
                    HStack(spacing: 10) {
                        editButton(action, showsLabel: true)
                        deleteButton(action, showsLabel: true)
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 14) {
                    actionSummary(action, color: color, compact: false)
                    Spacer()
                    editButton(action, showsLabel: false)
                    deleteButton(action, showsLabel: false)
                }
            }
        }
        .padding(usesCompactLayout ? 14 : 16)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(color.opacity(0.65), lineWidth: 1.2))
    }

    private func actionSummary(_ action: AdminAction, color: Color, compact: Bool) -> some View {
        HStack(alignment: .top, spacing: compact ? 12 : 14) {
            Text(actionEmoji(for: action.action_type))
                .font(.system(size: compact ? 26 : 30))
                .frame(width: compact ? 46 : 54, height: compact ? 46 : 54)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

            VStack(alignment: .leading, spacing: 5) {
                Text(prettyAction(action.action_type))
                    .font(.system(size: compact ? 18 : 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Von \(action.sender_number.displayEventNumber) → \(action.receiver_number.displayEventNumber)")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
    }

    private func editButton(_ action: AdminAction, showsLabel: Bool) -> some View {
        Button {
            editor = .edit(action)
        } label: {
            Group {
                if showsLabel {
                    Label("Bearbeiten", systemImage: "pencil")
                } else {
                    Image(systemName: "pencil")
                }
            }
            .font(.callout.bold())
            .foregroundStyle(SecretMatchTheme.secondary)
            .frame(maxWidth: showsLabel ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, showsLabel ? 10 : 4)
            .background(showsLabel ? SecretMatchTheme.surfaceRaised : Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Aktion bearbeiten")
    }

    private func deleteButton(_ action: AdminAction, showsLabel: Bool) -> some View {
        Button(role: .destructive) {
            pendingDelete = action
        } label: {
            Group {
                if showsLabel {
                    Label("Löschen", systemImage: "trash")
                } else {
                    Image(systemName: "trash")
                }
            }
            .font(.callout.bold())
            .foregroundStyle(.red)
            .frame(maxWidth: showsLabel ? .infinity : nil, minHeight: 44)
            .padding(.horizontal, showsLabel ? 10 : 4)
            .background(showsLabel ? Color.red.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Aktion löschen")
    }

    private var filteredActions: [AdminAction] {
        api.adminActions.filter { action in
            let matchesType = selectedType == "all" || action.action_type == selectedType
            let matchesSearch = searchText.isEmpty
                || action.sender_number.localizedCaseInsensitiveContains(searchText)
                || action.receiver_number.localizedCaseInsensitiveContains(searchText)
                || action.sender_number.displayEventNumber.localizedCaseInsensitiveContains(searchText)
                || action.receiver_number.displayEventNumber.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }

    private func actionEmoji(for type: String) -> String {
        actionDefinition(for: type).emoji
    }
    
    private func prettyAction(_ type: String) -> String {
        actionDefinition(for: type).name
    }

    private func actionColor(for type: String) -> Color {
        Color(hex: actionDefinition(for: type).color)
    }

    private func actionDefinition(for type: String) -> ActionDefinition {
        api.actionDefinitions.first { $0.id == type } ?? ActionDefinition.fallback(for: type)
    }

    @ViewBuilder
    private func actionEditor(_ editor: Editor) -> some View {
        switch editor {
        case .create:
            AdminRecordEditorView(
                title: "Aktion anlegen",
                firstNumberLabel: "Absender",
                secondNumberLabel: "Empfänger",
                typeOptions: actionTypeOptions
            ) { sender, receiver, type in
                try await api.createAdminAction(senderNumber: sender, receiverNumber: receiver, type: type)
            }
        case .edit(let action):
            AdminRecordEditorView(
                title: "Aktion bearbeiten",
                firstNumberLabel: "Absender",
                secondNumberLabel: "Empfänger",
                typeOptions: actionTypeOptions,
                initialFirstNumber: action.sender_number,
                initialSecondNumber: action.receiver_number,
                initialType: action.action_type
            ) { sender, receiver, type in
                try await api.updateAdminAction(
                    id: action.id,
                    senderNumber: sender,
                    receiverNumber: receiver,
                    type: type
                )
            }
        }
    }

    private var actionTypeOptions: [AdminRecordTypeOption] {
        api.actionDefinitions.map {
            .init(value: $0.id, title: $0.displayTitle + ($0.enabled ? "" : " · ausgeblendet"))
        }
    }

    @MainActor
    private func delete(_ action: AdminAction) async {
        operationErrorMessage = nil
        do {
            try await api.deleteAdminAction(id: action.id)
        } catch {
            operationErrorMessage = "Aktion konnte nicht gelöscht werden: \(error.localizedDescription)"
        }
    }
}
