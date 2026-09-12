import SwiftUI

struct AdminDeliveryDiagnosticsView: View {
    @EnvironmentObject private var api: APIService
    @State private var sourceNumber = ""
    @State private var targetNumber = ""
    @State private var diagnostics: [AdminDeliveryDiagnostic] = []
    @State private var hasSearched = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("FEHLERSUCHE")
                        .font(.caption.bold())
                        .tracking(1.8)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text("Sendungsdiagnose")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Zeigt für jede Sendung, ob sie vorgemerkt, erneut versucht, zugestellt oder abgelehnt wurde.")
                        .foregroundStyle(SecretMatchTheme.muted)
                }

                searchCard

                if isLoading {
                    ProgressView("Übertragungsweg wird geprüft …")
                        .tint(SecretMatchTheme.secondary)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 260)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Diagnose nicht möglich", systemImage: "stethoscope")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Erneut versuchen") { Task { await search() } }
                    }
                    .foregroundStyle(.white)
                } else if hasSearched && diagnostics.isEmpty {
                    ContentUnavailableView(
                        "Keine Sendeversuche gefunden",
                        systemImage: "tray",
                        description: Text("Für diese Kombination liegen keine Queue-Protokolle vor. Prüfe die Nummern oder suche ohne Zielnummer.")
                    )
                    .foregroundStyle(.white)
                    .frame(minHeight: 260)
                } else if !diagnostics.isEmpty {
                    ForEach(diagnostics) { diagnostic in
                        diagnosticCard(diagnostic)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 1080)
            .frame(maxWidth: .infinity)
        }
        .background(BrandBackground())
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                numberField("Von Nummer", text: $sourceNumber)
                Image(systemName: "arrow.right")
                    .font(.headline.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
                numberField("Zu Nummer (optional)", text: $targetNumber)
            }
            HStack {
                Text("Ohne Zielnummer werden alle letzten Sendungen der Ausgangsnummer angezeigt.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SecretMatchTheme.muted)
                Spacer()
                Button {
                    Task { await search() }
                } label: {
                    Label("Übertragung prüfen", systemImage: "waveform.path.ecg.rectangle")
                }
                .buttonStyle(.borderedProminent)
                .tint(SecretMatchTheme.primary)
                .disabled(sourceNumber.normalizedEventNumber.isEmpty || isLoading)
            }
        }
        .secretCard(padding: 16)
    }

    private func numberField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(SecretMatchTheme.secondary)
            AdminKeyboardTextField(
                title: title,
                text: text,
                keyboard: .number(maxDigits: 10),
                keyboardTitle: title
            )
                .font(.title3.bold().monospacedDigit())
                .padding(12)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        }
        .frame(maxWidth: .infinity)
    }

    private func diagnosticCard(_ diagnostic: AdminDeliveryDiagnostic) -> some View {
        let presentation = statusPresentation(diagnostic.state)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: presentation.icon)
                    .font(.title2.bold())
                    .foregroundStyle(presentation.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(diagnostic.sourceNumber.displayEventNumber) → \(diagnostic.targetNumber.displayEventNumber)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.white)
                    Text("\(typeLabel(diagnostic.interactionType)) · ID \(diagnostic.id.prefix(8))")
                        .font(.caption.bold())
                        .foregroundStyle(SecretMatchTheme.muted)
                }
                Spacer()
                Text(presentation.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(presentation.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(presentation.color.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(reason(for: diagnostic))
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                Label("\(diagnostic.retryCount) Retries", systemImage: "arrow.clockwise")
                Label(diagnostic.updatedAt, systemImage: "clock")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(SecretMatchTheme.muted)

            VStack(alignment: .leading, spacing: 9) {
                Text("Übertragungsweg")
                    .font(.caption.bold())
                    .foregroundStyle(SecretMatchTheme.secondary)
                ForEach(diagnostic.steps) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(stepColor(step))
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title).font(.subheadline.bold()).foregroundStyle(.white)
                            Text(step.occurredAt).font(.caption).foregroundStyle(SecretMatchTheme.muted)
                        }
                    }
                }
            }
            .padding(12)
            .background(SecretMatchTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))
        }
        .secretCard(padding: 16)
        .overlay(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius).stroke(presentation.color.opacity(0.28)))
    }

    private func statusPresentation(_ state: String) -> (title: String, icon: String, color: Color) {
        switch state {
        case "delivered": return ("Zugestellt", "checkmark.circle.fill", .green)
        case "rejected": return ("Abgelehnt", "xmark.octagon.fill", .red)
        case "retrying": return ("Wartet auf Retry", "wifi.exclamationmark", .orange)
        case "sending": return ("Sendeversuch", "arrow.up.circle.fill", SecretMatchTheme.secondary)
        case "queued": return ("Vorgemerkt", "clock.fill", .orange)
        case "withdrawn": return ("Zurückgezogen", "arrow.uturn.backward.circle.fill", SecretMatchTheme.secondary)
        default: return ("Unbekannt", "questionmark.circle.fill", SecretMatchTheme.muted)
        }
    }

    private func reason(for diagnostic: AdminDeliveryDiagnostic) -> String {
        switch diagnostic.state {
        case "delivered":
            return "Der Server hat die Sendung bestätigt. Sie ist nicht mehr in der iPad-Warteschlange."
        case "rejected":
            return diagnostic.errorCode.isEmpty
                ? "Die Sendung wurde dauerhaft abgelehnt und wird nicht erneut versucht."
                : "Die Sendung wurde dauerhaft abgelehnt (\(diagnostic.errorCode))."
        case "retrying":
            return diagnostic.errorCode.isEmpty
                ? "Der letzte Versuch konnte nicht abgeschlossen werden. Das iPad versucht automatisch erneut zu senden."
                : "Der letzte Versuch scheiterte mit \(diagnostic.errorCode). Das iPad versucht automatisch erneut zu senden."
        case "sending":
            return "Ein Sendeversuch wurde gestartet, aber es liegt noch keine abschließende Bestätigung vor."
        case "queued":
            return "Die Sendung wurde lokal auf dem iPad vorgemerkt. Noch ist kein Sendeversuch protokolliert."
        case "withdrawn":
            return "Die Aktion wurde vom Absender zurückgezogen und ist für den Empfänger nicht mehr sichtbar."
        default:
            return "Der aktuelle Zustand konnte aus den vorhandenen Protokollen nicht eindeutig bestimmt werden."
        }
    }

    private func typeLabel(_ type: String) -> String {
        if type == "normal" { return "Hot Match" }
        if type == "hot" { return "Fuck Match" }
        if type.isEmpty { return "Interaktion" }
        return api.actionDefinitions.first { $0.id == type }?.name
            ?? ActionDefinition.fallback(for: type).name
    }

    private func stepColor(_ step: AdminEventLogEntry) -> Color {
        if step.eventType == "interaction_delivered" { return .green }
        if step.eventType == "interaction_rejected" { return .red }
        if step.eventType == "interaction_retry_scheduled" { return .orange }
        if step.eventType == "action_withdrawn_locally" || step.eventType == "action_withdrawn_success" {
            return SecretMatchTheme.secondary
        }
        return SecretMatchTheme.secondary
    }

    private func search() async {
        guard !sourceNumber.normalizedEventNumber.isEmpty, !isLoading else { return }
        isLoading = true
        hasSearched = true
        errorMessage = nil
        do {
            diagnostics = try await api.loadDeliveryDiagnostics(
                sourceNumber: sourceNumber,
                targetNumber: targetNumber
            )
        } catch {
            diagnostics = []
            errorMessage = "Die Diagnose konnte nicht geladen werden. Bitte Verbindung und Nummern prüfen."
        }
        isLoading = false
    }
}
