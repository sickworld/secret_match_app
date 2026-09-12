import SwiftUI

struct AdminActionCatalogView: View {
    @EnvironmentObject private var api: APIService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var isPresented: Bool
    @State private var editor: EditorContext?
    @State private var pendingDelete: ActionDefinition?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private struct EditorContext: Identifiable {
        let id = UUID()
        let definition: ActionDefinition
        let isNew: Bool
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()

                Group {
                    if isLoading {
                        ProgressView("Aktionsarten werden geladen …")
                            .tint(.white)
                            .foregroundStyle(.white)
                    } else {
                        catalog
                    }
                }
                .padding(usesCompactLayout ? 12 : 22)
            }
            .navigationTitle("Aktionsarten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { isPresented = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editor = EditorContext(definition: newDefinition, isNew: true)
                    } label: {
                        Label("Neu", systemImage: "plus")
                    }
                }
            }
        }
        .tint(SecretMatchTheme.primary)
        .task { await load() }
        .sheet(item: $editor) { context in
            ActionDefinitionEditorView(definition: context.definition, isNew: context.isNew) { definition in
                try await api.saveAdminActionDefinition(definition, isNew: context.isNew)
            }
        }
        .alert("Aktionsart löschen?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                guard let definition = pendingDelete else { return }
                pendingDelete = nil
                Task { await delete(definition) }
            }
        } message: {
            Text("Bereits verwendete Aktionsarten können nicht gelöscht, aber jederzeit ausgeblendet werden.")
        }
    }

    private var catalog: some View {
        VStack(alignment: .leading, spacing: usesCompactLayout ? 10 : 14) {
            Text("Die Reihenfolge und Darstellung gelten gemeinsam für Teilnehmer-App, Adminbereiche und Billboard. Neue Vorschläge sind zunächst ausgeblendet.")
                .font(usesCompactLayout ? .callout : .body)
                .foregroundStyle(SecretMatchTheme.muted)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout.bold())
                    .foregroundStyle(.red)
            }

            ScrollView {
                LazyVGrid(columns: catalogColumns, spacing: 12) {
                    ForEach(api.actionDefinitions) { definition in
                        definitionCard(definition)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func definitionCard(_ definition: ActionDefinition) -> some View {
        let color = Color(hex: definition.color)
        return VStack(alignment: .leading, spacing: usesCompactLayout ? 10 : 12) {
            HStack(spacing: 12) {
                Text(definition.emoji.isEmpty ? "✨" : definition.emoji)
                    .font(.system(size: usesCompactLayout ? 27 : 30))
                    .frame(width: usesCompactLayout ? 46 : 52, height: usesCompactLayout ? 46 : 52)
                    .background(color.opacity(0.2))
                    .overlay(Rectangle().stroke(color.opacity(0.7), lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text(definition.name)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(definition.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(SecretMatchTheme.muted)
                }

                Spacer()

                Toggle("Aktiv", isOn: Binding(
                    get: { definition.enabled },
                    set: { enabled in Task { await setEnabled(enabled, for: definition) } }
                ))
                .labelsHidden()
            }

            metadataGrid(definition, color: color)

            HStack {
                Text("Position \(definition.sortOrder)")
                    .font(.caption)
                    .foregroundStyle(SecretMatchTheme.muted)
                Spacer()
                Button("Bearbeiten") {
                    editor = EditorContext(definition: definition, isNew: false)
                }
                .foregroundStyle(SecretMatchTheme.secondary)
                Button(role: .destructive) {
                    pendingDelete = definition
                } label: {
                    Image(systemName: "trash")
                }
            }
            .font(.callout.bold())
        }
        .padding(usesCompactLayout ? 13 : 16)
        .background(color.opacity(0.11))
        .overlay(Rectangle().stroke(color.opacity(0.55), lineWidth: 1))
    }

    private func metadata(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .frame(maxWidth: usesCompactLayout ? .infinity : nil, alignment: .leading)
    }

    @ViewBuilder
    private func metadataGrid(_ definition: ActionDefinition, color: Color) -> some View {
        if usesCompactLayout {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 7) {
                metadata(categoryTitle(definition.category), color: color)
                metadata(directionTitle(definition.direction), color: color)
                metadata(genderTitle(definition.targetGender), color: color)
            }
        } else {
            HStack(spacing: 8) {
                metadata(categoryTitle(definition.category), color: color)
                metadata(directionTitle(definition.direction), color: color)
                metadata(genderTitle(definition.targetGender), color: color)
            }
        }
    }

    private var usesCompactLayout: Bool {
#if ADMIN_APP
        true
#else
        horizontalSizeClass == .compact
#endif
    }

    private var catalogColumns: [GridItem] {
        usesCompactLayout
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 330), spacing: 12)]
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.loadAdminActionDefinitions()
            errorMessage = nil
        } catch {
            errorMessage = "Aktionsarten konnten nicht geladen werden."
        }
    }

    @MainActor
    private func setEnabled(_ enabled: Bool, for definition: ActionDefinition) async {
        var updated = definition
        updated.enabled = enabled
        do {
            try await api.saveAdminActionDefinition(updated, isNew: false)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func delete(_ definition: ActionDefinition) async {
        do {
            try await api.deleteAdminActionDefinition(id: definition.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var newDefinition: ActionDefinition {
        ActionDefinition(id: "", name: "", emoji: "✨", color: "#E83E8C", category: "play", direction: "neutral", targetGender: "any", enabled: false, sortOrder: (api.actionDefinitions.map(\.sortOrder).max() ?? 140) + 10)
    }

    private func categoryTitle(_ value: String) -> String {
        ["kennenlernen": "Kennenlernen", "naehe": "Nähe", "play": "Play"][value] ?? value
    }

    private func directionTitle(_ value: String) -> String {
        ["offer": "Ich biete an", "request": "Ich wünsche mir", "meet": "Treffen", "neutral": "Neutral"][value] ?? value
    }

    private func genderTitle(_ value: String) -> String {
        ["any": "Alle", "male": "Ziel: Mann", "female": "Ziel: Frau"][value] ?? value
    }
}

private struct ActionDefinitionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let isNew: Bool
    let save: (ActionDefinition) async throws -> Void

    @State private var technicalID: String
    @State private var name: String
    @State private var emoji: String
    @State private var color: String
    @State private var category: String
    @State private var direction: String
    @State private var targetGender: String
    @State private var enabled: Bool
    @State private var sortOrder: Int
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(definition: ActionDefinition, isNew: Bool, save: @escaping (ActionDefinition) async throws -> Void) {
        self.isNew = isNew
        self.save = save
        _technicalID = State(initialValue: definition.id)
        _name = State(initialValue: definition.name)
        _emoji = State(initialValue: definition.emoji)
        _color = State(initialValue: definition.color)
        _category = State(initialValue: definition.category)
        _direction = State(initialValue: definition.direction)
        _targetGender = State(initialValue: definition.targetGender)
        _enabled = State(initialValue: definition.enabled)
        _sortOrder = State(initialValue: definition.sortOrder)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Darstellung") {
                    if isNew {
                        AdminKeyboardTextField(title: "Technische ID", text: $technicalID, keyboard: .text(maxCharacters: 30), keyboardTitle: "Technische ID")
                    } else {
                        LabeledContent("Technische ID", value: technicalID)
                    }
                    AdminKeyboardTextField(title: "Name", text: $name, keyboard: .text(maxCharacters: 48), keyboardTitle: "Name der Aktionsart")
                    AdminKeyboardTextField(title: "Emoji", text: $emoji, keyboard: .text(maxCharacters: 8), keyboardTitle: "Emoji")
                    AdminKeyboardTextField(title: "Hex-Farbe", text: $color, keyboard: .text(maxCharacters: 7), keyboardTitle: "Farbe im Format #E83E8C", forcesUppercase: true)
                    HStack {
                        Text("Vorschau")
                        Spacer()
                        Text((emoji.isEmpty ? "✨" : emoji) + " " + (name.isEmpty ? "Aktionsart" : name))
                            .bold()
                            .foregroundStyle(Color(hex: validColor ? color : "#E83E8C"))
                    }
                }

                Section("Einordnung") {
                    Picker("Kategorie", selection: $category) {
                        Text("Kennenlernen").tag("kennenlernen")
                        Text("Nähe").tag("naehe")
                        Text("Play").tag("play")
                    }
                    Picker("Richtung", selection: $direction) {
                        Text("Neutral").tag("neutral")
                        Text("Ich biete an").tag("offer")
                        Text("Ich wünsche mir").tag("request")
                        Text("Treffen").tag("meet")
                    }
                    Picker("Ziel-Gender", selection: $targetGender) {
                        Text("Alle").tag("any")
                        Text("Mann").tag("male")
                        Text("Frau").tag("female")
                    }
                    Stepper("Position \(sortOrder)", value: $sortOrder, in: 0...999, step: 10)
                    Toggle("In der Teilnehmer-App aktiv", isOn: $enabled)
                }

                Section {
                    Text("Eine gesendete Aktion ist eine Anfrage, keine Zustimmung. Grenzen und Details werden persönlich besprochen.")
                        .font(.callout)
                        .foregroundStyle(SecretMatchTheme.muted)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SecretMatchTheme.background)
            .navigationTitle(isNew ? "Aktionsart anlegen" : "Aktionsart bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Speichert …" : "Speichern") {
                        Task { await performSave() }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
        }
        .tint(SecretMatchTheme.primary)
    }

    private var normalizedID: String {
        technicalID.lowercased().filter {
            String($0).range(of: "[a-z0-9_-]", options: .regularExpression) != nil
        }
    }

    private var validID: Bool {
        normalizedID.range(of: "^[a-z0-9][a-z0-9_-]{1,29}$", options: .regularExpression) != nil
    }

    private var validColor: Bool {
        color.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil
    }

    private var canSave: Bool {
        validID && validColor && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func performSave() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await save(ActionDefinition(
                id: normalizedID,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines),
                color: color.uppercased(),
                category: category,
                direction: direction,
                targetGender: targetGender,
                enabled: enabled,
                sortOrder: sortOrder
            ))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
