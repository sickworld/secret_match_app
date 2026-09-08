# secret_match_app

In allen sichtbaren App-Texten, Exporten und Benachrichtigungen lautet der Produktname **Match&Play**. Interne Bezeichner wie API-Pfade, Bundle-IDs und technische Klassen bleiben aus Kompatibilitätsgründen unverändert.

## Admin-CRUD

Die Admin-Bereiche auf iPhone und iPad können Aktionen und Matches anlegen, bearbeiten und löschen sowie Match-Requests einsehen und verwalten. In der Teilnehmerverwaltung lassen sich Nummern freigeben und sperren sowie Gender-Angaben setzen oder zurücksetzen. Jede Gender-Änderung und jeder Reset widerruft die aktive Sitzung der betroffenen Nummer; nach einem Reset erscheint die Gender-Auswahl beim nächsten Login erneut. Feedback bleibt als anonymer, unveränderlicher Datensatz bewusst auf Lesen und Löschen begrenzt.

iPads und Billboards besitzen ebenfalls eine vollständige Verwaltung für ihre technisch sinnvollen Lebenszyklen: iPads registrieren sich automatisch per Heartbeat und können danach umbenannt oder einzeln aus der Liste entfernt werden. Billboards lassen sich mit einem benannten Einmal-Link anlegen, direkt öffnen, umbenennen und einzeln widerrufen. Das zentrale manuelle Billboard-Passwort gilt für alle, während jeder geöffnete Zugang eine eigene löschbare Sitzung erhält.

Das zentrale Protokoll benennt jede schreibende Admin-Aktion verständlich, einschließlich Änderungen an Aktionen, Matches, Requests, Teilnehmern, PIN/Gender, Geräten, Billboards, Schnelltexten und Testdaten. Auch Änderungen aus dem WordPress-Backend erscheinen in der Admin-App; Passwörter, PINs, Tokens und Nachrichteninhalte werden nicht protokolliert. Ein erfolgreicher Event-Reset erzeugt absichtlich keinen neuen Eintrag, da er weiterhin sämtliche Logs vollständig entfernt.

Die Admin-App bietet zusätzlich eine globale Nummernakte mit bestätigtem PIN- und Gender-Reset, einen Event-Startcheck und eine Request-ID-basierte Sendungsdiagnose. Die Statistik lässt sich ohne Eventnummern, Nachrichten, PINs oder Gerätekennungen als PDF beziehungsweise CSV teilen. Auf dem iPad unterscheidet die Versandbestätigung sichtbar zwischen zugestellt, sicher vorgemerkt, teilweise zugestellt und fehlgeschlagen. Die grüne Bestätigung spricht bewusst in kurzer Event-Sprache und blendet sich nach vier Sekunden weich aus. Versand- und Queue-Hinweise erscheinen auf vollständig deckenden Karten direkt oberhalb des Senden-Buttons; sie blockieren den Button nicht und verändern das Layout nicht. Die Queue-Karte bleibt bis zur Zustellung sichtbar und bietet einen manuellen Retry.

## Gemeinsame Admin-Architektur

Der iPhone-Admin-Target und der im Event-iPad integrierte Admin-Modus verwenden dieselben SwiftUI-Views, Models und Methoden aus `APIService`. `AdminDashboardSection` ist die zentrale Quelle für Titel, Icons, Farben, Reihenfolge und Ziele aller Admin-Werkzeuge. Neue Admin-Funktionen werden dort einmal registriert und anschließend über `AdminMainView` auf beiden Gerätegrößen geöffnet; eigene API- oder View-Model-Implementierungen pro Target sind zu vermeiden.

Auf dem iPhone öffnet die Kopfleiste das kompakte Admin-Menü. Auf dem iPad nutzt der Adminbereich die volle Breite ohne permanente Sidebar; alle Funktionen liegen in der adaptiven Übersicht **Aktionen**. Sie enthält Livefeed, Aktionen-, Request- und Match-CRUD, Teilnehmerverwaltung, Eventsteuerung, Event-Check, Sendungsdiagnose, Protokoll, Statistik, Feedback sowie System und Reset. Nummernsuche und Admin-Logout bleiben direkt in der Kopfzeile erreichbar, Detailseiten erhalten einen Rückweg zu **Aktionen**. Die Inhalte nutzen adaptive Grids, statt das iPhone-Layout lediglich zu verbreitern.

Admin-Eingabefelder verwenden gemeinsam `AdminKeyboardTextField` beziehungsweise `AdminKeyboardTextEditor`. Im integrierten iPad-Adminbereich öffnen sie die große appinterne Zahlen- oder QWERTZ-Tastatur als einheitliches Overlay über der abgedunkelten aktuellen Ansicht; mehrzeilige Schnelltexte unterstützen dabei eine eigene Neue-Zeile-Taste. Die QWERTZ-Tastatur orientiert sich an einer normalen Bildschirmtastatur und wechselt über eigene Tasten zwischen Buchstaben, Zahlen, Sonderzeichen und einer kuratierten Emoji-Auswahl. Auch der iPad-Admin-Login verwendet diese gemeinsame Tastatur. Der eigenständige iPhone-Admin-Target rendert über dieselben Komponenten weiterhin native iOS-Eingabefelder.

## UI-Konventionen

Die bestehende dunkle Match&Play-Gestaltung verwendet für Karten, Buttons, Eingaben, Navigationselemente und Admin-Controls zentral `SecretMatchTheme.cornerRadius` mit **8 pt**. Neue Komponenten sollen `secretCard`, `secretInput`, `secretAdminInput`, `SecretPrimaryButtonStyle`, `SecretSecondaryButtonStyle` oder `SecretAdminFeatureButtonStyle` wiederverwenden. Pillenformen sind ausschließlich für kurze Status- und Auswahl-Chips vorgesehen; normale Aktionen und Schließen-Buttons bleiben kompakte, abgerundete Rechtecke. Systembuttons im Admin-Bereich erben dieselbe rechteckige Buttonform und den Produktfarbton.

Das kompakte Menü der iPhone-Admin-App bleibt flächig und neutral. Bereichsfarben erscheinen nur an den Icons sowie dezent am aktiven Eintrag; eine linke Markierung und ein Häkchen kennzeichnen die Auswahl zusätzlich unabhängig von der Farbe. Der Logout bleibt als destruktive Aktion rot.

Diese Funktionen benötigen das WordPress-Modul ab Version `2026.09.08.6`; das Modul muss vor oder zusammen mit diesem App-Build veröffentlicht werden.

## Eingehende Interessen

Die Reiter **Matches** und **Interesse** in der Teilnehmerübersicht unterscheiden gegenseitige Matches von noch offenen, eingehenden Match-Wünschen. `GET /wp-json/secretmatch/v1/interests` liefert ausschließlich Wünsche an die aktuell angemeldete Eventnummer, für die noch kein gegenseitiges Match besteht. Mehrere Wünsche derselben Nummer werden zu einem Eintrag zusammengefasst; ein Fuck-Wunsch hat dabei Vorrang. Das aktualisierte WordPress-Modul muss vor oder zusammen mit diesem App-Build veröffentlicht werden.

## Verbindungsstatus

Die App überwacht den Netzwerkpfad und prüft zusätzlich über `GET /wp-json/secretmatch/v1/status`, ob der SecretMatch-Server tatsächlich erreichbar ist. Bei fehlendem Internet oder einem nicht erreichbaren Server erscheint appweit ein schwebender Hinweis mit manueller Neuprüfung. Das Overlay belegt keinen Platz im eigentlichen Layout und verschiebt dadurch insbesondere den Senden-Button nicht. Alle Hinweise verwenden kurze Event-Sprache; bei einer nicht vorhandenen Zielnummer nennt die App die eingegebene Nummer und fordert direkt zur Prüfung auf. Solange die App aktiv ist, wird der Status außerdem alle 15 Sekunden aktualisiert. Ein erfolgreicher Check stößt offene Einträge der Sende-Warteschlange erneut an.

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

Die dauerhaft oben rechts eingeblendete Zoomgruppe **A− · Prozentwert · A+** wechselt zwischen 100 %, 115 % und 130 % Darstellungsgröße. Die gleich hohe, optisch getrennte Schaltfläche **Kontrast** zeigt ihren Zustand zusätzlich mit Kreis oder Häkchen und aktiviert einen dauerhaft gespeicherten High-Contrast-Modus mit schwarzem Hintergrund, helleren Sekundärtexten, kräftigeren Farben und klareren Begrenzungen. Die App respektiert zusätzlich die iPad-Systemeinstellung für erhöhten Kontrast. Beim Start des Bildschirmschoners wird die gesamte Bedienleiste verborgen und die manuelle Darstellung auf 100 % ohne High Contrast zurückgesetzt. Ein durch die iPad-Systemeinstellung erzwungener erhöhter Kontrast bleibt aktiv.

Im integrierten iPad-Adminbereich bleibt die Bediengruppe vollständig ausgeblendet, damit sie keine Admin-Navigation oder Dialoge überlagert. Beim Admin-Logout erscheint sie in den Teilnehmeransichten automatisch wieder; bestehende Zoom- und Kontrasteinstellungen werden durch den Wechsel nicht verändert.

Beim Zoomen werden Texte, Bedienelemente und Abstände gemeinsam skaliert; responsive Ansichten brechen bei Bedarf um oder werden scrollbar. Zoom und Kontrast werden unabhängig voneinander pro App und Gerät gespeichert, bis der Bildschirmschoner beide manuellen Einstellungen zurücksetzt.

Während modale Ansichten oder die appinternen Tastaturen geöffnet sind, wird die globale Bedienleiste vorübergehend ausgeblendet. Dadurch bleiben Schließen- und Tastaturtasten auf allen Zoomstufen frei erreichbar; die gewählte Darstellungsgröße und der Kontrastmodus bleiben dabei erhalten.

Auswahlzustände werden nicht nur über Farbe, sondern zusätzlich mit Kreis- und Häkchensymbolen dargestellt. Aktiviert das iPad **Ohne Farben differenzieren**, verwendet die App für wichtige Auswahlen automatisch eine kontrastreiche Schwarz-Weiß-Darstellung. Geräte- und Billboard-Zustände unterscheiden Online und Offline zusätzlich durch Häkchen beziehungsweise ein achteckiges X-Symbol.

Freie Match-Nachrichten werden über eine appinterne QWERTZ-Tastatur mit Umlauten, Zahlen und Satzzeichen eingegeben. Auch der gemeinsame Eventnummernfilter in **Matches**, **Interesse** und **Aktionen** nutzt die große appinterne Zahlentastatur. Die Schnelltexte lassen sich sowohl in der Admin-App unter **Steuerung → Match-Schnelltexte** als auch im WordPress-Backend unter **SecretMatch → Einstellungen** pflegen; beide Oberflächen bearbeiten dieselbe Liste.

## Sende-Warteschlange

Match- und Aktionssendungen werden vor dem ersten Netzwerkversuch lokal vorgemerkt. Bei fehlender oder instabiler Verbindung versucht die App sie mit wachsendem Abstand automatisch erneut; angemeldete Teilnehmer können den Retry zusätzlich über **Jetzt versuchen** auslösen. Offene Einträge bleiben an die ursprüngliche Eventnummer gebunden, überstehen einen App-Neustart und werden nach spätestens 24 Stunden verworfen. Die Anzeige unterscheidet einen gemeinsam ausgelösten Versandvorgang von seinen einzelnen Aktionen, beispielsweise „1 Versand mit 4 Aktionen“.

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
