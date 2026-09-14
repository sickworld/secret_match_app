# Domänenmodell und Invarianten

[Zur Übersicht](Business-Logic.md)

## Zentrale Entitäten

### Event und Eventnummer

Ein aktiver Eventstand besitzt eine UUID als `event_id`. Eventnummern werden als Strings behandelt, für die Anzeige kurz numerischer Werte aber mit führenden Nullen auf drei Stellen formatiert. Eingaben werden von Leerzeichen, einem optionalen `#` und überflüssigen führenden Nullen bereinigt. Nicht numerische Werte bleiben für historische oder technische Kompatibilität lesbar.

Nur freigegebene Nummern dürfen sich anmelden oder an Interaktionen beteiligt sein. Reguläre Nummernbereiche umfassen `1…N` mit `N` zwischen 1 und 10.000; der administrative Sonderwert `0` entfernt nach Bestätigung alle regulären Nummern. Die reservierten Dummy-Nummern `901…916` bleiben bei einem normalen Bereichsabgleich unberührt.

### Teilnehmerprofil

Ein Profil ordnet genau einer Eventnummer ein fachliches Geschlecht zu. Zulässige Werte sind `female` und `male`. Die Angabe dient ausschließlich zur Filterung passender Aktionstypen. Das Zielprofil selbst wird nicht an andere Teilnehmer-Clients ausgegeben.

Eine Nummer kann freigegeben sein, ohne bereits PIN oder Profil zu besitzen. PIN und Profil entstehen beim ersten Login in dieser Reihenfolge. Das Entfernen einer Nummer löscht die zugehörigen Profile, PINs und Sitzungen.

### Match-Wunsch und Match

Ein Match-Wunsch ist gerichtet: Absender, Empfänger, Match-Typ, optionale Nachricht, Erstellzeit und optionale `request_id`. Absender und Empfänger müssen verschieden und freigegeben sein.

Ein Match ist ungerichtet. Für dasselbe Nummernpaar darf unabhängig von der Reihenfolge nur ein Match existieren. Es enthält den aufgelösten Match-Typ sowie, aus Sicht beider Seiten, die jeweils fremde Nachricht.

### Aktion

Eine Aktion ist gerichtet und besteht aus Absender, Empfänger, Aktionstyp, Erstellzeit und optionaler `request_id`. Zurückgezogene Aktionen bleiben mit Widerrufszeit und Request-ID als Tombstone erhalten, sind aber nicht mehr als aktive Aktion sichtbar. Dadurch kann ein verspäteter Retry sie nicht erneut aktivieren.

### Katalogdefinitionen

Match-Typen besitzen technische ID, Name, Emoji, Farbe, Reihenfolge und Sichtbarkeit. Aktionstypen besitzen zusätzlich Kategorie, Richtung und Zielgeschlecht `any`, `female` oder `male`.

Technische IDs bestehen serverseitig aus stabilen Kleinbuchstaben-/Ziffern-Bezeichnern mit `_` oder `-` und sind höchstens 30 Zeichen lang. Historische IDs bleiben darstellbar. Der alte Match-Typ `F-` wird beim Lesen auf `hot` normalisiert.

Bereits verwendete Definitionen dürfen ausgeblendet, aber nicht gelöscht werden. Mindestens ein Match-Typ bleibt aktiv. Der Server verhindert außerdem eine Konfiguration, die für ein bekanntes männliches oder weibliches Ziel keine einzige Aktion mehr anbietet.

### Betriebsdaten

Geräte, Billboards, Admin-Push-Empfänger, Telemetrie und Audit-Einträge sind Betriebsdaten. Rohe Geräte-, Kiosk- und Push-Tokens werden nicht in Adminansichten ausgegeben. Geräte und Billboards erhalten organisatorische Anzeigenamen; ihre technische Identität bleibt pseudonym.

## Globale Invarianten

- Ein Teilnehmer darf niemals an sich selbst senden.
- Teilnehmerinteraktionen benötigen eine gültige Teilnehmer-Sitzung und weiterhin freigegebene Absender- und Zielnummern.
- Fachliche Validierung findet serverseitig statt; Clientvalidierung verbessert nur die Bedienung.
- Eine HTTP-200-Antwort gilt nur dann als Zustellung, wenn der fachliche Erfolgswert ebenfalls erfolgreich ist.
- Request-IDs dürfen nicht für andere Absender, Ziele oder Typen wiederverwendet werden.
- Eventdaten und globale Konfiguration sind getrennt: Kataloge, erlaubte Nummern, Schnelltexte und Medien überleben einen Eventwechsel; Matches, Requests, Aktionen, Profile, Feedback, Mitteilungen und Eventprotokoll nicht.
- PINs sind weder Teil von Eventarchiven noch von Statistik oder Audit.
- Freitext wird nicht an Telegram, APNs, Telemetrie oder Audit weitergegeben.
- Teilnehmer sehen nur Daten, die aus ihrer Serversitzung abgeleitet werden; fremde Nummern können nicht als Lesefilter eingeschleust werden.

## Zuständigkeit für Regeln

| Regelgruppe | Kanonische Ausführung |
| --- | --- |
| Anmeldung, PIN, Profil, Freigabe | WordPress-API und Session-Schicht |
| Match-Auflösung und Upgrade | WordPress-Matcher und Match-Katalog |
| Aktionsfilter und Widerruf | WordPress-API und Aktionskatalog |
| Offline-Retry und lokale Aufbewahrung | Teilnehmer-App |
| Eventabschluss und Restore | WordPress-API in Datenbanktransaktionen |
| Statistik | WordPress-Server aus Live- oder Archiv-Snapshot |
| UI-Ablauf, Countdown und Darstellung | jeweiliger Client |

## Kompatibilitätsprinzipien

Historische Daten müssen auch nach Katalogänderungen verständlich bleiben. Deshalb liefern Fallback-Definitionen einen brauchbaren Namen, Emoji und Farbe für unbekannte IDs. Alte Clients dürfen `request_id` weglassen; neue Clients senden für jeden Queue-Eintrag eine UUID. Das ältere Bestätigungswort `EVENT RESET` bleibt nur für bestehende native Clients API-kompatibel, während aktuelle Oberflächen `EVENT ABSCHLIESSEN` verlangen.
