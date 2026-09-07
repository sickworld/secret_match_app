# secret_match_app

## Admin-CRUD

Die iPhone-Admin-App kann Aktionen und Matches anlegen, bearbeiten und löschen. In der Teilnehmerverwaltung lassen sich Nummern freigeben und sperren sowie Gender-Angaben setzen oder zurücksetzen. Jede Gender-Änderung und jeder Reset widerruft die aktive Sitzung der betroffenen Nummer; nach einem Reset erscheint die Gender-Auswahl beim nächsten Login erneut. Feedback bleibt als anonymer, unveränderlicher Datensatz bewusst auf Lesen und Löschen begrenzt.

Diese Funktionen benötigen das WordPress-Modul ab Version `2026.09.07.4`; das Modul muss vor oder zusammen mit diesem App-Build veröffentlicht werden.

## Eingehende Interessen

Die getrennten Teilnehmeransichten **Matches** und **Interesse** unterscheiden gegenseitige Matches von noch offenen, eingehenden Match-Wünschen. `GET /wp-json/secretmatch/v1/interests` liefert ausschließlich Wünsche an die aktuell angemeldete Eventnummer, für die noch kein gegenseitiges Match besteht. Mehrere Wünsche derselben Nummer werden zu einem Eintrag zusammengefasst; ein Fuck-Wunsch hat dabei Vorrang. Das aktualisierte WordPress-Modul muss vor oder zusammen mit diesem App-Build veröffentlicht werden.

## Verbindungsstatus

Die App überwacht den Netzwerkpfad und prüft zusätzlich über `GET /wp-json/secretmatch/v1/status`, ob der SecretMatch-Server tatsächlich erreichbar ist. Bei fehlendem Internet oder einem nicht erreichbaren Server erscheint appweit ein Hinweis mit manueller Neuprüfung. Solange die App aktiv ist, wird der Status außerdem alle 15 Sekunden aktualisiert. Ein erfolgreicher Check stößt offene Einträge der Sende-Warteschlange erneut an.

Teilnehmer melden sich mit Eventnummer und individueller zweistelliger PIN an und müssen einmalig Frau oder Mann auswählen. Match-Wünsche können eine Nachricht mit bis zu 180 Zeichen enthalten; administrativ gepflegte Schnelltexte stehen direkt bei der Eingabe zur Verfügung. Nachrichten werden gemeinsam mit der Aktion dauerhaft zwischengespeichert und erst aus der Queue entfernt, nachdem der Server das erfolgreiche Datenbank-Speichern bestätigt hat.

Die Admin-App zeigt die PIN jeder freigegebenen Nummer. Unter **PIN verwalten** kann sie manuell geändert oder nach einer Bestätigung automatisch neu erzeugt werden; beide Wege beenden zur Sicherheit alle aktiven Sitzungen der Nummer.

Die Navigation führt Matches und offene Interessen als eigene Rubriken. Die Aktionsübersicht zeigt ausschließlich empfangene Aktionen und bietet Filter nach Kategorie und Absendernummer. Während einer aktiven Sitzung übermittelt das iPad alle 30 Sekunden Akkustand, Ladezustand und App-Version; die Admin-App zeigt Geräte an, deren letzter Heartbeat höchstens drei Minuten zurückliegt.

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
