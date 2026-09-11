import SwiftUI
import UIKit

struct AdminExportArtifact: Identifiable {
    let id = UUID()
    let url: URL
}

struct AdminShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

@MainActor
enum AdminReportExporter {
    static func csv(for statistics: AdminEventStatistics, eventName: String) throws -> URL {
        var rows: [[String]] = [
            ["Match&Play Eventbericht", eventName],
            ["Erstellt", statistics.generatedAt],
            ["Zeitraum", statistics.startedAt, statistics.completedAt ?? statistics.endedAt],
            [],
            ["Kennzahl", "Wert"],
        ]
        func addMetric(_ name: String, _ value: String) {
            rows.append([name, value])
        }
        addMetric("Freigegebene Nummern", String(statistics.allowedParticipants))
        addMetric("Teilnehmende", String(statistics.engagedParticipants))
        addMetric("Teilnahmequote Prozent", String(statistics.participationRatePercent ?? 0))
        addMetric("Match-Requests", String(statistics.requests))
        addMetric("Offene Match-Wünsche", String(statistics.openRequests ?? 0))
        addMetric("Match-Wünsche pro aktiver Nummer", String(statistics.requestsPerParticipant ?? 0))
        addMetric("Matches", String(statistics.matches))
        addMetric("Durchschnittliche Minuten bis Match", String(statistics.averageMatchMinutes ?? 0))
        addMetric("Median Minuten bis Match", String(statistics.medianMatchMinutes ?? 0))
        addMetric("Aktionen", String(statistics.actions))
        addMetric("Aktionen pro aktiver Nummer", String(statistics.actionsPerParticipant ?? 0))
        addMetric("Zurückgezogene Aktionen", String(statistics.withdrawnActions ?? 0))
        addMetric("Rückzugsquote Prozent", String(statistics.withdrawalRatePercent ?? 0))
        addMetric("Freitext-Requests", String(statistics.requestsWithMessage))
        addMetric("Freitext-Anteil Prozent", String(statistics.requestsWithMessagePercent ?? 0))
        addMetric("Match-Quote Prozent", String(statistics.matchRatePercent))
        addMetric("Feedbacks", String(statistics.feedbackCount ?? 0))
        addMetric("Feedback Gesamteindruck", String(statistics.feedbackAverage ?? 0))
        addMetric("Feedback Funktion", String(statistics.functionalityAverage ?? 0))
        addMetric("Feedback Bedienung", String(statistics.easeOfUseAverage ?? 0))
        addMetric("Feedback Design", String(statistics.designAverage ?? 0))
        addMetric("Eventdauer Minuten", String(statistics.eventDurationMinutes ?? 0))
        addMetric("Aktivste Viertelstunde", statistics.peakInterval ?? "")
        addMetric("Vorgänge in aktivster Viertelstunde", String(statistics.peakIntervalTotal ?? 0))
        addMetric("Zugestellte Sendungen", String(statistics.deliveryCount))
        addMetric("Retries", String(statistics.retryCount))
        addMetric("Technische Fehler", String(statistics.errorCount))
        addMetric("Abgelehnte Sendungen", String(statistics.rejectedSendCount ?? 0))
        addMetric("Queue-Stillstände", String(statistics.queueStallCount ?? 0))
        addMetric("Verbindungsabbrüche", String(statistics.connectionLossCount ?? 0))
        addMetric("Geräteausfälle", String(statistics.deviceOutageCount ?? 0))
        addMetric("Admin-Aktionen", String(statistics.adminActionCount ?? 0))
        addMetric("Fehlgeschlagene Admin-Aktionen", String(statistics.adminFailureCount ?? 0))
        rows.append([])
        rows.append(["Match-Wunsch Typ", "Anzahl"])
        rows.append(contentsOf: statistics.requestTypes.map { [$0.name, String($0.count)] })
        rows.append([])
        rows.append(["Match-Typ", "Wünsche", "Erfolgreiche Wünsche", "Quote Prozent"])
        rows.append(contentsOf: (statistics.matchTypePerformance ?? []).map {
            [$0.name, String($0.requests), String($0.matches), String($0.ratePercent)]
        })
        rows.append([])
        rows.append(["Aktionstyp", "Anzahl"])
        rows.append(contentsOf: statistics.actionTypes.map { [$0.name, String($0.count)] })
        rows.append([])
        rows.append(["15-Minuten-Zeitraum", "Requests", "Matches", "Aktionen"])
        rows.append(contentsOf: statistics.timeline.map {
            [$0.hour, String($0.requests), String($0.matches), String($0.actions)]
        })

        let contents = rows.map { $0.map(csvField).joined(separator: ";") }.joined(separator: "\n")
        let url = temporaryURL(eventName: eventName, extension: "csv")
        try ("\u{FEFF}" + contents).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func pdf(for statistics: AdminEventStatistics, eventName: String) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 46
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let data = renderer.pdfData { context in
            var y: CGFloat = margin

            func beginPage() {
                context.beginPage()
                y = margin
                UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1).setFill()
                context.cgContext.fill(page)
            }

            func ensureSpace(_ height: CGFloat) {
                if y + height > page.height - margin {
                    beginPage()
                }
            }

            func draw(_ text: String, font: UIFont, color: UIColor = .white, height: CGFloat = 28) {
                ensureSpace(height)
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                (text as NSString).draw(in: CGRect(x: margin, y: y, width: page.width - margin * 2, height: height), withAttributes: attributes)
                y += height
            }

            beginPage()
            draw("MATCH&PLAY", font: .boldSystemFont(ofSize: 12), color: UIColor(red: 0.95, green: 0.66, blue: 0.26, alpha: 1), height: 22)
            draw("Match&Play Eventbericht", font: .boldSystemFont(ofSize: 28), height: 42)
            draw(eventName, font: .boldSystemFont(ofSize: 18), color: UIColor(white: 0.82, alpha: 1), height: 30)
            draw("Erstellt: \(statistics.generatedAt)", font: .systemFont(ofSize: 10), color: UIColor(white: 0.62, alpha: 1), height: 24)
            y += 10

            let metrics: [(String, Int, UIColor)] = [
                ("Teilgenommen", statistics.engagedParticipants, .systemTeal),
                ("Match-Requests", statistics.requests, .systemPurple),
                ("Matches", statistics.matches, .systemPink),
                ("Aktionen", statistics.actions, .systemBlue),
                ("Zugestellt", statistics.deliveryCount, .systemGreen),
                ("Retries", statistics.retryCount, .systemOrange),
                ("Technische Fehler", statistics.errorCount, .systemRed),
                ("Admin-Aktionen", statistics.adminActionCount ?? 0, .systemIndigo),
            ]
            let maximum = max(1, metrics.map(\.1).max() ?? 1)
            draw("Übersicht", font: .boldSystemFont(ofSize: 18), height: 30)
            for metric in metrics {
                ensureSpace(31)
                (metric.0 as NSString).draw(
                    in: CGRect(x: margin, y: y, width: 145, height: 20),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.white]
                )
                let barWidth = CGFloat(metric.1) / CGFloat(maximum) * 285
                metric.2.setFill()
                context.cgContext.fill(CGRect(x: margin + 150, y: y + 3, width: max(metric.1 > 0 ? 4 : 0, barWidth), height: 12))
                (String(metric.1) as NSString).draw(
                    in: CGRect(x: page.width - margin - 48, y: y, width: 48, height: 20),
                    withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.white]
                )
                y += 27
            }

            y += 12
            draw("Qualität & Betrieb", font: .boldSystemFont(ofSize: 18), height: 30)
            draw("Teilnahmequote: \((statistics.participationRatePercent ?? 0).formatted(.number.precision(.fractionLength(1)))) %", font: .boldSystemFont(ofSize: 13), height: 23)
            draw("Match-Quote: \(statistics.matchRatePercent.formatted(.number.precision(.fractionLength(1)))) %", font: .boldSystemFont(ofSize: 13), height: 23)
            draw("Offene Wünsche: \(statistics.openRequests ?? 0) · Ø bis Match: \((statistics.averageMatchMinutes ?? 0).formatted(.number.precision(.fractionLength(1)))) Min.", font: .systemFont(ofSize: 12), color: UIColor(white: 0.8, alpha: 1), height: 21)
            draw("Freitext-Requests: \(statistics.requestsWithMessage)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.8, alpha: 1), height: 21)
            draw("Zurückgezogene Aktionen: \(statistics.withdrawnActions ?? 0)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.8, alpha: 1), height: 21)
            draw("Feedback: \((statistics.feedbackAverage ?? 0).formatted(.number.precision(.fractionLength(1)))) / 5 aus \(statistics.feedbackCount ?? 0) Rückmeldungen", font: .systemFont(ofSize: 12), color: UIColor(white: 0.8, alpha: 1), height: 21)
            draw("Peak: \(statistics.peakInterval ?? "–") · \(statistics.peakIntervalTotal ?? 0) Vorgänge", font: .systemFont(ofSize: 12), color: UIColor(white: 0.8, alpha: 1), height: 21)
            let adminFailures = statistics.adminFailureCount ?? 0
            draw("Fehlgeschlagene Admin-Aktionen: \(adminFailures)", font: .systemFont(ofSize: 12), color: adminFailures > 0 ? .systemOrange : .systemGreen, height: 21)
            draw("Zeitraum: \(statistics.startedAt) – \(statistics.completedAt ?? statistics.endedAt)", font: .systemFont(ofSize: 10), color: UIColor(white: 0.62, alpha: 1), height: 24)

            y += 12
            draw("Verteilung", font: .boldSystemFont(ofSize: 18), height: 30)
            for entry in statistics.requestTypes {
                draw("Match-Wunsch · \(label(for: entry.name)): \(entry.count)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.82, alpha: 1), height: 20)
            }
            for entry in statistics.matchTypePerformance ?? [] {
                draw("\(label(for: entry.name))-Quote: \(entry.ratePercent.formatted(.number.precision(.fractionLength(1)))) % (\(entry.matches) von \(entry.requests) Wünschen erfolgreich)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.82, alpha: 1), height: 20)
            }
            for entry in statistics.actionTypes {
                draw("Aktion · \(label(for: entry.name)): \(entry.count)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.82, alpha: 1), height: 20)
            }

            y += 12
            draw("Technik & Stabilität", font: .boldSystemFont(ofSize: 18), height: 30)
            draw("Abgelehnt \(statistics.rejectedSendCount ?? 0) · Queue hing \(statistics.queueStallCount ?? 0) · Verbindung weg \(statistics.connectionLossCount ?? 0) · Geräte offline \(statistics.deviceOutageCount ?? 0)", font: .systemFont(ofSize: 11), color: UIColor(white: 0.82, alpha: 1), height: 22)

            if !statistics.timeline.isEmpty {
                y += 12
                draw("Aktivitätsverlauf", font: .boldSystemFont(ofSize: 18), height: 30)
                for point in statistics.timeline.suffix(24) {
                    draw("\(point.hour)   Requests \(point.requests) · Matches \(point.matches) · Aktionen \(point.actions)", font: .monospacedSystemFont(ofSize: 9, weight: .regular), color: UIColor(white: 0.75, alpha: 1), height: 16)
                }
            }

            ensureSpace(45)
            y += 18
            draw("Anonymer Bericht: keine Eventnummern, PINs, Nachrichten oder Gerätekennungen enthalten.", font: .italicSystemFont(ofSize: 9), color: UIColor(white: 0.55, alpha: 1), height: 26)
        }

        let url = temporaryURL(eventName: eventName, extension: "pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func temporaryURL(eventName: String, extension fileExtension: String) -> URL {
        let name = eventName.lowercased().replacingOccurrences(of: " ", with: "-")
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("match-and-play-\(name)-bericht")
            .appendingPathExtension(fileExtension)
    }

    private static func label(for type: String) -> String {
        ["normal": "Hot", "hot": "Fuck", "bjob": "Blow-Job", "hjob": "Hand-Job", "ljob": "Lick-Job"][type] ?? type
    }
}
