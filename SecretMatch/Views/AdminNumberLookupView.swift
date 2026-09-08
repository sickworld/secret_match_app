import SwiftUI

struct AdminNumberLookupView: View {
    @EnvironmentObject private var api: APIService
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var overview: AdminNumberOverview?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isMutating = false
    @State private var operationMessage: String?
    @State private var operationError: String?
    @State private var pendingReset: ResetAction?

    private enum ResetAction: Identifiable {
        case pin(String)
        case gender(String)

        var id: String {
            switch self {
            case .pin(let number): return "pin-\(number)"
            case .gender(let number): return "gender-\(number)"
            }
        }

        var confirmationText: String {
            switch self {
            case .pin(let number):
                return "Die bisherige PIN von \(number.displayEventNumber) wird sofort ungültig. Alle Sitzungen werden beendet und beim nächsten Login legt die Person selbst eine neue PIN fest."
            case .gender(let number):
                return "Das Gender von \(number.displayEventNumber) wird gelöscht. Alle Sitzungen werden beendet und beim nächsten Login erscheint die Auswahl erneut."
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchCard

                    if isLoading {
                        ProgressView("Nummer wird gesucht …")
                            .tint(SecretMatchTheme.secondary)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else if let errorMessage {
                        ContentUnavailableView {
                            Label("Nummer nicht abrufbar", systemImage: "magnifyingglass")
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Erneut versuchen") { Task { await search() } }
                        }
                        .foregroundStyle(.white)
                    } else if let overview {
                        resultContent(overview)
                    } else {
                        ContentUnavailableView(
                            "Eventnummer suchen",
                            systemImage: "person.text.rectangle",
                            description: Text("Zeigt Status, Interaktionen, Geräte und die letzten Protokolle einer Nummer an.")
                        )
                        .foregroundStyle(.white)
                        .frame(minHeight: 260)
                    }
                }
                .padding(24)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .background(BrandBackground())
            .navigationTitle("Globale Nummernsuche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .alert("Zurücksetzen bestätigen", isPresented: Binding(
            get: { pendingReset != nil },
            set: { if !$0 { pendingReset = nil } }
        )) {
            Button("Abbrechen", role: .cancel) {}
            Button("Zurücksetzen", role: .destructive) {
                let selected = pendingReset
                Task { await performReset(selected) }
            }
        } message: {
            Text(pendingReset?.confirmationText ?? "")
        }
    }

    private var searchCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title2.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
            TextField("Eventnummer", text: $query)
                .font(.title2.bold().monospacedDigit())
                .keyboardType(.numberPad)
                .textContentType(.none)
                .foregroundStyle(.white)
                .onSubmit { Task { await search() } }
            Button("Suchen") { Task { await search() } }
                .buttonStyle(.borderedProminent)
                .tint(SecretMatchTheme.primary)
                .disabled(query.normalizedEventNumber.isEmpty || isLoading || isMutating)
        }
        .padding(16)
        .secretCard(padding: 0)
    }

    @ViewBuilder
    private func resultContent(_ overview: AdminNumberOverview) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(overview.number.displayEventNumber)
                .font(.system(size: 42, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
            Spacer()
            Label(overview.active ? "Gerade aktiv" : "Nicht aktiv", systemImage: overview.active ? "circle.fill" : "circle")
                .font(.subheadline.bold())
                .foregroundStyle(overview.active ? .green : SecretMatchTheme.muted)
        }

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
            statusCard("Freigegeben", value: overview.allowed ? "Ja" : "Nein", icon: "person.badge.key.fill", color: overview.allowed ? .green : .red)
            statusCard("PIN", value: overview.pinConfigured ? "Eingerichtet" : "Fehlt", icon: "lock.fill", color: overview.pinConfigured ? .green : .orange)
            statusCard("Gender", value: genderLabel(overview.gender), icon: "person.crop.circle", color: overview.gender == nil ? .orange : SecretMatchTheme.secondary)
            statusCard("Geräte", value: "\(overview.devices.count)", icon: "ipad", color: overview.devices.isEmpty ? SecretMatchTheme.muted : .green)
        }

        participantManagement(overview)

        section("Aktivität", icon: "chart.bar.fill") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                metric("Requests gesendet", overview.counts.sentRequests)
                metric("Requests erhalten", overview.counts.receivedRequests)
                metric("Aktionen gesendet", overview.counts.sentActions)
                metric("Aktionen erhalten", overview.counts.receivedActions)
                metric("Matches", overview.counts.matches)
            }
        }

        if !overview.devices.isEmpty {
            section("Verbundene iPads", icon: "ipad.and.iphone") {
                VStack(spacing: 10) {
                    ForEach(overview.devices) { device in
                        HStack(spacing: 12) {
                            SecretBinaryStatusIcon(isPositive: device.isOnline, size: 15)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(device.name ?? "iPad").font(.headline).foregroundStyle(.white)
                                Text("\(device.lastSeenDescription) · Akku \(device.batteryLevel) % · " + ((device.queuedSendCount ?? 0) == 0 ? "Queue frei" : device.queueSummary))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(SecretMatchTheme.muted)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }

        section("Letzte Vorgänge", icon: "arrow.left.arrow.right") {
            if overview.recentActivity.isEmpty {
                Text("Für diese Nummer gibt es noch keine Aktionen, Requests oder Matches.")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                VStack(spacing: 0) {
                    ForEach(overview.recentActivity) { activity in
                        HStack(spacing: 12) {
                            Image(systemName: activityIcon(activity.kind))
                                .foregroundStyle(activityColor(activity.kind))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activityTitle(activity))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                Text("Mit \(activity.counterpart.displayEventNumber) · \(activity.createdAt)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(SecretMatchTheme.muted)
                            }
                            Spacer()
                            if activity.hasMessage {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundStyle(SecretMatchTheme.secondary)
                                    .accessibilityLabel("Mit Freitext")
                            }
                        }
                        .padding(.vertical, 10)
                        if activity.id != overview.recentActivity.last?.id {
                            Divider().overlay(SecretMatchTheme.border)
                        }
                    }
                }
            }
        }

        section("Letzte Protokolle", icon: "list.bullet.rectangle") {
            if overview.recentLogs.isEmpty {
                Text("Keine Protokolle für diese Nummer gefunden.")
                    .foregroundStyle(SecretMatchTheme.muted)
            } else {
                VStack(spacing: 10) {
                    ForEach(overview.recentLogs.prefix(12)) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            let isError = entry.severity == "error" || entry.severity == "critical"
                            Image(systemName: isError ? "exclamationmark.octagon.fill" : "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isError ? Color.red : Color.green)
                                .frame(width: 14, height: 14)
                                .padding(.top, 6)
                                .accessibilityLabel(isError ? "Fehler" : "In Ordnung")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title).font(.subheadline.bold()).foregroundStyle(.white)
                                Text(entry.occurredAt).font(.caption).foregroundStyle(SecretMatchTheme.muted)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func participantManagement(_ overview: AdminNumberOverview) -> some View {
        section("Nummer verwalten", icon: "person.badge.key.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if let operationMessage {
                    Label(operationMessage, systemImage: "checkmark.circle.fill")
                        .font(.callout.bold())
                        .foregroundStyle(.green)
                }
                if let operationError {
                    Label(operationError, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout.bold())
                        .foregroundStyle(.red)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                    Button {
                        pendingReset = .pin(overview.number)
                    } label: {
                        Label("PIN zurücksetzen", systemImage: "key.slash.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .disabled(isMutating || !overview.pinConfigured)

                    Button {
                        pendingReset = .gender(overview.number)
                    } label: {
                        Label("Gender zurücksetzen", systemImage: "person.crop.circle.badge.xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .disabled(isMutating || overview.gender == nil)
                }

                if isMutating {
                    HStack(spacing: 9) {
                        ProgressView().tint(SecretMatchTheme.secondary)
                        Text("Änderung wird gespeichert …")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(SecretMatchTheme.muted)
                } else {
                    Text("Ein Reset meldet die Nummer auf allen Geräten ab. Fehlende Angaben werden beim nächsten Login neu eingerichtet.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SecretMatchTheme.muted)
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.title3.bold()).foregroundStyle(.white)
            content()
        }
        .secretCard(padding: 16)
    }

    private func statusCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.headline.bold()).foregroundStyle(.white)
            Text(title).font(.caption.bold()).foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(padding: 14)
    }

    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(value)").font(.title2.bold().monospacedDigit()).foregroundStyle(.white)
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(SecretMatchTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SecretMatchTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
    }

    private func activityTitle(_ activity: AdminNumberActivity) -> String {
        let type = typeLabel(activity.type)
        switch activity.kind {
        case "match": return "\(type)-Match"
        case "request": return activity.direction == "sent" ? "\(type)-Request gesendet" : "\(type)-Request erhalten"
        default: return activity.direction == "sent" ? "\(type) gesendet" : "\(type) erhalten"
        }
    }

    private func activityIcon(_ kind: String) -> String {
        kind == "match" ? "sparkles" : (kind == "request" ? "heart.text.square.fill" : "paperplane.fill")
    }

    private func activityColor(_ kind: String) -> Color {
        kind == "match" ? .green : (kind == "request" ? SecretMatchTheme.primary : SecretMatchTheme.secondary)
    }

    private func typeLabel(_ type: String) -> String {
        ["normal": "Hot", "hot": "Fuck", "bjob": "Blow-Job", "hjob": "Hand-Job", "ljob": "Lick-Job"][type] ?? type
    }

    private func genderLabel(_ gender: String?) -> String {
        switch gender {
        case "female": return "Weiblich"
        case "male": return "Männlich"
        case "skip": return "Lieber nicht"
        default: return "Nicht angegeben"
        }
    }

    private func search() async {
        guard !query.normalizedEventNumber.isEmpty, !isLoading, !isMutating else { return }
        isLoading = true
        errorMessage = nil
        operationMessage = nil
        operationError = nil
        do {
            overview = try await api.loadAdminNumberOverview(number: query)
        } catch {
            overview = nil
            errorMessage = "Die Nummer konnte nicht geladen werden. Bitte Verbindung und Eingabe prüfen."
        }
        isLoading = false
    }

    @MainActor
    private func performReset(_ action: ResetAction?) async {
        guard let action, !isMutating else { return }
        isMutating = true
        operationMessage = nil
        operationError = nil

        let number: String
        do {
            switch action {
            case .pin(let selectedNumber):
                number = selectedNumber
                try await api.resetParticipantPIN(number: selectedNumber)
                operationMessage = "PIN zurückgesetzt. Beim nächsten Login wird eine neue PIN festgelegt."
            case .gender(let selectedNumber):
                number = selectedNumber
                try await api.updateParticipantGender(number: selectedNumber, gender: nil)
                operationMessage = "Gender zurückgesetzt. Beim nächsten Login erscheint die Auswahl erneut."
            }
            if let refreshed = try? await api.loadAdminNumberOverview(number: number) {
                overview = refreshed
            }
        } catch {
            operationError = "Die Angabe konnte nicht zurückgesetzt werden. Bitte Verbindung prüfen und erneut versuchen."
        }
        isMutating = false
    }
}
