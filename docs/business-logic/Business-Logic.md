# Match&Play Business-Logik

Stand: 15. September 2026

Diese Dokumentation beschreibt die fachlichen Regeln von Match&Play im aktuell implementierten Stand. Sie verbindet die Teilnehmer-App, die native Admin-App, die externe Webverwaltung, das Billboard und das WordPress-Plugin zu einem gemeinsamen fachlichen Modell.

## Geltungsbereich und Quelle der Wahrheit

Die Dokumentation erklärt Verhalten und Verträge, ersetzt aber nicht den ausführbaren Code. Bei Abweichungen gilt folgende Reihenfolge:

1. Das WordPress-Plugin ist die Quelle der Wahrheit für Berechtigungen, Validierungen, Kataloge, Eventdaten, Matching, Archive und Statistiken.
2. `APIService` und die Swift-Modelle sind die Quelle der Wahrheit für lokale App-Zustände, Offline-Queue, Caches und die Kommunikation mit der API.
3. Die SwiftUI-Views und die Web-/Billboard-Oberflächen bestimmen Darstellung und Bedienabläufe.
4. Diese Seiten erklären den beabsichtigten fachlichen Zusammenhang über alle Clients hinweg.

Technische interne Namen wie `SecretMatch`, API-Namespace und Bundle-IDs bleiben aus Kompatibilitätsgründen bestehen. Sichtbarer Produktname ist **Match&Play**.

## Systemüberblick

| Teil | Fachliche Aufgabe |
| --- | --- |
| Teilnehmer-App | Anmeldung, Profil-Erstvergabe, Wünsche und Aktionen, Übersicht, Feedback und Offline-Nachlieferung |
| Native Admin-App | Betrieb, Kataloge, Eventdaten, Geräte, Billboard, Archive, Statistik und Diagnose |
| Webverwaltung | Alternativer Admin-Client unter `/matchplay-admin/` mit denselben Serverregeln |
| WordPress-Admin | Konfiguration, Notfallzugang und vollständige serverseitige Verwaltung |
| Billboard | Passive Live-Ausgabe von Matches, Aktionen, Top 16 und Event-Mitteilungen |
| WordPress-Plugin | Kanonische Validierung, Persistenz, Matching, Zugriffsschutz, Archivierung und Benachrichtigungen |

## Dokumente

- [Domänenmodell und Invarianten](domain-model-and-invariants.md)
- [Teilnehmer-Anmeldung und Sitzungen](participant-authentication-and-sessions.md)
- [Wünsche, Matches und Aktionen](interactions-matches-actions.md)
- [Offline-Queue, Verbindung und Telemetrie](offline-queue-connectivity-telemetry.md)
- [Admin und Zugriffsschutz](admin-and-access-control.md)
- [Event-Lebenszyklus, Statistik und Exporte](event-lifecycle-statistics-and-exports.md)
- [Billboard, Mitteilungen und Medien](billboards-announcements-and-media.md)
- [Geräte, Warnungen, Feedback und Datenschutz](devices-alerts-feedback-and-privacy.md)
- [REST-API-Verträge](api-contracts.md)

## Geplante Erweiterungen

- [Pärchenprofile und gemeinsames Matching](couple-profiles-and-matching.md) – fachlicher Zielentwurf; noch nicht implementiert

## Begriffe

| Begriff | Bedeutung |
| --- | --- |
| Eventnummer | Pseudonyme, für das aktuelle Event freigegebene Teilnehmernummer |
| Teilnehmer-Sitzung | Cookie-basierte Serversitzung einer Eventnummer |
| Match-Wunsch | Gerichtete Anfrage einer Nummer an eine andere Nummer mit Match-Typ |
| Match | Gegenseitige Verbindung zweier Nummern, unabhängig von ihrer Reihenfolge eindeutig |
| Aktion | Gerichtete, katalogbasierte Nachricht ohne Gegenseitigkeitsbedingung |
| Versandvorgang | Eine gemeinsame Auswahl, die aus mehreren einzelnen Queue-Einträgen bestehen kann |
| Event-ID | UUID des aktiven Eventstands; grenzt alte lokale Queues von einem neuen Event ab |
| Live-Stand | Aktuell veränderbare Eventdaten vor Abschluss oder Wiederherstellung |
| Archiv | Benannter, geschützter Snapshot eines abgeschlossenen oder gesicherten Live-Stands |
| Katalog | Serverseitig gepflegte Definitionen für Match- oder Aktionstypen |

## Pflege-Regel

Jede Änderung an der Business-Logik muss zusammen mit den passenden automatisierten Tests und der betroffenen Seite dieser Dokumentation ausgeliefert werden. Neue REST-Routen oder geänderte Felder werden zusätzlich in [REST-API-Verträge](api-contracts.md) eingetragen.
