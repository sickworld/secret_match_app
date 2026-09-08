import SwiftUI

struct AdminEventLogView: View {
    @EnvironmentObject private var api: APIService
    @State private var severity = ""
    @State private var category = ""
    @State private var search = ""
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var isCreatingExamples = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var actionErrorMessage: String?
    @State private var selectedEntry: AdminEventLogEntry?
    @State private var hasMore = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let statusMessage {
                    Label(statusMessage, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let actionErrorMessage {
                    Label(actionErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                incidentSummary
                filters

                if isLoading && api.adminEventLog.isEmpty {
                    ProgressView("Protokoll wird geladen …")
                        .tint(SecretMatchTheme.secondary)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 260)
                } else if let errorMessage, api.adminEventLog.isEmpty {
                    ContentUnavailableView {
                        Label("Protokoll nicht erreichbar", systemImage: "exclamationmark.triangle.fill")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Erneut versuchen") { Task { await load(reset: true) } }
                            .buttonStyle(.borderedProminent)
                            .tint(SecretMatchTheme.primary)
                    }
                    .foregroundStyle(.white)
                    .frame(minHeight: 300)
                } else if api.adminEventLog.isEmpty {
                    ContentUnavailableView(
                        "Keine Einträge",
                        systemImage: "checkmark.circle.fill",
                        description: Text("Für diese Filter wurden keine Ereignisse gefunden.")
                    )
                    .foregroundStyle(.white)
                    .frame(minHeight: 300)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(api.adminEventLog) { entry in
                            eventRow(entry)
                        }

                        if hasMore {
                            Button {
                                Task { await load(reset: false) }
                            } label: {
                                if isLoadingMore {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Ältere Einträge laden", systemImage: "arrow.down.circle")
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(SecretMatchTheme.secondary)
                            .disabled(isLoadingMore)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .background(BrandBackground())
        .task {
            await load(reset: true)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                await load(reset: true, quietly: true)
            }
        }
        .onChange(of: severity) { _, _ in Task { await load(reset: true) } }
        .onChange(of: category) { _, _ in Task { await load(reset: true) } }
        .sheet(item: $selectedEntry) { entry in
            eventDetails(entry)
                .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("BETRIEB & SICHERHEIT")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Zentrales Protokoll")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Sendewege, Geräte, Verbindungen und Admin-Änderungen an einem Ort.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            HStack(spacing: 10) {
                Button {
                    Task { await createExamples() }
                } label: {
                    if isCreatingExamples {
                        ProgressView().tint(.white)
                    } else {
                        Label("Alle Testlogs anlegen", systemImage: "wand.and.stars")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(SecretMatchTheme.primary)
                .disabled(isCreatingExamples)

                Spacer()

                ShareLink(
                    item: csvText,
                    subject: Text("Match&Play Eventprotokoll"),
                    message: Text("CSV-Export aus der Admin-App")
                ) {
                    Label("CSV exportieren", systemImage: "square.and.arrow.up")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .tint(SecretMatchTheme.secondary)
                .disabled(api.adminEventLog.isEmpty)
            }
        }
    }

    private var incidentSummary: some View {
        let devices = api.adminDashboard?.devices ?? []
        let offline = devices.filter { !$0.isOnline }.count
        let queued = devices.reduce(0) { $0 + ($1.queuedSendCount ?? 0) }
        let lowBattery = devices.filter { $0.batteryLevel < 20 }.count
        let errors = api.adminEventLog.filter { $0.severity == "error" || $0.severity == "critical" }.count

        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            summaryCard("Offline", value: offline, icon: "wifi.slash", color: offline > 0 ? .red : .green)
            summaryCard("In Queue", value: queued, icon: "tray.full.fill", color: queued > 0 ? .orange : .green)
            summaryCard("Akkuwarnungen", value: lowBattery, icon: "battery.25percent", color: lowBattery > 0 ? .orange : .green)
            summaryCard("Fehler im Filter", value: errors, icon: "exclamationmark.triangle.fill", color: errors > 0 ? .red : .green)
        }
    }

    private var filters: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField("Nummer, Request-ID oder Ereignis suchen", text: $search)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 50)
                    .background(SecretMatchTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .onSubmit { Task { await load(reset: true) } }

                Button {
                    Task { await load(reset: true) }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.headline.bold())
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(SecretMatchTheme.primary)
            }

            HStack(spacing: 12) {
                filterPicker("Schweregrad", selection: $severity, options: [
                    ("", "Alle"), ("critical", "Kritisch"), ("error", "Fehler"),
                    ("warning", "Warnung"), ("info", "Info"),
                ])
                filterPicker("Kategorie", selection: $category, options: [
                    ("", "Alle"), ("queue", "Sendequeue"), ("connectivity", "Verbindung"),
                    ("device", "Geräte"), ("security", "Login & PIN"),
                    ("interaction", "Interaktionen"), ("admin", "Admin"), ("system", "System"),
                ])
                Spacer()
                if isLoading {
                    ProgressView().tint(SecretMatchTheme.secondary)
                }
            }
        }
        .secretCard(cornerRadius: 18, padding: 14)
    }

    private func eventRow(_ entry: AdminEventLogEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: severityIcon(entry.severity))
                    .font(.title3.bold())
                    .foregroundStyle(severityColor(entry.severity))
                    .frame(width: 44, height: 44)
                    .background(severityColor(entry.severity).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(entry.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(entry.category.uppercased())
                            .font(.caption2.bold())
                            .foregroundStyle(severityColor(entry.severity))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(severityColor(entry.severity).opacity(0.13))
                            .clipShape(Capsule())
                    }
                    if !entry.references.isEmpty {
                        Text(entry.references)
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(SecretMatchTheme.secondary)
                    }
                    Text(formattedDate(entry.occurredAt))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SecretMatchTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .padding(.top, 12)
            }
            .padding(14)
            .background(SecretMatchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(severityColor(entry.severity).opacity(0.3)))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Öffnet alle technischen Details dieses Ereignisses")
    }

    private func eventDetails(_ entry: AdminEventLogEntry) -> some View {
        NavigationStack {
            List {
                Section("Ereignis") {
                    detailRow("Typ", entry.title)
                    detailRow("Zeitpunkt", formattedDate(entry.occurredAt))
                    detailRow("Schweregrad", entry.severity)
                    detailRow("Kategorie", entry.category)
                    detailRow("Status", entry.status)
                }
                Section("Zuordnung") {
                    if !entry.actorRef.isEmpty { detailRow("Quelle", entry.actorRef.displayEventNumber) }
                    if !entry.subjectRef.isEmpty { detailRow("Ziel", entry.subjectRef.displayEventNumber) }
                    if !entry.requestID.isEmpty { detailRow("Request-ID", entry.requestID) }
                    if !entry.deviceID.isEmpty { detailRow("Geräte-ID", String(entry.deviceID.prefix(12))) }
                }
                if !entry.context.isEmpty {
                    Section("Diagnose") {
                        ForEach(entry.context.keys.sorted(), id: \.self) { key in
                            detailRow(key.replacingOccurrences(of: "_", with: " "), entry.context[key]?.displayValue ?? "–")
                        }
                    }
                }
            }
            .navigationTitle(entry.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { selectedEntry = nil }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func summaryCard(_ title: String, value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)").font(.title2.bold().monospacedDigit()).foregroundStyle(.white)
                Text(title).font(.caption.bold()).foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer()
        }
        .padding(14)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(color.opacity(0.3)))
    }

    private func filterPicker(
        _ title: String,
        selection: Binding<String>,
        options: [(String, String)]
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.0) { value, label in
                Text(label).tag(value)
            }
        }
        .pickerStyle(.menu)
        .tint(.white)
        .frame(minHeight: 44)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        LabeledContent(title, value: value.isEmpty ? "–" : value)
    }

    private func load(reset: Bool, quietly: Bool = false) async {
        guard !isLoading, !isLoadingMore else { return }
        if reset { isLoading = true } else { isLoadingMore = true }
        defer {
            if reset { isLoading = false } else { isLoadingMore = false }
        }
        do {
            let previousLastID = reset ? nil : api.adminEventLog.last?.id
            let loadedCount = try await api.loadAdminEventLog(
                severity: severity.isEmpty ? nil : severity,
                category: category.isEmpty ? nil : category,
                search: search,
                beforeID: previousLastID
            )
            errorMessage = nil
            hasMore = loadedCount == 100
            if reset {
                try? await api.loadAdminDashboard()
            }
        } catch {
            if !quietly { errorMessage = "Die Ereignisse konnten nicht geladen werden." }
        }
    }

    private func createExamples() async {
        guard !isCreatingExamples else { return }
        isCreatingExamples = true
        statusMessage = nil
        actionErrorMessage = nil
        defer { isCreatingExamples = false }
        do {
            let result = try await api.createAdminEventLogExamples()
            await load(reset: true)
            statusMessage = "\(result.created) von \(result.available) Testlogs wurden angelegt."
        } catch {
            actionErrorMessage = "Die Testlogs konnten nicht angelegt werden."
        }
    }

    private var csvText: String {
        let header = ["ID", "Zeitpunkt", "Schweregrad", "Kategorie", "Ereignis", "Status", "Quelle", "Quelle-ID", "Ziel-ID", "Request-ID", "Kontext"]
        return ([header] + api.adminEventLog.map(\.csvRow))
            .map { $0.map(csvEscape).joined(separator: ";") }
            .joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical", "error": return .red
        case "warning": return .orange
        default: return .green
        }
    }

    private func severityIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.octagon.fill"
        case "error": return "xmark.octagon.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default: return "info.circle.fill"
        }
    }

    private func formattedDate(_ value: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.timeZone = TimeZone(secondsFromGMT: 0)
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = input.date(from: value) else { return value }
        return date.formatted(date: .abbreviated, time: .standard)
    }
}
