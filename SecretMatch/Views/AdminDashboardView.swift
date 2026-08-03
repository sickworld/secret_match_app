import SwiftUI

enum AdminDashboardSection {
    case overview, liveFeed, actions, matches, controls, participants, system
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
    @State private var rotationSeconds = 6
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var confirmation: Confirmation?
    @State private var showResetAssistant = false
    @State private var resetConfirmation = ""

    private enum Confirmation: String, Identifiable {
        case createDummy, deleteDummy, revokeBillboard
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
#if ADMIN_APP
                adminAppContent
#else
                header
                liveStatus
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
    }

#if ADMIN_APP
    @ViewBuilder
    private var adminAppContent: some View {
        switch dashboardSection {
        case .overview:
            header
            liveStatus
            metrics
            topPreview
        case .controls:
            sectionHeading("Eventsteuerung", subtitle: "Billboard und Testdaten verwalten")
            controls
            topPreview
        case .participants:
            sectionHeading("Teilnehmer", subtitle: "Nummern suchen, abmelden oder sperren")
            participants
        case .system:
            sectionHeading("System & Reset", subtitle: "Systemzustand prüfen und Events vorbereiten")
            systemStatus
            resetCard
        case .liveFeed, .actions, .matches:
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
        let online = api.adminDashboard?.billboardOnline == true
        let testMode = api.adminDashboard?.topTestActive == true
        let color: Color = online ? (testMode ? .yellow : .green) : .red
        return HStack(spacing: 14) {
            Circle().fill(color).frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 3) {
                Text(online ? (testMode ? "TESTMODUS LÄUFT" : "EVENT LÄUFT") : "BILLBOARD OFFLINE")
                    .font(.headline.bold())
                    .foregroundStyle(color)
                Text(online
                     ? "TV verbunden · \(billboardResolution) · \(billboardModeLabel)"
                     : "Seit mindestens 25 Sekunden kein Signal vom TV.")
                    .foregroundStyle(.white.opacity(0.82))
            }
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.13))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.75), lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                            Text(entry.createdAt)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.48))
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
            controlCard(title: "📺 Billboard", subtitle: "TV-Ansicht und Top-16-Modus") {
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
        }
    }

    private var participants: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("👤 Teilnehmerverwaltung")
                .font(.title2.bold())
                .foregroundStyle(.white)
            TextField("Nummer suchen", text: $participantSearch)
                .textFieldStyle(.roundedBorder)

            if filteredParticipants.isEmpty {
                Text("Keine passende Nummer gefunden.")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                ForEach(filteredParticipants.prefix(24), id: \.self) { number in
                    HStack {
                        Text(number.displayEventNumber)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.white)
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
                        if activeNumbers.contains(number) {
                            Button("Abmelden") { Task { await logout(number) } }
                        }
                        Button("Sperren", role: .destructive) { Task { await block(number) } }
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

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🚨 Neues Event vorbereiten")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Erstellt zuerst ein Backup, leert Matches, Anfragen und Aktionen, beendet Sessions und setzt das Billboard zurück. Freigegebene Nummern und Einstellungen bleiben erhalten.")
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
                    Label("Matches, Anfragen und Aktionen leeren", systemImage: "trash")
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

    private var activeNumbers: Set<String> {
        Set(api.adminParticipants.active.map(\.number))
    }

    private var confirmationText: String {
        switch confirmation {
        case .createDummy: return "Die Testnummern 901–916 samt Beispieldaten anlegen?"
        case .deleteDummy: return "Alle erzeugten Testdaten wieder löschen?"
        case .revokeBillboard: return "Alle aktuell geöffneten Billboard-Zugänge ungültig machen?"
        case nil: return ""
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
        return "\(version).\(build)"
    }

    private var billboardResolution: String {
        let width = api.adminDashboard?.billboardWidth ?? 0
        let height = api.adminDashboard?.billboardHeight ?? 0
        return width > 0 && height > 0 ? "\(width) × \(height)" : "Auflösung unbekannt"
    }

    private var billboardModeLabel: String {
        api.adminDashboard?.billboardMode == "top" ? "Top 16" : "Normalbetrieb"
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
    private func logout(_ number: String) async {
        await operation("\(number.displayEventNumber) wurde abgemeldet.") { try await api.logoutParticipant(number: number) }
    }

    @MainActor
    private func block(_ number: String) async {
        await operation("\(number.displayEventNumber) wurde gesperrt.") { try await api.blockParticipant(number: number) }
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
        case nil:
            break
        }
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
            statusMessage = "Event zurückgesetzt. Backup: \(result.backupCreatedAt) · \(result.deleted.matches) Matches und \(result.deleted.actions) Aktionen entfernt."
            errorMessage = nil
            showResetAssistant = false
        } catch {
            errorMessage = "Event-Reset fehlgeschlagen: \(error.localizedDescription)"
        }
        isWorking = false
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
