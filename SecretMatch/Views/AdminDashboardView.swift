import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var api: APIService
    @Binding var showBillboard: Bool

    @State private var participantSearch = ""
    @State private var rotationSeconds = 6
    @State private var isWorking = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var confirmation: Confirmation?

    private enum Confirmation: String, Identifiable {
        case createDummy, deleteDummy, revokeBillboard
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                metrics
                controls
                participants
                systemStatus
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

    private var controls: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 16)], spacing: 16) {
            controlCard(title: "📺 Billboard", subtitle: "TV-Ansicht und Top-16-Modus") {
                Button("Vollbild öffnen") { showBillboard = true }
                    .buttonStyle(SecretPrimaryButtonStyle())

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
                        Text("#\(number)")
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
            .filter { participantSearch.isEmpty || $0.localizedCaseInsensitiveContains(participantSearch) }
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
        await operation("#\(number) wurde abgemeldet.") { try await api.logoutParticipant(number: number) }
    }

    @MainActor
    private func block(_ number: String) async {
        await operation("#\(number) wurde gesperrt.") { try await api.blockParticipant(number: number) }
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
}
