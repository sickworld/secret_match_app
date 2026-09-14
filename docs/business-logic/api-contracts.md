# REST-API-Verträge

[Zur Übersicht](Business-Logic.md)

## Grundlagen

Basis ist `/wp-json/secretmatch/v1`. Teilnehmer-Routen verwenden die serverseitige Cookie-Sitzung. Admin-Routen verwenden `Authorization: Bearer <token>`, ausgenommen der Admin-Login. JSON ist das Standardformat; Teilnehmer-Login, PIN und Profil werden von der App formcodiert gesendet.

Fehler werden als WordPress-REST-Fehler mit stabilem `code`, verständlicher `message` und HTTP-Status geliefert. Clients dürfen HTTP 200 nicht allein als fachlichen Erfolg interpretieren.

## Teilnehmer-Routen

| Methode und Pfad | Zugriff | Fachlicher Zweck |
| --- | --- | --- |
| `POST /login` | öffentlich, gedrosselt | Nummer/PIN prüfen, Sitzung anlegen, `needs_pin`, `needs_gender` und `event_id` liefern |
| `POST /pin` | Teilnehmer-Sitzung | erstmalige zweistellige PIN atomar speichern |
| `POST /profile` | Teilnehmer-Sitzung und gesetzte PIN | Gender `female` oder `male` speichern |
| `POST /logout` | Teilnehmer-Sitzung optional | Sitzung beenden; idempotenter Erfolg |
| `GET /status` | Cookie optional | Loginstatus, Nummer falls vorhanden und aktuelle `event_id` |
| `POST /heartbeat` | Sitzung oder registrierter Geräte-Token | Geräte-, Akku-, Verbindungs- und Queue-Zustand aktualisieren |
| `POST /telemetry/events` | Teilnehmer-Sitzung | bis zu 50 bekannte Clientereignisse dedupliziert übernehmen |
| `GET /interaction-options?target_number=…` | Teilnehmer-Sitzung | Ziel prüfen und zulässige Match-/Aktionstypen ohne Zielprofil liefern |
| `GET /match-types` | öffentlich lesbarer Katalog | alle Match-Definitionen für aktive und historische Darstellung |
| `GET /action-types` | öffentlich lesbarer Katalog | aktive Aktionstypen liefern |
| `GET /match-message-options` | Teilnehmer-Sitzung | bis zu acht Schnelltexte liefern |
| `POST /match` | Teilnehmer-Sitzung | Wunsch speichern und gegebenenfalls Match erzeugen/aufwerten |
| `GET /matches` | Teilnehmer-Sitzung | Matches der Sitzungsnummer mit Gegenüber-Nachricht liefern |
| `GET /interests` | Teilnehmer-Sitzung | offene eingehende Wünsche der Sitzungsnummer zusammengefasst liefern |
| `POST /actions` | Teilnehmer-Sitzung | katalogbasierte Aktion idempotent speichern |
| `GET /actions` | Teilnehmer-Sitzung | aktive relevante Aktionen liefern |
| `DELETE /actions/{request_id}` | Teilnehmer-Sitzung | eigene Aktion idempotent zurückziehen |
| `POST /feedback` | bewusst cookiefrei | anonyme Sternebewertungen speichern |
| `GET /screensaver-content` | öffentlich | sichtbaren sortierten Medienkatalog liefern |
| `GET /screensaver-settings` | öffentlich | zentrale Leerlaufzeit liefern |

### Wichtige Teilnehmerfelder

`POST /login` erwartet `secretmatch_number` und optional `secretmatch_pin`. Erfolg liefert mindestens `success`, `number`, `needs_pin`, `needs_gender` und `event_id`.

`POST /match` erwartet `target_number`, `match_type`, optional `message` bis 180 Zeichen und optional eine UUID als `request_id`. `POST /actions` erwartet `target_number`, `action_type` und optional `request_id`.

`POST /feedback` erwartet `rating`, `functionality_rating`, `ease_of_use_rating` und `design_rating` jeweils 1–5; `reuse_rating` ist optional kompatibel.

## Admin-Authentifizierung und Zugänge

| Methode und Pfad | Zweck |
| --- | --- |
| `POST /admin/login` | Standard- oder benannten Zugang prüfen und Token mit Ablauf ausstellen |
| `POST /admin/logout` | aktuelles Token widerrufen |
| `GET, POST /admin/credentials` | Zugänge listen oder anlegen |
| `PATCH, DELETE /admin/credentials/{uuid}` | Zugang ändern/Passwort rotieren oder mit Sitzungen widerrufen |
| `POST, DELETE /admin/push-token` | APNs-Gerät für aktuellen Admin registrieren/entfernen |

Alle folgenden Routen verlangen ein gültiges Admin-Bearer-Token.

## Admin-Betrieb und Diagnose

| Methode und Pfad | Zweck |
| --- | --- |
| `GET /admin/dashboard` | Kennzahlen, Systemstatus, Geräte, Billboards und Konfiguration |
| `GET /admin/number-overview` | globale Akte einer Eventnummer |
| `GET /admin/delivery-diagnostics` | Request-ID-basierter Versandpfad |
| `GET /admin/event-log` | filterbares Audit-/Betriebsprotokoll |
| `POST /admin/event-log/examples` | ungefährliche Diagnosebeispiele erzeugen |
| `GET /admin/statistics` | Live- oder archivierte Statistik liefern |
| `PATCH, DELETE /admin/devices/{sha256}` | Gerät benennen oder Registrierung widerrufen |
| `POST /admin/billboard-access` | benannten Einmal-Zugang erzeugen |
| `PATCH, DELETE /admin/billboards/{sha256}` | Billboard benennen oder widerrufen |
| `POST /admin/billboard-control` | Top-16-Test und Billboard-Einstellungen steuern |
| `POST /admin/dummy-data` | isolierte Testdaten erzeugen oder entfernen |

## Admin-Eventdaten und Kataloge

| Methode und Pfad | Zweck |
| --- | --- |
| `GET, POST /admin/actions` | Aktionen listen oder anlegen |
| `PATCH, DELETE /admin/actions/{id}` | Aktion ändern oder löschen |
| `GET, POST /admin/matches` | Matches listen oder anlegen |
| `PATCH, DELETE /admin/matches/{id}` | Match ändern oder löschen |
| `GET /admin/requests` | Match-Requests listen |
| `PATCH, DELETE /admin/requests/{id}` | Request ändern oder löschen |
| `GET, POST /admin/action-types` | Aktionskatalog lesen oder Definition anlegen |
| `PATCH, DELETE /admin/action-types/{id}` | Definition ändern oder löschen, sofern unbenutzt |
| `GET, POST /admin/match-types` | Match-Katalog lesen oder Definition anlegen |
| `PATCH, DELETE /admin/match-types/{id}` | Definition ändern oder löschen, sofern unbenutzt |
| `GET, POST /admin/participants` | Freigaben lesen oder Nummer hinzufügen |
| `PUT /admin/participants/range` | regulären Nummernbereich abgleichen |
| `PATCH, DELETE /admin/participants/{number}` | PIN/Gender ändern oder Nummer sperren |
| `POST /admin/participants/{number}/logout` | Sitzungen einer Nummer widerrufen |
| `PATCH /admin/match-message-options` | gemeinsame Schnelltexte ersetzen |
| `GET /admin/feedback` | anonymes Feedback lesen |
| `DELETE /admin/feedback/{id}` | Feedback löschen |

## Inhalte und Event-Lebenszyklus

| Methode und Pfad | Zweck |
| --- | --- |
| `GET, POST /admin/screensaver-content` | Medienkatalog lesen oder Eintrag anlegen |
| `POST /admin/screensaver-content/upload` | Bild hochladen und Katalogeintrag anlegen |
| `PATCH, DELETE /admin/screensaver-content/{uuid}` | Medieneintrag ändern oder löschen |
| `GET, PATCH /admin/screensaver-settings` | Leerlaufzeit lesen oder ändern |
| `GET, POST /admin/event-announcements` | Mitteilungen lesen oder anlegen |
| `PATCH, DELETE /admin/event-announcements/{uuid}` | Mitteilung ändern oder löschen |
| `GET /admin/event-archives` | Archivliste und Kennzahlen liefern |
| `GET /admin/event-archives/{uuid}` | geschütztes vollständiges Archiv liefern |
| `PATCH, DELETE /admin/event-archives/{uuid}` | Archiv umbenennen oder löschen |
| `POST /admin/event-archives/{uuid}/restore` | Archiv nach Sicherheitsarchiv wiederherstellen |
| `POST /admin/event-reset` | Live-Event benannt archivieren und neu beginnen |

## Versions- und Änderungsregel

Neue oder geänderte API-Felder müssen abwärtskompatibel decodierbar sein, solange bestehende Clients noch im Einsatz sind. Neue Pflichtregeln werden zuerst serverseitig ausgerollt, wenn ein älterer Client sonst ungültige Daten senden könnte. Jede Vertragsänderung benötigt Server-Vertragstests, passende Swift-Decodierungs-/Ablauftests und eine Aktualisierung dieser Seite.
