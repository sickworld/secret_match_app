# Agent Workflow für SecretMatch

Diese Datei enthält die verbindlichen Arbeitsregeln für Agenten in diesem Repository.

## Grundregeln

- Vor Änderungen den relevanten Code, `git status --short` und bei Bedarf den aktuellen Diff prüfen.
- Bestehende Nutzeränderungen erhalten. Unverwandte Änderungen weder bearbeiten noch in den eigenen Commit aufnehmen.
- Für Datei- und Textsuche zuerst `rg` beziehungsweise `rg --files` verwenden.
- Änderungen klein, thematisch und passend zur vorhandenen SwiftUI-Struktur halten.
- Keine neue Architektur oder Abhängigkeit einführen, wenn das Problem mit den bestehenden Patterns sauber lösbar ist.
- Keine Secrets, Passwörter, Tokens, Zertifikate, Provisioning Profiles oder personenbezogenen Daten protokollieren oder committen.

## Projektstruktur

- Xcode-Projekt: `SecretMatch.xcodeproj`
- Scheme und App-Target: `SecretMatch`
- App-Code: `SecretMatch/`
- Views: `SecretMatch/Views/`
- Wiederverwendbare UI: `SecretMatch/Components/`
- Netzwerkzugriff: `SecretMatch/Service/APIService.swift`
- API-Modelle: `SecretMatch/Objects/`
- Assets: `SecretMatch/Assets.xcassets/`
- Zielgerät laut Projektkonfiguration: iPad

## Implementierung

- UI-State, Nebenwirkungen und asynchrone Arbeit klar trennen.
- UI-Änderungen in Dark Mode und auf iPad-Layouts prüfen.
- Bestehende Theme-Komponenten bevorzugen; Farben, Abstände und Styles nicht unnötig duplizieren.
- Netzwerkparameter korrekt URL- oder JSON-encodieren. Keine Werte durch String-Verkettung ungeprüft in Request-Bodies einsetzen.
- HTTP-Statuscodes validieren, bevor Responses dekodiert werden.
- Nutzerfreundliche Fehler anzeigen, ohne Serverantworten oder interne Details ungefiltert offenzulegen.
- Admin- und normale Nutzerzustände strikt trennen. Admin-Daten und Admin-Funktionen dürfen nicht in reguläre Flows gelangen.
- Bei Änderungen an API-Requests immer Request-Methode, Content-Type, Encoding, Response-Modell, Fehlerfälle und Serverkompatibilität gemeinsam prüfen.
- Debug-Ausgaben mit Response-Inhalten vor Auslieferung entfernen oder auf nicht sensible Diagnosen begrenzen.

## Dokumentation

`README.md` aktualisieren, wenn sich Setup, unterstützte Plattformen, Bedienung, API-Vertrag, Konfiguration oder Build-Ablauf ändern.

Für sichtbare Produktänderungen Release Notes oder ein vorhandenes Changelog aktualisieren. Falls noch kein Changelog existiert, keines nur für eine kleine Änderung erfinden; den Bedarf bei einer Release-Aufgabe neu bewerten.

## Versionierung

- Bei jeder ausgelieferten Änderung an App-Code, UI, API-Integration, Modellen, Assets oder Xcode-Projekt sowohl `MARKETING_VERSION` als auch `CURRENT_PROJECT_VERSION` erhöhen.
- `SecretMatch` und `SecretMatch Admin` müssen in allen Build-Konfigurationen dieselben Versions- und Buildnummern verwenden.
- Die Marketing-Version als nächste Patch-Version und die Buildnummer um eins erhöhen, sofern der Nutzer keine andere Zielversion vorgibt.
- Reine Dokumentations- oder Agentenanweisungsänderungen benötigen keinen Versionssprung.

## WordPress-Modul

- Bei Änderungen an API-Requests, Responses, Authentifizierung, Feedback, Event-Reset oder anderem serverabhängigem Verhalten immer das zugehörige SecretMatch-WordPress-Modul unter `../../wordpress/wordpress/wp-content/plugins/secretmatch` prüfen und bei Bedarf gemeinsam anpassen.
- Bei Moduländerungen Plugin-Version, `README.md` und `CHANGELOG.md` konsistent aktualisieren sowie PHP-Lint und passende Modulprüfungen ausführen.
- Die `AGENTS.md` und Git-Regeln des WordPress-Repositories zusätzlich befolgen; insbesondere nicht eigenmächtig committen, pushen oder deployen, wenn dessen Regeln dafür eine ausdrückliche Freigabe verlangen.

## Review-Pflicht

Jede Codeänderung vor Commit anhand von `skill/secretmatch-review/SKILL.md` prüfen.

Besonders prüfen:

- fachliche Korrektheit und Regressionen
- Nebenläufigkeit, `@MainActor` und SwiftUI-State
- Request-Encoding, Statuscode- und Fehlerbehandlung
- Zugriffstrennung zwischen Admins und normalen Nutzern
- Datenschutz, Logs und Secrets
- iPad-Layout, Lade-, Fehler- und Leerzustände
- unbeabsichtigte Änderungen an Signing, Bundle ID oder Deployment Target

Bei einer reinen Review-Aufgabe keine Änderungen implementieren, sofern der User nicht ausdrücklich auch einen Fix verlangt.

## Validierung

Nach App-Code- oder Projektänderungen mindestens:

```bash
xcodebuild -project SecretMatch.xcodeproj -scheme SecretMatch -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
git diff --check
```

Bei reinen Markdown-Änderungen reichen normalerweise Inhaltsprüfung, Skill-Validierung und `git diff --check`.

Wenn Tests ergänzt werden, den kleinsten passenden Test-Plan oder gezielte Tests ausführen. Eine erfolgreiche Kompilierung nicht als Testabdeckung ausgeben.

## Git und Commit

Nach abgeschlossener und geprüfter Arbeit:

1. `git status --short` und `git diff` prüfen.
2. Xcode-Nutzerdateien wie `xcuserdata/` und `UserInterfaceState.xcuserstate` ausschließen.
3. Nur die zur Aufgabe gehörenden Dateien stagen.
4. Den staged Diff mit `git diff --cached` abschließend reviewen.
5. Aussagekräftig committen.
6. Auf den aktuellen Branch pushen, sofern der User nichts anderes sagt.
7. Final `git status --short` prüfen.

Commit-Messages beschreiben die fachliche Änderung, zum Beispiel:

```text
Improve admin login error handling
Add empty state to match history
Document SecretMatch review workflow
```

Verboten sind nichtssagende Messages wie `.`, `fix`, `fixes`, `wip`, `change` oder `Update files`.

Wenn ein Push fehlschlägt, den konkreten Fehler melden und keine erzwungenen Git-Operationen durchführen.

## Kommunikation

Im Abschluss knapp nennen:

- fachliche Änderungen
- Review-Ergebnis und Restrisiken
- ausgeführte Builds, Tests und Checks
- Commit-Hash
- Push-Ergebnis
- sauberer oder durch vorbestehende Änderungen weiterhin veränderter Working Tree
