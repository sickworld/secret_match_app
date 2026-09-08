# secret_match_app

## Admin-CRUD

Die iPhone-Admin-App kann Aktionen und Matches anlegen, bearbeiten und löschen sowie Match-Requests einsehen und verwalten. In der Teilnehmerverwaltung lassen sich Nummern freigeben und sperren sowie Gender-Angaben setzen oder zurücksetzen. Jede Gender-Änderung und jeder Reset widerruft die aktive Sitzung der betroffenen Nummer; nach einem Reset erscheint die Gender-Auswahl beim nächsten Login erneut. Feedback bleibt als anonymer, unveränderlicher Datensatz bewusst auf Lesen und Löschen begrenzt.

iPads und Billboards besitzen ebenfalls eine vollständige Verwaltung für ihre technisch sinnvollen Lebenszyklen: iPads registrieren sich automatisch per Heartbeat und können danach umbenannt oder einzeln aus der Liste entfernt werden. Billboards lassen sich mit einem benannten Einmal-Link anlegen, direkt öffnen, umbenennen und einzeln widerrufen. Das zentrale manuelle Billboard-Passwort gilt für alle, während jeder geöffnete Zugang eine eigene löschbare Sitzung erhält.

Das zentrale Protokoll benennt jede schreibende Admin-Aktion verständlich, einschließlich Änderungen an Aktionen, Matches, Requests, Teilnehmern, PIN/Gender, Geräten, Billboards, Schnelltexten und Testdaten. Auch Änderungen aus dem WordPress-Backend erscheinen in der Admin-App; Passwörter, PINs, Tokens und Nachrichteninhalte werden nicht protokolliert. Ein erfolgreicher Event-Reset erzeugt absichtlich keinen neuen Eintrag, da er weiterhin sämtliche Logs vollständig entfernt.

Die Admin-App bietet zusätzlich eine globale Nummernakte mit bestätigtem PIN- und Gender-Reset, einen Event-Startcheck und eine Request-ID-basierte Sendungsdiagnose. Die Statistik lässt sich ohne Eventnummern, Nachrichten, PINs oder Gerätekennungen als PDF beziehungsweise CSV teilen. Auf dem iPad unterscheidet die Versandbestätigung sichtbar zwischen zugestellt, sicher vorgemerkt, teilweise zugestellt und fehlgeschlagen. Die grüne Bestätigung spricht bewusst in kurzer Event-Sprache und blendet sich nach vier Sekunden weich aus; Hinweise zu Queue, Teilzustellung und Fehlern bleiben sichtbar.

Diese Funktionen benötigen das WordPress-Modul ab Version `2026.09.08.4`; das Modul muss vor oder zusammen mit diesem App-Build veröffentlicht werden.

## Eingehende Interessen

Die Reiter **Matches** und **Interesse** in der Teilnehmerübersicht unterscheiden gegenseitige Matches von noch offenen, eingehenden Match-Wünschen. `GET /wp-json/secretmatch/v1/interests` liefert ausschließlich Wünsche an die aktuell angemeldete Eventnummer, für die noch kein gegenseitiges Match besteht. Mehrere Wünsche derselben Nummer werden zu einem Eintrag zusammengefasst; ein Fuck-Wunsch hat dabei Vorrang. Das aktualisierte WordPress-Modul muss vor oder zusammen mit diesem App-Build veröffentlicht werden.

## Verbindungsstatus

Die App überwacht den Netzwerkpfad und prüft zusätzlich über `GET /wp-json/secretmatch/v1/status`, ob der SecretMatch-Server tatsächlich erreichbar ist. Bei fehlendem Internet oder einem nicht erreichbaren Server erscheint appweit ein Hinweis mit manueller Neuprüfung. Solange die App aktiv ist, wird der Status außerdem alle 15 Sekunden aktualisiert. Ein erfolgreicher Check stößt offene Einträge der Sende-Warteschlange erneut an.

Im Admin-Dashboard stehen Billboard und iPads direkt am Anfang der Übersicht. Bekannte iPads bleiben auch offline sichtbar. Das WordPress-Modul sendet über die bestehende Telegram-Konfiguration einmalige Warnungen und Entwarnungen, wenn Heartbeats länger ausbleiben beziehungsweise zurückkehren.

Die eigenständige Admin-App registriert sich nach erfolgreicher Anmeldung für Apple-Push-Nachrichten. Dadurch erreichen Billboard- und iPad-Ausfallwarnungen das Admin-iPhone auch bei gesperrtem Gerät oder beendeter App. Push muss für die App-ID `com.SecretMatch.Admin` im Apple-Developer-Portal aktiviert sein; die APNs-Zugangsdaten werden ausschließlich serverseitig konfiguriert. Wenn APNs nicht vollständig eingerichtet ist, zeigt der Systemstatus mit dem WordPress-Modul ab Version `2026.09.07.11` sichere Einzelprüfungen für IDs, Topic, Schlüsseldatei, OpenSSL, cURL und HTTP/2. Für verlässliche Warnzeiten muss der Server `wp-cron.php` mindestens einmal pro Minute ausführen.

Der Login fragt zunächst nur die Eventnummer ab. Ist bereits eine PIN gesetzt, erscheint sie anschließend als eigener zweiter Schritt. Beim ersten Login mit einer freigegebenen Eventnummer legt der Teilnehmer stattdessen direkt selbst eine zweistellige PIN fest und wählt Frau oder Mann. Sowohl Anmeldung als auch PIN-Ersteinrichtung verwenden ausschließlich die vorhandene appinterne Zahlentastatur. Match-Wünsche können eine Nachricht mit bis zu 180 Zeichen enthalten; administrativ gepflegte Schnelltexte stehen direkt bei der Eingabe zur Verfügung. Nachrichten werden gemeinsam mit der Aktion dauerhaft zwischengespeichert und erst aus der Queue entfernt, nachdem der Server das erfolgreiche Datenbank-Speichern bestätigt hat.

Die Admin-App zeigt gesetzte PINs. Unter **PIN verwalten** kann eine PIN manuell geändert oder zurückgesetzt werden. Nach einem Reset beendet der Server alle Sitzungen; der Teilnehmer legt beim nächsten Login selbst eine neue PIN fest.

Die Admin-App besitzt eine eigene Rubrik **Match-Requests**. Sie zeigt alle gesendeten Wünsche mit Absender, Empfänger, Typ, Freitext und dem Status offen oder gematcht. Requests können gesucht, gefiltert, bearbeitet und einzeln gelöscht werden; vorhandene gegenseitige Matches bleiben dabei eigenständig bestehen.

Die Teilnehmernavigation bündelt Matches, offene Interessen und erhaltene Aktionen unter **Deine Übersicht**. Drei klar erklärte Reiter unterscheiden gegenseitig bestätigte Matches, noch offene Interessen und direkt empfangene Aktionen. Einheitliche Karten stellen die Eventnummer zuerst dar; Typ- und Nummernfilter funktionieren in allen drei Bereichen. Nach einer einmaligen Registrierung während eines Teilnehmer-Logins übermittelt das iPad im Vordergrund unabhängig vom aktuellen Login alle 30 Sekunden Akkustand, Ladezustand, App-Version und die gesamte lokale Queue. Der dafür ausgestellte Geräte-Token liegt nur im iOS-Schlüsselbund. Die Admin-App zeigt Geräte an, deren letzter Heartbeat höchstens drei Minuten zurückliegt, und kennzeichnet iPads auf der Loginseite als „Keine Nummer angemeldet“.

Beim manuellen und automatischen Teilnehmer-Logout wird die Sitzung sofort über `POST /wp-json/secretmatch/v1/logout` beendet. Der Geräte-Heartbeat läuft danach weiter und bestätigt dem Server zusätzlich, dass lokal keine Teilnehmernummer angemeldet ist. Damit bleibt das iPad über seinen Gerätenamen überwachbar, ohne die abgemeldete Eventnummer weiter als aktiv zu führen.

Beim Login erhält die PIN-Tastatur einen sichtbaren Kontext mit Eventnummer, Erklärung und direkter Möglichkeit, die Nummer zu ändern. Die PIN-Erstanlage kennzeichnet die Eingabe und Bestätigung zusätzlich eindeutig als Schritt 1 und Schritt 2.

Die PIN-Erstanlage kann jederzeit über **Abbrechen** verlassen werden. Dabei verwirft die App den begonnenen Login, beendet die vorläufige Teilnehmer-Sitzung und kehrt zur Eingabe der Eventnummer zurück.

## Barrierearme Darstellung

Die dauerhaft eingeblendeten Schaltflächen **A−** und **A+** wechseln zwischen 100 %, 115 % und 130 % Darstellungsgröße. Dabei werden Texte, Bedienelemente und Abstände gemeinsam skaliert; responsive Ansichten brechen bei Bedarf um oder werden scrollbar. Die Auswahl bleibt pro App und Gerät gespeichert.

Freie Match-Nachrichten werden über eine appinterne QWERTZ-Tastatur mit Umlauten, Zahlen und Satzzeichen eingegeben. Die Schnelltexte lassen sich sowohl in der Admin-App unter **Steuerung → Match-Schnelltexte** als auch im WordPress-Backend unter **SecretMatch → Einstellungen** pflegen; beide Oberflächen bearbeiten dieselbe Liste.

## Sende-Warteschlange

Match- und Aktionssendungen werden vor dem ersten Netzwerkversuch lokal vorgemerkt. Bei fehlender oder instabiler Verbindung versucht die App sie mit wachsendem Abstand automatisch erneut; angemeldete Teilnehmer können den Retry zusätzlich über **Jetzt versuchen** auslösen. Offene Einträge bleiben an die ursprüngliche Eventnummer gebunden, überstehen einen App-Neustart und werden nach spätestens 24 Stunden verworfen.

Jede Sendung enthält eine UUID als `request_id`. Der Aktions-Endpunkt des WordPress-Moduls speichert diese ID eindeutig und beantwortet einen Retry derselben ID erfolgreich, ohne eine zweite Aktion anzulegen. Das aktualisierte WordPress-Modul muss deshalb vor oder zusammen mit diesem App-Build veröffentlicht werden.

Während ein Eintrag wartet, liegen Absender-Eventnummer, Ziel-Eventnummer und Aktionstyp ausschließlich im lokalen App-Container. Nach erfolgreichem Versand, einem endgültigen Validierungsfehler oder Ablauf der 24 Stunden wird der Eintrag entfernt.

## Admin-Billboard

Angemeldete Administratoren können das WordPress-Billboard über **Billboard Vollbild** direkt in der App öffnen. Die App fordert dafür über `POST /wp-json/secretmatch/v1/admin/billboard-access` einen kurzlebigen Einmal-Link an; Admin- oder Billboard-Passwörter werden nicht in der WebView-URL übertragen.

Der Admin-Login liefert ein zeitlich begrenztes Bearer-Token. Es bleibt nur im Arbeitsspeicher der App, wird bei jedem geschützten Admin-Aufruf mitgesendet und beim Abmelden serverseitig widerrufen.

## Anonymes Feedback

Die Teilnehmer-App sendet Feedback über `POST /wp-json/secretmatch/v1/feedback` als JSON mit `rating`, `functionality_rating`, `ease_of_use_rating` und `design_rating` (jeweils 1–5). Der Request nutzt eine cookiefreie, ephemere Session und enthält keine Eventnummer. Das WordPress-Modul unterstützt `reuse_rating` weiterhin optional für ältere oder andere Clients.

Der Server-Endpunkt muss die vier App-Bewertungen validieren und darf Feedback weder mit Teilnehmer-Sitzungen noch mit Eventnummern verknüpfen.

Beim Event-Reset werden die anonymen Feedbacks zusammen mit den übrigen Eventdaten im letzten Reset-Backup gesichert und anschließend aus dem aktiven System gelöscht.

Die iPhone-Admin-App lädt die anonymen Einträge über `GET /wp-json/secretmatch/v1/admin/feedback` und löscht einzelne Einträge über `DELETE /wp-json/secretmatch/v1/admin/feedback/{id}`. Beide Aufrufe erfordern das Admin-Bearer-Token.

Die Teilnehmer-App bündelt Feedback, Datenschutz, Impressum und App-Version im Bereich **Info & Support**. Dieser ist sowohl vor dem Login als auch im laufenden Event erreichbar.

## Event-iPad im Single-App-Modus

Für ein dauerhaft eingesetztes Event-iPad sollte der **Single-App-Modus** von Apple verwendet werden. Er hält das iPad in SecretMatch, öffnet die App nach einem Neustart erneut und kann den oberen Ein-/Ausschalter, Auto-Lock und bei Bedarf die Lautstärketasten deaktivieren. Eine normale iOS-App kann diese Hardwaretasten nicht selbst sperren.

### Voraussetzungen

- ein Mac mit installiertem **Apple Configurator**
- ein Datenkabel für die Verbindung zwischen Mac und iPad
- ein iPad, das als **betreutes Gerät** eingerichtet werden darf
- SecretMatch bereits auf dem iPad installiert, entweder über TestFlight oder später über die reguläre Verteilung

> **Achtung:** Das erstmalige Vorbereiten als betreutes Gerät löscht ein bereits eingerichtetes iPad in der Regel vollständig. Benötigte Daten vorher sichern und nach Möglichkeit ein eigenes Event-iPad verwenden.

### iPad verbinden und betreuen

1. Apple Configurator auf dem Mac öffnen.
2. Das entsperrte iPad per USB-C- oder Lightning-Kabel direkt mit dem Mac verbinden.
3. Auf dem iPad bei **Diesem Computer vertrauen?** auf **Vertrauen** tippen und den Gerätecode eingeben.
4. Warten, bis das iPad in Apple Configurator als Gerät erscheint.
5. Das iPad auswählen und **Vorbereiten** öffnen.
6. **Manuelle Konfiguration** wählen und **Geräte betreuen** aktivieren.
7. Wenn kein MDM verwendet wird, die MDM-Registrierung überspringen und die Vorbereitung abschließen.
8. Nach dem Zurücksetzen die iPad-Einrichtung durchführen und SecretMatch installieren.

### Verwendung mit TestFlight

Der Single-App-Modus funktioniert auch mit einem über TestFlight installierten SecretMatch-Build. TestFlight und SecretMatch müssen installiert und der gewünschte Build muss vollständig gestartet worden sein, bevor der Single-App-Modus aktiviert wird.

TestFlight-Builds laufen nach 90 Tagen ab. Für ein Update den Single-App-Modus bei Bedarf kurz über Apple Configurator beenden, TestFlight öffnen, den neuen Build installieren und SecretMatch anschließend wieder in den Single-App-Modus setzen. Vor jedem Event prüfen, dass der installierte Build noch gültig ist.

### Single-App-Modus aktivieren

1. Das betreute iPad mit dem Mac verbinden und in Apple Configurator auswählen.
2. **Aktionen → Erweitert → Single-App-Modus starten** wählen.
3. SecretMatch als einzige verfügbare App auswählen.
4. In den Optionen mindestens den **Sleep/Wake- beziehungsweise oberen Knopf** und **Auto-Lock** deaktivieren.
5. Optional auch die Lautstärketasten, Bildschirmrotation oder weitere Systemfunktionen sperren.
6. Die Einstellung anwenden und am iPad kontrollieren, dass SecretMatch automatisch geöffnet wird.

Danach prüfen, dass weder die Home-Geste noch der obere Knopf die App verlassen oder das Display sperren und dass SecretMatch nach einem Neustart wieder erscheint.

### Single-App-Modus beenden

Das iPad wieder mit dem verwaltenden Mac verbinden, in Apple Configurator auswählen und unter **Aktionen → Erweitert** den Single-App-Modus stoppen. Diese Möglichkeit vor dem ersten Event einmal testen, damit das Gerät bei einem App- oder TestFlight-Problem wieder freigegeben werden kann.
