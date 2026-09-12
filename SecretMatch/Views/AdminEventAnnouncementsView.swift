import SwiftUI

struct AdminEventAnnouncementsView: View {
    @EnvironmentObject private var api: APIService

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var editor: AnnouncementDraft?
    @State private var pendingDeletion: EventAnnouncement?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let successMessage {
                    Label(successMessage, systemImage: "checkmark.circle.fill")
                        .font(.callout.bold())
                        .foregroundStyle(.green)
                }
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout.bold())
                        .foregroundStyle(SecretMatchTheme.danger)
                }

                if isLoading && api.adminEventAnnouncements.isEmpty {
                    ProgressView("Mitteilungen werden geladen …")
                        .tint(.white)
                        .foregroundStyle(SecretMatchTheme.muted)
                        .frame(maxWidth: .infinity, minHeight: 180)
                } else if api.adminEventAnnouncements.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Mitteilung",
                        systemImage: "megaphone",
                        description: Text("Lege einen kurzen Hinweis für alle verbundenen Billboards an.")
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .secretCard(padding: 20)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 14)], spacing: 14) {
                        ForEach(api.adminEventAnnouncements) { announcement in
                            announcementCard(announcement)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await load() }
        .task { await load() }
        .sheet(item: $editor) { draft in
            AnnouncementEditorView(draft: draft) { savedDraft in
                await save(savedDraft)
            }
            .environmentObject(api)
        }
        .alert("Mitteilung löschen?", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                guard let announcement = pendingDeletion else { return }
                pendingDeletion = nil
                Task { await delete(announcement) }
            }
        } message: {
            Text("Die Mitteilung verschwindet beim nächsten Billboard-Abgleich.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("EVENT CONTROL")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Event-Mitteilungen")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Kurze Hinweise erscheinen auf allen verbundenen Billboards – auch während der Top 16.")
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            Spacer(minLength: 10)

            Button {
                editor = AnnouncementDraft()
            } label: {
                Label("Mitteilung anlegen", systemImage: "plus")
            }
            .buttonStyle(SecretPrimaryButtonStyle())
        }
    }

    private func announcementCard(_ announcement: EventAnnouncement) -> some View {
        let tone = EventAnnouncementTone(rawValue: announcement.tone) ?? .info
        let color = color(for: tone)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Label(tone.title, systemImage: tone.systemImage)
                    .font(.callout.bold())
                    .foregroundStyle(color)
                Spacer()
                Label(statusTitle(for: announcement), systemImage: statusIcon(for: announcement))
                    .font(.caption.bold())
                    .foregroundStyle(announcement.live ? .green : SecretMatchTheme.muted)
            }

            Text(announcement.message)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(scheduleDescription(for: announcement))
                .font(.caption)
                .foregroundStyle(SecretMatchTheme.muted)

            Divider().background(SecretMatchTheme.border)

            HStack(spacing: 10) {
                Button(announcement.enabled ? "Pausieren" : "Aktivieren") {
                    Task { await toggle(announcement) }
                }
                .buttonStyle(SecretSecondaryButtonStyle())

                Button("Bearbeiten") {
                    editor = AnnouncementDraft(announcement)
                }
                .buttonStyle(SecretSecondaryButtonStyle())

                Spacer(minLength: 0)

                Button(role: .destructive) {
                    pendingDeletion = announcement
                } label: {
                    Image(systemName: "trash")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Mitteilung löschen")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(padding: 18)
        .overlay {
            RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius)
                .stroke(color.opacity(announcement.live ? 0.85 : 0.35), lineWidth: announcement.live ? 2 : 1)
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        do {
            try await api.loadAdminEventAnnouncements()
            errorMessage = nil
        } catch {
            errorMessage = "Mitteilungen konnten nicht geladen werden."
        }
        isLoading = false
    }

    @MainActor
    private func save(_ draft: AnnouncementDraft) async -> Bool {
        do {
            if let id = draft.persistedID {
                try await api.updateAdminEventAnnouncement(
                    id: id,
                    message: draft.message,
                    tone: draft.tone.rawValue,
                    enabled: draft.enabled,
                    startsAt: draft.hasStart ? Int(draft.startsAt.timeIntervalSince1970) : nil,
                    endsAt: draft.hasEnd ? Int(draft.endsAt.timeIntervalSince1970) : nil
                )
                successMessage = "Mitteilung wurde gespeichert."
            } else {
                try await api.createAdminEventAnnouncement(
                    message: draft.message,
                    tone: draft.tone.rawValue,
                    enabled: draft.enabled,
                    startsAt: draft.hasStart ? Int(draft.startsAt.timeIntervalSince1970) : nil,
                    endsAt: draft.hasEnd ? Int(draft.endsAt.timeIntervalSince1970) : nil
                )
                successMessage = "Mitteilung wurde angelegt."
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    private func toggle(_ announcement: EventAnnouncement) async {
        do {
            try await api.updateAdminEventAnnouncement(
                id: announcement.id,
                message: announcement.message,
                tone: announcement.tone,
                enabled: !announcement.enabled,
                startsAt: announcement.startsAt,
                endsAt: announcement.endsAt
            )
            successMessage = announcement.enabled ? "Mitteilung wurde pausiert." : "Mitteilung wurde aktiviert."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func delete(_ announcement: EventAnnouncement) async {
        do {
            try await api.deleteAdminEventAnnouncement(id: announcement.id)
            successMessage = "Mitteilung wurde gelöscht."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func color(for tone: EventAnnouncementTone) -> Color {
        switch tone {
        case .info: return .cyan
        case .highlight: return SecretMatchTheme.primary
        case .urgent: return .orange
        }
    }

    private func statusTitle(for announcement: EventAnnouncement) -> String {
        if !announcement.enabled { return "Pausiert" }
        if announcement.live { return "Jetzt sichtbar" }
        if let endsAt = announcement.endsAt, endsAt <= Int(Date().timeIntervalSince1970) { return "Abgelaufen" }
        return "Geplant"
    }

    private func statusIcon(for announcement: EventAnnouncement) -> String {
        if announcement.live { return "checkmark.circle.fill" }
        if !announcement.enabled { return "pause.circle.fill" }
        return "clock.fill"
    }

    private func scheduleDescription(for announcement: EventAnnouncement) -> String {
        let start = announcement.startsAt.map { Self.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval($0))) } ?? "sofort"
        let end = announcement.endsAt.map { Self.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval($0))) } ?? "manuell"
        return "Start: \(start) · Ende: \(end)"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct AnnouncementDraft: Identifiable {
    let draftID = UUID()
    var id: UUID { draftID }
    let announcementID: String?
    var message: String
    var tone: EventAnnouncementTone
    var enabled: Bool
    var hasStart: Bool
    var startsAt: Date
    var hasEnd: Bool
    var endsAt: Date

    init() {
        announcementID = nil
        message = ""
        tone = .info
        enabled = true
        hasStart = false
        startsAt = Date()
        hasEnd = false
        endsAt = Date().addingTimeInterval(60 * 60)
    }

    init(_ announcement: EventAnnouncement) {
        announcementID = announcement.id
        message = announcement.message
        tone = EventAnnouncementTone(rawValue: announcement.tone) ?? .info
        enabled = announcement.enabled
        hasStart = announcement.startsAt != nil
        startsAt = Date(timeIntervalSince1970: TimeInterval(announcement.startsAt ?? Int(Date().timeIntervalSince1970)))
        hasEnd = announcement.endsAt != nil
        endsAt = Date(timeIntervalSince1970: TimeInterval(announcement.endsAt ?? Int(Date().addingTimeInterval(60 * 60).timeIntervalSince1970)))
    }

    var persistedID: String? { announcementID }
}

private struct AnnouncementEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AnnouncementDraft
    @State private var isSaving = false
    @State private var errorMessage: String?
    let onSave: (AnnouncementDraft) async -> Bool

    init(draft: AnnouncementDraft, onSave: @escaping (AnnouncementDraft) async -> Bool) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Mitteilung") {
                    AdminKeyboardTextEditor(
                        title: "Event-Mitteilung",
                        text: $draft.message,
                        maxCharacters: 160,
                        allowsNewlines: true
                    )
                    .frame(minHeight: 120)

                    Picker("Darstellung", selection: $draft.tone) {
                        ForEach(EventAnnouncementTone.allCases) { tone in
                            Label(tone.title, systemImage: tone.systemImage).tag(tone)
                        }
                    }

                    Toggle("Auf Billboards anzeigen", isOn: $draft.enabled)
                }

                Section("Zeitsteuerung") {
                    Toggle("Startzeit festlegen", isOn: $draft.hasStart)
                    if draft.hasStart {
                        DatePicker("Start", selection: $draft.startsAt)
                    }

                    Toggle("Automatisch beenden", isOn: $draft.hasEnd)
                    if draft.hasEnd {
                        DatePicker("Ende", selection: $draft.endsAt)
                    }

                    Text("Ohne Endzeit bleibt die Mitteilung sichtbar, bis sie pausiert oder gelöscht wird.")
                        .font(.caption)
                        .foregroundStyle(SecretMatchTheme.muted)
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(SecretMatchTheme.danger)
                    }
                } else if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(SecretMatchTheme.danger)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SecretMatchTheme.surface)
            .navigationTitle(draft.announcementID == nil ? "Mitteilung anlegen" : "Mitteilung bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Wird gespeichert …" : "Speichern") {
                        Task { await save() }
                    }
                    .disabled(isSaving || validationMessage != nil)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var validationMessage: String? {
        let message = draft.message.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.isEmpty { return "Bitte gib einen Text ein." }
        if draft.hasEnd && draft.hasStart && draft.endsAt <= draft.startsAt {
            return "Das Ende muss nach dem Start liegen."
        }
        return nil
    }

    @MainActor
    private func save() async {
        guard validationMessage == nil else { return }
        isSaving = true
        errorMessage = nil
        if await onSave(draft) {
            dismiss()
        } else {
            errorMessage = "Die Mitteilung konnte nicht gespeichert werden."
        }
        isSaving = false
    }
}
