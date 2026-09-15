# Pärchenprofile und gemeinsames Matching

[Zur Übersicht](Business-Logic.md)

## Status

- **Konzeptstand:** 15. September 2026
- **Phase:** Geplant, noch nicht implementiert
- **Ziel:** Match&Play soll neben Einzelpersonen auch gemeinsam auftretende Paare als eigenständige matchbare Einheit unterstützen.

Diese Seite beschreibt den fachlichen Zielentwurf. Sie ändert den aktuell implementierten Login-, Profil- oder Match-Vertrag noch nicht. Offene Produktentscheidungen sind ausdrücklich als `TBD` gekennzeichnet.

## Fachliche Leitentscheidung

Ein Paar wird als eigenes **Match-Profil** behandelt. Es ist weder ein drittes Geschlecht noch lediglich zwei lose Einzel-Logins mit gemeinsam dargestellten Daten.

Für die erste Version handelt das Paar vollständig gemeinsam:

- eine gemeinsame Eventnummer,
- eine gemeinsame zweistellige PIN,
- eine gemeinsame Teilnehmer-Sitzung,
- eine gemeinsame Auswahl von Match-Wünschen und Aktionen,
- eine gemeinsame Übersicht über Interessen, Matches und Aktionen.

Beide Personen müssen wissen, dass alle Inhalte des Paarprofils gemeinsam sichtbar sind. Getrennte Entscheidungen einzelner Partner innerhalb desselben Paarprofils sind nicht Bestandteil der ersten Version.

## Vorgeschlagenes Domänenmodell

Das bisherige nummernbasierte Teilnehmerprofil wird fachlich zu einem Match-Profil erweitert.

| Eigenschaft | Bedeutung |
| --- | --- |
| Interne Profil-ID | Stabile, nicht öffentlich dargestellte Identität für Beziehungen und spätere Erweiterungen |
| Eventnummer | Am Event sichtbare und für Login sowie Zielauswahl verwendete Nummer |
| Profiltyp | `single` oder `couple` |
| Mitglieder | Eine Person bei `single`, zwei Personen bei `couple` |
| PIN und Sitzung | Authentifizierung des gesamten Match-Profils |
| Zielpräferenzen | Legt fest, ob das Profil Singles, Paare oder beide Profiltypen matchen möchte |
| Eingangsfreigaben | Legt fest, von welchen Profiltypen das Profil Wünsche und Aktionen erhalten möchte |

Geschlecht und Profiltyp bleiben getrennte Eigenschaften. `couple` darf deshalb nicht als zusätzlicher Gender-Wert in das bestehende Feld aufgenommen werden. Bei Paaren können Geschlechter oder andere mitgliederbezogene Angaben intern gespeichert werden, sofern sie für serverseitige Aktionsregeln benötigt werden; sie werden anderen Teilnehmer-Clients nicht offengelegt.

## Matching-Regeln

Match-Wünsche werden künftig fachlich zwischen Match-Profilen statt zwischen natürlichen Personen ausgetauscht. Die sichtbaren Eventnummern bleiben die Bedien- und Darstellungsreferenz.

| Absender | Ziel | Ergebnis |
| --- | --- | --- |
| Single `#042` | Paar `#180` | Match, sobald das Paar einen Gegenwunsch an `#042` sendet |
| Paar `#180` | Single `#042` | Match, sobald der Single einen Gegenwunsch an `#180` sendet |
| Paar `#180` | Paar `#181` | Match, sobald beide Paarprofile einander gewählt haben |

Es gelten weiterhin die bestehenden Grundregeln:

- Ein Wunsch ist gerichtet und ein Match entsteht erst durch einen Gegenwunsch.
- Pro ungeordnetem Profilpaar existiert höchstens ein Match.
- Ein Profil darf nicht an sich selbst senden.
- Match-Typ, Upgrade-Regeln, Freitext, Request-ID und Offline-Queue funktionieren unabhängig vom Profiltyp.
- Der Server prüft beim Abruf der Optionen und beim Versand, ob die beteiligten Profiltypen gegenseitig zugelassen sind.

Ein Paarmatch beschreibt immer die Verbindung der beiden vollständigen Profile. Die erste Version erzeugt keine separaten Teilmatches zwischen einzelnen Mitgliedern eines Paares und dem Gegenüber.

## Zustimmung und Zielpräferenzen

Damit ein Single nicht ungefragt als Ziel für Paare freigeschaltet wird, sollen Match-Profile getrennt festlegen können:

1. Wen möchte das Profil matchen: Singles, Paare oder beide?
2. Von wem möchte das Profil Wünsche und Aktionen erhalten: Singles, Paare oder beide?

Eine Zielnummer ist nur auswählbar, wenn die serverseitigen Freigaben beider Seiten die konkrete Kombination zulassen. Die App erhält lediglich das Ergebnis und die erlaubten Optionen, nicht die privaten Profil- oder Mitgliederangaben des Ziels.

Die genauen Voreinstellungen sind vor Umsetzung festzulegen. Empfohlen ist eine bewusste Auswahl während der Ersteinrichtung statt einer stillen Freigabe für alle Kombinationen.

## Vorgeschlagener Login- und Einrichtungsablauf

1. Der Teilnehmer gibt wie bisher die Eventnummer ein.
2. Der Server prüft Freigabe, vorhandene PIN und Profilzustand.
3. Eine vorhandene PIN wird wie bisher über den zweistelligen Login geprüft.
4. Bei der Ersteinrichtung wird einmalig **Allein** oder **Als Paar** gewählt.
5. Ein Single vervollständigt das bestehende Einzelprofil.
6. Ein Paar bestätigt die gemeinsame Nutzung und richtet seine Ziel- und Eingangsfreigaben ein.
7. Nach Abschluss wird der Profiltyp gesperrt; eine spätere Korrektur erfolgt nur administrativ und beendet bestehende Sitzungen.

Alternativ kann der Profiltyp bereits durch den Einlass beziehungsweise die Administration vorgegeben werden. Welche Variante im Eventbetrieb weniger fehleranfällig ist, bleibt `TBD` und soll vor der technischen Umsetzung mit dem tatsächlichen Einlassablauf geprüft werden.

## Darstellung in Teilnehmer-App und Verwaltung

Der Profiltyp muss überall erkennbar sein, ohne personenbezogene Daten zu zeigen:

- `👤 Single #042`
- `👥 Paar #180`

Nach Eingabe einer Zielnummer zeigt die App den Profiltyp vor der Auswahl noch einmal deutlich an. Matches, offene Interessen, Aktionen, Adminlisten und Exporte verwenden dieselbe Kennzeichnung.

Die Administration benötigt mindestens:

- Profiltyp anzeigen und korrigieren,
- Ziel- und Eingangsfreigaben einsehen und ändern,
- Paarprofil zurücksetzen oder sperren,
- erkennen, ob ein Paarprofil vollständig eingerichtet ist,
- beim Wechsel des Profiltyps PINs und aktive Sitzungen sicher widerrufen.

## Aktionskatalog

Das heutige Zielkriterium `target_gender` reicht für Paarprofile nicht aus. Der Katalog soll zusätzlich zulässige Ziel-Profiltypen kennen, beispielsweise:

- alle Profile,
- nur Singles,
- nur Paare.

Mitgliederbezogene Gender-Regeln können bei Bedarf ergänzend serverseitig ausgewertet werden. Die API liefert der Teilnehmer-App weiterhin nur die für die konkrete Zielnummer erlaubten Aktionen. Private Angaben zur Zusammensetzung eines Paares bleiben auf dem Server.

## Billboard und Benachrichtigungen

Billboard, Match-Overlay und Benachrichtigungen stellen Profiltyp und Eventnummer dar, beispielsweise:

> 👥 180 + 👤 042

Mitgliedernamen oder andere personenbezogene Angaben werden nicht eingeblendet. Ein Match mit einem Paar löst genau eine gemeinsame Match-Anzeige aus und nicht je eine Anzeige pro Mitglied.

## Top 16

Die bestehende Top 16 basiert auf acht Frauen und acht Männern und setzt damit Einzelprofile voraus. Für die erste Pärchen-Version gilt die Empfehlung:

- Paarprofile nehmen nicht an der bestehenden Top 16 teil.
- Die bisherige Auswahl für Einzelprofile bleibt unverändert.
- Eine spätere eigene Kategorie wie **Top Couples** wird separat konzipiert und gewichtet.

Eine gemeinsame Rangliste von Einzel- und Paarprofilen ist nicht vorgesehen, solange Bewertung, Personenzahl und Darstellung nicht fachlich eindeutig definiert sind.

## Statistik und Datenschutz

Statistiken müssen künftig zwischen **Match-Profilen** und **anwesenden Personen** unterscheiden. Ein Paar zählt als ein Match-Profil, aber als zwei Gäste. Matches und Aktionen werden weiterhin pro Profil gezählt.

Für Datenschutz und Protokollierung gelten zusätzlich:

- Die gemeinsame Sichtbarkeit innerhalb eines Paarprofils wird vor Abschluss der Einrichtung erklärt und bestätigt.
- Mitgliederangaben erscheinen weder im Billboard noch in Telegram-, APNs-, Telemetrie- oder Audit-Inhalten.
- Freitexte bleiben ausschließlich für die am Match beteiligten Profile sichtbar.
- Beim administrativen Auflösen eines Paarprofils werden Sitzungen widerrufen und die Auswirkungen auf bestehende Matches ausdrücklich bestätigt.

## Technische Migration und Kompatibilität

Bestehende Teilnehmer werden ohne sichtbare Änderung als Match-Profile vom Typ `single` übernommen. Die bisherige Eventnummer bleibt erhalten.

Für eine schrittweise Einführung wird empfohlen:

1. Eine interne Profil-ID und den Profiltyp additiv einführen.
2. Bestehende Nummern einmalig oder beim Lesen auf `single` abbilden.
3. Sessions, Requests, Matches und Aktionen intern auf die Profil-ID beziehen, die Eventnummer aber in kompatiblen API-Antworten weiter ausgeben.
4. Paarprofile erst freischalten, wenn App, WordPress-Modul, Adminoberflächen, Billboard, Statistik und Exporte den Typ gemeinsam verstehen.
5. Alte App-Versionen über Feature-Gate oder Mindestversion davon abhalten, Paarprofile mit unvollständigen Regeln zu verwenden.

Eine dauerhafte Reservierung bestimmter Nummernbereiche für Paare ist nicht erforderlich. Der Profiltyp soll als gepflegte Eigenschaft gespeichert und nicht aus der Nummer abgeleitet werden.

## Geplanter Rollout

### Phase 1: Domäne und Administration

- Profiltyp und interne Profil-ID einführen.
- Bestehende Einzelprofile kompatibel migrieren.
- Paarprofile administrativ anlegen, korrigieren und sperren können.

### Phase 2: Login und Matching

- Paar-Ersteinrichtung und gemeinsame Sitzung ergänzen.
- Single-zu-Paar- und Paar-zu-Paar-Wünsche unterstützen.
- Präferenzen und gegenseitige Freigaben serverseitig erzwingen.

### Phase 3: Gesamtsystem

- Aktionen, Übersicht, Billboard, Benachrichtigungen und Exporte paarfähig machen.
- Profil- und Personenzahlen in der Statistik trennen.
- Top-16-Ausschluss technisch und durch Tests absichern.

### Phase 4: Mögliche Erweiterungen

- eigene Top-Couples-Auswertung,
- getrennte Bestätigung beider Partner,
- Verknüpfung vorhandener Einzelprofile zu einem temporären Paarprofil.

Phase 4 ist nicht Teil des ersten Lieferumfangs.

## Anforderungen für eine spätere Umsetzung

### SM-COUPLE-DOMAIN-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Das System unterscheidet Singles und Paare über einen eigenen Profiltyp; bestehende Einzelprofile bleiben ohne erneute Einrichtung nutzbar.

### SM-COUPLE-AUTH-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Ein Paar kann sich mit einer gemeinsamen Eventnummer und PIN anmelden und sieht ausschließlich die gemeinsame Paar-Sitzung.

### SM-COUPLE-MATCH-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Singles und Paare können im Rahmen ihrer gegenseitigen Freigaben Wünsche an Singles und Paare senden; ein Gegenwunsch erzeugt genau ein gemeinsames Match.

### SM-COUPLE-CONSENT-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Vor Aktivierung bestätigt das Paar die gemeinsame Sichtbarkeit; Singles und Paare wählen bewusst, von welchen Profiltypen sie kontaktiert werden dürfen.

### SM-COUPLE-PRESENTATION-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Teilnehmer-App, Adminoberflächen, Billboard, Benachrichtigungen und Exporte kennzeichnen den Profiltyp einheitlich, ohne Mitgliederdaten offenzulegen.

### SM-COUPLE-TOP16-001

- **Priorität:** P1
- **Phase:** Geplant
- **Akzeptanzkriterium:** Paarprofile werden in der ersten Version nicht in die bestehende geschlechterbasierte Top 16 aufgenommen.

## Offene Produktentscheidungen

- `TBD`: Wird der Profiltyp beim Einlass administrativ gesetzt oder bei der ersten Anmeldung gewählt?
- `TBD`: Welche Ziel- und Eingangsfreigaben sind beim ersten Öffnen vorausgewählt?
- `TBD`: Müssen beide Mitglieder eines Paares ihre gemeinsame Nutzung technisch separat bestätigen?
- `TBD`: Welche Mitgliederangaben werden für paarabhängige Aktionsregeln wirklich benötigt?
- `TBD`: Was geschieht mit bestehenden Matches, wenn ein Paarprofil administrativ aufgelöst oder in ein Einzelprofil geändert wird?
