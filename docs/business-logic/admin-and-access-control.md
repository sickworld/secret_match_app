# Admin und Zugriffsschutz

[Zur Übersicht](Business-Logic.md)

## Admin-Zugänge

Neben einem kompatiblen Standardzugang können bis zu 20 benannte Admin-Zugänge existieren. Jeder besitzt eine UUID, einen Anzeigenamen, einen ausschließlich gehasht gespeicherten Passwortwert und einen Erstellzeitpunkt. Das im WordPress-Backend gepflegte Match&Play-Standardpasswort und optional `SECRETMATCH_ADMIN_PASSWORD` bleiben als Standard- beziehungsweise Konfigurationszugang kompatibel.

Ein erfolgreicher API-Login stellt ein zufälliges Bearer-Token aus. Seine Laufzeit ist zwischen einer und 24 Stunden konfigurierbar und beträgt standardmäßig 12 Stunden. Das Token ist einem benannten Zugang zugeordnet, sofern dieser verwendet wurde.

- Die native Admin-App verwendet das Token im Arbeitsspeicher und speichert es gerätegebunden im iOS-Schlüsselbund, damit eine gültige Sitzung einen Neustart überstehen kann.
- Optional gespeicherte biometrische Zugangsdaten liegen mit Bindung an den aktuellen Biometriesatz ebenfalls im iOS-Schlüsselbund.
- Ein Logout widerruft das Token serverseitig und räumt lokale Zugangsdaten auf.
- Das Löschen eines benannten Zugangs widerruft alle zugehörigen Sitzungen sofort.
- Passwortrotation oder relevante Zugangsänderung widerruft bestehende Sitzungen dieses Zugangs.

## Webverwaltung

Die externe Verwaltung unter `/matchplay-admin/` ist ein alternativer Client derselben Admin-API und enthält keine eigene fachliche Schreiblogik. Das Bearer-Token liegt ausschließlich in einem sicheren `HttpOnly`-Cookie und wird nicht an JavaScript ausgegeben. Zusätzlich benötigt jeder Browser-API-Aufruf einen an die Sitzung gebundenen CSRF-Wert.

Friendly Captcha v2 schützt ausschließlich den Web-Admin-Login, sobald Sitekey und API-Key vollständig konfiguriert sind. Fachlich ungültige, abgelaufene oder wiederverwendete Lösungen werden vor der Passwortprüfung abgewiesen und zählen zum IP-Limit. Reine Netzwerk- oder Dienstausfälle der externen Prüfung werden protokolliert, blockieren aber nicht den gesamten Login; Passwortprüfung und Lockout bleiben aktiv. Der API-Key wird nie ans Frontend oder in Logs ausgegeben.

## Berechtigungsgrenze

Alle `/admin/*`-Routen außer Login verlangen ein gültiges Bearer-Token. WordPress-Oberflächen verlangen zusätzlich die passenden Administratorrechte und Nonces. Der Server führt dieselben Validierungs- und Mutationsmethoden aus, unabhängig davon, ob eine Änderung aus nativer App, Webverwaltung oder WordPress-Backend kommt.

## Fachliche Admin-Funktionen

Administratoren können:

- Dashboard, Systemzustand und aktive Betriebsdaten lesen,
- Teilnehmer freigeben, Bereiche abgleichen, sperren, abmelden sowie PIN und Gender verwalten,
- Aktionen und Matches anlegen, ändern und löschen,
- Match-Requests einschließlich Status und Freitext lesen, ändern und löschen,
- Match- und Aktionskataloge verwalten,
- bis zu acht Match-Schnelltexte pflegen,
- Screensaver-/Sponsorenmedien und Leerlaufzeit pflegen,
- Event-Mitteilungen verwalten,
- Geräte und Billboards benennen oder widerrufen,
- Protokoll, Nummernakte, Sendungsdiagnose und Statistik lesen,
- Feedback lesen und löschen,
- Testdaten erzeugen oder entfernen,
- Events abschließen, Archive verwalten und wiederherstellen.

Feedback ist absichtlich unveränderlich: Admins dürfen es lesen oder löschen, aber nicht umschreiben.

## Validierung administrativer Eventdaten

Auch Admin-Mutationen müssen unterschiedliche und freigegebene Nummern verwenden. Aktionstypen müssen im Katalog existieren. Historische ausgeblendete Typen dürfen für Korrekturen bestehender Datensätze verwendet werden. Matches bleiben pro ungeordnetem Nummernpaar eindeutig.

Beim Verkleinern des regulären Nummernbereichs nennt die API vorab die betroffenen Nummern und verlangt exakt `NUMMERN ANPASSEN`. Entfernte Nummern verlieren Profil, PIN und Sitzungen. Das Zielmaximum liegt zwischen 1 und 10.000; der bestätigungspflichtige Sonderwert `0` entfernt alle regulären Nummern. Dummy-Nummern bleiben standardmäßig erhalten.

## Sicherheitsbestätigungen

| Operation | Exakte Bestätigung |
| --- | --- |
| Nummernbereich verkleinern | `NUMMERN ANPASSEN` |
| Aktuelles Event abschließen | `EVENT ABSCHLIESSEN` |
| Archiv wiederherstellen | `EVENT WIEDERHERSTELLEN` |

Aktuelle Oberflächen ergänzen bei besonders destruktiven Aktionen einen verständlichen Dialog. `EVENT RESET` bleibt nur als API-Kompatibilität für ältere native Clients bestehen.

## Admin-Audit

Jede schreibende Admin-Aktion aus API und WordPress wird mit Kategorie, Ereignistyp, Akteur, betroffenen fachlichen Referenzen, Ergebnis und sicherem Kontext protokolliert. Die Protokollierung klassifiziert Authentifizierung, Interaktionen, Geräte, Billboard, Kataloge, Eventwechsel und Systembetrieb getrennt.

Nicht protokolliert werden Passwörter, PINs, Bearer-/CSRF-/Push-/Kiosk-Tokens, APNs-Schlüssel oder Nachrichteninhalte. Admin-Oberflächen erhalten bei APNs ausschließlich boolesche Diagnosewerte und die Art der Schlüsselquelle, nie Schlüsselmaterial oder Dateipfade.

## Testdaten

Die gemeinsame Testdatenfunktion nutzt ausschließlich die reservierten Nummern `901…916` und erzeugt einen simulierten vierstündigen Verlauf mit 48 Matches, 300 Aktionen und 96 Requests. Das Entfernen der Testdaten darf echte Eventnummern und deren Daten nicht verändern.
