# Match&Play Event-Netzwerk

Stand: 12. September 2026

Dieses Setup ist für einen mittelgroßen Club mit ungefähr 10–30 iPads, zwei Billboards und mehreren Admin-Geräten ausgelegt. Ziel ist ein eigenes, stabiles Veranstaltungsnetz, das auch bei einem Ausfall des Club-Internets lokal weiterarbeitet.

> **Aktueller Softwarestatus:** Die Match&Play-App verwendet derzeit noch den Cloud-Endpunkt. Der hier beschriebene vollständige Offline-Betrieb setzt den geplanten lokalen Eventserver und die lokale Servererkennung in der App voraus. Ein eigener Router verbessert bereits jetzt die WLAN-Stabilität, ersetzt diese Softwareerweiterung aber nicht.

## Empfohlene Geräte

| Anzahl | Gerät | Aufgabe | Richtpreis |
| ---: | --- | --- | ---: |
| 1 | UniFi Dream Router 7 | Router, Firewall, Internet-Failover und zentraler WLAN-Punkt | 250 € |
| 2 | UniFi U6 Mesh | Zusätzliche WLAN-Abdeckung im Club | je 160 € |
| 1 | UniFi Lite 8 PoE | Strom und Netzwerk für Access Points, Server und Billboards | 99 € |
| 1 | Raspberry Pi 5 mit 8 GB RAM | Lokaler Match&Play-Server | abhängig vom Set |
| 1 | 512-GB-NVMe-SSD mit M.2 HAT+ | Zuverlässiger Serverspeicher | abhängig vom Set |
| 1 | Aktiver Kühler und offizielles 27-W-Netzteil | Kühlung und stabile Stromversorgung des Servers | abhängig vom Set |
| 1 | Kleine USV mit ungefähr 500–750 VA | Überbrückt kurze Stromausfälle | abhängig vom Modell |
| optional | 5G-Router mit Ethernet und SIM | Unabhängiger Internet-Ersatz | abhängig vom Modell |

Der UniFi-Netzwerkteil aus Router, zwei Access Points und PoE-Switch kostet nach den offiziellen Listenpreisen derzeit ungefähr **669 €**. Preise können sich ändern.

## Verkabelung

```text
Club-LAN ───────────────→ WAN 1
5G-Router optional ─────→ WAN 2

                    Dream Router 7
                           │
                    Lite 8 PoE Switch
                  ┌────────┼─────────┐
               U6 Mesh   U6 Mesh   Raspberry Pi
                  │          │
             Club vorne  Club hinten

Billboards möglichst per LAN am Switch
iPads und Admin-iPhone per MatchPlay-Event-WLAN
```

Der lokale Server wird immer per Netzwerkkabel mit dem Switch verbunden. Auch die Billboards sollten nach Möglichkeit kabelgebunden sein. Die U6-Mesh-Geräte werden bevorzugt als kabelgebundene Access Points verwendet. Drahtloses Meshing ist nur die Ausweichlösung, wenn sich kein Kabel verlegen lässt.

## WLAN-Konfiguration

- Eigene SSID, zum Beispiel `MatchPlay-Event`
- WPA2/WPA3-Mischbetrieb für die Kompatibilität mit allen vorhandenen iPads
- Gleiche SSID und gleiches Passwort auf allen Access Points
- DHCP ausschließlich auf dem Dream Router
- Keine Gastnetz-Funktion und keine Client-Isolation
- Lokalen Server per DHCP-Reservierung fest auf `10.42.0.10` legen
- Eigenes Netz, zum Beispiel `10.42.0.0/24`
- 5 GHz als primäres Band; 2,4 GHz für Reichweite und ältere Geräte aktiviert lassen
- Access Points auf unterschiedlichen, möglichst störungsarmen Kanälen betreiben
- Access Points erhöht und nicht direkt hinter Metallflächen, Lautsprechern oder dichter Bühnentechnik platzieren
- Veranstaltungsgäste nicht in das interne Match&Play-WLAN aufnehmen

## Internetanbindung

Die beste Internetquelle ist ein Club-LAN-Anschluss am ersten WAN-Port. Das interne Match&Play-Netz bleibt davon unabhängig bestehen.

Als optionales Backup kann ein 5G-Router mit Ethernet an einem zweiten WAN-Port verwendet werden. Falls der Club ausschließlich WLAN anbietet, kann ein geeigneter Mobilfunkrouter das Club-WLAN als Upstream empfangen und bei dessen Ausfall auf eine SIM-Verbindung wechseln. Das Eventnetz hinter dem Dream Router bleibt dabei unverändert.

Das persönliche iPhone sollte nicht selbst als Hotspot für das Eventnetz dienen. Als normaler Client im Match&Play-WLAN kann es gleichzeitig den lokalen Server erreichen und über den Router ins Internet gehen.

## Lokaler Eventserver

Empfohlene Grundausstattung:

- Raspberry Pi 5 mit 8 GB RAM
- 512-GB-NVMe-SSD statt einer microSD-Karte für Datenbank und Eventdaten
- M.2 HAT+
- Aktive Kühlung
- Offizielles 27-W-USB-C-Netzteil
- Gigabit-Ethernet zum PoE-Switch
- Automatische lokale Sicherungen auf ein separates USB-Laufwerk

Während des Events soll der lokale Server die maßgebliche Instanz sein. iPads, Admin-App und Billboards greifen auf denselben lokalen Datenbestand zu. Cloud-Backups und Eventarchive werden übertragen, sobald Internet verfügbar ist. Unkontrolliertes paralleles Schreiben auf eine lokale und eine unabhängige Cloud-Datenbank ist zu vermeiden.

## Geplanter Local-Network-Check in der App

### Ausgangslage

Die App überwacht bereits mit `NWPathMonitor`, ob iOS einen verwendbaren Netzwerkpfad sieht, und prüft zusätzlich den Cloud-Endpunkt `https://secret-match.de/wp-json/secretmatch/v1/status`. Das unterscheidet **offline** von **Cloudserver nicht erreichbar**, erkennt aber noch keinen lokalen Match&Play-Server. Ein iPad kann deshalb erfolgreich mit dem Event-WLAN verbunden sein, obwohl weder der Cloudserver noch ein lokaler Eventserver erreichbar ist.

Ein sinnvoller Local-Network-Check besteht aus drei getrennten Prüfungen:

1. **Netzwerkpfad:** Ist ein nutzbarer WLAN-Pfad vorhanden?
2. **Lokaler Dienst:** Wird ein autorisierter Match&Play-Server im Eventnetz gefunden?
3. **Funktionsprüfung:** Beantwortet dessen API den Status-Endpunkt innerhalb eines kurzen Zeitlimits korrekt?

Nur die dritte Stufe darf den lokalen Server für Login, Matches, Aktionen, Adminzugriffe oder Billboards freigeben. Das bloße Erreichen des Routers oder eine WLAN-Verbindung reicht dafür nicht.

### Vorgesehene Zustände

| Interner Zustand | Bedeutung | Verhalten der App |
| --- | --- | --- |
| `localOnline` | Lokaler Eventserver antwortet korrekt | Lokale API verwenden, Queue sofort bearbeiten |
| `cloudOnline` | Cloudserver antwortet, kein lokaler Eventmodus aktiv | Cloud-API verwenden, Queue sofort bearbeiten |
| `wifiOnly` | WLAN vorhanden, aber kein Match&Play-Server erreichbar | Verständlichen Hinweis zeigen, Sendungen sicher vormerken |
| `serverUnavailable` | Netzwerk vorhanden, ausgewählter Server antwortet nicht | Kurze Neuprüfung und Queue-Retry durchführen |
| `offline` | Kein verwendbarer Netzwerkpfad | Sendungen lokal vormerken und auf Netzwechsel warten |
| `checking` | Verbindung wird gerade neu bewertet | Vorhandene Ansicht nicht blockieren |

Die sichtbare Meldung soll beispielsweise **„Eventserver lokal verbunden“**, **„Über Internet verbunden“** oder **„Eventserver gerade nicht erreichbar – Versand ist vorgemerkt“** lauten. Technische Hostnamen, IP-Adressen und Tokens gehören nicht in die Teilnehmeransicht.

### Diensterkennung mit Bonjour

Der lokale Server kündigt im Eventnetz einen Bonjour-Dienst vom Typ `_matchplay._tcp` an. Die App sucht diesen Dienst mit `NWBrowser`. Nach einem Fund prüft sie nicht blind die veröffentlichte Adresse, sondern validiert den Server über HTTPS und einen kurzen API-Handshake.

Der Handshake soll mindestens folgende nicht personenbezogene Angaben liefern:

- kompatible API-Version
- stabile Server- beziehungsweise Installations-ID
- aktuelle Event-ID
- Betriebsrolle `event-primary`
- Serverzeit

Die App darf niemals irgendeinem Gerät vertrauen, das lediglich denselben Bonjour-Namen sendet. Der lokale Endpunkt benötigt eine gültig überprüfte TLS-Identität beziehungsweise eine zuvor administrativ gekoppelte Serveridentität. Eine pauschale Abschaltung von App Transport Security ist ausdrücklich nicht vorgesehen.

Für den lokalen Zugriff benötigt die iOS-App:

- `NSLocalNetworkUsageDescription` mit einer verständlichen Match&Play-Erklärung
- `_matchplay._tcp` in `NSBonjourServices`
- eine Behandlung für verweigerten lokalen Netzwerkzugriff, die den Nutzer nicht in einer Endlosschleife erneut fragt

### Endpoint-Auswahl

Die Netzwerklogik soll in einem gemeinsamen `EndpointRouter` beziehungsweise `ConnectionCoordinator` liegen. Views und einzelne API-Methoden wählen keine URLs selbst aus. Der Coordinator hält den zuletzt bestätigten Endpunkt kurzzeitig im Speicher und bewertet ihn bei App-Aktivierung, Netzwerkwechsel sowie nach einem Verbindungsfehler neu.

Vorgesehener Ablauf:

```text
App wird aktiv oder Netzwerk ändert sich
               │
               ▼
       WLAN-Pfad vorhanden?
          │             │
        nein           ja
          │             │
       offline     lokalen Dienst suchen
                        │
                 HTTPS-/Statusprüfung
                   │             │
                 gültig        nicht gültig
                   │             │
             localOnline   Cloudmodus erlaubt?
                                 │
                           Cloud prüfen oder
                           Sendung vormerken
```

Zeitkritische Teilnehmeraktionen sollen nicht vor jedem Request erneut Bonjour durchsuchen. Der letzte gültige lokale Endpunkt wird verwendet, solange seine kurzen Healthchecks erfolgreich bleiben. Discovery und Healthchecks laufen entprellt, damit viele iPads den Server bei einem Netzwerkwechsel nicht gleichzeitig mit Anfragen überlasten.

### Schreibvorgänge, Queue und Doppelversand

Die vorhandene lokale Sendequeue und ihre `request_id` bleiben auch im Local-First-Betrieb verpflichtend:

- Eine Sendung erhält ihre `request_id` vor dem ersten lokalen oder entfernten Netzwerkversuch.
- Ein Endpunktwechsel erzeugt niemals eine neue ID für denselben fachlichen Vorgang.
- Nur eine bestätigte, erfolgreiche Serverspeicherung entfernt den Queue-Eintrag.
- Timeouts und Verbindungsabbrüche gelten als unklarer Zustand und lösen einen idempotenten Retry aus.
- Telemetrie protokolliert nur Verbindungsart, Statuswechsel und gekürzte Serveridentität – keine PINs, Tokens, Nachrichten oder vollständigen Eventnummern.

### Vermeidung von Split-Brain

Im empfohlenen vollständigen Offlinebetrieb ist der Raspberry Pi während des Events die einzige schreibende Instanz. Fällt nur das Internet aus, arbeiten alle Geräte unverändert lokal weiter. Fällt der lokale Server aus, bleiben neue Sendungen in der Gerätequeue, bis er wieder erreichbar ist.

Die App darf in diesem Betriebsmodus **nicht automatisch schreibend auf eine unabhängige Cloud-Datenbank wechseln**. Sonst könnten lokale und entfernte Datenbestände auseinanderlaufen und später widersprüchliche Matches, PINs oder Aktionen enthalten. Ein schreibender Cloud-Fallback ist erst zulässig, wenn Server und Cloud eine ausdrücklich implementierte, konfliktfreie Replikation besitzen.

Als kleinere Zwischenstufe wäre ein lokaler Relay möglich, der Sendungen bei Internetausfall puffert und später unverändert an die Cloud weitergibt. Dieser Relay verbessert den Versand, ermöglicht ohne zusätzlich replizierte Daten aber keinen vollständig lokalen Login, keine Nummernprüfung und keine aktuellen Ansichten. Für das geplante Eventsetup bleibt deshalb der lokale, maßgebliche Eventserver die empfohlene Zielarchitektur.

### Datenschutz und Admin-Diagnose

Die Admin-App soll pro iPad zusätzlich anzeigen können:

- lokale, Cloud- oder fehlende Serververbindung
- Zeitpunkt des letzten erfolgreichen lokalen Healthchecks
- Queue-Anzahl und Alter des ältesten wartenden Versands
- kompatible oder abweichende API-Version
- verweigerte lokale Netzwerkberechtigung

Die Gerätebezeichnung bleibt die sichtbare Identität. SSID, lokale IP, vollständige Geräte-ID und Server-Token werden weder in Teilnehmermeldungen noch im zentralen Eventprotokoll ausgegeben.

### Umsetzungsschritte

1. Lokalen Server als maßgebliche Eventinstanz bereitstellen und `_matchplay._tcp` ankündigen.
2. HTTPS-Identität, Status-Handshake und Server-/Event-ID festlegen.
3. Gemeinsamen Endpoint-Coordinator in der iOS-App ergänzen.
4. Local-Network-Berechtigung und Bonjour-Dienst im Xcode-Projekt deklarieren.
5. Bestehende `APIService`-Requests schrittweise auf den ausgewählten Endpunkt umstellen.
6. Heartbeat, Queue, Telemetrie und Admin-Diagnose um die Verbindungsart erweitern.
7. WordPress-Modul beziehungsweise lokalen Server um Discovery-Metadaten und Synchronisierung erweitern.
8. Erst nach bestandenem Ausfalltest den Local-First-Modus für ein echtes Event aktivieren.

### Testmatrix

| Szenario | Erwartetes Ergebnis |
| --- | --- |
| Event-WLAN und Internet verfügbar | Lokaler Server bleibt bevorzugt; Cloudzugang ist nur für Sync relevant |
| Internet fällt aus | Login, Matches, Aktionen, Admin und Billboard arbeiten lokal weiter |
| Internet kehrt zurück | Lokaler Betrieb bleibt stabil; Backup/Sync startet ohne Doppelversand |
| Access Point wechselt | Kurzer Statuswechsel, keine neue fachliche Request-ID, Queue läuft weiter |
| Lokaler Server startet neu | Sendungen bleiben vorgemerkt und werden anschließend genau einmal verarbeitet |
| Lokaler Server fehlt, WLAN funktioniert | Zustand `wifiOnly`, keine irreführende Onlineanzeige |
| Lokaler Netzwerkzugriff wurde verweigert | Verständlicher Adminhinweis; kein wiederholtes Berechtigungs-Popup |
| Fremder Bonjour-Dienst verwendet denselben Namen | TLS-/Identitätsprüfung lehnt ihn ab |
| Cloud und lokaler Server melden unterschiedliche Event-IDs | Kein automatischer Wechsel; Adminwarnung und Queue-Sperre bis zur Klärung |

Der Simulator eignet sich für Zustands- und Fehlerlogik, ersetzt aber nicht den Test auf echten iPads. Bonjour-Erkennung, lokale Netzwerkberechtigung, Access-Point-Wechsel und Verhalten bei abgeschaltetem WAN müssen mit mindestens zwei realen Geräten im vorgesehenen Eventnetz geprüft werden.

## Stromversorgung

Router, PoE-Switch und lokaler Server werden gemeinsam an die USV angeschlossen. Die Access Points erhalten ihren Strom über PoE und bleiben dadurch bei einem kurzen Stromausfall ebenfalls online.

Zusätzlich mitnehmen:

- Zwei längere Cat-6-Kabel für die Access Points
- Mehrere kurze Patchkabel
- Beschriftete Mehrfachsteckdosen
- Gaffer-Tape oder Kabelbrücken
- Ein Ersatznetzteil und mindestens ein Ersatznetzwerkkabel
- USB-Laufwerk für Serverbackups
- Ausdruck mit SSID, Geräte-IP und Adminzugang

## Aufbau am Veranstaltungsort

1. Router, Switch und Server zentral und geschützt aufbauen.
2. Club-LAN beziehungsweise 5G-Uplink am WAN-Port anschließen.
3. Access Points per Kabel in den relevanten Clubbereichen verteilen.
4. Lokalen Server starten und dessen feste IP prüfen.
5. iPads, Billboards und Admin-iPhone mit `MatchPlay-Event` verbinden.
6. In jedem Bereich des Clubs Verbindung, Login und Versand testen.
7. Erst danach die Geräte in den geführten Zugriff beziehungsweise Kioskmodus setzen.

## Verbindlicher Ausfalltest vor dem Event

1. Testevent anlegen und mehrere Geräte anmelden.
2. Matches und Aktionen in beide Richtungen senden.
3. Internetkabel am WAN-Port abziehen.
4. Prüfen, dass Login, Nummernprüfung, Matches, Aktionen, Admin-App und Billboards lokal weiterarbeiten.
5. Während des Ausfalls weitere Aktionen und Matches senden.
6. Internet wieder anschließen.
7. Cloud-Synchronisierung, Archive, Logs und Queues kontrollieren.
8. Lokalen Server kurz neu starten und die automatische Wiederherstellung prüfen.
9. Die WLAN-Abdeckung mit Gästen beziehungsweise mehreren Personen im Raum erneut prüfen, da Menschen das Funksignal deutlich stärker dämpfen als ein leerer Club.

## Quellen und Produktdaten

- [UniFi Dream Router 7 – EU Store](https://eu.store.ui.com/eu/en/category/all-cloud-gateways/products/udr7)
- [UniFi Dream Router 7 – technische Daten](https://techspecs.ui.com/unifi/cloud-gateways/udr7)
- [UniFi U6 Mesh – EU Store](https://eu.store.ui.com/eu/en/products/u6-mesh)
- [UniFi U6 Mesh – technische Daten](https://techspecs.ui.com/unifi/wifi/u6-mesh)
- [UniFi Lite 8 PoE – technische Daten](https://techspecs.ui.com/unifi/wifi/usw-lite-8-poe)
- [Raspberry Pi 5 – Produktseite](https://www.raspberrypi.com/products/raspberry-pi-5/)
- [Raspberry Pi SSD-Dokumentation](https://www.raspberrypi.com/documentation/accessories/ssds.html)
- [GL.iNet Spitz AX – Internet-Failover](https://www.gl-inet.com/usecases/integrating-spitz-ax-as-a-cellular-failover-network/)
- [Apple – NWPath](https://developer.apple.com/documentation/network/nwpath)
- [Apple – NWBrowser und Bonjour](https://developer.apple.com/documentation/network/nwbrowser)
- [Apple – NSLocalNetworkUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nslocalnetworkusagedescription)
