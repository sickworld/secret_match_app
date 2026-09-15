# Wünsche, Matches und Aktionen

[Zur Übersicht](Business-Logic.md)

## Gemeinsamer Teilnehmerablauf

1. Der Teilnehmer gibt eine andere freigegebene Zielnummer ein.
2. Bei Online-Verbindung fragt die App die zulässigen Optionen für genau dieses Ziel ab.
3. Match-Typen bleiben unabhängig vom Zielprofil verfügbar. Aktionstypen werden nach Sichtbarkeit und Zielgeschlecht gefiltert.
4. Der Teilnehmer wählt mindestens einen Typ. Eine gemeinsame Auswahl kann Match-Wünsche und Aktionen enthalten.
5. Die App legt vor dem ersten Netzwerkversuch für jeden Typ einen Queue-Eintrag an.
6. Der Server validiert Sitzung, Nummern, Typen und optionale Nachricht erneut.

Absender und Ziel dürfen nicht identisch sein. Wird die Zielnummer geändert, verwirft die App die bisherige Auswahl und die zugehörige Nachricht.

## Zielabhängige Aktionsauswahl

`interaction-options` liefert aktive Match-Typen und nur jene aktiven Aktionen, deren `target_gender` zu einem bekannten Zielprofil passt. Bei fehlendem Profil bleibt der aktive Katalog verfügbar und die Antwort kennzeichnet, dass nicht profilbasiert gefiltert wurde. Die Ziel-Genderangabe selbst verlässt den Server nicht.

Bei bereits erkannter Offline-Verbindung zeigt die App sofort den letzten vollständig gespeicherten aktiven Katalog mit sichtbarem Offline-Hinweis. Bei Timeout der interaktiven Zielabfrage wechselt sie ebenfalls in diesen erklärten Fallback. Fachliche HTTP-, Sitzungs- oder Decodierungsfehler dürfen die ungefilterte Auswahl nicht still öffnen.

Der Server prüft beim tatsächlichen Aktionsversand nochmals Sichtbarkeit und, sofern das Zielprofil bekannt ist, die Genderfreigabe.

## Match-Wünsche

Ein Wunsch enthält Absender, Ziel, Match-Typ und optional eine Nachricht mit höchstens 180 Zeichen. Administrativ gepflegte Schnelltexte erleichtern die Eingabe; es gibt höchstens acht Vorschläge mit jeweils höchstens 80 Zeichen. Ein übernommener Text kann vor dem Versand bearbeitet werden.

Ein gleicher Wunsch von demselben Absender an dasselbe Ziel mit demselben Typ ist idempotent. Eine mitgesendete Request-ID darf nur denselben fachlichen Wunsch bezeichnen. Eine erneute Sendung kann die eigene gespeicherte Nachricht ergänzen oder aktualisieren.

## Match-Auflösung

Ein Match entsteht erst, wenn mindestens ein Wunsch in Gegenrichtung existiert.

- Haben beide Seiten denselben Typ gewählt, erhält das Match diesen Typ.
- Haben sie unterschiedliche Typen gewählt, verwendet der Server den ersten aktiven Match-Typ in der gepflegten Katalogreihenfolge als Basistyp.
- Pro ungeordnetem Nummernpaar gibt es höchstens ein Match.
- Ein bestehendes Match wird nur auf einen höher sortierten Typ aufgewertet.
- Ein Upgrade erfolgt nur, wenn die beiden maßgeblichen Wünsche denselben höherwertigen Typ tragen.
- Ein Downgrade findet nicht statt.

Bei einem neuen Match oder Upgrade kann der Server eine Telegram-Nachricht mit Nummernpaar und Match-Bezeichnung senden. Freitext wird nicht übertragen.

## Interessen und Matches aus Teilnehmersicht

Die Rubrik **Interesse** zeigt eingehende Wünsche an die angemeldete Nummer, solange für das Paar noch kein Match existiert. Mehrere Wünsche derselben Absendernummer werden zusammengefasst; der höher sortierte Typ gewinnt, und eine vorhandene Nachricht bleibt erhalten.

Die Rubrik **Matches** zeigt das Gegenüber, den finalen Typ, Zeitpunkt und nur die Nachricht der jeweils anderen Seite. Bereits gematchte Nummern erscheinen nicht mehr unter offenen Interessen.

## Aktionen

Aktionen benötigen keine Gegenrichtung. Jeder Versand enthält Aktionstyp, Absender, Ziel und nach Möglichkeit eine UUID als `request_id`. Die Request-ID ist eindeutig:

- Derselbe Retry wird erfolgreich beantwortet, ohne eine zweite Aktion anzulegen.
- Eine parallele Einfügung wird nach einem Unique-Key-Konflikt erneut gelesen und ebenfalls idempotent beantwortet.
- Eine bereits zurückgezogene Request-ID bleibt zurückgezogen.

Die Teilnehmerübersicht stellt erhaltene Aktionen und die für einen Rückzug benötigten eigenen Sendungen getrennt dar. Richtungsreiter und Typfilter verwenden auf dem iPad dieselbe visuelle Auswahlkomponente, bleiben aber zwei unabhängige Filterdimensionen. Ein Richtungswechsel setzt Typ- und Nummernfilter zurück, damit keine unsichtbar weiterwirkende Einschränkung aus der zuvor geöffneten Liste bestehen bleibt. Zurückgezogene Aktionen sind beim Empfänger nicht mehr sichtbar.

## Rückzug einer Aktion

Nur der aus der aktiven Serversitzung abgeleitete Absender darf seine Aktion über deren Request-ID zurückziehen. Die Operation ist idempotent.

- Liegt die Aktion noch ausschließlich in der lokalen Queue, entfernt die App sie lokal.
- Ist sie zugestellt, setzt der Server `withdrawn_at` statt den Datensatz vollständig zu vergessen.
- Ein verspäteter Retry erkennt denselben Tombstone und aktiviert die Aktion nicht erneut.
- Match-Wünsche und Matches werden durch den Aktionsrückzug nicht verändert.

## Katalogpflege

Administratoren pflegen Match- und Aktionstypen zentral. Änderungen wirken ohne neuen App-Build auf Teilnehmerauswahl, Adminlisten, Billboard und Statistik. Verwendete Typen können nur ausgeblendet werden. Teilnehmer dürfen nur aktive Typen neu senden; Admin-Korrekturen dürfen historische ausgeblendete Typen weiterhin bearbeiten, damit bestehende Eventdaten lesbar bleiben.
