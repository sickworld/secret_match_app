# Match&Play Event-Netzwerk

Stand: 11. September 2026

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
