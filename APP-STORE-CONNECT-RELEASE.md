# Automatischer App-Store-Connect-Release

Der Workflow `App Store Connect Release` lädt die Teilnehmer-App und die Admin-App nach App Store Connect hoch, sobald ein entsprechend benannter Pull Request sicher nach `main` gemergt wurde und die normale `iOS Quality`-Pipeline für genau diesen Merge-Commit vollständig erfolgreich war.

## Release auslösen

1. Die Release-Änderungen mit synchroner Marketing- und Buildversion für beide Targets als Pull Request nach `main` öffnen.
2. Den PR exakt `release` oder `Release: <Version>` nennen; Groß-/Kleinschreibung ist egal.
3. Den normalen PR-Run prüfen und den PR mergen.
4. Der Push-Run von `iOS Quality` prüft den tatsächlichen Merge-Commit erneut.
5. Nur bei grünem Ergebnis lädt `App Store Connect Release` beide Schemes nacheinander hoch.

Ein offener PR, ein fehlgeschlagener Quality-Run, ein normal benannter PR oder ein direkter Push löst keinen Upload aus. Ein erneuter Upload derselben App-Version und Buildnummer wird von Apple abgewiesen; jeder Release-Stand benötigt deshalb eine noch nicht verwendete Buildnummer.

Der Workflow überträgt Builds nach App Store Connect. Nach Apples asynchroner Verarbeitung stehen sie in TestFlight bereit. Er verteilt sie nicht automatisch an externe Tester und reicht keine App-Version automatisch zur App-Store-Prüfung ein.

## Einmalige GitHub-Einrichtung

Unter **Settings → Environments** ein Environment namens `app-store-connect` anlegen. Dort diese Environment Secrets speichern:

| Secret | Inhalt |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | Key-ID des App-Store-Connect-Team-API-Keys |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer-ID des App-Store-Connect-Accounts |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | vollständiger Inhalt der einmal herunterladbaren Datei `AuthKey_<KEY_ID>.p8` |

Der private Schlüssel darf niemals ins Repository, in Artefakte oder Logs gelangen. Das Environment kann optional mit Required Reviewers geschützt werden; ohne diese Zusatzfreigabe startet der Upload direkt nach der grünen Pipeline.

## Einmalige Apple-Einrichtung

- In App Store Connect müssen Apps für `com.SecretMatch` und `com.SecretMatch.Admin` existieren.
- Unter **Users and Access → Integrations → App Store Connect API** einen Team-Key mit einer zum Build-Upload berechtigten Rolle erstellen, beispielsweise Developer oder App Manager.
- Den privaten `.p8`-Schlüssel sofort sicher speichern; Apple bietet ihn nur einmal zum Download an.
- Team `BVCKM275FP`, Bundle-IDs und benötigte Capabilities müssen im Apple Developer Account eingerichtet sein.
- Verträge und sonstige Apple-Voraussetzungen müssen aktiv sein.

Xcode nutzt den Team-API-Key mit automatischer Signierung und darf erforderliche App-Store-Provisioning-Profile beziehungsweise verwaltete Cloud-Signing-Zertifikate anlegen oder laden. Es werden keine Zertifikate oder Provisioning Profiles im Repository gespeichert.

## Sicherheit und Nachvollziehbarkeit

- Der Apple-Workflow läuft erst nach dem erfolgreichen `iOS Quality`-Push-Run auf `main`.
- Der Release-Gate-Job erhält keine Apple-Secrets und prüft über die GitHub-API den tatsächlich zugehörigen gemergten PR.
- Nur der Upload-Job verwendet das geschützte Environment und checkt exakt den bereits getesteten Commit-SHA aus.
- Teilnehmer- und Admin-App werden absichtlich nacheinander hochgeladen.
- Signierte Archive und API-Key werden nicht als Artefakte gespeichert.
- Archive-/Upload-Logs verfallen nach 14 Tagen.
- Der Workflow lädt einen Build hoch, veröffentlicht ihn aber nicht selbst im öffentlichen App Store.

## Fehlerdiagnose

| Fehler | Typische Ursache |
| --- | --- |
| Fehlendes Environment Secret | Environment oder Secret-Name stimmt nicht exakt |
| Authentifizierung fehlgeschlagen | Key-ID, Issuer-ID und `.p8` gehören nicht zusammen oder der Key wurde widerrufen |
| Signing/Provisioning fehlgeschlagen | Bundle-ID, Capability, Team oder API-Key-Rolle fehlt |
| App nicht gefunden | Passender App-Store-Connect-Eintrag für die Bundle-ID fehlt |
| Buildnummer bereits verwendet | `CURRENT_PROJECT_VERSION` vor dem Release nicht erhöht |
| Build hochgeladen, aber noch nicht sichtbar | Apple verarbeitet Uploads asynchron; Verarbeitung in App Store Connect prüfen |
