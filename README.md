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

## Dateien

| Datei | Zweck |
|---|---|
| `ae2colony.lua` | Hauptprogramm |
| `update.lua` | Installer/Updater |
| `ae2colony_debug.lua` | Diagnose (`ae2colony_debug upload`) |

## Neue Version veröffentlichen

1. Erhöhe `scriptVersion` in `ae2colony.lua`.
2. Ergänze im Kopfkommentar eine Zeile `-- vX.Y: ...`. Sie erscheint im Updater als Änderungsliste.
3. Lade die Dateien hoch (commit und push).

GitHub liefert neue Dateien teilweise erst nach bis zu 5 Minuten aus.

## Herkunft

Basiert auf [ae2Colony von toastonrye](https://github.com/toastonrye/ae2Colony) und der Weiterentwicklung v0.5.5 von MFeltmann1 (MIT-Lizenz, siehe `LICENSE`).
