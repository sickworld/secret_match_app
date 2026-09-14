# Offline-Queue, Verbindung und Telemetrie

[Zur Übersicht](Business-Logic.md)

## Lokale Versandqueue

Match-Wünsche und Aktionen werden in der Teilnehmer-App vor dem ersten Netzwerkversuch lokal gespeichert. Jeder Eintrag enthält:

- eigene UUID und gemeinsame Batch-ID,
- ursprüngliche Absender- und Zielnummer,
- fachlichen Typ und Art `match` oder `action`,
- bei Matches die auf 180 Zeichen begrenzte Nachricht,
- Erstellzeit, Retry-Zähler und Zeitpunkt des nächsten Versuchs.

Die Batch-ID fasst eine gemeinsame Auswahl für die Anzeige als einen Versandvorgang zusammen. Die Queue selbst verarbeitet weiterhin jeden Typ einzeln und in Einfügereihenfolge.

## Zustellentscheidung

Ein Queue-Eintrag wird nur entfernt, wenn der Server die fachlich erfolgreiche Persistenz bestätigt. Folgende Ergebnisse bleiben retrybar:

- fehlende oder ungültig decodierbare Antwort,
- Netzwerk- und DNS-Probleme, Timeout oder Verbindungsverlust,
- HTTP 401, 403, 408, 425, 429 sowie Serverfehler ab 500.

Endgültige Fachfehler wie ungültige Eingaben, unzulässiges Ziel, zu lange Nachricht, Request-ID-Konflikt oder abgelehnter Typ werden nicht erneut gesendet. Bei einem solchen Fehler verwirft die App die übrigen Einträge desselben Batches, damit keine teilweise fachlich falsche Auswahl weiterläuft.

## Retry-Verhalten

Nach einem temporären Fehler wächst der Abstand exponentiell: 2, 4, 8, 16 und anschließend höchstens 30 Sekunden. Die App plant den nächsten Versuch nur für die aktuell angemeldete ursprüngliche Absendernummer. Ein manueller Retry setzt deren fällige Einträge sofort auf Versuch null zurück.

Ein erfolgreicher Verbindungstest, die Rückkehr der App in den Vordergrund und ein abgeschlossener Login stoßen die Queue ebenfalls an. Vor einer neuen Anmeldung versucht die App, eine noch bestehende Serversitzung der vorherigen Nummer zu erkennen und deren Queue fertigzustellen.

Einträge überleben App-Neustarts, werden aber nach 24 Stunden gelöscht. Sie dürfen niemals unter einer später angemeldeten anderen Eventnummer versendet werden.

## Eventgrenze

Die serverseitige `event_id` grenzt Events voneinander ab. Bei einem Wechsel löscht die App sämtliche lokalen Interaktionen und Telemetrie des vorherigen Events. Das ist bewusst strenger als eine Nummernprüfung: Auch dieselbe Eventnummer darf nach Eventabschluss keine alte Sendung nachliefern.

## Rückzug und Queue

Beim Rückzug entfernt die App passende noch wartende Aktionseinträge lokal. Für möglicherweise bereits zugestellte Einträge sendet sie zusätzlich das serverseitige DELETE. Netzwerkfehler beim Rückzug dürfen den lokalen Queue-Eintrag nicht unkontrolliert reaktivieren; der serverseitige Tombstone schützt vor späteren Duplikaten.

## Verbindungsmodell

Die App unterscheidet:

- `checking`: Prüfung läuft,
- `online`: Netzwerk und SecretMatch-Server sind erreichbar,
- `offline`: kein nutzbarer Netzwerkpfad,
- `server_unavailable`: Netzwerk vorhanden, Server aber nicht erreichbar.

Der Netzwerkpfad wird laufend beobachtet; im Vordergrund prüft die App den Status zusätzlich alle 15 Sekunden. Der Hinweis ist ein Overlay und verändert nicht das eigentliche Layout. Authentifizierung bleibt immer onlinepflichtig. Nur die Interaktionsauswahl und bereits vorgemerkte Sendungen besitzen einen Offline-Fallback.

## Client-Telemetrie

Die App protokolliert Queue- und Verbindungsereignisse lokal und liefert sie später in Paketen von höchstens 50 Einträgen nach. Unterstützt werden:

- vorgemerkt, Versand gestartet, Retry geplant, zugestellt und abgelehnt,
- Verbindung verloren und Verbindung wiederhergestellt.

Ein Event enthält UUID, Zeitpunkt, Kategorie, Typ, pseudonyme Gerätekennung, optional Zielnummer und Request-ID, Status und einen begrenzten technischen Kontext. Der Server akzeptiert nur bekannte Ereignistypen, dedupliziert über die Event-UUID und begrenzt einen Teilnehmer auf 300 Einträge pro Minute.

Lokal bleiben Telemetrieeinträge höchstens sieben Tage und insgesamt höchstens 500 Einträge erhalten. Serverseitig werden operative Diagnoseeinträge regulär 14 Tage, Admin- und Sicherheitsereignisse höchstens 90 Tage aufbewahrt. Beim Eventabschluss wandert das aktive Eventprotokoll in den Snapshot und der neue Live-Stand beginnt leer.

## Datenschutz der Diagnose

PINs, Passwörter, Auth-, Geräte- oder Push-Tokens und Freitextnachrichten gehören niemals in Telemetrie oder Audit. Bei Interaktionen werden nur fachliche Nummern, Ressourcentyp, technische ID, Status und Fehlercode verwendet. Die Geräte-ID wird serverseitig gehasht.
