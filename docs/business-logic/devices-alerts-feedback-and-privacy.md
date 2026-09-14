# Geräte, Warnungen, Feedback und Datenschutz

[Zur Übersicht](Business-Logic.md)

## Geräteidentität und Heartbeat

Jede Teilnehmerinstallation erzeugt eine zufällige UUID. Für den login-unabhängigen Heartbeat wird zusätzlich ein zufälliger Geräte-Token im iOS-Schlüsselbund gespeichert; der Server hält nur dessen Hash. Die erstmalige Registrierung geschieht während einer gültigen Teilnehmer-Sitzung. Danach darf dasselbe Gerät auch auf der Loginseite weiter Heartbeats senden.

Im Vordergrund übermittelt die App alle 30 Sekunden:

- pseudonyme Installations-ID,
- letzte beziehungsweise aktuelle Eventnummer, sofern angemeldet,
- Akkustand und Ladezustand,
- App-Version,
- Zahl einzelner Queue-Aktionen und gemeinsamer Versandvorgänge,
- Alter des ältesten Queue-Eintrags,
- letzten erfolgreichen Sync,
- Verbindungszustand und lokalen Loginstatus.

Der Server akzeptiert Akkustände von 0 bis 100, bekannte Lade- und Verbindungszustände und begrenzt Queue-Zähler. Das Gerät gilt in den Adminansichten bis drei Minuten nach dem letzten Signal als online. Die zufällige technische Identität bleibt bestehen, während ein Admin einen verständlichen Anzeigenamen pflegen kann.

Beim Löschen entfernt der Server Status, Anzeigename, Heartbeat-Token und zugehörige Warnzustände. Ist auf dem iPad noch ein Teilnehmer angemeldet, registriert der nächste Heartbeat das Gerät erneut; auf der Loginseite ist dafür zunächst wieder eine gültige Teilnehmeranmeldung nötig.

## Betriebswarnungen

Der Server überwacht Heartbeats unabhängig von einer geöffneten Admin-App:

- Billboard-Warnung nach 90 Sekunden ohne Signal,
- iPad-Warnung nach 180 Sekunden ohne Signal,
- Queue-Warnung bei mindestens 60 Sekunden festhängender Queue,
- Warnung bei kritischem Akkustand,
- einmalige Entwarnung bei Erholung.

Unveränderte Fehlerzustände erzeugen keine wiederholten Warnungen. Für verlässliche Zeiten muss ein echter Server-Cron `wp-cron.php` mindestens einmal pro Minute ausführen.

Warnungen gehen über die vorhandene Telegram-Konfiguration und, falls eingerichtet, zusätzlich über APNs an registrierte Admin-Geräte. Ein APNs-Fehler darf Telegram nicht verhindern. Von Apple als ungültig oder widerrufen gemeldete Push-Tokens werden entfernt.

## APNs-Zugriff und Diagnose

Die native Admin-App registriert und entfernt ihren Push-Token nur über authentifizierte Admin-Routen. APNs-Key-ID, Team-ID, Topic und privater Schlüssel existieren ausschließlich auf dem Server. Bevorzugt wird eine nicht öffentlich erreichbare Schlüsseldatei; die ältere Inline-Konfiguration bleibt kompatibel.

Dashboard und Testfunktion zeigen nur sichere Ergebnisse: Gültigkeit der IDs und des Topics, Schlüssel vorhanden/lesbar/gültig, Quelle `file` oder `inline`, OpenSSL, cURL und HTTP/2. Weder Schlüsselmaterial noch Pfade oder Gerätetokens verlassen den Server.

## Anonymes Feedback

Die Teilnehmer-App erfasst vier Pflichtbewertungen von jeweils 1 bis 5 Sternen:

- Gesamtbewertung,
- Funktionalität,
- Bedienbarkeit,
- Design.

`reuse_rating` bleibt für ältere Clients optional kompatibel. Der Versand verwendet eine ephemere, cookiefreie URLSession und enthält weder Eventnummer noch Teilnehmer-Sitzung. Feedback ist nur für Administratoren lesbar und kann einzeln gelöscht, aber nicht nachträglich verändert werden.

Feedback gehört zum Event: Es wird in den Event-Snapshot aufgenommen und anschließend aus dem neuen Live-Stand entfernt. Statistik und anonyme Berichte dürfen nur Aggregate verwenden.

## Datenschutzmatrix

| Datenart | Zweck | Sichtbarkeit/Aufbewahrung |
| --- | --- | --- |
| Eventnummer | pseudonyme Teilnahme und Zuordnung | Teilnehmer sieht eigene/relevante Gegenüber; Admins sehen Eventdaten; Bestandteil geschützter Archive |
| PIN | Schutz der Nummernanmeldung | serverseitige zweistellige Werte, nur über geschützte Adminbereiche verwaltbar; nie Archiv, Log oder Export; Reset je Eventwechsel |
| Gender | Filterung von Aktionstypen | Zielwert wird Teilnehmern nicht offengelegt; Eventprofil und geschütztes Archiv |
| Match-Nachricht | Kommunikation zwischen gematchten Nummern | nur relevantes Gegenüber und Admins; Eventdaten/Archiv; nie Push, Telegram oder Audit |
| Geräte-ID | Betriebsüberwachung | zufällig lokal, serverseitig gehasht; keine Seriennummer oder Apple-ID |
| Push-/Kiosk-/Auth-Token | Zugriff | nur Klartext beim jeweiligen Client; serverseitig gehasht oder geschützt; nie Adminliste/Log |
| Feedback | Produktverbesserung | ohne Nummer und Sitzung; Admins und aggregierte Statistik |
| Telemetrie/Audit | Diagnose und Nachvollziehbarkeit | bekannte sichere Felder; operativ 14 Tage, Admin/Sicherheit höchstens 90 Tage, danach Archivgrenze |

## Grundsätze

- Es werden keine Namen, E-Mail-Adressen, Apple-Konten oder Hardware-Seriennummern für den Eventablauf benötigt.
- Secrets und Nachrichteninhalte werden aus Logs entfernt.
- Öffentliche Billboard-Seiten zeigen nur den für den Eventbetrieb vorgesehenen pseudonymen Live-Inhalt.
- Vollständige Archive sind personenbezugsärmer als Namensdaten, aber wegen Nummern, Profilen und Freitext trotzdem geschützt zu behandeln.
