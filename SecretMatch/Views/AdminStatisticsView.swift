import SwiftUI

struct AdminStatisticsView: View {
    @EnvironmentObject private var api: APIService
    @State private var selectedEventID = "current"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var exportArtifact: AdminExportArtifact?
    @State private var exportError: String?
    @State private var archiveOperation: ArchiveOperation?
    @State private var archiveNameDraft = ""
    @State private var archiveDeleteConfirmation = ""
    @State private var archiveError: String?

    private enum ArchiveOperation: Identifiable {
        case rename(AdminEventArchiveSummary)
        case delete(AdminEventArchiveSummary)

        var id: String {
            switch self {
            case .rename(let archive): return "rename-\(archive.id)"
            case .delete(let archive): return "delete-\(archive.id)"
            }
        }
    }

    private var statistics: AdminEventStatistics? {
        if selectedEventID == "current" { return api.adminStatistics?.current }
        if selectedEventID == "legacy-last" { return api.adminStatistics?.lastEvent }
        return api.adminStatistics?.archives?.first(where: { $0.id == selectedEventID })?.statistics
    }

    private var selectedArchive: AdminEventArchiveSummary? {
        api.adminStatistics?.archives?.first(where: { $0.id == selectedEventID })
    }

    private var isCurrentEvent: Bool {
        selectedEventID == "current"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if isLoading && statistics == nil {
                    ProgressView("Statistik wird berechnet …")
                        .tint(SecretMatchTheme.secondary)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let errorMessage, statistics == nil {
                    ContentUnavailableView {
                        Label("Statistik nicht erreichbar", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Erneut versuchen") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                            .tint(SecretMatchTheme.primary)
                    }
                    .foregroundStyle(.white)
                } else if let statistics {
                    overview(statistics)
                    matchFunnel(statistics)
                    if isCurrentEvent, let lastEvent = api.adminStatistics?.archives?.first?.statistics ?? api.adminStatistics?.lastEvent {
                        eventComparison(current: api.adminStatistics?.current ?? statistics, last: lastEvent)
                    }
                    participantRanking(statistics.topParticipants ?? [])
                    if isCurrentEvent {
                        deviceMonitoring
                    }
                    distributions(statistics)
                    timeline(statistics)
                } else {
                    ContentUnavailableView(
                        "Noch keine Abschlussstatistik",
                        systemImage: "calendar.badge.clock",
                        description: Text("Beim Eventabschluss wird automatisch ein dauerhaftes Archiv gespeichert.")
                    )
                    .foregroundStyle(.white)
                    .frame(minHeight: 300)
                }
            }
            .padding(24)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .background(BrandBackground())
        .sheet(item: $exportArtifact) { artifact in
            AdminShareSheet(url: artifact.url)
        }
        .sheet(item: $archiveOperation) { operation in
            archiveOperationSheet(operation)
        }
        .alert("Export fehlgeschlagen", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "Der Bericht konnte nicht erstellt werden.")
        }
        .alert("Archiv konnte nicht geändert werden", isPresented: Binding(
            get: { archiveError != nil },
            set: { if !$0 { archiveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(archiveError ?? "Bitte versuche es erneut.")
        }
        .task {
            await load()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                if isCurrentEvent { await load(quietly: true) }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("EVENT-AUSWERTUNG")
                        .font(.caption.bold())
                        .tracking(1.8)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text("Statistik")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(isCurrentEvent ? "Live-Auswertung des laufenden Events." : "Rückblick auf \(selectedArchive?.name ?? "das abgeschlossene Event").")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SecretMatchTheme.muted)
                }
                Spacer()
                HStack(spacing: 10) {
                    Menu {
                        Button {
                            export(format: "pdf")
                        } label: {
                            Label("Als PDF teilen", systemImage: "doc.richtext")
                        }
                        Button {
                            export(format: "csv")
                        } label: {
                            Label("Als CSV teilen", systemImage: "tablecells")
                        }
                    } label: {
                        Label("Bericht exportieren", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SecretMatchTheme.primary)
                    .disabled(statistics == nil)

                    if let selectedArchive {
                        Menu {
                            Button {
                                archiveNameDraft = selectedArchive.name
                                archiveOperation = .rename(selectedArchive)
                            } label: {
                                Label("Umbenennen", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                archiveDeleteConfirmation = ""
                                archiveOperation = .delete(selectedArchive)
                            } label: {
                                Label("Archiv löschen", systemImage: "trash")
                            }
                        } label: {
                            Label("Archiv", systemImage: "archivebox")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Picker("Event", selection: $selectedEventID) {
                Text("Aktuelles Event · Live").tag("current")
                ForEach(api.adminStatistics?.archives ?? []) { archive in
                    Text("\(archive.name) · \(archive.completedAt)").tag(archive.id)
                }
                if (api.adminStatistics?.archives ?? []).isEmpty, api.adminStatistics?.lastEvent != nil {
                    Text("Letztes Event (älteres Archiv)").tag("legacy-last")
                }
            }
            .pickerStyle(.menu)
            .tint(SecretMatchTheme.secondary)
            .frame(maxWidth: 560, alignment: .leading)
        }
    }

    private func overview(_ stats: AdminEventStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Überblick", icon: "rectangle.grid.2x2.fill")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 175), spacing: 12)], spacing: 12) {
                metric("Freigegeben", stats.allowedParticipants, color: Color(hex: "#E6923E"))
                metric("Teilgenommen", stats.engagedParticipants, color: SecretMatchTheme.secondary)
                metric("Match-Requests", stats.requests, color: Color(hex: "#8E63D2"))
                metric("Matches", stats.matches, color: Color(hex: "#E83E8C"))
                metric("Aktionen", stats.actions, color: Color(hex: "#3E9ED6"))
                metric("Freitexte", stats.requestsWithMessage, color: Color(hex: "#E6923E"))
                metric("Zugestellt", stats.deliveryCount, color: .green)
                metric("Retries", stats.retryCount, color: stats.retryCount > 0 ? .orange : .green)
                metric("Technische Fehler", stats.errorCount, color: stats.errorCount > 0 ? .red : .green)
                metric("Admin-Aktionen", stats.adminActionCount ?? 0, color: SecretMatchTheme.secondary)
                metric("Admin-Fehler", stats.adminFailureCount ?? 0, color: (stats.adminFailureCount ?? 0) > 0 ? .orange : .green)
                percentageMetric("Match-Quote", stats.matchRatePercent, color: SecretMatchTheme.primary)
            }

            if !stats.startedAt.isEmpty {
                Text("Zeitraum: \(stats.startedAt) – \(stats.completedAt ?? stats.endedAt)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SecretMatchTheme.muted)
            }
        }
    }

    private func archiveOperationSheet(_ operation: ArchiveOperation) -> some View {
        NavigationStack {
            Form {
                switch operation {
                case .rename:
                    Section("Eventname") {
                        AdminKeyboardTextField(
                            title: "Name des Events",
                            text: $archiveNameDraft,
                            keyboard: .text(maxCharacters: 120),
                            keyboardTitle: "Event umbenennen"
                        )
                    }
                    Section {
                        Button("Namen speichern") {
                            Task { await renameArchive(operation) }
                        }
                        .disabled(archiveNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                case .delete(let archive):
                    Section {
                        Text("„\(archive.name)“ wird samt aller Eventdaten unwiderruflich gelöscht.")
                    }
                    Section("Sicherheitsbestätigung") {
                        Text("Bitte exakt ARCHIV LÖSCHEN eingeben.")
                        AdminKeyboardTextField(
                            title: "ARCHIV LÖSCHEN",
                            text: $archiveDeleteConfirmation,
                            keyboard: .text(maxCharacters: 14),
                            keyboardTitle: "Archiv löschen",
                            forcesUppercase: true
                        )
                        Button("Archiv endgültig löschen", role: .destructive) {
                            Task { await deleteArchive(operation) }
                        }
                        .disabled(archiveDeleteConfirmation != "ARCHIV LÖSCHEN" || isLoading)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SecretMatchTheme.background)
            .navigationTitle(operationTitle(operation))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { archiveOperation = nil }
                }
            }
        }
    }

    private func operationTitle(_ operation: ArchiveOperation) -> String {
        switch operation {
        case .rename: return "Event umbenennen"
        case .delete: return "Archiv löschen"
        }
    }

    private func distributions(_ stats: AdminEventStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Verteilung", icon: "chart.bar.fill")
            HStack(alignment: .top, spacing: 14) {
                distributionCard("Match-Wünsche", entries: stats.requestTypes)
                distributionCard("Aktionen", entries: stats.actionTypes)
            }
        }
    }

    private func matchFunnel(_ stats: AdminEventStatistics) -> some View {
        let reciprocated = min(stats.requests, stats.matches * 2)
        let maximum = max(1, stats.requests)
        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Match-Funnel", icon: "arrow.down.right.and.arrow.up.left")
            VStack(spacing: 14) {
                funnelRow("Interessen gesendet", value: stats.requests, maximum: maximum, color: Color(hex: "#8E63D2"))
                funnelRow("Gegenseitig bestätigt", value: reciprocated, maximum: maximum, color: Color(hex: "#E83E8C"))
                funnelRow("Match-Paare", value: stats.matches, maximum: maximum, color: SecretMatchTheme.secondary)
            }
            .secretCard(padding: 16)
        }
    }

    private func eventComparison(current: AdminEventStatistics, last: AdminEventStatistics) -> some View {
        let values = [
            ("Teilgenommen", current.engagedParticipants, last.engagedParticipants),
            ("Requests", current.requests, last.requests),
            ("Matches", current.matches, last.matches),
            ("Aktionen", current.actions, last.actions),
        ]
        let maximum = max(1, values.flatMap { [$0.1, $0.2] }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Eventvergleich", icon: "chart.bar.xaxis.ascending")
            VStack(spacing: 14) {
                HStack(spacing: 18) {
                    Label("Aktuell", systemImage: "circle.fill").foregroundStyle(SecretMatchTheme.primary)
                    Label("Letztes Event", systemImage: "circle.fill").foregroundStyle(SecretMatchTheme.secondary)
                    Spacer()
                }
                .font(.caption.bold())
                ForEach(values, id: \.0) { title, currentValue, lastValue in
                    comparisonRow(title, current: currentValue, last: lastValue, maximum: maximum)
                }
            }
            .secretCard(padding: 16)
        }
    }

    private func participantRanking(_ entries: [AdminParticipantStatistic]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Aktivste Eventnummern", icon: "person.3.sequence.fill")
            if entries.isEmpty {
                Text("Noch keine Teilnehmeraktivität vorhanden.")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .secretCard(padding: 18)
            } else {
                let maximum = max(1, entries.map(\.activityTotal).max() ?? 1)
                VStack(spacing: 14) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 12) {
                            Text("\(index + 1).")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(SecretMatchTheme.muted)
                                .frame(width: 24, alignment: .trailing)
                            Text(entry.number.displayEventNumber)
                                .font(.headline.bold().monospacedDigit())
                                .foregroundStyle(.white)
                                .frame(width: 54, alignment: .leading)
                            GeometryReader { proxy in
                                HStack(spacing: 2) {
                                    rankingSegment(entry.sent, maximum: maximum, width: proxy.size.width, color: Color(hex: "#E83E8C"))
                                    rankingSegment(entry.received, maximum: maximum, width: proxy.size.width, color: Color(hex: "#3E9ED6"))
                                    rankingSegment(entry.matches * 2, maximum: maximum, width: proxy.size.width, color: .green)
                                }
                            }
                            .frame(height: 18)
                            Text("↑\(entry.sent) ↓\(entry.received) ♥\(entry.matches)")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(SecretMatchTheme.muted)
                                .frame(width: 118, alignment: .trailing)
                        }
                    }
                }
                .secretCard(padding: 16)
            }
        }
    }

    private var deviceMonitoring: some View {
        let devices = api.adminDashboard?.devices ?? []
        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Gerätegesundheit", icon: "ipad.and.iphone")
            if devices.isEmpty {
                Text("Noch keine iPads verbunden.")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .secretCard(padding: 18)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 12)], spacing: 12) {
                    ForEach(devices) { device in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(device.name ?? "iPad")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(device.isOnline ? "Online" : "Offline")
                                    .font(.caption.bold())
                                    .foregroundStyle(device.isOnline ? .green : .red)
                            }
                            HStack {
                                Text("Akku \(device.batteryLevel) %")
                                    .font(.caption.bold().monospacedDigit())
                                Spacer()
                                Text((device.queuedSendCount ?? 0) == 0 ? "Queue frei" : device.queueSummary)
                                    .font(.caption.bold().monospacedDigit())
                                    .multilineTextAlignment(.trailing)
                            }
                            .foregroundStyle(SecretMatchTheme.muted)
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.08))
                                    Capsule()
                                        .fill(device.batteryLevel < 10 ? Color.red : (device.batteryLevel < 20 ? Color.orange : Color.green))
                                        .frame(width: proxy.size.width * CGFloat(max(0, min(100, device.batteryLevel))) / 100)
                                }
                            }
                            .frame(height: 12)
                        }
                        .secretCard(padding: 14)
                    }
                }
            }
        }
    }

    private func timeline(_ stats: AdminEventStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Aktivität je 15 Minuten", icon: "clock.fill")
            if stats.timeline.isEmpty {
                Text("Noch keine Aktivität vorhanden.")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .secretCard(padding: 18)
            } else {
                let maximum = max(1, stats.timeline.map(\.total).max() ?? 1)
                VStack(spacing: 12) {
                    ForEach(stats.timeline) { point in
                        HStack(spacing: 12) {
                            Text(String(point.hour.suffix(5)))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(SecretMatchTheme.muted)
                                .frame(width: 46, alignment: .leading)
                            GeometryReader { proxy in
                                HStack(spacing: 2) {
                                    barSegment(point.requests, maximum: maximum, width: proxy.size.width, color: Color(hex: "#8E63D2"))
                                    barSegment(point.matches, maximum: maximum, width: proxy.size.width, color: Color(hex: "#E83E8C"))
                                    barSegment(point.actions, maximum: maximum, width: proxy.size.width, color: Color(hex: "#3E9ED6"))
                                }
                            }
                            .frame(height: 22)
                            Text("\(point.total)")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(.white)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
                .secretCard(padding: 16)
            }
        }
    }

    private func metric(_ title: String, _ value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(value)")
                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
            Text(title).font(.caption.bold()).foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(color.opacity(0.32)))
    }

    private func percentageMetric(_ title: String, _ value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value.formatted(.number.precision(.fractionLength(1))) + " %")
                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
            Text(title).font(.caption.bold()).foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(color.opacity(0.32)))
    }

    private func distributionCard(_ title: String, entries: [AdminStatisticCount]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(.white)
            if entries.isEmpty {
                Text("Keine Daten").foregroundStyle(SecretMatchTheme.muted)
            } else {
                ForEach(entries) { entry in
                    HStack {
                        Text(label(for: entry.name)).foregroundStyle(SecretMatchTheme.muted)
                        Spacer()
                        Text("\(entry.count)").fontWeight(.bold).foregroundStyle(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(padding: 16)
    }

    private func barSegment(_ value: Int, maximum: Int, width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(color)
            .frame(width: value > 0 ? max(4, width * CGFloat(value) / CGFloat(maximum)) : 0)
    }

    private func funnelRow(_ title: String, value: Int, maximum: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(SecretMatchTheme.muted)
                .frame(width: 170, alignment: .leading)
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 7)
                    .fill(color)
                    .frame(width: value > 0 ? max(6, proxy.size.width * CGFloat(value) / CGFloat(maximum)) : 0)
            }
            .frame(height: 24)
            Text("\(value)")
                .font(.headline.bold().monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func comparisonRow(_ title: String, current: Int, last: Int, maximum: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.bold()).foregroundStyle(SecretMatchTheme.muted)
            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 3) {
                    Capsule().fill(SecretMatchTheme.primary)
                        .frame(width: current > 0 ? max(4, proxy.size.width * CGFloat(current) / CGFloat(maximum)) : 0, height: 8)
                    Capsule().fill(SecretMatchTheme.secondary)
                        .frame(width: last > 0 ? max(4, proxy.size.width * CGFloat(last) / CGFloat(maximum)) : 0, height: 8)
                }
            }
            .frame(height: 19)
            Text("Aktuell \(current) · vorher \(last)")
                .font(.caption2.bold().monospacedDigit())
                .foregroundStyle(.white)
        }
    }

    private func rankingSegment(_ value: Int, maximum: Int, width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: value > 0 ? max(3, width * CGFloat(value) / CGFloat(maximum)) : 0)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.title3.bold())
            .foregroundStyle(.white)
    }

    private func label(for type: String) -> String {
        [
            "normal": "Hot",
            "hot": "Fuck",
            "bjob": "Blow-Job",
            "hjob": "Hand-Job",
            "ljob": "Lick-Job",
        ][type] ?? type
    }

    private func load(quietly: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.loadAdminStatistics()
            try? await api.loadAdminDashboard()
            errorMessage = nil
        } catch {
            if !quietly { errorMessage = "Die Event-Auswertung konnte nicht geladen werden." }
        }
    }

    private func renameArchive(_ operation: ArchiveOperation) async {
        guard case .rename(let archive) = operation else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.renameAdminEventArchive(id: archive.id, name: archiveNameDraft)
            archiveOperation = nil
            errorMessage = nil
        } catch {
            archiveError = "Das Event-Archiv konnte nicht umbenannt werden."
        }
    }

    private func deleteArchive(_ operation: ArchiveOperation) async {
        guard case .delete(let archive) = operation else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.deleteAdminEventArchive(id: archive.id, confirmation: archiveDeleteConfirmation)
            selectedEventID = "current"
            archiveOperation = nil
            errorMessage = nil
        } catch {
            archiveError = "Das Event-Archiv konnte nicht gelöscht werden."
        }
    }

    private func export(format: String) {
        guard let statistics else { return }
        do {
            let name = isCurrentEvent ? "aktuelles-event" : (selectedArchive?.name ?? "archiviertes-event")
            let url = if format == "pdf" {
                try AdminReportExporter.pdf(for: statistics, eventName: name)
            } else {
                try AdminReportExporter.csv(for: statistics, eventName: name)
            }
            exportArtifact = AdminExportArtifact(url: url)
        } catch {
            exportError = "Der \(format.uppercased())-Bericht konnte nicht erstellt werden."
        }
    }
}
