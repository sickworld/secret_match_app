import SwiftUI

enum AdminDashboardSection {
    case overview, readiness, diagnostics, liveFeed, eventLog, statistics, actions, requests, matches, feedback, controls, participants, system
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

    @State private var participantSearch = ""
    @State private var newParticipantNumber = ""
    @State private var rotationSeconds = 6
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var confirmation: Confirmation?
    @State private var showResetAssistant = false
    @State private var resetConfirmation = ""
    @State private var quickMessagesText = ""
    @State private var quickMessagesSaveState = QuickMessagesSaveState.idle
    @State private var pinEditorNumber: String?
    @State private var pinDraft = ""
    @State private var equipmentEditor: EquipmentEditor?
    @State private var equipmentNameDraft = ""
    @State private var billboardNameDraft = ""
    @State private var generatedBillboardURL: URL?
    @State private var showBillboardCreator = false
    @State private var participantRangeMax = ""
    @State private var participantRangeConfirmation = ""

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
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
#if ADMIN_APP
                operationFeedback
                adminAppContent
#else
                header
                liveStatus
                deviceStatus
                metrics
                liveFeed
                controls
                topPreview
                participants
                systemStatus
                resetCard
#endif
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
    }

#if ADMIN_APP
    @ViewBuilder
    private var adminAppContent: some View {
        switch dashboardSection {
        case .overview:
            header
            liveStatus
            deviceStatus
            metrics
            topPreview
        case .controls:
            sectionHeading("Eventsteuerung", subtitle: "Billboard und Testdaten verwalten")
            controls
            topPreview
        case .participants:
            sectionHeading("Teilnehmer", subtitle: "Nummern freigeben, Gender verwalten, abmelden oder sperren")
            participants
        case .system:
            sectionHeading("System & Reset", subtitle: "Systemzustand prüfen und Events vorbereiten")
            systemStatus
            deviceStatus
            resetCard
        case .readiness, .diagnostics, .liveFeed, .eventLog, .statistics, .actions, .requests, .matches, .feedback:
            EmptyView()
        }
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
#endif

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
        .secretCard(cornerRadius: 20, padding: 20)
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
                Text("Event steuern, Teilnehmer verwalten und den Systemzustand prüfen.")
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))

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
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(entry.color.opacity(0.32)))
                }
            }
        }
        .secretCard(cornerRadius: 20, padding: 20)
    }

    private var liveFeedEntries: [LiveFeedEntry] {
        let actions = api.adminActions.map { action in
            LiveFeedEntry(
                id: "action-\(action.id)",
                createdAt: action.created_at,
                emoji: actionEmoji(action.action_type),
                title: actionTitle(action.action_type),
                detail: "\(action.sender_number.displayEventNumber) → \(action.receiver_number.displayEventNumber)",
                color: actionColor(action.action_type)
            )
        }
        let matches = api.adminMatches.map { match in
            let isHot = match.type == "hot" || match.type == "F-"
            return LiveFeedEntry(
                id: "match-\(match.id)",
                createdAt: match.created_at,
                emoji: isHot ? "🍆" : "❤️",
                title: isHot ? "Fuck-Match entstanden" : "Hot-Match entstanden",
                detail: "\(match.number_a.displayEventNumber) ↔ \(match.number_b.displayEventNumber)",
                color: isHot ? Color(hex: "#8E63D2") : Color(hex: "#E83E8C")
            )
        }
        return (actions + matches).sorted { $0.createdAt > $1.createdAt }
    }

    private func actionEmoji(_ type: String) -> String {
        switch type {
        case "normal": return "❤️"
        case "hot": return "🍆"
        case "bjob": return "👄"
        case "hjob": return "✋"
        case "ljob": return "👅"
        default: return "💌"
        }
    }

    private func actionTitle(_ type: String) -> String {
        switch type {
        case "normal": return "Hot-Aktion gesendet"
        case "hot": return "Fuck-Aktion gesendet"
        case "bjob": return "Blow-Job-Aktion gesendet"
        case "hjob": return "Hand-Job-Aktion gesendet"
        case "ljob": return "Lick-Job-Aktion gesendet"
        default: return "Aktion gesendet"
        }
    }

    private func actionColor(_ type: String) -> Color {
        switch type {
        case "normal": return Color(hex: "#E83E8C")
        case "hot": return Color(hex: "#8E63D2")
        case "bjob": return Color(hex: "#3E9ED6")
        case "hjob": return Color(hex: "#E6923E")
        case "ljob": return Color(hex: "#D65C8D")
        default: return SecretMatchTheme.primary
        }
    }

    private var controls: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 16)], spacing: 16) {
            controlCard(title: "📺 Billboard-Steuerung", subtitle: "Darstellung und globale Steuerung aller Bildschirme") {
#if !ADMIN_APP
                Button("Vollbild öffnen") { showBillboard = true }
                    .buttonStyle(SecretPrimaryButtonStyle())
#endif

                HStack {
                    Button("Top 16 testen") { Task { await billboard("start_top_test") } }
                    Button("Normalbetrieb") { Task { await billboard("normal_mode") } }
                }
                .buttonStyle(SecretSecondaryButtonStyle())

                Stepper("Wechsel alle \(rotationSeconds) Sekunden", value: $rotationSeconds, in: 5...8)
                    .foregroundStyle(.white)
                Button("Intervall speichern") {
                    Task { await billboard("set_interval", seconds: rotationSeconds) }
                }
                .buttonStyle(SecretSecondaryButtonStyle())

                Button("Alle Billboard-Zugänge abmelden", role: .destructive) {
                    confirmation = .revokeBillboard
                }
                .foregroundStyle(.red)
            }

            controlCard(title: "🧪 Testdaten", subtitle: "Dummy-Nummern 901–916 und Top 16 testen") {
                Text(api.adminDashboard?.dummyDataActive == true ? "Testdaten sind aktiv." : "Momentan keine Testdaten.")
                    .foregroundStyle(api.adminDashboard?.dummyDataActive == true ? .green : SecretMatchTheme.muted)
                Button("Testdaten anlegen") { confirmation = .createDummy }
                    .buttonStyle(SecretPrimaryButtonStyle())
                Button("Testdaten löschen", role: .destructive) { confirmation = .deleteDummy }
                    .foregroundStyle(.red)
            }

            controlCard(title: "💬 Match-Schnelltexte", subtitle: "Bis zu 8 Texte, je eine Zeile") {
                TextEditor(text: $quickMessagesText)
                    .frame(minHeight: 150)
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    TextField("Höchste Nummer", text: $participantRangeMax)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
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
                    TextField("NUMMERN ANPASSEN", text: $participantRangeConfirmation)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                }
                Text("Die Testnummern 901–916 bleiben bei diesem Abgleich unverändert.")
                    .font(.caption)
                    .foregroundStyle(SecretMatchTheme.muted)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 10) {
                TextField("Neue Nummer", text: $newParticipantNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                Button {
                    Task { await addParticipant() }
                } label: {
                    Label("Freigeben", systemImage: "person.badge.plus")
                }
                .buttonStyle(SecretPrimaryButtonStyle(fullWidth: false))
                .disabled(!isValidNewParticipantNumber || isWorking)
            }

            TextField("Nummer suchen", text: $participantSearch)
                .textFieldStyle(.roundedBorder)

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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if filteredParticipants.count > 24 {
                    Text("\(filteredParticipants.count - 24) weitere – Suche zum Eingrenzen verwenden.")
                        .font(.caption)
                        .foregroundStyle(SecretMatchTheme.muted)
                }
            }
        }
        .secretCard(cornerRadius: 20, padding: 20)
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
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            if api.adminDashboard?.topPeople?.isEmpty != false {
                Text("Noch keine Top-16-Daten vorhanden.")
                    .foregroundStyle(SecretMatchTheme.muted)
            }
        }
        .secretCard(cornerRadius: 20, padding: 20)
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
                        Circle()
                            .fill(device.isOnline ? Color.green : Color.red)
                            .frame(width: 13, height: 13)
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Text("iPads registrieren sich automatisch mit ihrem ersten Heartbeat. Ein aktives iPad erscheint nach dem Entfernen wieder, sobald es erneut sendet.")
                .font(.caption)
                .foregroundStyle(SecretMatchTheme.muted)
        }
        .secretCard(cornerRadius: 20, padding: 20)
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
        return HStack(spacing: 12) {
            Circle().fill(color).frame(width: 13, height: 13)
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
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.45)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var pinEditor: some View {
        NavigationStack {
            Form {
                Section("Neue zweistellige PIN") {
                    TextField("00", text: $pinDraft)
                        .keyboardType(.numberPad)
                        .onChange(of: pinDraft) { _, value in pinDraft = String(value.filter(\.isNumber).prefix(2)) }
                    Text("Die Nummer wird beim Speichern auf allen Geräten abgemeldet.")
                }
            }
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
                    TextField("z. B. Eingang links", text: $equipmentNameDraft)
                        .onChange(of: equipmentNameDraft) { _, value in
                            equipmentNameDraft = String(value.prefix(40))
                        }
                    Text("Dieser Name erscheint im Dashboard sowie in Ausfall- und Entwarnungsmeldungen.")
                }
            }
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
                    TextField("Name, z. B. Hauptsaal", text: $billboardNameDraft)
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
            Text("🚨 Neues Event vorbereiten")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Erstellt zuerst ein Backup und eine anonyme Abschlussstatistik, leert Matches, Anfragen, Aktionen, Feedbacks und sämtliche Logs, beendet Sessions und setzt das Billboard zurück. Freigegebene Nummern und Einstellungen bleiben erhalten.")
                .foregroundStyle(SecretMatchTheme.muted)
            Button("Event-Reset-Assistent öffnen", role: .destructive) {
                resetConfirmation = ""
                showResetAssistant = true
            }
            .foregroundStyle(.red)
        }
        .secretCard(cornerRadius: 20, padding: 20)
    }

    private var resetAssistant: some View {
        NavigationStack {
            Form {
                Section("Der Assistent führt diese Schritte aus") {
                    Label("Backup des aktuellen Events erstellen", systemImage: "archivebox")
                    Label("Anonyme Abschlussstatistik sichern", systemImage: "chart.bar.xaxis")
                    Label("Matches, Anfragen, Aktionen, Feedbacks und Logs leeren", systemImage: "trash")
                    Label("Teilnehmer- und Billboard-Sessions beenden", systemImage: "person.crop.circle.badge.xmark")
                    Label("Top-16-Testmodus zurücksetzen", systemImage: "rectangle.on.rectangle.slash")
                }
                Section("Sicherheitsbestätigung") {
                    Text("Zum Ausführen exakt EVENT RESET eingeben.")
                    TextField("EVENT RESET", text: $resetConfirmation)
                        .textInputAutocapitalization(.characters)
                    Button("Backup erstellen und Event zurücksetzen", role: .destructive) {
                        Task { await performReset() }
                    }
                    .disabled(resetConfirmation != "EVENT RESET" || isWorking)
                }
            }
            .navigationTitle("Event-Reset")
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
        .secretCard(cornerRadius: 20, padding: 20)
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
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.55)))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func controlCard<Content: View>(title: String, subtitle: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title2.bold()).foregroundStyle(.white)
            Text(subtitle).foregroundStyle(SecretMatchTheme.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(cornerRadius: 20, padding: 20)
    }

    private func statusRow(_ label: String, _ value: String, good: Bool? = nil) -> some View {
        HStack {
            Text(label).foregroundStyle(SecretMatchTheme.muted)
            Spacer()
            if let good {
                Circle().fill(good ? Color.green : Color.red).frame(width: 9, height: 9)
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
            let result = try await api.resetEvent(confirmation: resetConfirmation)
            if let feedback = result.deleted.feedback {
                statusMessage = "Event zurückgesetzt. Backup: \(result.backupCreatedAt) · \(result.deleted.matches) Matches, \(result.deleted.actions) Aktionen, \(feedback) Feedbacks und \(result.deleted.eventLog ?? 0) Logs entfernt. Die anonyme Statistik bleibt erhalten."
            } else {
                statusMessage = "Event zurückgesetzt. Backup: \(result.backupCreatedAt) · \(result.deleted.matches) Matches und \(result.deleted.actions) Aktionen entfernt."
            }
            errorMessage = nil
            showResetAssistant = false
        } catch {
            errorMessage = "Event-Reset fehlgeschlagen: \(error.localizedDescription)"
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
