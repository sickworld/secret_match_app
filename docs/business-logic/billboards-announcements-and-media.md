# Billboard, Mitteilungen und Medien

[Zur Übersicht](Business-Logic.md)

## Billboard-Zugang

Administratoren können einen benannten, kurzlebigen Einmal-Link erzeugen. Der Link enthält kein Admin- oder Billboard-Passwort, ist 60 Sekunden gültig und kann nur einmal eingelöst werden. Beim Öffnen wird daraus ein `HttpOnly`-Kiosk-Cookie; der Klartexttoken wird weder im Dashboard noch in Warnungen ausgegeben. Die anschließende Tokenlaufzeit ist zwischen einer und 72 Stunden konfigurierbar und beträgt standardmäßig 12 Stunden.

Alternativ kann das zentral gepflegte Billboard-Passwort direkt an der öffentlichen Board-Route eingegeben werden. Auch dieser Weg erzeugt eine eigene widerrufbare Billboard-Sitzung; das gespeicherte Passwort wird nicht in das Eingabefeld zurückgeschrieben.

Mehrere Billboards besitzen voneinander getrennte Token, Namen und Heartbeats. Sie können einzeln umbenannt oder widerrufen werden. Eventabschluss, Restore oder globaler Widerruf beendet ihre Überwachung.

## Live-Modus

Das Billboard ist eine passive, kontrastreiche Anzeige. Es zeigt:

- alle Matches ohne Wiederholung,
- die 40 neuesten aktiven Aktionen,
- je eine getrennt rotierende Match- und Aktionsspalte,
- Typ, Richtung und konsistente Katalogfarbe/-symbole,
- `NEU` nur beim aktuellsten Match am Anfang der ersten Match-Seite.

Beide Spalten wechseln unabhängig alle vier Sekunden mit zwei Sekunden Versatz. Summen und detaillierte Verteilungen bleiben im Adminbereich.

Die Seite sperrt Dokument-Scroll und nutzt `100dvh` bis in Board, Panels und Listen. Pro Seite werden mindestens zehn und höchstens 16 Einträge vorgesehen. Nummern und Trennzeichen skalieren mit der Viewport-Höhe. Auch kurze Bestände und unvollständige letzte Seiten verteilen ihre sichtbaren Zeilen über die volle nutzbare Höhe; das gilt insbesondere beim Spiegeln eines Laptop-Browsers auf einen Fernseher.

Die Dauer der großen Einblendung eines neuen Matches ist administrativ zwischen fünf und acht Sekunden pflegbar.

## Top 16

Der Top-16-Modus wertet aus, welche Nummern innerhalb des konfigurierten Zeitfensters in Matches und Aktionen vorkommen. Start und Ende verwenden die WordPress-Zeitzone; ein Zeitfenster über Mitternacht wird korrekt geteilt, identische Start- und Endzeit bedeutet ganztägig aktiv. Admins können die Darstellung unabhängig vom Zeitplan für 15 Minuten testen.

Alle 16 Platzierungen erscheinen gleichzeitig als leicht verfolgbare Rangliste. Ein optionaler Text mit höchstens 280 Zeichen kann ausschließlich in der externen Webverwaltung gepflegt werden und erscheint als Dialogkarte unter der Rangliste. Ein leerer Wert blendet die Karte aus.

## Event-Mitteilungen

Bis zu 20 Mitteilungen gehören zum aktuellen Event. Jede besitzt:

- Text mit 1 bis 160 Zeichen,
- Darstellungsstufe `info`, `highlight` oder `urgent`,
- Sichtbarkeitsschalter,
- optionale Start- und Endzeit.

Aktiv sind nur sichtbare Einträge innerhalb ihres Zeitfensters. Alle Billboards übernehmen Änderungen spätestens beim regulären Datenabgleich nach zehn Sekunden. Mehrere aktive Hinweise wechseln alle acht Sekunden.

Mitteilungen erscheinen als nicht interaktives Overlay über Live-Inhalt oder Top 16, ohne die Listenhöhe zu verkleinern. Die drei Stufen behalten eigene Farbe und Symbolik. Eine neue Match-Einblendung liegt über dem Mitteilungsoverlay.

Mitteilungen werden beim Eventabschluss archiviert und im neuen Live-Stand geleert. Ein Restore spielt den damaligen Bestand zurück. Die Teilnehmer-App zeigt diese Mitteilungen nicht an.

## Screensaver- und Sponsorenmedien

Ein gemeinsamer, sortierbarer Medienkatalog steuert Login-Screensaver und Sponsorendarstellung. Ein Eintrag besitzt Bild, optionalen Begleittext, Reihenfolge, Sichtbarkeit, Darstellungsdauer und die Option für einen hellen Logohintergrund. Die Bilddauer wird clientseitig zwischen drei und 30 Sekunden begrenzt.

Die Leerlaufzeit vor dem Login-Screensaver ist zentral zwischen 15 Sekunden und zehn Minuten pflegbar. Die Teilnehmer-App speichert Einstellung und Katalog für den Offline-Betrieb.

Ein neuer Remote-Katalog wird erst aktiviert, wenn alle enthaltenen Bilder vollständig geladen und decodiert wurden. Bei einem Teilfehler bleibt der letzte vollständige Katalog aktiv; fehlt auch dieser, verwendet die App ihre mitgelieferten Standardmotive. Dadurch entsteht kein gemischter oder leerer Präsentationsstand.

Die vier Standardmotive werden serverseitig einmalig in einen bearbeitbaren Medienkatalog migriert. Spätere manuelle Änderungen oder Löschungen werden bei Updates nicht überschrieben.

## Aktualisierung und Fehler

Billboard-Heartbeats melden Auflösung, Modus und letzte Aktivität getrennt pro Token. Refresh-Fehler werden ohne Tokeninhalt mit HTTP-Status, Modus und Viewport protokolliert. Ein fehlerhafter Billboard-Abruf lässt den zuletzt sichtbaren Zustand bestehen, statt vertrauliche Diagnosedaten öffentlich anzuzeigen.
