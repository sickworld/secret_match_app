import SwiftUI

struct AdminChangelogView: View {
    private let releases = AdminChangelogRelease.all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                LazyVStack(spacing: 14) {
                    ForEach(releases) { release in
                        releaseCard(release)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2.bold())
                    .foregroundStyle(Color.mint)
                    .frame(width: 52, height: 52)
                    .background(Color.mint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: SecretMatchTheme.cornerRadius))

                VStack(alignment: .leading, spacing: 5) {
                    Text("MATCH&PLAY")
                        .font(.caption.bold())
                        .tracking(1.8)
                        .foregroundStyle(SecretMatchTheme.secondary)
                    Text("Changelog")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Neue Funktionen, Verbesserungen und wichtige Änderungen.")
                        .foregroundStyle(SecretMatchTheme.muted)
                }

                Spacer(minLength: 0)
            }

            Label("Installiert: Version \(appVersion) (Build \(buildNumber))", systemImage: "iphone.gen3")
                .font(.callout.bold().monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(SecretMatchTheme.surfaceRaised)
                .clipShape(Capsule())
                .accessibilityLabel("Installierte Version \(appVersion), Build \(buildNumber)")
        }
        .secretCard(padding: 20)
    }

    private func releaseCard(_ release: AdminChangelogRelease) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(release.version)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)

                if release.version == appVersion {
                    Text("AKTUELL")
                        .font(.caption2.bold())
                        .tracking(0.8)
                        .foregroundStyle(Color.mint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mint.opacity(0.14))
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)

                Text(release.date)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(SecretMatchTheme.muted)
            }

            VStack(alignment: .leading, spacing: 11) {
                ForEach(release.changes, id: \.self) { change in
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.callout.bold())
                            .foregroundStyle(Color.mint)
                            .padding(.top, 1)
                            .accessibilityHidden(true)

                        Text(change)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .secretCard(padding: 20)
        .accessibilityElement(children: .contain)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"
    }
}

private struct AdminChangelogRelease: Identifiable {
    let version: String
    let date: String
    let changes: [String]

    var id: String { version }

    static let all: [AdminChangelogRelease] = [
        AdminChangelogRelease(
            version: "2026.09.13",
            date: "13.09.2026",
            changes: [
                "Der neue Changelog macht Änderungen und die installierte App-Version direkt im Admin sichtbar.",
                "Event-Mitteilungen lassen sich zentral erstellen und auf allen Billboards anzeigen."
            ]
        ),
        AdminChangelogRelease(
            version: "2026.09.12",
            date: "12.09.2026",
            changes: [
                "Aktionen und Match-Typen können über konfigurierbare Kataloge verwaltet werden.",
                "Die Aktionsverwaltung auf dem iPhone wurde übersichtlicher und leichter bedienbar.",
                "Die Auswahl passender Zielaktionen wurde vereinfacht."
            ]
        ),
        AdminChangelogRelease(
            version: "2026.09.10",
            date: "10.09.2026",
            changes: [
                "Event-Archive können im Admin verwaltet und bei Bedarf wiederhergestellt werden.",
                "Das Zurücksetzen von Teilnehmer-PINs während eines Eventwechsels wurde verständlicher gemacht."
            ]
        ),
        AdminChangelogRelease(
            version: "2026.09.09",
            date: "09.09.2026",
            changes: [
                "Admin-Zugänge lassen sich als eigene Zugangsdaten verwalten und widerrufen.",
                "Bildschirmschoner- und Sponsorenmedien können zentral gepflegt werden.",
                "Teilnehmer können gesendete Aktionen zurückziehen und sehen passendere Aktionsvorschläge.",
                "Offline-Fehler und Netzwerk-Zeitüberschreitungen werden schneller erkannt."
            ]
        )
    ]
}
