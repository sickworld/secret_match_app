# Event-Lebenszyklus, Statistik und Exporte

[Zur Übersicht](Business-Logic.md)

## Live-Event

Das aktive Event wird durch eine UUID gekennzeichnet. Zum Live-Stand gehören Matches, Match-Requests, Aktionen, Profile, Feedback, Event-Mitteilungen und Eventprotokoll. PINs und freigegebene Nummern werden zwar für den Eventbetrieb benötigt, gehören aber ausdrücklich nicht in den archivierten Snapshot.

Globale Konfiguration bleibt eventübergreifend erhalten: Nummernfreigabe, Match-/Aktionskataloge, Schnelltexte, Medien, Screensaver-Einstellung, Adminzugänge, APNs-/Telegram-Konfiguration und andere Plugin-Einstellungen.

## Eventabschluss

Der aktuelle Abschluss verlangt einen nicht leeren Archivnamen und exakt `EVENT ABSCHLIESSEN`. In WordPress kommen Administratorrecht, Nonce und zusätzliche Browserbestätigung hinzu.

Der Server führt den Wechsel transaktional aus:

1. Er erzeugt aus dem Live-Stand einen benannten Snapshot mit bisheriger Event-ID.
2. Er berechnet und speichert die vollständige Abschlussstatistik.
3. Erst nach erfolgreichem Archivieren leert er sämtliche Eventtabellen.
4. Er prüft, dass die Live-Eventtabellen tatsächlich leer sind.
5. Er löscht alle Teilnehmer-PINs.
6. Er widerruft Teilnehmer- und Billboard-Sitzungen.
7. Er erzeugt eine neue Event-ID.

Schlägt ein Datenbankschritt fehl, darf der Abschluss nicht als erfolgreich gemeldet werden. Der alte Live-Stand und seine PINs bleiben durch Rollback konsistent.

## Archivinhalt

Ein Archiv enthält vollständige, wiederherstellbare Datensätze für:

- Matches,
- Match-Requests einschließlich Nachrichten,
- Aktionen einschließlich Rückzügen,
- Gender-Profile,
- anonymes Feedback,
- Event-Mitteilungen,
- Eventprotokoll,
- berechnete Statistik und Metadaten.

Archive enthalten keine Teilnehmer-PINs, Adminpasswörter, Tokens oder APNs-Schlüssel. Da Eventnummern, Profile, Freitexte und Protokolle enthalten sein können, sind Archivliste, Detail und JSON-Export ausschließlich für authentifizierte Administratoren bestimmt.

Archive können umbenannt und nach Bestätigung vollständig gelöscht werden. Beliebig viele Archive bleiben für historische Vergleiche erhalten.

## Wiederherstellung

Ein Restore verlangt exakt `EVENT WIEDERHERSTELLEN` und läuft in einer Datenbanktransaktion:

1. Der aktuelle Live-Stand wird zuerst als benanntes Sicherheitsarchiv gespeichert.
2. Die Eventtabellen werden durch den gewählten Archivstand ersetzt.
3. Datensatzzahlen werden überprüft.
4. PINs sowie Teilnehmer- und Billboard-Sitzungen werden zurückgesetzt.
5. Eine neue Event-ID wird erzeugt.

Das Quellarchiv bleibt unverändert; das Sicherheitsarchiv bleibt zusätzlich in der Liste. Globale Konfiguration wird nicht aus dem Archiv übernommen. Ein Fehler rollt die gesamte Operation zurück.

## Statistik

Die Statistik wird serverseitig aus dem kanonischen Live- oder Archiv-Snapshot berechnet. Dazu gehören insbesondere:

- freigegebene, aktive und beteiligte Nummern sowie Teilnahmequote,
- Wünsche, offene Wünsche, Matches und Aktionen,
- erfolgreiche Wünsche und Verteilung je Match- beziehungsweise Aktionstyp,
- Wünsche und Aktionen pro aktiver Nummer,
- durchschnittliche und mediane Zeit bis zum Match,
- Freitext- und Rückzugsquote,
- Feedback-Mittelwerte,
- Eventdauer, 15-Minuten-Verlauf und Peak-Viertelstunde,
- Retry-, Fehler- und relevante Betriebsereignisse,
- aktuelles Nummern-Ranking und Gerätegesundheit,
- Vergleich mehrerer archivierter Events.

Historische Statistiken werden aus dem gespeicherten Snapshot nach derselben Logik erzeugt, sodass alte Archive keine eigene Datenmigration benötigen.

## Exporte

Die native Admin-App erstellt PDF- und CSV-Berichte ausschließlich aus Aggregaten. Diese Berichte enthalten keine Eventnummern, Nachrichten, PINs oder Gerätekennungen. Der vollständige JSON-Archivexport ist davon getrennt: Er dient der Sicherung und Wiederherstellung und enthält deshalb die geschützten Eventdatensätze.

## Eventwechsel in Clients

Nach Eventabschluss oder Restore erkennen Teilnehmer-Apps die neue Event-ID über Login oder Status. Sie löschen alte Queue- und Telemetriedaten. Billboards verlieren ihre Sitzungen und müssen neu autorisiert werden. Teilnehmer legen beim nächsten Login neue PINs fest und wählen bei fehlendem wiederhergestelltem Profil erneut ihr Gender.
