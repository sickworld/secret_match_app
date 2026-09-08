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
        var rows = [
            ["SecretMatch Eventbericht", eventName],
            ["Erstellt", statistics.generatedAt],
            ["Zeitraum", statistics.startedAt, statistics.completedAt ?? statistics.endedAt],
            [],
            ["Kennzahl", "Wert"],
            ["Freigegebene Nummern", String(statistics.allowedParticipants)],
            ["Teilnehmende", String(statistics.engagedParticipants)],
            ["Match-Requests", String(statistics.requests)],
            ["Matches", String(statistics.matches)],
            ["Aktionen", String(statistics.actions)],
            ["Freitext-Requests", String(statistics.requestsWithMessage)],
            ["Match-Quote Prozent", String(statistics.matchRatePercent)],
            ["Zugestellte Sendungen", String(statistics.deliveryCount)],
            ["Retries", String(statistics.retryCount)],
            ["Technische Fehler", String(statistics.errorCount)],
            ["Admin-Aktionen", String(statistics.adminActionCount ?? 0)],
            ["Fehlgeschlagene Admin-Aktionen", String(statistics.adminFailureCount ?? 0)],
            [],
            ["Match-Wunsch Typ", "Anzahl"],
        ]
        rows.append(contentsOf: statistics.requestTypes.map { [$0.name, String($0.count)] })
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
            draw("SecretMatch Eventbericht", font: .boldSystemFont(ofSize: 28), height: 42)
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
            draw("Match-Quote: \(statistics.matchRatePercent.formatted(.number.precision(.fractionLength(1)))) %", font: .boldSystemFont(ofSize: 13), height: 23)
            draw("Freitext-Requests: \(statistics.requestsWithMessage)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.8, alpha: 1), height: 21)
            let adminFailures = statistics.adminFailureCount ?? 0
            draw("Fehlgeschlagene Admin-Aktionen: \(adminFailures)", font: .systemFont(ofSize: 12), color: adminFailures > 0 ? .systemOrange : .systemGreen, height: 21)
            draw("Zeitraum: \(statistics.startedAt) – \(statistics.completedAt ?? statistics.endedAt)", font: .systemFont(ofSize: 10), color: UIColor(white: 0.62, alpha: 1), height: 24)

            y += 12
            draw("Verteilung", font: .boldSystemFont(ofSize: 18), height: 30)
            for entry in statistics.requestTypes {
                draw("Match-Wunsch · \(label(for: entry.name)): \(entry.count)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.82, alpha: 1), height: 20)
            }
            for entry in statistics.actionTypes {
                draw("Aktion · \(label(for: entry.name)): \(entry.count)", font: .systemFont(ofSize: 12), color: UIColor(white: 0.82, alpha: 1), height: 20)
            }

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
            .appendingPathComponent("secretmatch-\(name)-bericht")
            .appendingPathExtension(fileExtension)
    }

    private static func label(for type: String) -> String {
        ["normal": "Hot", "hot": "Fuck", "bjob": "Blow-Job", "hjob": "Hand-Job", "ljob": "Lick-Job"][type] ?? type
    }
}
