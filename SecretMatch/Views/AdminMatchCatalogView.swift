import SwiftUI

struct AdminMatchCatalogView: View {
    @EnvironmentObject private var api: APIService
    @Binding var isPresented: Bool
    @State private var editor: EditorContext?
    @State private var pendingDelete: MatchDefinition?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private struct EditorContext: Identifiable {
        let id = UUID()
        let definition: MatchDefinition
        let isNew: Bool
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()
                Group {
                    if isLoading { ProgressView("Match-Typen werden geladen …").tint(.white).foregroundStyle(.white) }
                    else { catalog }
                }
                .padding(20)
            }
            .navigationTitle("Match-Typen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Schließen") { isPresented = false } }
                ToolbarItem(placement: .primaryAction) {
                    Button { editor = .init(definition: newDefinition, isNew: true) } label: { Label("Neu", systemImage: "plus") }
                }
            }
        }
        .tint(SecretMatchTheme.primary)
        .task { await load() }
        .sheet(item: $editor) { context in
            MatchDefinitionEditorView(definition: context.definition, isNew: context.isNew) { definition in
                try await api.saveAdminMatchDefinition(definition, isNew: context.isNew)
            }
        }
        .alert("Match-Typ löschen?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                guard let definition = pendingDelete else { return }
                pendingDelete = nil
                Task { await delete(definition) }
            }
        } message: {
            Text("Bereits verwendete Match-Typen können nicht gelöscht, aber ausgeblendet werden.")
        }
    }

    private var catalog: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Darstellung und Sichtbarkeit gelten gemeinsam für Teilnehmer-App, Admin und Billboard. Die Reihenfolge bestimmt die Stärke bei gegenseitigen Wünschen.")
                .foregroundStyle(SecretMatchTheme.muted)
            if let errorMessage { Label(errorMessage, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                    ForEach(api.matchDefinitions) { definition in definitionCard(definition) }
                }
            }
        }
    }

    private func definitionCard(_ definition: MatchDefinition) -> some View {
        let color = Color(hex: definition.color)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(definition.emoji.isEmpty ? "✨" : definition.emoji).font(.system(size: 30)).frame(width: 52, height: 52).background(color.opacity(0.2))
                VStack(alignment: .leading) {
                    Text(definition.name).font(.headline.bold()).foregroundStyle(.white)
                    Text(definition.id).font(.caption.monospaced()).foregroundStyle(SecretMatchTheme.muted)
                }
                Spacer()
                Toggle("Aktiv", isOn: Binding(get: { definition.enabled }, set: { enabled in Task { await setEnabled(enabled, for: definition) } })).labelsHidden()
            }
            HStack {
                Text("Position / Stärke \(definition.sortOrder)").font(.caption).foregroundStyle(SecretMatchTheme.muted)
                Spacer()
                Button("Bearbeiten") { editor = .init(definition: definition, isNew: false) }.foregroundStyle(SecretMatchTheme.secondary)
                Button(role: .destructive) { pendingDelete = definition } label: { Image(systemName: "trash") }
            }
        }
        .padding(16)
        .background(color.opacity(0.11))
        .overlay(Rectangle().stroke(color.opacity(0.55), lineWidth: 1))
    }

    private var newDefinition: MatchDefinition {
        .init(id: "", name: "", emoji: "💞", color: "#E83E8C", enabled: false, sortOrder: (api.matchDefinitions.map(\.sortOrder).max() ?? 20) + 10)
    }

    @MainActor private func load() async {
        isLoading = true; defer { isLoading = false }
        do { try await api.loadAdminMatchDefinitions(); errorMessage = nil }
        catch { errorMessage = "Match-Typen konnten nicht geladen werden." }
    }

    @MainActor private func setEnabled(_ enabled: Bool, for definition: MatchDefinition) async {
        var updated = definition; updated.enabled = enabled
        do { try await api.saveAdminMatchDefinition(updated, isNew: false); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    @MainActor private func delete(_ definition: MatchDefinition) async {
        do { try await api.deleteAdminMatchDefinition(id: definition.id); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
}

private struct MatchDefinitionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let isNew: Bool
    let save: (MatchDefinition) async throws -> Void
    @State private var technicalID: String
    @State private var name: String
    @State private var emoji: String
    @State private var color: String
    @State private var enabled: Bool
    @State private var sortOrder: Int
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(definition: MatchDefinition, isNew: Bool, save: @escaping (MatchDefinition) async throws -> Void) {
        self.isNew = isNew; self.save = save
        _technicalID = State(initialValue: definition.id); _name = State(initialValue: definition.name)
        _emoji = State(initialValue: definition.emoji); _color = State(initialValue: definition.color)
        _enabled = State(initialValue: definition.enabled); _sortOrder = State(initialValue: definition.sortOrder)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Darstellung") {
                    if isNew { AdminKeyboardTextField(title: "Technische ID", text: $technicalID, keyboard: .text(maxCharacters: 30)) }
                    else { LabeledContent("Technische ID", value: technicalID) }
                    AdminKeyboardTextField(title: "Name", text: $name, keyboard: .text(maxCharacters: 48))
                    AdminKeyboardTextField(title: "Emoji", text: $emoji, keyboard: .text(maxCharacters: 8))
                    AdminKeyboardTextField(title: "Hex-Farbe", text: $color, keyboard: .text(maxCharacters: 7), forcesUppercase: true)
                    Stepper("Position / Stärke \(sortOrder)", value: $sortOrder, in: 0...999, step: 10)
                    Toggle("In der Teilnehmer-App aktiv", isOn: $enabled)
                }
                Section { Text("Treffen zwei unterschiedliche Wünsche aufeinander, wird der erste aktive Match-Typ verwendet. Gleiche Wünsche ergeben genau diesen Typ.").foregroundStyle(.secondary) }
                if let errorMessage { Section { Label(errorMessage, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) } }
            }
            .scrollContentBackground(.hidden).background(SecretMatchTheme.background)
            .navigationTitle(isNew ? "Match-Typ anlegen" : "Match-Typ bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() }.disabled(isSaving) }
                ToolbarItem(placement: .confirmationAction) { Button(isSaving ? "Speichert …" : "Speichern") { Task { await performSave() } }.disabled(!canSave || isSaving) }
            }
        }
        .tint(SecretMatchTheme.primary)
    }

    private var normalizedID: String { technicalID.lowercased().filter { String($0).range(of: "[a-z0-9_-]", options: .regularExpression) != nil } }
    private var canSave: Bool {
        normalizedID.range(of: "^[a-z0-9][a-z0-9_-]{1,29}$", options: .regularExpression) != nil
            && color.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor private func performSave() async {
        guard canSave else { return }; isSaving = true; defer { isSaving = false }
        do {
            try await save(.init(id: normalizedID, name: name.trimmingCharacters(in: .whitespacesAndNewlines), emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines), color: color.uppercased(), enabled: enabled, sortOrder: sortOrder)); dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
