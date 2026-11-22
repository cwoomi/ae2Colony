# AE2 Colony – ATM10 Edition

CC:Tweaked-Programm für All the Mods 10. Es beliefert MineColonies-Anfragen automatisch aus dem AE2-Netz (Advanced Peripherals ME Bridge und Colony Integrator).

## Installation (ingame)

```
wget run https://raw.githubusercontent.com/cwoomi/ae2Colony/main/update.lua
```

Der Installer lädt alle Dateien und fragt, ob eine `startup.lua` angelegt werden soll.

## Update

Halte im Computer **Strg+T** gedrückt, um das laufende Programm zu stoppen. Danach:

```
update          # prüfen, Änderungen anzeigen, installieren
update check    # nur prüfen
update force    # neu installieren
```

Die Konfiguration (`ae2colony_config.lua`) und die Datenbanken bleiben erhalten. Alte Dateien werden als `.bak` gesichert.

Einfacher geht es direkt am Monitor: Das Programm sucht jede Stunde nach Updates. Gibt es eins, steht **UPDATE VERFÜGBAR** in der Titelzeile, und auf der Startseite erscheint der Button **[ Jetzt updaten ]**. Zweimal antippen genügt, dann wird installiert und neu gestartet. Am Terminal geht das auch mit der Taste **U**. Im Reiter „Optionen“ kannst du außerdem sofort nach Updates suchen, das Intervall ändern oder automatische Updates einschalten.

## Pocket Computer

Status der Kolonie unterwegs ansehen und das Programm fernsteuern.

- **Hardware:** Advanced Pocket Computer mit **Ender-Modem** (überall, auch dimensionsübergreifend) oder Wireless-Modem (nur in Reichweite). Der Hauptcomputer braucht ebenfalls ein Wireless- oder Ender-Modem.
- **Installation auf dem Pocket:**
  ```
  wget https://raw.githubusercontent.com/cwoomi/ae2Colony/main/ae2colony_pocket.lua startup.lua
  reboot
  ```
- **Updates:** Der Pocket sucht beim Start und danach stündlich selbst nach einer neuen Version und aktualisiert sich automatisch (oder im Reiter Ctl: „Pocket-Update suchen“).
- **Reiter:** Hom (Übersicht), Prb (Probleme + Crafts), Bau, Tdo (Zu tun), Log, Ctl (Steuerung). Wechseln per Antippen oder Pfeil links/rechts, scrollen mit Mausrad oder Pfeil hoch/runter.
- **Mehrere Kolonien:** Jeder Hauptcomputer funkt seine Kolonie. Kopfzeile antippen wechselt die Kolonie; im Reiter Ctl unter „Kolonien“ ein- und ausblenden, welche du sehen willst.
- **Steuern** (Reiter Ctl: Scan starten, Update auslösen, Auto-Crafting, Vorlieferung usw.) braucht den **Pocket-Code**. Er steht auf der Startseite und im Reiter **Optionen** des Computer-Bildschirms; auf Monitoren nur über den Knopf „Pocket-Code zeigen“ (15 Sekunden). Jede Kolonie hat ihren eigenen Code. Ansehen können alle Pockets in Reichweite, steuern nur, wer den Code kennt.

## Lager-Füllstand (MineColonies Warehouse)

Das Programm zeigt, wie voll das Lager ist (Kachel „ME-Netz“, Reiter „Kolonie“, Verlauf unter „Stats“). Dafür muss es den **Lager-Hüttenblock** lesen können:

- **Per Kabel:** Wired Modem an den Lager-Hüttenblock setzen und mit Netzwerkkabel an das Modem-Netz des Computers anschließen (Modem rechtsklicken, damit es rot leuchtet). Alternativ steht der Computer direkt am Hüttenblock.
- **Per Funk:** Ein zweiter Computer steht direkt am Lager-Hüttenblock, und **beide** Computer bekommen ein Wireless- oder Ender-Modem. Auf dem zweiten Computer:
  ```
  wget https://raw.githubusercontent.com/cwoomi/ae2Colony/main/ae2colony_lager.lua startup.lua
  reboot
  ```
  Der Sender funkt den Füllstand alle 20 Sekunden an das Hauptprogramm.

## Dateien

| Datei | Zweck |
|---|---|
| `ae2colony.lua` | Hauptprogramm |
| `update.lua` | Installer/Updater |
| `ae2colony_debug.lua` | Diagnose (`ae2colony_debug upload`) |
| `ae2colony_lager.lua` | Funk-Sender für den Lager-Füllstand (auf einem zweiten Computer) |
| `ae2colony_pocket.lua` | Programm für den Pocket Computer |

## Neue Version veröffentlichen

1. Erhöhe `scriptVersion` in `ae2colony.lua`.
2. Ergänze im Kopfkommentar eine Zeile `-- vX.Y: ...`. Sie erscheint im Updater als Änderungsliste.
3. Lade die Dateien hoch (commit und push).

GitHub liefert neue Dateien teilweise erst nach bis zu 5 Minuten aus.

## Herkunft

Basiert auf [ae2Colony von toastonrye](https://github.com/toastonrye/ae2Colony) und der Weiterentwicklung v0.5.5 von MFeltmann1 (MIT-Lizenz, siehe `LICENSE`).
