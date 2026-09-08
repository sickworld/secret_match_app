import SwiftUI

struct AdminEventCheckView: View {
    @EnvironmentObject private var api: APIService
    @State private var isLoading = false
    @State private var errorMessage: String?

    private enum Importance {
        case required
        case recommended
    }

    private struct CheckItem: Identifiable {
        let id: String
        let title: String
        let detail: String
        let passed: Bool
        let importance: Importance
        let icon: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if isLoading && api.adminDashboard == nil {
                    ProgressView("Event wird geprüft …")
                        .tint(SecretMatchTheme.secondary)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 280)
                } else if let errorMessage, api.adminDashboard == nil {
                    ContentUnavailableView {
                        Label("Event-Check nicht erreichbar", systemImage: "checklist")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Erneut prüfen") { Task { await refresh() } }
                    }
                    .foregroundStyle(.white)
                } else if let dashboard = api.adminDashboard {
                    overallStatus(for: checks(dashboard))
                    checkSection("Muss funktionieren", items: checks(dashboard).filter { $0.importance == .required })
                    checkSection("Empfohlen", items: checks(dashboard).filter { $0.importance == .recommended })
                }
            }
            .padding(24)
            .frame(maxWidth: 1050)
            .frame(maxWidth: .infinity)
        }
        .background(BrandBackground())
        .task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                await refresh(quietly: true)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("STARTKLAR")
                    .font(.caption.bold())
                    .tracking(1.8)
                    .foregroundStyle(SecretMatchTheme.secondary)
                Text("Event-Check")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Live-Prüfung von Server, Nummern, iPads, Queue, Billboard und Benachrichtigungen.")
                    .foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer()
            Button {
                Task { await refresh() }
            } label: {
                Label(isLoading ? "Prüft …" : "Jetzt prüfen", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .tint(SecretMatchTheme.secondary)
            .disabled(isLoading)
        }
    }

    private func overallStatus(for items: [CheckItem]) -> some View {
        let requiredFailures = items.filter { $0.importance == .required && !$0.passed }
        let warnings = items.filter { $0.importance == .recommended && !$0.passed }
        let presentation: (title: String, detail: String, icon: String, color: Color)
        if !requiredFailures.isEmpty {
            presentation = ("Noch nicht startklar", "\(requiredFailures.count) notwendige Prüfungen sind fehlgeschlagen.", "xmark.octagon.fill", .red)
        } else if !warnings.isEmpty {
            presentation = ("Startklar mit Hinweisen", "Die Kernfunktionen laufen; \(warnings.count) Empfehlungen sind noch offen.", "exclamationmark.triangle.fill", .orange)
        } else {
            presentation = ("Event ist startklar", "Alle notwendigen und empfohlenen Prüfungen sind grün.", "checkmark.seal.fill", .green)
        }

        return HStack(spacing: 16) {
            Image(systemName: presentation.icon)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(presentation.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title).font(.title2.bold()).foregroundStyle(.white)
                Text(presentation.detail).foregroundStyle(SecretMatchTheme.muted)
            }
            Spacer()
        }
        .padding(20)
        .background(presentation.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(presentation.color.opacity(0.45), lineWidth: 1.5))
    }

    private func checkSection(_ title: String, items: [CheckItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold()).foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: item.icon)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Image(systemName: item.passed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(item.passed ? .green : (item.importance == .required ? .red : .orange))
                                .background(Circle().fill(SecretMatchTheme.surface))
                                .offset(x: 5, y: 5)
                        }
                        .frame(width: 34, height: 34)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.headline.bold()).foregroundStyle(.white)
                            Text(item.detail).font(.subheadline.weight(.medium)).foregroundStyle(SecretMatchTheme.muted)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .secretCard(cornerRadius: 16, padding: 14)
                }
            }
        }
    }

    private func checks(_ dashboard: AdminDashboard) -> [CheckItem] {
        let devices = dashboard.devices ?? []
        let onlineDevices = devices.filter(\.isOnline)
        let offlineDevices = devices.count - onlineDevices.count
        let queuedActions = devices.reduce(0) { $0 + ($1.queuedSendCount ?? 0) }
        let queuedShipments = devices.reduce(0) {
            $0 + InteractionQueueWording.shipmentCount(
                reportedShipmentCount: $1.queuedBatchCount,
                actionCount: $1.queuedSendCount ?? 0
            )
        }
        let lowBattery = devices.filter { $0.batteryLevel < 30 }.count
        let billboards = dashboard.billboards ?? []
        let onlineBillboards = billboards.filter(\.online).count
        let quickMessages = dashboard.matchMessageOptions ?? []
        let moduleCurrent = dashboard.pluginVersion.compare("2026.09.08.6", options: .numeric) != .orderedAscending

        return [
            CheckItem(id: "api", title: "Server & API", detail: dashboard.apiOK ? "WordPress antwortet · Modul \(dashboard.pluginVersion)" : "Die API meldet einen Fehler.", passed: dashboard.apiOK, importance: .required, icon: "server.rack"),
            CheckItem(id: "module", title: "WordPress-Modul", detail: moduleCurrent ? "Version \(dashboard.pluginVersion) unterstützt alle Admin-Werkzeuge." : "Bitte mindestens Version 2026.09.08.6 installieren.", passed: moduleCurrent, importance: .required, icon: "shippingbox.fill"),
            CheckItem(id: "numbers", title: "Eventnummern", detail: dashboard.allowedParticipants > 0 ? "\(dashboard.allowedParticipants) Nummern sind freigegeben." : "Es sind keine Nummern freigegeben.", passed: dashboard.allowedParticipants > 0, importance: .required, icon: "number"),
            CheckItem(id: "ipads", title: "iPads erreichbar", detail: devices.isEmpty ? "Noch kein iPad registriert." : "\(onlineDevices.count) von \(devices.count) iPads sind online.", passed: !devices.isEmpty && offlineDevices == 0, importance: .required, icon: "ipad"),
            CheckItem(
                id: "queue",
                title: "Sendewarteschlangen",
                detail: queuedActions == 0
                    ? "Keine wartenden Versandvorgänge."
                    : InteractionQueueWording.waitingDescription(
                        reportedShipmentCount: queuedShipments,
                        actionCount: queuedActions
                    ) + " noch auf Zustellung.",
                passed: queuedActions == 0,
                importance: .required,
                icon: "tray.full"
            ),
            CheckItem(id: "battery", title: "Akkustände", detail: devices.isEmpty ? "Noch keine Akkudaten vorhanden." : (lowBattery == 0 ? "Alle iPads haben mindestens 30 %." : "\(lowBattery) iPads liegen unter 30 %."), passed: !devices.isEmpty && lowBattery == 0, importance: .recommended, icon: "battery.75percent"),
            CheckItem(id: "billboard", title: "Billboards", detail: billboards.isEmpty ? "Noch kein Billboard angelegt." : "\(onlineBillboards) von \(billboards.count) Billboards sind online.", passed: !billboards.isEmpty && onlineBillboards == billboards.count, importance: .recommended, icon: "tv"),
            CheckItem(id: "apns", title: "Admin-Push", detail: dashboard.apnsConfigured == true ? "APNs ist konfiguriert; \(dashboard.adminPushDevices ?? 0) Geräte registriert." : "APNs ist nicht vollständig konfiguriert.", passed: dashboard.apnsConfigured == true && (dashboard.adminPushDevices ?? 0) > 0, importance: .recommended, icon: "bell.badge"),
            CheckItem(id: "telegram", title: "Telegram", detail: dashboard.telegramConfigured ? "Telegram ist konfiguriert." : "Telegram ist nicht konfiguriert.", passed: dashboard.telegramConfigured, importance: .recommended, icon: "paperplane.circle"),
            CheckItem(id: "quick-messages", title: "Schnelltexte", detail: quickMessages.isEmpty ? "Keine Schnelltexte gepflegt." : "\(quickMessages.count) Schnelltexte sind verfügbar.", passed: !quickMessages.isEmpty, importance: .recommended, icon: "text.bubble"),
            CheckItem(id: "top-test", title: "Billboard-Testmodus", detail: dashboard.topTestActive ? "Der Top-16-Testmodus ist noch aktiv." : "Normalbetrieb ist aktiv.", passed: !dashboard.topTestActive, importance: .recommended, icon: "testtube.2"),
        ]
    }

    private func refresh(quietly: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.loadAdminDashboard()
            errorMessage = nil
        } catch {
            if !quietly {
                errorMessage = "Der aktuelle Systemzustand konnte nicht geladen werden."
            }
        }
    }
}
