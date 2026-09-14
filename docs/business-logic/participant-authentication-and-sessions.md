# Teilnehmer-Anmeldung und Sitzungen

[Zur Übersicht](Business-Logic.md)

## Login-Ablauf

1. Die Teilnehmer-App zeigt zunächst nur die Eventnummer.
2. Der Server prüft, ob die Nummer freigegeben ist und ob bereits eine PIN existiert.
3. Existiert eine PIN, fordert die App sie als zweiten Schritt an. Nach Eingabe der zweiten Ziffer startet der Login automatisch; die sichtbare Anmelden-Taste bleibt als Rückfall erhalten.
4. Existiert keine PIN, erstellt der Server eine vorläufige Teilnehmer-Sitzung und meldet `needs_pin`.
5. Der Teilnehmer vergibt eine exakt zweistellige PIN und bestätigt sie identisch.
6. Fehlt das Profil, muss anschließend `female` oder `male` gewählt werden.
7. Erst nach abgeschlossener PIN- und Profilanlage aktiviert die App den Teilnehmerbereich und startet Queue-Verarbeitung und Heartbeat.

Die PIN-Erstanlage lässt sich abbrechen. Die App beendet dann die vorläufige Serversitzung und kehrt zur leeren Eventnummerneingabe zurück.

## Validierung und Schutz

- Die Eventnummer muss in der serverseitigen Freigabeliste stehen.
- Eine bestehende PIN muss exakt zwei Ziffern besitzen und zeitkonstant verglichen werden.
- Eine neue PIN muss exakt zwei Ziffern besitzen und mit der Bestätigung übereinstimmen.
- Eine bereits gesetzte PIN kann nicht durch eine zweite Erstanlage überschrieben werden.
- Nach fünf fehlgeschlagenen Versuchen für Nummer und Quell-IP sperrt der Server weitere Versuche für 20 Sekunden.
- Ohne Serververbindung gibt es keinen Offline-Login. Interaktive Authentifizierungsaufrufe brechen clientseitig nach drei Sekunden ab.
- Ungültige Nummern gelangen nicht in den PIN-Schritt; eine falsche PIN hält die Person im PIN-Schritt.

Die kurze PIN verhindert beiläufige Fremdanmeldungen mit sichtbaren Eventnummern, ist aber keine hochsichere Identitätsprüfung.

## Sitzungsmodell

Teilnehmer-Sitzungen verwenden ein serverseitiges Cookie mit `HttpOnly`, `SameSite=Lax`, sicherem Transport bei HTTPS und einer Laufzeit bis zum Browser-/App-Sitzungsende. Ein erfolgreicher Login regeneriert die Session-ID.

Der Server verwirft eine Teilnehmer-Sitzung nach 120 Sekunden ohne serverseitig berührende Aktivität. Die Teilnehmer-App besitzt zusätzlich den strengeren sichtbaren Auto-Logout nach 30 Sekunden Inaktivität.

### App-Auto-Logout

Im angemeldeten Bereich startet ein Countdown von 30 Sekunden. Berührung, Button, Auswahl, Scroll- oder Drag-Geste setzen ihn zurück. Während laufender Serveraktionen und in der Supportansicht wird der Countdown bewusst pausiert und danach neu gestartet. Bei Ablauf räumt die App ihren lokalen Teilnehmerzustand sofort auf und versucht zusätzlich, `POST /logout` mit einem harten Drei-Sekunden-Limit zuzustellen.

Der Geräte-Heartbeat läuft nach dem Logout ohne Teilnehmernummer weiter. So bleibt das iPad im Betrieb sichtbar, ohne die zuletzt verwendete Nummer als aktiv zu führen.

## Administrative Änderungen

Administratoren können:

- eine PIN setzen, ändern oder löschen,
- ein Gender setzen oder zurücksetzen,
- eine aktive Teilnehmer-Sitzung abmelden,
- eine Nummer sperren beziehungsweise aus der Freigabe entfernen.

Jede administrative PIN- oder Gender-Änderung widerruft aktive Sitzungen der betroffenen Nummer. Nach PIN-Reset folgt beim nächsten Login die Erstanlage; nach Gender-Reset folgt erneut die Profilauswahl. Beim Eventabschluss und bei einer Archiv-Wiederherstellung werden alle Teilnehmer-Sitzungen und sämtliche PINs zurückgesetzt.

## Eventgrenze

Login und Status liefern die aktuelle `event_id`. Erkennt die App gegenüber der lokal gespeicherten Event-ID einen Wechsel, löscht sie offene Interaktionen, ausstehende Telemetrie und den letzten Sync-Zeitpunkt. Dadurch können Daten eines abgeschlossenen Events nicht in den neuen Live-Stand gelangen.

## Anzeige und Datenschutz

Die normale Loginseite enthält Logo, Eventnummer beziehungsweise PIN sowie Info/Datenschutz/Impressum. Frühere Introtexte und Claims sind entfernt. PINs erscheinen weder in Protokollen noch in Exporten und werden nicht an normale Teilnehmer ausgegeben. Authentifizierte Adminoberflächen dürfen die eingerichteten PINs für Betrieb, Änderung und Reset laden.
