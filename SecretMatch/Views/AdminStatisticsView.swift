import SwiftUI

struct AdminStatisticsView: View {
    @EnvironmentObject private var api: APIService
    @State private var showsLastEvent = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var statistics: AdminEventStatistics? {
        showsLastEvent ? api.adminStatistics?.lastEvent : api.adminStatistics?.current
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
                    distributions(statistics)
                    timeline(statistics)
                } else {
                    ContentUnavailableView(
                        "Noch keine Abschlussstatistik",
                        systemImage: "calendar.badge.clock",
                        description: Text("Beim Event-Reset wird automatisch eine anonyme Zusammenfassung gespeichert.")
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
        .task {
            await load()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                if !showsLastEvent { await load(quietly: true) }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("EVENT-AUSWERTUNG")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Statistik")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(showsLastEvent ? "Anonyme Abschlusswerte des letzten Events." : "Live-Auswertung des laufenden Events.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer()
            Picker("Zeitraum", selection: $showsLastEvent) {
                Text("Aktuelles Event").tag(false)
                Text("Letztes Event").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 360)
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
                percentageMetric("Match-Quote", stats.matchRatePercent, color: SecretMatchTheme.primary)
            }

            if !stats.startedAt.isEmpty {
                Text("Zeitraum: \(stats.startedAt) – \(stats.completedAt ?? stats.endedAt)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SecretMatchTheme.muted)
            }
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

    private func timeline(_ stats: AdminEventStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Aktivität nach Stunde", icon: "clock.fill")
            if stats.timeline.isEmpty {
                Text("Noch keine Aktivität vorhanden.")
                    .foregroundStyle(SecretMatchTheme.muted)
                    .secretCard(cornerRadius: 16, padding: 18)
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
                .secretCard(cornerRadius: 18, padding: 16)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.32)))
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.32)))
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
        .secretCard(cornerRadius: 18, padding: 16)
    }

    private func barSegment(_ value: Int, maximum: Int, width: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(color)
            .frame(width: value > 0 ? max(4, width * CGFloat(value) / CGFloat(maximum)) : 0)
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
            errorMessage = nil
        } catch {
            if !quietly { errorMessage = "Die Event-Auswertung konnte nicht geladen werden." }
        }
    }
}
