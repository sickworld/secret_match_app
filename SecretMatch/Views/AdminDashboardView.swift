import SwiftUI

enum AdminDashboardSection: String, CaseIterable, Identifiable {
    case overview, readiness, diagnostics, liveFeed, eventLog, statistics, actions, requests, matches, feedback, controls, participants, system

    var id: String { rawValue }

    static let featureSections: [AdminDashboardSection] = [
        .liveFeed, .actions, .requests, .matches,
        .participants, .controls, .readiness, .diagnostics,
        .eventLog, .statistics, .feedback, .system
    ]

    var title: String {
        switch self {
        case .overview: return "Aktionen"
        case .readiness: return "Event-Check"
        case .diagnostics: return "Sendungsdiagnose"
        case .liveFeed: return "Livefeed"
        case .eventLog: return "Protokoll"
        case .statistics: return "Statistik"
        case .actions: return "Aktionen verwalten"
        case .requests: return "Match-Requests"
        case .matches: return "Matches verwalten"
        case .feedback: return "Feedback"
        case .controls: return "Eventsteuerung"
        case .participants: return "Teilnehmer"
        case .system: return "System & Archiv"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return "Alle Werkzeuge für dein Event"
        case .readiness: return "Vor dem Start alles prüfen"
        case .diagnostics: return "Sendungen per Request-ID verfolgen"
        case .liveFeed: return "Aktivität während des Events"
        case .eventLog: return "Zentrale Ereignisse und Admin-Eingriffe"
        case .statistics: return "Eventverlauf auswerten und exportieren"
        case .actions: return "Empfangene Aktionen anlegen und bearbeiten"
        case .requests: return "Offene und gematchte Wünsche verwalten"
        case .matches: return "Erfolgreiche Matches verwalten"
        case .feedback: return "Anonyme Bewertungen auswerten"
        case .controls: return "Billboards, Medien, Schnelltexte und Testdaten"
        case .participants: return "Nummern, PIN und Gender verwalten"
        case .system: return "Status, Geräte und Event-Archiv"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .readiness: return "checkmark.seal.fill"
        case .diagnostics: return "waveform.path.ecg.rectangle"
        case .liveFeed: return "dot.radiowaves.left.and.right"
        case .eventLog: return "list.bullet.rectangle.portrait.fill"
        case .statistics: return "chart.bar.xaxis"
        case .actions: return "paperplane.fill"
        case .requests: return "heart.text.square.fill"
        case .matches: return "sparkles"
        case .feedback: return "star.bubble.fill"
        case .controls: return "slider.horizontal.3"
        case .participants: return "person.3.fill"
        case .system: return "gearshape.2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .overview, .actions, .feedback: return SecretMatchTheme.primary
        case .readiness, .eventLog, .controls: return SecretMatchTheme.secondary
        case .diagnostics, .system: return .orange
        case .liveFeed: return .green
        case .statistics: return .cyan
        case .requests: return Color(hex: "#8E63D2")
        case .matches: return Color(hex: "#E83E8C")
        case .participants: return Color(hex: "#3E9ED6")
        }
    }
}

private struct AdminDashboardSectionKey: EnvironmentKey {
    static let defaultValue = AdminDashboardSection.overview
}

extension EnvironmentValues {
    var adminDashboardSection: AdminDashboardSection {
        get { self[AdminDashboardSectionKey.self] }
        set { self[AdminDashboardSectionKey.self] = newValue }
    }
}

struct AdminDashboardView: View {
    @EnvironmentObject private var api: APIService
    @Environment(\.adminDashboardSection) private var dashboardSection
    @Binding var showBillboard: Bool
    @Binding var selectedSection: AdminDashboardSection
    var showsFeatureOverview = true

    @State private var participantSearch = ""
    @State private var newParticipantNumber = ""
    @State private var rotationSeconds = 6
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var confirmation: Confirmation?
    @State private var showResetAssistant = false
    @State private var resetConfirmation = ""
    @State private var archiveName = ""
    @State private var quickMessagesText = ""
    @State private var quickMessagesSaveState = QuickMessagesSaveState.idle
    @State private var pinEditorNumber: String?
    @State private var pinDraft = ""
    @State private var equipmentEditor: EquipmentEditor?
    @State private var equipmentNameDraft = ""
    @State private var billboardNameDraft = ""
    @State private var generatedBillboardURL: URL?
    @State private var showBillboardCreator = false
    @State private var showScreensaverMediaManager = false
    @State private var participantRangeMax = ""
    @State private var participantRangeConfirmation = ""
    @State private var adminCredentialName = ""
    @State private var adminCredentialPassword = ""
    @State private var adminCredentialConfirmation = ""

    private enum QuickMessagesSaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    private enum EquipmentEditor: Identifiable {
        case device(id: String, currentName: String)
        case billboard(id: String, currentName: String)

        var id: String {
            switch self {
            case .device(let id, _): return "device-\(id)"
            case .billboard(let id, _): return "billboard-\(id)"
            }
        }

        var title: String {
            switch self {
            case .device: return "iPad benennen"
            case .billboard: return "Billboard benennen"
            }
        }
    }

    private enum Confirmation: Identifiable {
        case createDummy
        case deleteDummy
        case revokeBillboard
        case resetGender(String)
        case resetPIN(String)
        case blockParticipant(String)
        case deleteDevice(id: String, name: String)
        case deleteBillboard(id: String, name: String)
        case deleteAdminCredential(id: String, name: String)

        var id: String {
            switch self {
            case .createDummy: return "create-dummy"
            case .deleteDummy: return "delete-dummy"
            case .revokeBillboard: return "revoke-billboard"
            case .resetGender(let number): return "reset-gender-\(number)"
            case .resetPIN(let number): return "reset-pin-\(number)"
            case .blockParticipant(let number): return "block-participant-\(number)"
            case .deleteDevice(let id, _): return "delete-device-\(id)"
            case .deleteBillboard(let id, _): return "delete-billboard-\(id)"
            case .deleteAdminCredential(let id, _): return "delete-admin-credential-\(id)"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                operationFeedback
                adminAppContent
            }
            .padding(24)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await refresh(showErrors: false)
            }
        }
        .alert("Aktion bestätigen", isPresented: Binding(
            get: { confirmation != nil },
            set: { if !$0 { confirmation = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Ausführen", role: .destructive) {
                let selected = confirmation
                confirmation = nil
                Task { await runConfirmation(selected) }
            }
        } message: {
            Text(confirmationText)
        }
        .sheet(isPresented: $showResetAssistant) {
            resetAssistant
        }
        .sheet(isPresented: Binding(get: { pinEditorNumber != nil }, set: { if !$0 { pinEditorNumber = nil } })) {
            pinEditor
        }
        .sheet(item: $equipmentEditor) { editor in
            equipmentNameEditor(editor)
        }
        .sheet(isPresented: $showBillboardCreator) {
            billboardCreator
        }
        .sheet(isPresented: $showScreensaverMediaManager) {
            AdminScreensaverMediaView()
                .environmentObject(api)
        }
    }

    @ViewBuilder
    private var adminAppContent: some View {
        switch dashboardSection {
        case .overview:
            header
            if showsFeatureOverview {
                featureOverview
            }
            liveStatus
            deviceStatus
            metrics
            topPreview
        case .controls:
            sectionHeading(dashboardSection.title, subtitle: dashboardSection.subtitle)
            controls
            topPreview
        case .participants:
            sectionHeading(dashboardSection.title, subtitle: dashboardSection.subtitle)
            participants
        case .system:
            sectionHeading(dashboardSection.title, subtitle: dashboardSection.subtitle)
            adminAccess
            systemStatus
            deviceStatus
            resetCard
        case .readiness, .diagnostics, .liveFeed, .eventLog, .statistics, .actions, .requests, .matches, .feedback:
            EmptyView()
        }
    }

    private var featureOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("ADMIN-AKTIONEN")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Werkzeuge")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Dieselben Funktionen stehen auf iPhone und iPad zur Verfügung.")
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 235), spacing: 12)], spacing: 12) {
                ForEach(AdminDashboardSection.featureSections) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        HStack(alignment: .top, spacing: 13) {
                            Image(systemName: section.systemImage)
                                .font(.title3.bold())
                                .foregroundStyle(section.tint)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(section.title)
                                    .font(.headline.bold())
                                Text(section.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(SecretMatchTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(SecretMatchTheme.muted)
                        }
                    }
                    .buttonStyle(SecretAdminFeatureButtonStyle(tint: section.tint))
                    .accessibilityHint("Öffnet \(section.title)")
                }
            }
        }
        .secretCard(padding: 20)
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EVENT CONTROL")
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(SecretMatchTheme.secondary)
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .foregroundStyle(SecretMatchTheme.muted)
        }
    }

    private var liveStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📺 Billboards verwalten")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(billboardStatuses.count)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(SecretMatchTheme.secondary)
                Button {
                    billboardNameDraft = ""
                    generatedBillboardURL = nil
                    showBillboardCreator = true
                } label: {
                    Label("Neu", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .tint(SecretMatchTheme.secondary)
                .disabled(isWorking)
            }

            if billboardStatuses.isEmpty {
                Label("Noch kein Billboard verbunden oder vorbereitet.", systemImage: "tv.slash")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                ForEach(billboardStatuses) { billboard in
                    billboardStatusRow(billboard)
                }
            }

            Text("Das zentrale Passwort gilt beim manuellen Login für alle Billboards. Ein Einmal-Link meldet das gewählte Billboard stattdessen mit einer eigenen, separat löschbaren Sitzung an.")
                .font(.caption)
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .secretCard(padding: 20)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("EVENT CONTROL CENTER")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Live-Übersicht")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(
                    showsFeatureOverview
                        ? "Event steuern, Teilnehmer verwalten und den Systemzustand prüfen."
                        : "Live-Status, Geräte und Kennzahlen auf einen Blick."
                )
                    .foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer()
            Button {
                Task { await refresh() }
            } label: {
                Label("Aktualisieren", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecretSecondaryButtonStyle())
            .disabled(isWorking)
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
            metric("👥", "Gerade aktiv", api.adminDashboard?.activeParticipants ?? 0, SecretMatchTheme.secondary)
            metric("❤️", "Matches", api.adminDashboard?.matches ?? 0, Color(hex: "#E83E8C"))
            metric("📨", "Requests", api.adminDashboard?.requests ?? 0, Color(hex: "#8E63D2"))
            metric("💌", "Aktionen", api.adminDashboard?.actions ?? 0, Color(hex: "#3E9ED6"))
            metric("#️⃣", "Freigegeben", api.adminDashboard?.allowedParticipants ?? 0, Color(hex: "#E6923E"))
        }
    }

    private var liveFeed: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVEFEED")
                        .font(.caption.bold())
                        .tracking(1.8)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text("Was gerade passiert")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                Label("alle 10 Sek.", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }

            if liveFeedEntries.isEmpty {
                Label("Noch keine Aktionen oder Matches vorhanden.", systemImage: "waveform.path")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            } else {
                ForEach(liveFeedEntries.prefix(8)) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Text(entry.emoji)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(entry.color.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(entry.detail)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SecretMatchTheme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(entry.color.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(entry.color.opacity(0.32)))
                }
            }
        }
        .secretCard(padding: 20)
    }

    private var liveFeedEntries: [LiveFeedEntry] {
        let actions = api.adminActions.map { action in
            LiveFeedEntry(
                id: "action-\(action.id)",
                createdAt: action.created_at,
                emoji: actionEmoji(action),
                title: actionTitle(action),
                detail: "\(action.sender_number.displayEventNumber) → \(action.receiver_number.displayEventNumber)",
                color: actionColor(action)
            )
        }
        let matches = api.adminMatches.map { match in
            let definition = api.matchDefinitions.first(where: { $0.id == MatchDefinition.normalizedID(match.type) }) ?? .fallback(for: match.type)
            return LiveFeedEntry(
                id: "match-\(match.id)",
                createdAt: match.created_at,
                emoji: definition.emoji,
                title: "\(definition.name) entstanden",
                detail: "\(match.number_a.displayEventNumber) ↔ \(match.number_b.displayEventNumber)",
                color: Color(hex: definition.color)
            )
        }
        return (actions + matches).sorted { $0.createdAt > $1.createdAt }
    }

    private func actionEmoji(_ action: AdminAction) -> String {
        action.action_emoji ?? api.actionDefinitions.first { $0.id == action.action_type }?.emoji ?? ActionDefinition.fallback(for: action.action_type).emoji
    }

    private func actionTitle(_ action: AdminAction) -> String {
        let name = action.action_name ?? api.actionDefinitions.first { $0.id == action.action_type }?.name ?? ActionDefinition.fallback(for: action.action_type).name
        return "\(name)-Aktion gesendet"
    }

    private func actionColor(_ action: AdminAction) -> Color {
        Color(hex: action.action_color ?? api.actionDefinitions.first { $0.id == action.action_type }?.color ?? ActionDefinition.fallback(for: action.action_type).color)
    }

    private var controls: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 16)], spacing: 16) {
            controlCard(title: "🖼️ Bildschirmschoner & Sponsoren", subtitle: "Startzeit, Bilder, Texte und Sichtbarkeit gemeinsam pflegen") {
                Text(api.adminScreensaverItems.isEmpty
                     ? "Standardbilder sind aktiv."
                     : "\(api.adminScreensaverItems.count) eigene Medien im Katalog.")
                    .foregroundStyle(SecretMatchTheme.muted)

                Button("Medien verwalten") {
                    showScreensaverMediaManager = true
                }
                .buttonStyle(SecretPrimaryButtonStyle())
            }

            controlCard(title: "📺 Billboard-Steuerung", subtitle: "Darstellung und globale Steuerung aller Bildschirme") {
                Button("Vollbild öffnen") { showBillboard = true }
                    .buttonStyle(SecretPrimaryButtonStyle())

                HStack {
                    Button("Top 16 testen") { Task { await billboard("start_top_test") } }
                    Button("Normalbetrieb") { Task { await billboard("normal_mode") } }
                }
                .buttonStyle(SecretSecondaryButtonStyle())

                Stepper("Match-Einblendung: \(rotationSeconds) Sekunden", value: $rotationSeconds, in: 5...8)
                    .foregroundStyle(.white)
                Text("Neue Matches werden kurz groß gezeigt. Die Live-Ansicht selbst bleibt ruhig stehen.")
                    .font(.caption)
                    .foregroundStyle(SecretMatchTheme.muted)
                Button("Dauer speichern") {
                    Task { await billboard("set_interval", seconds: rotationSeconds) }
                }
                .buttonStyle(SecretSecondaryButtonStyle())

                Button("Alle Billboard-Zugänge abmelden", role: .destructive) {
                    confirmation = .revokeBillboard
                }
                .foregroundStyle(.red)
            }

            controlCard(title: "🧪 Testdaten", subtitle: "48 Matches, 300 Aktionen und 96 Anfragen realistisch testen") {
                Text(api.adminDashboard?.dummyDataActive == true ? "Testdaten sind aktiv." : "Momentan keine Testdaten.")
                    .foregroundStyle(api.adminDashboard?.dummyDataActive == true ? .green : SecretMatchTheme.muted)
                Button("Testdaten anlegen") { confirmation = .createDummy }
                    .buttonStyle(SecretPrimaryButtonStyle())
                Button("Testdaten löschen", role: .destructive) { confirmation = .deleteDummy }
                    .foregroundStyle(.red)
            }

            controlCard(title: "💬 Match-Schnelltexte", subtitle: "Bis zu 8 Texte, je eine Zeile") {
                AdminKeyboardTextEditor(
                    title: "Match-Schnelltexte",
                    text: $quickMessagesText,
                    maxCharacters: 647,
                    allowsNewlines: true
                )
                    .frame(minHeight: 150)
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                    .onChange(of: quickMessagesText) { _, _ in
                        if quickMessagesSaveState != .saving {
                            quickMessagesSaveState = .idle
                        }
                    }

                Button { Task { await saveQuickMessages() } } label: {
                    HStack(spacing: 10) {
                        if quickMessagesSaveState == .saving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.down.fill")
                        }
                        Text(quickMessagesSaveState == .saving ? "Wird gespeichert…" : "Schnelltexte speichern")
                    }
                }
                    .buttonStyle(SecretPrimaryButtonStyle())
                    .disabled(isWorking || quickMessagesSaveState == .saving)

                switch quickMessagesSaveState {
                case .idle, .saving:
                    EmptyView()
                case .saved:
                    Label("Schnelltexte gespeichert", systemImage: "checkmark.circle.fill")
                        .font(.callout.bold())
                        .foregroundStyle(.green)
                case .failed(let message):
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout.bold())
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var participants: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("👤 Teilnehmerverwaltung")
                .font(.title2.bold())
                .foregroundStyle(.white)

            if let statusMessage {
                Text(statusMessage)
                    .font(.callout.bold())
                    .foregroundStyle(.green)
                    .textSelection(.enabled)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.callout.bold())
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nummernbestand")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(api.adminParticipants.allowed.count) Nummern freigegeben")
                            .foregroundStyle(SecretMatchTheme.muted)
                    }
                    Spacer()
                    Text("1…N")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(SecretMatchTheme.secondary)
                }

                HStack(spacing: 10) {
                    AdminKeyboardTextField(
                        title: "Höchste Nummer",
                        text: $participantRangeMax,
                        keyboard: .number(maxDigits: 5),
                        keyboardTitle: "Nummernbereich festlegen"
                    )
                        .textFieldStyle(.plain)
                        .secretAdminInput()
                        .onChange(of: participantRangeMax) { _, value in
                            participantRangeMax = String(value.filter(\.isNumber).prefix(5))
                            participantRangeConfirmation = ""
                        }
                    Button(numbersRemovedByRange > 0 ? "Bereich verkleinern" : "Bereich ergänzen") {
                        Task { await reconcileParticipantRange() }
                    }
                    .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
                    .disabled(!isValidParticipantRange || (numbersRemovedByRange > 0 && participantRangeConfirmation != "NUMMERN ANPASSEN") || isWorking)
                }

                if let target = participantRangeTarget {
                    Text(rangePreview(target: target))
                        .font(.callout.bold())
                        .foregroundStyle(numbersRemovedByRange > 0 ? .orange : SecretMatchTheme.muted)
                }
                if numbersRemovedByRange > 0 {
                    Text("Zum Entfernen exakt NUMMERN ANPASSEN eingeben.")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    AdminKeyboardTextField(
                        title: "NUMMERN ANPASSEN",
                        text: $participantRangeConfirmation,
                        keyboard: .text(maxCharacters: 16),
                        keyboardTitle: "Änderung bestätigen",
                        forcesUppercase: true
                    )
                        .textFieldStyle(.plain)
                        .secretAdminInput()
                        .textInputAutocapitalization(.characters)
                }
                Text("Die Testnummern 901–916 bleiben bei diesem Abgleich unverändert.")
                    .font(.caption)
                    .foregroundStyle(SecretMatchTheme.muted)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

            HStack(spacing: 10) {
                AdminKeyboardTextField(
                    title: "Neue Nummer",
                    text: $newParticipantNumber,
                    keyboard: .number(maxDigits: 10),
                    keyboardTitle: "Teilnehmernummer freigeben"
                )
                    .textFieldStyle(.plain)
                    .secretAdminInput()
                Button {
                    Task { await addParticipant() }
                } label: {
                    Label("Freigeben", systemImage: "person.badge.plus")
                }
                .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
                .disabled(!isValidNewParticipantNumber || isWorking)
            }

            AdminKeyboardTextField(
                title: "Nummer suchen",
                text: $participantSearch,
                keyboard: .number(maxDigits: 10),
                keyboardTitle: "Teilnehmer suchen"
            )
                .textFieldStyle(.plain)
                .secretAdminInput(highlighted: !participantSearch.isEmpty)

            if filteredParticipants.isEmpty {
                Text("Keine passende Nummer gefunden.")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                ForEach(filteredParticipants.prefix(24), id: \.self) { number in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(number.displayEventNumber)
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(.white)
                            Text("PIN \(api.adminParticipants.pins[number] ?? "–")")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(SecretMatchTheme.secondary)
                            if activeNumbers.contains(number) {
                                Text("LIVE")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            genderBadge(for: number)
                        }

                        HStack(spacing: 14) {
                            if activeNumbers.contains(number) {
                                Button("Abmelden") { Task { await logout(number) } }
                            }

                            genderMenu(for: number)
                            Menu {
                                Button("PIN manuell ändern") {
                                    pinDraft = api.adminParticipants.pins[number] ?? ""
                                    pinEditorNumber = number
                                }
                                Button("PIN zurücksetzen", role: .destructive) {
                                    confirmation = .resetPIN(number)
                                }
                            } label: {
                                Label("PIN verwalten", systemImage: "key.fill")
                            }
                            .disabled(isWorking)

                            Spacer()

                            Button("Sperren", role: .destructive) {
                                confirmation = .blockParticipant(number)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                }
                if filteredParticipants.count > 24 {
                    Text("\(filteredParticipants.count - 24) weitere – Suche zum Eingrenzen verwenden.")
                        .font(.caption)
                        .foregroundStyle(SecretMatchTheme.muted)
                }
            }
        }
        .secretCard(padding: 20)
    }

    private var topPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🏆 Top-16-Vorschau")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(api.adminDashboard?.topPeople?.count ?? 0) / 16")
                    .foregroundStyle(SecretMatchTheme.secondary)
            }
            Text("Genau diese Nummern erscheinen im Top-16-Modus auf dem Billboard.")
                .foregroundStyle(SecretMatchTheme.muted)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                ForEach(Array((api.adminDashboard?.topPeople ?? []).enumerated()), id: \.offset) { index, person in
                    HStack {
                        Text("\(index + 1).  \(person.number.displayEventNumber)")
                        Spacer(minLength: 4)
                        Text(person.genderSymbol)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(SecretMatchTheme.secondary)
                            .accessibilityLabel(person.genderSymbol == "–" ? "Keine Angabe" : "Geschlecht angegeben")
                    }
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(SecretMatchTheme.primary.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                }
            }
            if api.adminDashboard?.topPeople?.isEmpty != false {
                Text("Noch keine Top-16-Daten vorhanden.")
                    .foregroundStyle(SecretMatchTheme.muted)
            }
        }
        .secretCard(padding: 20)
    }

    private var deviceStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔋 iPads verwalten")
                .font(.title2.bold())
                .foregroundStyle(.white)
            if (api.adminDashboard?.devices ?? []).isEmpty {
                Text("Für dieses Event wurde noch kein iPad-Heartbeat empfangen.")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                ForEach(api.adminDashboard?.devices ?? []) { device in
                    HStack(spacing: 12) {
                        SecretBinaryStatusIcon(isPositive: device.isOnline, size: 17)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name ?? "iPad")
                                .font(.title3.bold().monospacedDigit())
                            Text(device.number.isEmpty ? "Keine Nummer angemeldet" : "Nummer \(device.number.displayEventNumber)")
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(SecretMatchTheme.muted)
                            Text(device.isOnline ? "Online" : "Offline · zuletzt \(device.lastSeenDescription)")
                                .font(.caption.bold())
                                .foregroundStyle(device.isOnline ? Color.green : Color.red)
                            if let queueCount = device.queuedSendCount, queueCount > 0 {
                                Text("\(device.queueWaitingDescription) · älteste Aktion seit \(device.oldestPendingSeconds ?? 0) Sek.")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)
                            } else if let lastSync = device.lastSuccessfulSyncAt, !lastSync.isEmpty {
                                Text("Letzter Sync: \(lastSync)")
                                    .font(.caption)
                                    .foregroundStyle(SecretMatchTheme.muted)
                            }
                        }
                        Spacer()
                        Image(systemName: device.batteryState == "charging" ? "battery.100percent.bolt" : "battery.100percent")
                        Text("\(device.batteryLevel) %").font(.title3.bold().monospacedDigit())
                        Text("v\(device.appVersion)").foregroundStyle(SecretMatchTheme.muted)
                        if let id = device.deviceID {
                            Menu {
                                Button {
                                    equipmentNameDraft = device.name ?? ""
                                    equipmentEditor = .device(id: id, currentName: device.name ?? "")
                                } label: {
                                    Label("Umbenennen", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    confirmation = .deleteDevice(id: id, name: device.name ?? "iPad")
                                } label: {
                                    Label("Aus Liste entfernen", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("\(device.name ?? "iPad") verwalten")
                            .disabled(isWorking)
                        }
                    }
                    .foregroundStyle(
                        device.batteryLevel < 20 || !device.isOnline || (device.queuedSendCount ?? 0) > 0
                            ? .red
                            : .white
                    )
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
                }
            }
            Text("iPads registrieren sich automatisch mit ihrem ersten Heartbeat. Ein aktives iPad erscheint nach dem Entfernen wieder, sobald es erneut sendet.")
                .font(.caption)
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .secretCard(padding: 20)
    }

    private var billboardStatuses: [AdminBillboardStatus] {
        if let billboards = api.adminDashboard?.billboards, !billboards.isEmpty {
            return billboards
        }
        guard let dashboard = api.adminDashboard,
              let lastSeen = dashboard.billboardLastSeen,
              lastSeen > 0 else { return [] }
        return [AdminBillboardStatus(
            billboardID: "legacy",
            name: "Billboard",
            lastSeen: lastSeen,
            online: dashboard.billboardOnline == true,
            width: dashboard.billboardWidth ?? 0,
            height: dashboard.billboardHeight ?? 0,
            mode: dashboard.billboardMode ?? "unknown"
        )]
    }

    private func billboardStatusRow(_ billboard: AdminBillboardStatus) -> some View {
        let testMode = api.adminDashboard?.topTestActive == true && billboard.online
        let color: Color = billboard.online ? (testMode ? .yellow : .green) : .red
        let statusIcon = billboard.online ? (testMode ? "testtube.2" : "checkmark.circle.fill") : "xmark.octagon.fill"
        return HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 17, height: 17)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(billboard.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(billboard.online
                     ? "Online · \(billboard.resolution) · \(billboard.modeLabel)"
                     : "Offline · \(billboard.lastSeenDescription)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }
            Spacer()
            if let url = billboardPublicURL {
                Link(destination: url) {
                    Label("Öffnen", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.bordered)
                .tint(SecretMatchTheme.secondary)
            }
            if billboard.billboardID != "legacy" {
                Menu {
                    Button {
                        equipmentNameDraft = billboard.name
                        equipmentEditor = .billboard(id: billboard.billboardID, currentName: billboard.name)
                    } label: {
                        Label("Umbenennen", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmation = .deleteBillboard(id: billboard.billboardID, name: billboard.name)
                    } label: {
                        Label("Zugang löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(billboard.name) verwalten")
                .disabled(isWorking)
            }
        }
        .padding(12)
        .background(color.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(color.opacity(0.45)))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
    }

    private var pinEditor: some View {
        NavigationStack {
            Form {
                Section("Neue zweistellige PIN") {
                    AdminKeyboardTextField(
                        title: "00",
                        text: $pinDraft,
                        keyboard: .number(maxDigits: 2),
                        keyboardTitle: "Neue zweistellige PIN",
                        isSecure: true
                    )
                        .onChange(of: pinDraft) { _, value in pinDraft = String(value.filter(\.isNumber).prefix(2)) }
                    Text("Die Nummer wird beim Speichern auf allen Geräten abgemeldet.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(SecretMatchTheme.background)
            .navigationTitle("PIN für \(pinEditorNumber?.displayEventNumber ?? "")")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { pinEditorNumber = nil } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { Task { await savePIN() } }.disabled(pinDraft.count != 2)
                }
            }
        }
    }

    private func equipmentNameEditor(_ editor: EquipmentEditor) -> some View {
        NavigationStack {
            Form {
                Section("Fester Anzeigename") {
                    AdminKeyboardTextField(
                        title: "z. B. Eingang links",
                        text: $equipmentNameDraft,
                        keyboard: .text(maxCharacters: 40),
                        keyboardTitle: "Anzeigename"
                    )
                        .onChange(of: equipmentNameDraft) { _, value in
                            equipmentNameDraft = String(value.prefix(40))
                        }
                    Text("Dieser Name erscheint im Dashboard sowie in Ausfall- und Entwarnungsmeldungen.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(SecretMatchTheme.background)
            .navigationTitle(editor.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { equipmentEditor = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { Task { await saveEquipmentName(editor) } }
                        .disabled(equipmentNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)
                }
            }
        }
    }

    private var billboardCreator: some View {
        NavigationStack {
            Form {
                Section("Neues Billboard") {
                    AdminKeyboardTextField(
                        title: "Name, z. B. Hauptsaal",
                        text: $billboardNameDraft,
                        keyboard: .text(maxCharacters: 40),
                        keyboardTitle: "Billboard benennen"
                    )
                        .onChange(of: billboardNameDraft) { _, value in
                            billboardNameDraft = String(value.prefix(40))
                            generatedBillboardURL = nil
                        }
                    Text("Der Name erscheint in Status, Warnungen und der Billboard-Verwaltung.")
                }

                Section("Zugang") {
                    Button {
                        Task { await createBillboardAccess() }
                    } label: {
                        Label("Einmal-Link erstellen", systemImage: "link.badge.plus")
                    }
                    .disabled(billboardNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)

                    if let generatedBillboardURL {
                        Link(destination: generatedBillboardURL) {
                            Label("Billboard jetzt öffnen", systemImage: "arrow.up.forward.app")
                        }
                        ShareLink(item: generatedBillboardURL) {
                            Label("Zugangslink teilen", systemImage: "square.and.arrow.up")
                        }
                        Text("Der Link meldet genau dieses Billboard ohne Passworteingabe an und muss innerhalb einer Minute einmalig geöffnet werden.")
                    } else {
                        Text("Alternativ kann am Billboard der normale Link geöffnet und das gemeinsame Billboard-Passwort eingegeben werden.")
                    }
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
            .navigationTitle("Billboard anlegen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { showBillboardCreator = false }
                }
            }
        }
    }

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🗄️ Event abschließen")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Archiviert Eventdaten, Logs und die vollständige Statistik dauerhaft. Danach startet der Live-Stand für das nächste Event bei null; Teilnehmer-PINs werden zurückgesetzt, freigegebene Nummern und Einstellungen bleiben erhalten.")
                .foregroundStyle(SecretMatchTheme.muted)
            Button("Event-Archiv öffnen", role: .destructive) {
                resetConfirmation = ""
                archiveName = ""
                showResetAssistant = true
            }
            .foregroundStyle(.red)
        }
        .secretCard(padding: 20)
    }

    private var resetAssistant: some View {
        NavigationStack {
            Form {
                Section("Der Assistent führt diese Schritte aus") {
                    Label("Benanntes Archiv des aktuellen Events erstellen", systemImage: "archivebox")
                    Label("Daten, Logs und vollständige Statistik sichern", systemImage: "chart.bar.xaxis")
                    Label("Live-Stand für das nächste Event auf null setzen", systemImage: "arrow.counterclockwise")
                    Label("Teilnehmer-PINs für die neue Selbstvergabe löschen", systemImage: "key.slash")
                    Label("Teilnehmer- und Billboard-Sessions beenden", systemImage: "person.crop.circle.badge.xmark")
                    Label("Top-16-Testmodus zurücksetzen", systemImage: "rectangle.on.rectangle.slash")
                }
                Section("Eventname") {
                    AdminKeyboardTextField(
                        title: "z. B. Match&Play September 2026",
                        text: $archiveName,
                        keyboard: .text(maxCharacters: 120),
                        keyboardTitle: "Event benennen"
                    )
                }
                Section("Sicherheitsbestätigung") {
                    Text("Zum Ausführen exakt EVENT ABSCHLIESSEN eingeben.")
                    AdminKeyboardTextField(
                        title: "EVENT ABSCHLIESSEN",
                        text: $resetConfirmation,
                        keyboard: .text(maxCharacters: 18),
                        keyboardTitle: "Eventabschluss bestätigen",
                        forcesUppercase: true
                    )
                        .textInputAutocapitalization(.characters)
                    Button("Event abschließen und archivieren", role: .destructive) {
                        Task { await performReset() }
                    }
                    .disabled(resetConfirmation != "EVENT ABSCHLIESSEN" || archiveName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)
                }
                Section("Rückblick") {
                    Text("Alle abgeschlossenen Events findest du anschließend unter Statistik und kannst dort ihre Kennzahlen rückwirkend ansehen und exportieren.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(SecretMatchTheme.background)
            .navigationTitle("Event-Archiv")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { showResetAssistant = false }
                }
            }
        }
    }

    private var systemStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚙️ Systemstatus")
                .font(.title2.bold())
                .foregroundStyle(.white)
            statusRow("API", api.adminDashboard?.apiOK == true ? "Online" : "Nicht erreichbar",
                      good: api.adminDashboard?.apiOK == true)
            statusRow("WordPress-Plugin", api.adminDashboard?.pluginVersion ?? "–")
            statusRow("App-Version", appVersion)
            statusRow("Telegram", api.adminDashboard?.telegramConfigured == true ? "Konfiguriert" : "Nicht konfiguriert",
                      good: api.adminDashboard?.telegramConfigured == true)
            statusRow("Admin-App-Warnungen", api.adminDashboard?.apnsConfigured == true
                      ? "Konfiguriert · \(api.adminDashboard?.adminPushDevices ?? 0) Gerät(e)"
                      : "APNs nicht konfiguriert",
                      good: api.adminDashboard?.apnsConfigured == true)
            if api.adminDashboard?.apnsConfigured != true,
               let diagnostics = api.adminDashboard?.apnsDiagnostics {
                Divider().overlay(SecretMatchTheme.muted.opacity(0.35))
                Text("APNs-Diagnose")
                    .font(.headline)
                    .foregroundStyle(.white)
                statusRow("Key-ID", diagnostics.keyIDValid ? "Gültig" : "Fehlt oder ungültig",
                          good: diagnostics.keyIDValid)
                statusRow("Team-ID", diagnostics.teamIDValid ? "Gültig" : "Fehlt oder ungültig",
                          good: diagnostics.teamIDValid)
                statusRow("Topic", diagnostics.topicValid ? "Gültig" : "Ungültig",
                          good: diagnostics.topicValid)
                statusRow("Key-Quelle", diagnostics.keySourceDescription,
                          good: diagnostics.privateKeyConfigured)
                statusRow("Key geladen", diagnostics.privateKeyReadable ? "Lesbar" : "Nicht lesbar",
                          good: diagnostics.privateKeyReadable)
                statusRow("Key geprüft", diagnostics.privateKeyValid ? "Gültig" : "Ungültig",
                          good: diagnostics.privateKeyValid)
                statusRow("OpenSSL", diagnostics.opensslAvailable ? "Verfügbar" : "Fehlt",
                          good: diagnostics.opensslAvailable)
                statusRow("cURL", diagnostics.curlAvailable ? "Verfügbar" : "Fehlt",
                          good: diagnostics.curlAvailable)
                statusRow("cURL HTTP/2", diagnostics.curlHTTP2 ? "Verfügbar" : "Fehlt",
                          good: diagnostics.curlHTTP2)
            }
            statusRow("Billboard-Sessions", "\(api.adminDashboard?.billboardSessions ?? 0)")
            statusRow("WordPress-Zeit", api.adminDashboard?.wordpressTime ?? "–")
            statusRow("Letzte Aktivität", api.adminDashboard?.latestActivity.isEmpty == false
                      ? api.adminDashboard!.latestActivity : "Noch keine")
            if let statusMessage {
                Text(statusMessage).foregroundStyle(.green).font(.callout.bold())
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.callout.bold())
            }
        }
        .secretCard(padding: 20)
    }

    private var adminAccess: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("🔐 Admin-Zugänge")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Getrennte Passwörter für Eventleitung, Technik und weitere Administratoren.")
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            HStack(spacing: 10) {
                SecretBinaryStatusIcon(isPositive: api.adminStandardCredentialActive)
                Text("Bisheriger Standardzugang")
                    .foregroundStyle(.white)
                Spacer()
                Text(api.adminStandardCredentialActive ? "Aktiv" : "Nicht eingerichtet")
                    .font(.callout.bold())
                    .foregroundStyle(api.adminStandardCredentialActive ? .green : SecretMatchTheme.muted)
            }
            .padding(12)
            .background(SecretMatchTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

            if api.adminCredentials.isEmpty {
                Label("Noch keine benannten Zugänge", systemImage: "person.badge.key")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(api.adminCredentials.enumerated()), id: \.element.id) { index, credential in
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.title3)
                                .foregroundStyle(SecretMatchTheme.secondary)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(credential.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Angelegt: \(credential.createdAtDescription)")
                                    .font(.caption)
                                    .foregroundStyle(SecretMatchTheme.muted)
                            }

                            Spacer(minLength: 10)

                            Button(role: .destructive) {
                                confirmation = .deleteAdminCredential(id: credential.id, name: credential.name)
                            } label: {
                                Label("Widerrufen", systemImage: "trash")
                                    .font(.callout.bold())
                            }
                            .buttonStyle(.bordered)
                            .tint(SecretMatchTheme.danger)
                            .disabled(isWorking)
                        }
                        .padding(.vertical, 12)

                        if index < api.adminCredentials.count - 1 {
                            Divider().overlay(SecretMatchTheme.border)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
            }

            Divider().overlay(SecretMatchTheme.border)

            Text("Neuen Zugang anlegen")
                .font(.headline)
                .foregroundStyle(.white)

            AdminKeyboardTextField(
                title: "Name, z. B. Eventleitung",
                text: $adminCredentialName,
                keyboard: .text(maxCharacters: 60),
                keyboardTitle: "Name des Admin-Zugangs"
            )
            .secretAdminInput(highlighted: !adminCredentialName.isEmpty)

            AdminKeyboardTextField(
                title: "Passwort (mindestens 4 Zeichen)",
                text: $adminCredentialPassword,
                keyboard: .text(maxCharacters: 128),
                keyboardTitle: "Admin-Passwort festlegen",
                isSecure: true
            )
            .textContentType(.newPassword)
            .secretAdminInput(highlighted: !adminCredentialPassword.isEmpty)

            AdminKeyboardTextField(
                title: "Passwort wiederholen",
                text: $adminCredentialConfirmation,
                keyboard: .text(maxCharacters: 128),
                keyboardTitle: "Admin-Passwort wiederholen",
                isSecure: true,
                doneLabel: "Zugang anlegen",
                onSubmit: createAdminCredential
            )
            .textContentType(.newPassword)
            .secretAdminInput(highlighted: !adminCredentialConfirmation.isEmpty)

            if !adminCredentialConfirmation.isEmpty,
               adminCredentialPassword != adminCredentialConfirmation {
                Label("Die Passwörter stimmen noch nicht überein.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(SecretMatchTheme.danger)
            }

            Button(action: createAdminCredential) {
                Label("Admin-Zugang anlegen", systemImage: "person.badge.plus")
            }
            .buttonStyle(SecretPrimaryButtonStyle(minHeight: 56))
            .disabled(!canCreateAdminCredential || isWorking)
            .opacity(canCreateAdminCredential ? 1 : 0.55)

            Text("Beim Widerrufen werden die mit diesem Zugang angemeldeten Sitzungen sofort beendet. Passwörter werden nicht angezeigt oder protokolliert.")
                .font(.caption)
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .secretCard(padding: 20)
    }

    private var filteredParticipants: [String] {
        api.adminParticipants.allowed
            .filter {
                participantSearch.isEmpty
                    || $0.localizedCaseInsensitiveContains(participantSearch)
                    || $0.displayEventNumber.localizedCaseInsensitiveContains(participantSearch)
            }
            .sorted { ($0.localizedStandardCompare($1)) == .orderedAscending }
    }

    private var participantRangeTarget: Int? {
        guard let value = Int(participantRangeMax), (1...10_000).contains(value) else { return nil }
        return value
    }

    private var isValidParticipantRange: Bool {
        participantRangeTarget != nil
    }

    private var canCreateAdminCredential: Bool {
        let name = adminCredentialName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty
            && name.count <= 60
            && (4...128).contains(adminCredentialPassword.count)
            && adminCredentialPassword == adminCredentialConfirmation
            && api.adminCredentials.count < 20
    }

    private var dummyNumbers: Set<String> {
        Set((901...916).map(String.init))
    }

    private var numbersRemovedByRange: Int {
        guard let target = participantRangeTarget else { return 0 }
        return api.adminParticipants.allowed.filter { number in
            !dummyNumbers.contains(number) && (Int(number) ?? Int.max) > target
        }.count
    }

    private func rangePreview(target: Int) -> String {
        let allowed = Set(api.adminParticipants.allowed)
        let additions = (1...target).lazy.map(String.init).filter { !allowed.contains($0) }.count
        if numbersRemovedByRange > 0 {
            return "\(additions) hinzufügen · \(numbersRemovedByRange) entfernen (inklusive Profil, PIN und Sitzung)"
        }
        return additions > 0 ? "\(additions) fehlende Nummern werden ergänzt." : "Der Bereich 1…\(target) ist bereits vollständig."
    }

    private var activeNumbers: Set<String> {
        Set(api.adminParticipants.active.map(\.number))
    }

    private var profilesByNumber: [String: AdminParticipantProfile] {
        Dictionary(uniqueKeysWithValues: api.adminParticipants.profiles.map { ($0.number, $0) })
    }

    private var isValidNewParticipantNumber: Bool {
        let cleaned = newParticipantNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        return !cleaned.isEmpty
            && cleaned.count <= 10
            && cleaned.allSatisfy(\.isNumber)
            && cleaned.normalizedEventNumber != "0"
    }

    private var confirmationText: String {
        switch confirmation {
        case .createDummy: return "Die Testnummern 901–916 samt Beispieldaten anlegen?"
        case .deleteDummy: return "Alle erzeugten Testdaten wieder löschen?"
        case .revokeBillboard: return "Alle aktuell geöffneten Billboard-Zugänge ungültig machen?"
        case .resetGender(let number):
            return "Das Gender von \(number.displayEventNumber) zurücksetzen und alle Sitzungen dieser Nummer abmelden? Beim nächsten Login wird die Auswahl erneut angezeigt."
        case .resetPIN(let number):
            return "Die PIN von \(number.displayEventNumber) zurücksetzen? Die bisherige PIN wird sofort ungültig, alle Sitzungen werden beendet und beim nächsten Login legt der Teilnehmer selbst eine neue PIN fest."
        case .blockParticipant(let number):
            return "\(number.displayEventNumber) sperren, das Profil löschen und alle Sitzungen dieser Nummer abmelden?"
        case .deleteDevice(_, let name):
            return "\(name) aus der iPad-Liste entfernen und den Gerätezugang widerrufen? Ist dort noch eine Nummer angemeldet, registriert es sich beim nächsten Heartbeat, sonst beim nächsten Teilnehmer-Login erneut."
        case .deleteBillboard(_, let name):
            return "Den Zugang für \(name) löschen? Die laufende Sitzung wird sofort ungültig und das Billboard muss danach neu angemeldet werden."
        case .deleteAdminCredential(_, let name):
            return "Den Admin-Zugang „\(name)“ widerrufen? Alle damit angemeldeten Sitzungen werden sofort beendet. Falls du gerade diesen Zugang verwendest, kehrst du anschließend zum Admin-Login zurück."
        case nil: return ""
        }
    }

    private var billboardPublicURL: URL? {
        guard let value = api.adminDashboard?.billboardURL,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else { return nil }
        return url
    }

    @ViewBuilder
    private var operationFeedback: some View {
        if let statusMessage {
            Label(statusMessage, systemImage: "checkmark.circle.fill")
                .font(.callout.bold())
                .foregroundStyle(.green)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.callout.bold())
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
        return "\(version).\(build)"
    }

    private func metric(_ emoji: String, _ title: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 32))
            VStack(alignment: .leading) {
                Text("\(value)").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text(title).foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer()
        }
        .padding(18)
        .background(color.opacity(0.14))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(color.opacity(0.55)))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
    }

    private func controlCard<Content: View>(title: String, subtitle: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title2.bold()).foregroundStyle(.white)
            Text(subtitle).foregroundStyle(SecretMatchTheme.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(padding: 20)
    }

    private func statusRow(_ label: String, _ value: String, good: Bool? = nil) -> some View {
        HStack {
            Text(label).foregroundStyle(SecretMatchTheme.muted)
            Spacer()
            if let good {
                SecretBinaryStatusIcon(isPositive: good, size: 14)
            }
            Text(value).foregroundStyle(.white).multilineTextAlignment(.trailing)
        }
    }

    @MainActor
    private func refresh(showErrors: Bool = true) async {
        isWorking = true
        do {
            try await api.refreshAdminControlData()
            rotationSeconds = api.adminDashboard?.billboardRotationSeconds ?? rotationSeconds
            if participantRangeMax.isEmpty {
                let regularNumbers = api.adminParticipants.allowed
                    .filter { !dummyNumbers.contains($0) }
                    .compactMap(Int.init)
                participantRangeMax = String(regularNumbers.max() ?? max(1, api.adminParticipants.allowed.count))
            }
            if !isWorking || quickMessagesText.isEmpty {
                quickMessagesText = (api.adminDashboard?.matchMessageOptions ?? []).joined(separator: "\n")
            }
            try? await api.loadAdminCredentials()
            errorMessage = nil
        } catch {
            if showErrors { errorMessage = "Aktualisierung fehlgeschlagen." }
        }
        try? await api.loadAdminActions()
        try? await api.loadAdminMatches()
        isWorking = false
    }

    @MainActor
    private func billboard(_ action: String, seconds: Int? = nil) async {
        await operation("Billboard aktualisiert.") {
            try await api.controlBillboard(action: action, seconds: seconds)
        }
    }

    @MainActor
    private func createBillboardAccess() async {
        isWorking = true
        do {
            generatedBillboardURL = try await api.createBillboardAccessURL(name: billboardNameDraft)
            statusMessage = "Zugang für \(billboardNameDraft) wurde erstellt."
            errorMessage = nil
            try? await api.loadAdminDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    @MainActor
    private func saveEquipmentName(_ editor: EquipmentEditor) async {
        let name = equipmentNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        await operation("Name wurde gespeichert.") {
            switch editor {
            case .device(let id, _):
                try await api.updateAdminDeviceName(id: id, name: name)
            case .billboard(let id, _):
                try await api.updateAdminBillboardName(id: id, name: name)
            }
        }
        if errorMessage == nil { equipmentEditor = nil }
    }

    private func createAdminCredential() {
        guard canCreateAdminCredential, !isWorking else { return }
        let name = adminCredentialName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await operation("Admin-Zugang „\(name)“ wurde angelegt.") {
                try await api.createAdminCredential(name: name, password: adminCredentialPassword)
            }
            if errorMessage == nil {
                adminCredentialName = ""
                adminCredentialPassword = ""
                adminCredentialConfirmation = ""
            }
        }
    }

    @MainActor
    private func logout(_ number: String) async {
        await operation("\(number.displayEventNumber) wurde abgemeldet.") { try await api.logoutParticipant(number: number) }
    }

    @MainActor
    private func block(_ number: String) async {
        await operation("\(number.displayEventNumber) wurde gesperrt.") { try await api.blockParticipant(number: number) }
    }

    @MainActor
    private func addParticipant() async {
        let number = newParticipantNumber.normalizedEventNumber
        await operation("\(number.displayEventNumber) wurde freigegeben.") {
            try await api.createAdminParticipant(number: number)
        }
        if errorMessage == nil {
            newParticipantNumber = ""
        }
    }

    @MainActor
    private func reconcileParticipantRange() async {
        guard let target = participantRangeTarget else { return }
        isWorking = true
        do {
            let result = try await api.reconcileParticipantRange(
                targetMax: target,
                confirmation: participantRangeConfirmation
            )
            statusMessage = "Nummernbereich 1…\(result.targetMax): \(result.addedCount) ergänzt, \(result.removedCount) entfernt."
            errorMessage = nil
            participantRangeConfirmation = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    @MainActor
    private func setGender(_ gender: ParticipantGender, for number: String) async {
        await operation("Gender für \(number.displayEventNumber) wurde auf \(gender.title) gesetzt. Die Nummer wurde abgemeldet.") {
            try await api.updateParticipantGender(number: number, gender: gender)
        }
    }

    @MainActor
    private func savePIN() async {
        guard let number = pinEditorNumber, pinDraft.count == 2 else { return }
        await operation("PIN für \(number.displayEventNumber) geändert; Sitzungen wurden beendet.") {
            try await api.updateParticipantPIN(number: number, pin: pinDraft)
        }
        if errorMessage == nil { pinEditorNumber = nil }
    }

    @MainActor
    private func saveQuickMessages() async {
        guard !isWorking else { return }
        let options = quickMessagesText.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard options.count <= 8 else {
            quickMessagesSaveState = .failed("Bitte maximal acht Schnelltexte eingeben.")
            return
        }
        guard options.allSatisfy({ $0.count <= 80 }) else {
            quickMessagesSaveState = .failed("Ein Schnelltext darf höchstens 80 Zeichen haben.")
            return
        }
        quickMessagesSaveState = .saving
        isWorking = true
        do {
            try await api.updateMatchMessageOptions(options)
            statusMessage = "Schnelltexte gespeichert."
            errorMessage = nil
            quickMessagesSaveState = .saved
        } catch {
            let message = "Schnelltexte konnten nicht gespeichert werden."
            errorMessage = message
            quickMessagesSaveState = .failed(message)
        }
        isWorking = false
    }

    @MainActor
    private func runConfirmation(_ selected: Confirmation?) async {
        switch selected {
        case .createDummy:
            await operation("Testdaten wurden angelegt.") { try await api.manageDummyData(action: "create") }
        case .deleteDummy:
            await operation("Testdaten wurden gelöscht.") { try await api.manageDummyData(action: "delete") }
        case .revokeBillboard:
            await operation("Billboard-Zugänge wurden abgemeldet.") {
                try await api.controlBillboard(action: "revoke_access")
            }
        case .resetGender(let number):
            await operation("Gender für \(number.displayEventNumber) wurde zurückgesetzt. Die Nummer wurde abgemeldet.") {
                try await api.updateParticipantGender(number: number, gender: nil)
            }
        case .resetPIN(let number):
            await resetPIN(for: number)
        case .blockParticipant(let number):
            await block(number)
        case .deleteDevice(let id, let name):
            await operation("\(name) wurde aus der iPad-Liste entfernt.") {
                try await api.deleteAdminDevice(id: id)
            }
        case .deleteBillboard(let id, let name):
            await operation("Der Zugang für \(name) wurde gelöscht.") {
                try await api.deleteAdminBillboard(id: id)
            }
        case .deleteAdminCredential(let id, let name):
            await operation("Admin-Zugang „\(name)“ wurde widerrufen.") {
                _ = try await api.deleteAdminCredential(id: id)
            }
        case nil:
            break
        }
    }

    @MainActor
    private func resetPIN(for number: String) async {
        isWorking = true
        do {
            try await api.resetParticipantPIN(number: number)
            statusMessage = "PIN für \(number.displayEventNumber) zurückgesetzt. Beim nächsten Login wird eine neue PIN festgelegt."
            errorMessage = nil
        } catch {
            errorMessage = "PIN-Reset fehlgeschlagen: \(error.localizedDescription)"
        }
        isWorking = false
    }

    @MainActor
    private func operation(_ success: String, work: () async throws -> Void) async {
        isWorking = true
        do {
            try await work()
            statusMessage = success
            errorMessage = nil
        } catch {
            errorMessage = "Aktion fehlgeschlagen: \(error.localizedDescription)"
        }
        isWorking = false
    }

    @MainActor
    private func performReset() async {
        isWorking = true
        do {
            let result = try await api.resetEvent(confirmation: resetConfirmation, name: archiveName)
            let name = result.archiveName ?? archiveName
            statusMessage = "„\(name)“ wurde archiviert. Der Live-Stand ist wieder leer und alle Teilnehmer-PINs wurden für die neue Selbstvergabe zurückgesetzt: \(result.deleted.matches) Matches, \(result.deleted.requests) Anfragen, \(result.deleted.actions) Aktionen und \(result.deleted.eventLog ?? 0) Logs abgeschlossen."
            errorMessage = nil
            showResetAssistant = false
        } catch {
            errorMessage = "Event konnte nicht archiviert werden: \(error.localizedDescription)"
        }
        isWorking = false
    }

    @ViewBuilder
    private func genderBadge(for number: String) -> some View {
        if let gender = profilesByNumber[number]?.gender {
            Text("\(gender.symbol) \(gender.title)")
                .font(.caption.bold())
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(SecretMatchTheme.secondary.opacity(0.18))
                .foregroundStyle(SecretMatchTheme.secondary)
                .clipShape(Capsule())
        } else {
            Text("Gender offen")
                .font(.caption.bold())
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .foregroundStyle(SecretMatchTheme.muted)
                .clipShape(Capsule())
        }
    }

    private func genderMenu(for number: String) -> some View {
        Menu {
            ForEach(ParticipantGender.allCases.filter { $0 == .female || $0 == .male }) { gender in
                Button("\(gender.symbol) \(gender.title)") {
                    Task { await setGender(gender, for: number) }
                }
            }
            if profilesByNumber[number] != nil {
                Divider()
                Button("Gender zurücksetzen", role: .destructive) {
                    confirmation = .resetGender(number)
                }
            }
        } label: {
            Label("Gender", systemImage: "person.2")
        }
        .disabled(isWorking)
    }
}

private struct LiveFeedEntry: Identifiable {
    let id: String
    let createdAt: String
    let emoji: String
    let title: String
    let detail: String
    let color: Color
}
