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

## Kontrollierter Testlauf

Ein vollständiger Test ist ein echter Upload nach App Store Connect, veröffentlicht die Apps aber noch nicht im öffentlichen App Store:

1. Von aktuellem `main` einen neuen Branch erstellen.
2. `MARKETING_VERSION` in beiden Targets und allen Build-Konfigurationen auf das aktuelle Datum setzen und `CURRENT_PROJECT_VERSION` auf eine bei Apple noch nicht verwendete Nummer erhöhen. Für den ersten Test nach Build `149` ist Build `150` vorgesehen, sofern diese Nummer noch bei keiner der beiden Apps verwendet wurde.
3. Die Versionsänderung committen, pushen und einen Pull Request nach `main` öffnen.
4. Den PR exakt `release` oder beispielsweise `Release: 2026.09.14` nennen.
5. Zuerst den normalen PR-Lauf von `iOS Quality` prüfen. Solange der PR nur offen ist, erfolgt kein Apple-Upload.
6. Den grünen PR nach `main` mergen. Dadurch startet ein neuer `iOS Quality`-Push-Lauf für den tatsächlichen Merge-Commit.
7. Nach dessen Erfolg unter **Actions → App Store Connect Release** prüfen, dass **Verify merged release PR**, **Upload participant-app to App Store Connect** und **Upload admin-app to App Store Connect** erfolgreich sind.
8. Nach Apples Verarbeitung in App Store Connect bei beiden Apps unter **TestFlight** prüfen, dass der neue Build erscheint.

Der Test verbraucht die gewählte Buildnummer bei Apple dauerhaft. Einen fehlgeschlagenen Upload erst nach Fehleranalyse erneut ausführen; sobald Apple einen Build angenommen hat, benötigt ein weiterer Upload derselben App eine neue Buildnummer. Ein übersprungener `App Store Connect Release`-Lauf nach einem normalen Push ist erwartet und bestätigt, dass der Release-Gate keine unbeabsichtigten Uploads zulässt.

## App Store Connect API Key und GitHub Secrets

### Werte bei Apple erzeugen und finden

Für diesen Workflow einen **Team API Key** verwenden:

1. [App Store Connect](https://appstoreconnect.apple.com/) öffnen.
2. **Users and Access → Integrations → App Store Connect API → Team Keys** öffnen.
3. Falls dort zunächst **Request Access** erscheint, muss der Account Holder den API-Zugriff einmalig beantragen und freischalten lassen.
4. Als Account Holder oder Admin **Generate API Key** beziehungsweise **+** wählen, einen internen Namen wie `GitHub Actions Release` vergeben und eine zum Build-Upload berechtigte Rolle auswählen.
5. Nach **Generate** stehen die drei zusammengehörenden Werte bereit:

| GitHub Secret | Fundstelle bei Apple |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | Wert **Key ID** in der Zeile des erzeugten Team Keys |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Wert **Issuer ID** auf der Seite **App Store Connect API** |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | vollständiger Textinhalt der heruntergeladenen Datei `AuthKey_<KEY_ID>.p8`, einschließlich `BEGIN PRIVATE KEY` und `END PRIVATE KEY` |

Die `.p8`-Datei kann nur einmal heruntergeladen werden. Ist der Download nicht mehr verfügbar und wurde die Datei nicht sicher gespeichert, den alten Key widerrufen und einen neuen Team Key erzeugen. Keinen individuellen API Key verwenden, weil der Release-Workflow die Provisioning- und Signing-Funktionen des Team Keys benötigt. Details stehen in Apples Dokumentation zu [App Store Connect API Keys](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api).

### Werte bei GitHub hinterlegen

Im Repository **Settings → Environments** öffnen und ein Environment namens `app-store-connect` anlegen. In diesem Environment unter **Environment secrets → Add secret** jeden der drei Werte einzeln speichern:

| Secret | Inhalt |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | Key-ID des App-Store-Connect-Team-API-Keys |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer-ID des App-Store-Connect-Accounts |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | vollständiger Inhalt der einmal herunterladbaren Datei `AuthKey_<KEY_ID>.p8` |

Beim privaten Key die Datei in einem Texteditor öffnen und ihren gesamten Inhalt als Secret-Wert einsetzen; die `.p8`-Datei selbst wird nicht ins Repository hochgeladen. GitHub beschreibt diese Oberfläche unter [Environment Secrets anlegen](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets#creating-secrets-for-an-environment).

Der private Schlüssel darf niemals ins Repository, in Artefakte, Logs oder einen Chat gelangen. Das Environment kann optional mit Required Reviewers geschützt werden; ohne diese Zusatzfreigabe startet der Upload direkt nach der grünen Pipeline.

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
