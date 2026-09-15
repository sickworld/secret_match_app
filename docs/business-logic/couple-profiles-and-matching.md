# Pärchenprofile und gemeinsames Matching

[Zur Übersicht](Business-Logic.md)

## Status

- **Konzeptstand:** 15. September 2026
- **Phase:** Geplant, noch nicht implementiert
- **Ziel:** Paare sollen mit demselben einfachen Ablauf wie bisher teilnehmen und sowohl Einzelpersonen als auch andere Paare matchen können.

Diese Seite beschreibt den vereinbarten fachlichen Zielentwurf. Sie ändert den aktuell implementierten Login-, Profil- oder Match-Vertrag noch nicht.

## Leitentscheidung: Paar als Gender-Wert

Das bestehende Teilnehmerprofil wird bewusst nur minimal erweitert. Das Feld `gender` erhält neben `female` und `male` den zusätzlichen Wert `couple`.

| Gender-Wert | Bedeutung |
| --- | --- |
| `female` | einzelne Frau |
| `male` | einzelner Mann |
| `couple` | gemeinsam auftretendes Paar |

Es wird kein zusätzlicher Profiltyp, keine interne Paar-Mitgliederstruktur und keine neue Präferenzlogik eingeführt. Eine Paar-Eventnummer verhält sich technisch wie jede andere freigegebene Eventnummer.

## Login und gemeinsamer Zugriff

Ein Paar verwendet:

- eine gemeinsame Eventnummer,
- eine gemeinsame zweistellige PIN,
- eine gemeinsame Teilnehmer-Sitzung,
- eine gemeinsame Übersicht über Interessen, Matches und Aktionen.

Bei der erstmaligen Profilauswahl stehen **Frau**, **Mann** und **Paar** zur Verfügung. Nach der Auswahl `couple` läuft der bestehende Login ohne weitere Paar-Schritte weiter. Beide Partner verwenden denselben Zugang und sehen deshalb dieselben Inhalte.

Ein administrativer Gender-Wechsel folgt den vorhandenen Regeln: Die Profilangabe wird geändert und aktive Sitzungen der Nummer werden widerrufen.

## Matching-Regeln

Alle freigegebenen Nummern dürfen sich wie bisher gegenseitig matchen. Es gibt keine zusätzlichen Freigaben oder Einschränkungen nach Gender.

| Absender | Ziel | Fachliches Verhalten | Darstellung bei Match |
| --- | --- | --- | --- |
| Frau oder Mann | Frau oder Mann | bestehendes Matching | bestehende Darstellung |
| Paar | Frau oder Mann | bestehendes Matching | bestehende Darstellung |
| Frau oder Mann | Paar | bestehendes Matching | bestehende Darstellung |
| Paar | Paar | bestehendes Matching | eigene Paar-Match-Farbe |

Die bisherigen Regeln bleiben vollständig erhalten:

- Ein Match-Wunsch ist gerichtet.
- Ein Match entsteht erst durch einen Gegenwunsch.
- Absender und Ziel müssen verschieden und freigegeben sein.
- Pro ungeordnetem Nummernpaar existiert höchstens ein Match.
- Match-Typ, Upgrade-Regeln, Freitext, Request-ID und Offline-Queue ändern sich nicht.

Ein Paar-zu-Single- oder Single-zu-Paar-Match erhält keine besondere Kennzeichnung. Ausschließlich ein gegenseitiges Match zwischen zwei Profilen mit `gender = couple` wird farblich als Paar-Match dargestellt.

## Farbdarstellung eines Paar-Matches

Die Paar-Kennzeichnung erfolgt ausschließlich über Farbe. Es werden dafür keine zusätzlichen Badges, Symbole, Texte, Tabs oder Dialoge ergänzt.

Die Paarfarbe soll auf allen bereits vorhandenen Match-Darstellungen konsistent verwendet werden:

- Match-Karte in der Teilnehmerübersicht,
- neues Match-Overlay in der Teilnehmer-App,
- Match-Karte und Match-Animation auf dem Billboard,
- Match-Darstellung in den Adminoberflächen.

Damit der eigentliche Match-Typ weiterhin erkennbar bleibt, färbt die Paarfarbe bevorzugt Kartenrahmen, Hintergrundakzent oder Leuchteffekt. Bezeichnung und inhaltliche Bedeutung des bestehenden Match-Typs bleiben unverändert. Die konkrete Paarfarbe ist vor der Implementierung festzulegen (`TBD`).

Der Server soll in seinen Match-Antworten eine abgeleitete Information wie `is_couple_match` liefern. Sie ist genau dann `true`, wenn beide zugehörigen Profile `gender = couple` besitzen. Dadurch müssen App, Weboberfläche und Billboard die beiden Profile nicht selbst nachladen.

## Aktionen und Ziel-Gender

Der Aktionskatalog bleibt unverändert bei `any`, `female` und `male`.

- Aktionen mit `target_gender = any` werden auch für Paare angeboten.
- Aktionen für `female` oder `male` werden einem Paar nicht angeboten.
- Die konkrete Gender-Angabe des Ziels bleibt serverseitig und wird nicht an andere Teilnehmer-Clients ausgegeben.

Es gibt weder eine neue Paar-Aktionskategorie noch eine weitere Filter- oder Präferenzebene.

## Top 16

Die bestehende Top 16 bleibt eine Auswahl aus acht Frauen und acht Männern. Profile mit `gender = couple` werden bei dieser Berechnung ignoriert. Es wird zunächst weder eine eigene Paar-Rangliste noch eine neue Top-Couples-Oberfläche ergänzt.

## Statistik, Billboard und Datenschutz

Eine Paar-Eventnummer zählt in bestehenden Statistiken weiterhin als genau eine Teilnehmernummer. Es wird keine zusätzliche Personenanzahl geführt.

Billboard, Benachrichtigungen, Exporte und Protokolle verwenden weiterhin ausschließlich Eventnummern. Namen, Paarzusammensetzung oder andere Mitgliederdaten werden nicht erhoben und können deshalb auch nicht ausgegeben werden.

Außer der eigenen Farbdarstellung bei Paar-zu-Paar-Matches bleiben Aufbau und Inhalte der vorhandenen Oberflächen unverändert.

## Technische Kompatibilität

Die Einführung benötigt eine abgestimmte Erweiterung in allen Schichten:

1. WordPress-Profilvalidierung und Adminverwaltung akzeptieren `couple`.
2. Swift-Modell und Login-Auswahl akzeptieren und senden `couple`.
3. Die Zielprüfung liefert für `couple` ausschließlich vorhandene Aktionen mit `target_gender = any`.
4. Match-Antworten liefern die abgeleitete Paar-Match-Kennzeichnung.
5. Teilnehmer-App, Admin-App, Webverwaltung und Billboard verwenden dieselbe Paarfarbe.
6. Top 16 schließt `couple` ausdrücklich aus.

Vorhandene Profile mit `female` oder `male`, PINs, Sessions, Requests und Matches benötigen keine Migration. Alte App-Versionen kennen `couple` allerdings nicht; deshalb dürfen Paarprofile erst aktiviert werden, wenn Server und eingesetzte App-Version gemeinsam aktualisiert wurden.

## Anforderungen für eine spätere Umsetzung

### SM-COUPLE-GENDER-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Login, Swift-Modell, WordPress-Profil und Adminverwaltung unterstützen neben `female` und `male` den Gender-Wert `couple`.

### SM-COUPLE-AUTH-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Ein Paar verwendet eine gemeinsame Eventnummer, PIN und Sitzung ohne zusätzliche Paar-spezifische Login-Schritte.

### SM-COUPLE-MATCH-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Paar-Nummern können ohne neue Freigabe- oder Präferenzregeln Einzelnummern und andere Paar-Nummern nach den bestehenden Gegenseitigkeitsregeln matchen.

### SM-COUPLE-PRESENTATION-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Nur wenn beide Seiten `gender = couple` besitzen, zeigen Teilnehmer-App, Adminoberflächen und Billboard das Match mit der einheitlichen Paarfarbe. Andere Kombinationen bleiben optisch unverändert.

### SM-COUPLE-ACTION-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Bei einem Ziel mit `gender = couple` werden ausschließlich vorhandene Aktionen mit `target_gender = any` angeboten; der Aktionskatalog erhält keine neue Paar-Kategorie.

### SM-COUPLE-TOP16-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Profile mit `gender = couple` werden von der bestehenden Top-16-Auswahl ausgeschlossen.

## Offene Entscheidung

- `TBD`: Welche feste Akzentfarbe kennzeichnet ein Paar-zu-Paar-Match, ohne die vorhandenen Match-Typ-Farben unleserlich zu machen?
