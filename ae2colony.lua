-- AE2 Colony - ATM10 Edition
-- Liefert MineColonies-Anfragen automatisch aus dem AE2-Netz bzw. startet Autocrafting.
-- Ziel: All the Mods 10 (MC 1.21.1 / NeoForge)
--   Advanced Peripherals 1.21.1-0.8.2a, CC:Tweaked 1.120+, MineColonies 1.1.x, AE2 19.x
--
-- Basiert auf ae2Colony v0.5.5 (MFeltmann1).
-- v0.6: Anpassung an AP 0.8 (nbtHash-Filter, neue Request-Felder, Tag-Map, isCrafting, Cooldown)
-- v0.7: Baustellen-Vorlieferung, Kolonie-Status, Chat Box, fehlende Patterns, Config-Datei, Stufenlimit
-- v0.8: * Neues UI mit Reitern (Start, Anfragen, Bau, Buerger, Kolonie, Stats), Touch-Bedienung
--       * Baufortschritt in Prozent mit Bauphase
--       * Buerger-Probleme, Gebaeude-Ausbau, Besucher/Anwerbekosten
--       * ME-Speicher- und Energie-Warnung, haengende Anfragen, Statistik
--       * Mehrere Monitore (jeder mit eigenem Reiter), Terminal per Tastatur bedienbar
-- v0.9: * Update-System: Programm "update" laedt die neue Version von GitHub
--       * Automatische Pruefung auf neue Versionen (Hinweis auf Startseite + Chat)
-- v0.10: * Neuer Reiter "Crafts": laufende Crafts mit Fortschritt, CPU-Auslastung, haengende Crafts
--        * Vorab-Crafting: Baumaterial nur mit freien CPUs, Reserve fuer Buerger-Anfragen
--        * Besucher anwerben: Kosten per Antippen in eine Kiste legen, Chat-Hinweis
--        * Verlaufsdiagramme (24h): Lieferungen, ME-Speicher, Zufriedenheit
--        * Neuer Reiter "Optionen": Einstellungen per Touch umschalten
-- v0.11: * Update-Button: "Update verfuegbar" in der Titelzeile, Installation per Antippen
--        * Stuendliche Update-Pruefung, "Jetzt pruefen" im Reiter Optionen
-- v0.12: * Kachel-Uebersicht als Startseite auf grossen Monitoren (Kachel antippen = Reiter oeffnen)
--        * Neuer Reiter "Karte": Draufsicht der Kolonie mit Gebaeude-Umrissen und Status-Farben
-- v0.13: * Reiter "Forschung": laufende/verfuegbare Forschungen, Kosten im ME, Chat bei Abschluss
--        * Buerger-Steckbrief (antippen) mit Skills und Job-Berater fuer Arbeitslose
--        * Verteidigung: Wachen-Uebersicht, ungeschuetzte Gebaeude, Verteidigungs-Ansicht der Karte
--        * Restzeit-Schaetzung fuer Baustellen, Essens-Vorrat mit Reichweite, Fertig-Meldung
-- v0.13.1: * Fix: "more than 200 local variables" (Programm startete nicht)
--          * Fehler werden abgefangen und protokolliert (ae2colony_crash.txt), Programm laeuft weiter
--          * Autostart im Hintergrund-Tab (Terminal bleibt frei)
-- v0.14: * Reiter "Zu tun": was du selbst craften musst, welche Patterns sich lohnen
--        * Raid-Modus: Monitore zeigen Verteidigung, schnellere Scans, optional Redstone-Alarm
--        * Reiter "Log": Ereignis-Protokoll (Lieferungen, Crafts, Bau, Raids, Fehler ...)
--        * Liefer-Statistik (Wartezeiten) und Builder-Auslastung
-- v0.14.1: * Werkzeug-/Ruestungsanfragen zeigen, welche Items versucht wurden; Diagnose erweitert
-- v0.14.2: * Fix: Crafts starteten nicht ("Zutaten fehlen"), wenn ein gebrauchtes Exemplar im ME lag
-- v0.15: * Lager-Fuellstand (MineColonies Warehouse): direkt per Wired Modem oder per Funk-Sender
-- v0.16: * Performance: keine komplette ME-Liste mehr, nur gezielte Abfragen der benoetigten Items;
--          Craft-Pruefungen zwischengespeichert; Kolonie-Daten, Lager und Essen seltener abgefragt
-- v0.16.1: * Server-Schonung: Raid-Modus nur bei echtem Raid (nicht bei jedem Mob-Angriff),
--            Monitore ohne Sekunden-Countdown, Neustart-Bremse nach Fehlern, keine Doppel-Crafts
-- v0.16.2: * Crash-Schutz: Update/Neustart erst, wenn keine selbst gestarteten Crafts mehr laufen
--            (AP 0.8.2a crasht den Server, wenn ein Craft fertig wird und der Computer neu gestartet wurde)
--          * Notschalter "Auto-Crafting" (craftingEnabled), kleinere Baumaterial-Crafts
-- v0.16.3: * Anzeige: "Scan laeuft" + Dauer, Countdown alle 10 s auch auf Monitoren,
--            Monitore zeigen waehrend eines Scans den letzten vollstaendigen Stand
--          * Weniger ME-Abfragen: Bestaende zwischengespeichert (Anfragen 15 s, Bau 2 min, Rest 10 min)
-- v0.16.4: * Advanced AE Quantum Computer: CPUs entstehen erst pro Auftrag -> keine "alle CPUs belegt"-
--            Sperre mehr (automatisch erkannt, Schalter cpuCheck)
--          * Craftbarkeit ueber AE2s Liste craftbarer Items (getCraftableItems) statt isCraftable:
--            erkennt auch Rezepte, die nicht in Pattern Providern liegen (z.B. Advanced AE Quantum Crafter)
-- v0.17: * Kein Ueberliefern mehr: Vorlieferung merkt sich, was unterwegs/im Lager ist; Anfragen werden
--          nicht beliefert, wenn das Item im Lager liegt, und hoechstens 1x nach 30 min nachgeliefert;
--          Vorlieferung pausiert ab 90 % Lager-Fuellstand, Mengen pro Lieferung/Scan begrenzt
-- v0.18: * Pocket Computer: Status per Funk (ae2colony_pocket), Fernsteuerung mit Pocket-Code
-- v0.18.1: * Pocket-Code auch auf der Startseite des Computer-Bildschirms, Taste O = Optionen
-- v0.18.2: * Monitor: Knopf "Pocket-Code zeigen" im Reiter Optionen (15 s sichtbar)
-- v0.19: * Kolonie-Relais: Colony Integrator am Lager-Computer, Kontroll-PC holt die Daten per Funk
--          (Hauptcomputer kann ausserhalb der Kolonie stehen)

local scriptName = "AE2 Colony"
local scriptVersion = "0.19.0-ATM10"
local UPDATE_URL = "https://raw.githubusercontent.com/cwoomi/ae2Colony/main/"
local CONFIG_FILE = "ae2colony_config.lua"
local PROGRAM_PATH = shell and shell.getRunningProgram and shell.getRunningProgram() or "ae2colony.lua"

-- =====================================================================
-- Standard-Konfiguration (wird beim ersten Start als Datei gespeichert)
-- =====================================================================
local DEFAULT_CONFIG = [==[
-- AE2 Colony Konfiguration
-- Nach Aenderungen das Programm neu starten (Strg+T halten, dann neu starten).
return {
  -- ===== Allgemein =====
  -- Ziel-Inventar fuer Lieferungen: "@front", "@back", "@left", "@right", "@top", "@bottom"
  -- (relativ zur ME Bridge) oder ein Peripheral-Name im Netzwerk, z.B. "minecraft:chest_0".
  exportSide = "@front",
  scanInterval = 30,          -- Sekunden zwischen Scans

  -- ===== Performance (fuer grosse ME-Systeme / Kolonien) =====
  colonyInterval = 60,        -- Sekunden: Buerger und Gebaeude neu abfragen (im Raid bei jedem Scan)
  builderResourceInterval = 60, -- Sekunden: Materiallisten der Baustellen neu abfragen
  warehouseInterval = 60,     -- Sekunden: Lager-Fuellstand neu abfragen
  foodInterval = 300,         -- Sekunden: Essens-Vorrat im ME neu zaehlen
  maxStockLookups = 40,       -- hoechstens so viele ME-Abfragen pro Scan (Rest kommt im naechsten Scan dran)
  resendCooldown = 300,       -- Sekunden: gleiches Item nicht erneut an dasselbe Ziel (Doppel-Schutz)
  resendAfterMinutes = 30,    -- Anfrage nach vollstaendiger Lieferung noch offen: fruehestens dann nachliefern
  maxResends = 1,             -- so oft wird pro Anfrage hoechstens nachgeliefert
  craftingEnabled = true,     -- false = keine Crafts ueber die ME Bridge starten (nur ausliefern)
  craftMaxStack = false,      -- true = immer mindestens 64 Stueck craften
  maxCraftCandidates = 5,     -- wie viele Alternativ-Items maximal auf Craftbarkeit geprueft werden
  doLog = false,              -- true = Logdateien in "ae2Colony_logs" schreiben

  -- ===== Blacklist / Whitelist =====
  -- Items mit diesen Tags werden NICHT geliefert (z.B. kocht die Kolonie selbst) ...
  blacklistedTags = { ["c:foods"] = true },
  -- ... ausser diese Items:
  whitelistItemName = {
    ["minecraft:beef"] = true, ["minecraft:carrot"] = true,
    ["minecraft:potato"] = true, ["minecolonies:apple_pie"] = true,
  },

  -- ===== Werkzeuge & Ruestung: hoechste Stufe, die automatisch geliefert wird =====
  -- Werkzeuge: "wood", "stone", "iron", "diamond", "netherite"
  -- Ruestung:  "leather", "gold", "chain", "iron", "diamond", "netherite"
  maxToolTier = "iron",
  maxArmorTier = "iron",

  -- ===== Baustellen-Vorlieferung =====
  prestockEnabled = true,     -- Material fuer laufende Bauauftraege vorab liefern
  prestockSide = "",          -- "" = wie exportSide, sonst eigenes Ziel
  prestockCraft = true,       -- fehlendes Baumaterial automatisch craften
  prestockMaxCraft = 128,     -- maximale Menge pro Craft-Auftrag fuer Baumaterial (kleiner = kuerzere Crafts)
  prestockCooldown = 600,     -- Sekunden: Schutz gegen doppelte Vorlieferung innerhalb kurzer Zeit
  prestockMaxPerItem = 256,   -- hoechstens so viele Stueck pro Item und Lieferung
  prestockMaxPerScan = 1024,  -- hoechstens so viele Stueck Baumaterial pro Scan insgesamt
  warehouseStopPercent = 90,  -- Vorlieferung pausieren, wenn das Lager so voll ist (0 = nie)
  -- Vorab-Crafting: fehlendes Baumaterial aller angenommenen Bauauftraege wird gecraftet,
  -- aber nur, solange genug Crafting-CPUs frei sind (Buerger-Anfragen haben Vorrang).
  craftReserveCpus = 1,       -- so viele CPUs bleiben fuer Buerger-Anfragen frei
  -- false = freie CPUs nicht pruefen. Wird automatisch abgeschaltet, wenn CPUs dynamisch entstehen
  -- (Advanced AE Quantum Computer: legt pro Auftrag eine eigene CPU an, im Leerlauf keine sichtbar).
  cpuCheck = true,
  prestockMaxCraftsPerScan = 3, -- hoechstens so viele neue Baumaterial-Crafts pro Scan
  craftStuckMinutes = 15,     -- Crafts, die laenger laufen, gelten als "haengend" (0 = aus)

  -- ===== Anzeige =====
  showColonyStatus = true,
  dashboardMinWidth = 60,     -- ab dieser Breite zeigt die Startseite Kacheln statt einer Liste (0 = nie)
  mapShowCitizens = true,     -- Buerger als Punkte auf der Karte
  monitorScale = 0.5,         -- Textgroesse der Monitore (0.5 - 5)
  -- Start-Reiter je Monitor, z.B. { ["monitor_0"] = "start", ["monitor_1"] = "anfragen" }
  -- Reiter: "start", "todo", "anfragen", "bau", "crafts", "buerger", "kolonie", "forschung", "karte", "stats", "log", "optionen"
  -- Ohne Eintrag: 1. Monitor = start, 2. Monitor = anfragen
  monitorTabs = {},

  -- ===== Warnungen =====
  storageWarnPercent = 90,    -- ME-Speicher: Warnung ab diesem Fuellstand (0 = aus)
  warehouseWarnPercent = 90,  -- Lager (Warehouse): Warnung ab diesem Fuellstand (0 = aus)
  -- Lager-Huettenblock als Peripheral (Wired Modem / direkt angrenzend). "" = automatisch suchen.
  -- Ohne Kabel: Programm "ae2colony_lager" auf einem Computer am Lager, beide mit Wireless/Ender Modem.
  warehousePeripheral = "",
  -- Kolonie-Relais: Ist kein Colony Integrator angeschlossen, holt das Programm die Kolonie-Daten
  -- per Funk vom Lager-Computer (ae2colony_lager mit Colony Integrator). 0 = automatisch suchen,
  -- sonst die Computer-ID des Lager-Computers (bei mehreren Kolonien).
  colonyRelayId = 0,
  energyWarnPercent = 10,     -- ME-Energie: Warnung unter diesem Stand (0 = aus)
  oldRequestMinutes = 10,     -- Anfragen, die laenger offen sind, gelten als "haengend" (0 = aus)
  citizenHappinessBelow = 5,  -- Buerger unter dieser Zufriedenheit gelten als unzufrieden
  citizenHungerBelow = 4,     -- Buerger unter dieser Saettigung gelten als hungrig (max 20)
  foodWarnHours = 6,          -- Warnung, wenn das Essen im ME voraussichtlich kuerzer reicht (0 = aus)
  researchInterval = 300,     -- Sekunden zwischen zwei Abfragen der Forschung

  -- ===== Chat-Benachrichtigungen (nur wenn eine Chat Box angeschlossen ist) =====
  chatEnabled = true,
  chatPlayer = "",            -- "" = alle Spieler in Reichweite, sonst Spielername
  chatRange = -1,             -- -1 = Standard-Reichweite der Chat Box
  chatPrefix = "AE2 Colony",
  chatOnMissingPattern = true,  -- fehlendes Pattern (einmal pro Item und Programmstart)
  chatOnAttack = true,          -- Kolonie wird angegriffen / Raid
  chatOnDeath = true,           -- neues Grab = Buerger gestorben
  chatOnOffline = true,         -- ME-Netz offline
  chatHappinessBelow = 5,       -- Warnung wenn Kolonie-Zufriedenheit darunter faellt (0 = aus)
  chatOnStorage = true,         -- ME-Speicher fast voll / Energie niedrig
  chatOnOldRequest = true,      -- Anfrage haengt laenger als oldRequestMinutes
  chatOnDisease = true,         -- Buerger ist krank geworden
  chatOnStuckCraft = true,      -- Craft haengt / konnte nicht starten
  chatOnVisitor = true,         -- neuer Besucher, dessen Anwerbekosten im ME liegen
  chatOnBuildDone = true,       -- Bauauftrag fertig
  chatOnResearch = true,        -- Forschung abgeschlossen
  chatOnFood = true,            -- Essens-Vorrat reicht nicht mehr lange

  -- ===== Dateien & Statistik =====
  trackMissingPatterns = true,
  missingPatternFile = "ae2colony_missing.db",
  missingPatternShowTop = 5,
  statsFile = "ae2colony_stats.db",
  statsShowTop = 10,
  buildsFile = "ae2colony_builds.db",
  historyFile = "ae2colony_history.db",

  -- ===== Besucher =====
  -- Kiste fuer Anwerbekosten (wie exportSide, z.B. "@top"). "" = Funktion aus.
  -- Im Reiter "Kolonie" einen Besucher zweimal antippen -> Kosten werden in diese Kiste gelegt.
  recruitSide = "",

  -- ===== Raid-Modus =====
  raidSwitchMonitors = true,  -- bei Raid/Angriff alle Monitore auf die Verteidigungs-Karte schalten
  raidScanInterval = 10,      -- Sekunden zwischen Scans waehrend eines Raids
  raidRedstoneSide = "",      -- Redstone-Signal waehrend eines Raids, z.B. "back" ("" = aus)

  -- ===== Pocket Computer =====
  pocketEnabled = true,       -- Status per Funk an Pocket Computer senden (Wireless/Ender Modem noetig)
  pocketCode = "",            -- Code fuer die Fernsteuerung; "" = beim Start automatisch erzeugen

  -- ===== Optionen-Reiter =====
  lockSettings = false,       -- true = Optionen nur am Computer-Terminal aenderbar, nicht am Monitor

  -- ===== Updates =====
  updateCheckHours = 1,       -- alle X Stunden nach neuer Version suchen (0 = aus)
  autoUpdate = false,         -- true = neue Version automatisch installieren und neu starten
  updateUrl = "",             -- "" = Standard-Adresse, sonst eigene Download-Adresse (endet mit /)
}
]==]

-- =====================================================================
-- Konfiguration laden
-- =====================================================================
local cfg
do
  local defaults = assert(load(DEFAULT_CONFIG, "default_config", "t", {}))()
  if not fs.exists(CONFIG_FILE) then
    local f = fs.open(CONFIG_FILE, "w"); f.write(DEFAULT_CONFIG); f.close()
    print("Konfiguration erstellt: "..CONFIG_FILE)
  end
  local user = {}
  local fn, err = loadfile(CONFIG_FILE, "t", {})
  if fn then
    local ok, res = pcall(fn)
    if ok and type(res) == "table" then user = res
    else print("WARNUNG: "..CONFIG_FILE.." fehlerhaft ("..tostring(res).."), nutze Standardwerte") end
  else
    print("WARNUNG: "..CONFIG_FILE.." nicht lesbar ("..tostring(err).."), nutze Standardwerte")
  end
  cfg = {}
  for k, v in pairs(defaults) do
    if user[k] ~= nil then cfg[k] = user[k] else cfg[k] = v end
  end
  for k in pairs(user) do
    if defaults[k] == nil then print("WARNUNG: unbekannte Option '"..tostring(k).."' in "..CONFIG_FILE) end
  end
  if cfg.prestockSide == "" then cfg.prestockSide = cfg.exportSide end
end

local skipStates = { COMPLETED=true, CANCELLED=true, RECEIVED=true, OVERRULED=true }
local logFolder, maxLogs, maxLogSize = "ae2Colony_logs", 10, 200*1024

local apVersionText = "unknown"
if advancedperipherals and advancedperipherals.getAPVersion then
  local ok, v = pcall(advancedperipherals.getAPVersion)
  if ok and v then apVersionText = tostring(v) end
end
if not apVersionText:find("0.8.", 1, true) then
  print("WARNUNG: Getestet mit Advanced Peripherals 0.8.x (ATM10). Gefunden: "..apVersionText)
end

-- =====================================================================
-- Hilfsfunktionen
-- =====================================================================
if cfg.doLog and not fs.exists(logFolder) then fs.makeDir(logFolder) end
local logLine
do -- log
local function nextLogFile()
  local nums = {}
  for _, f in ipairs(fs.list(logFolder)) do local n = f:match("^log_(%d+)%.log$"); if n then nums[#nums+1] = tonumber(n) end end
  table.sort(nums); return string.format("%s/log_%03d.log", logFolder, (nums[#nums] or 0)+1)
end
function logLine(msg)
  if not cfg.doLog then return end
  local files = fs.list(logFolder); table.sort(files)
  local path = #files > 0 and (logFolder.."/"..files[#files]) or nextLogFile()
  if fs.exists(path) and fs.getSize(path) >= maxLogSize then path = nextLogFile() end
  local f = fs.open(path, "a")
  if f then f.writeLine("["..os.date("%H:%M:%S", os.epoch("local")/1000).."] "..tostring(msg)); f.close() end
end
end -- log
local function cleanupOldLogs()
  if not cfg.doLog then return end
  local files = {}
  for _, f in ipairs(fs.list(logFolder)) do if f:match("^log_%d+%.log$") then files[#files+1] = f end end
  table.sort(files); while #files > maxLogs do fs.delete(logFolder.."/"..table.remove(files, 1)) end
end
local function dump(v)
  if v == nil then return "nil" end
  local ok, s = pcall(textutils.serialize, v); return ok and s or tostring(v)
end
local function now() return os.epoch("utc") end

local function loadDb(path)
  if not fs.exists(path) then return {} end
  local f = fs.open(path, "r"); local s = f.readAll(); f.close()
  local t = textutils.unserialize(s or ""); return type(t) == "table" and t or {}
end
local function saveDb(path, t)
  local f = fs.open(path, "w"); f.write(textutils.serialize(t)); f.close()
end

-- CC-Bildschirme koennen kein UTF-8: Umlaute umschreiben, Rest entfernen
local asc
do -- ascii
local translit = {["\195\164"]="ae", ["\195\182"]="oe", ["\195\188"]="ue", ["\195\132"]="Ae",
  ["\195\150"]="Oe", ["\195\156"]="Ue", ["\195\159"]="ss"}
function asc(s)
  s = tostring(s or "")
  s = s:gsub("[\192-\223][\128-\191]", function(c) return translit[c] or "?" end)
  return (s:gsub("[\128-\255]", ""))
end
end -- ascii
-- "com.minecolonies.building.builder" / "minecolonies:builder" -> "Builder"
local function pretty(s)
  s = asc(s)
  if s:find("^[%w_%.:]+$") and (s:find("%.") or s:find(":")) then
    s = s:match("([%w_]+)$") or s
    s = s:gsub("_", " "):gsub("^%l", string.upper)
  end
  return s
end
local function shortName(name) return asc((tostring(name):gsub("^minecraft:", ""))) end

-- AP 0.8: Items haben "nbt" = Fingerprint-Hash der Components (nil wenn keine Components).
-- In Filtern muss dieser Hash als "nbtHash" uebergeben werden. nbtHash="" = exakt ohne Components.
local function itemHash(it)
  if it and type(it.nbt) == "string" and it.nbt ~= "" then return it.nbt end
  return nil
end
local function itemLabel(it)
  if not it then return "?" end
  return asc(it.displayName or shortName(it.name))
end
local function hasBlacklistedTag(it)
  if not it or type(it.tags) ~= "table" then return false end
  for k, v in pairs(it.tags) do
    local tag = type(k) == "string" and k or (type(v) == "string" and v or nil)
    if tag and cfg.blacklistedTags[(tag:gsub("^#", ""))] then return true end
  end
  return false
end
local function formatPos(t)
  if type(t) == "table" then
    if t.x then return string.format("%d,%d,%d", t.x, t.y or 0, t.z or 0) end
    return dump(t)
  end
  return tostring(t or "?")
end
local function fmtAge(ms)
  local m = math.floor(ms/60000)
  if m < 60 then return m.."m" end
  return math.floor(m/60).."h"..(m%60).."m"
end

-- =====================================================================
-- Zustand
-- =====================================================================
local S = {}                 -- Ergebnis des aktuellen Scans (fuer die Anzeige)
local function newState()
  return {
    requests = {}, builds = {}, citizens = {}, citizenCount = 0,
    buildingsWorking = {}, buildingsUpgrade = {}, visitors = {}, mapBuildings = {}, citizenPos = {},
    allCitizens = {}, guards = {}, food = nil,
    alerts = {}, errors = {}, colony = {}, me = {}, online = false, meStatus = "...",
    cpus = nil, freeCpus = nil, cpuJobs = nil, warehouse = nil,
  }
end
S = newState()
local function addError(msg) logLine("[ERROR] "..msg); S.errors[#S.errors+1] = asc(msg) end
local function addAlert(msg) logLine("[ALARM] "..msg); S.alerts[#S.alerts+1] = asc(msg) end

local missingDb  = cfg.trackMissingPatterns and loadDb(cfg.missingPatternFile) or {}
local statsDb    = loadDb(cfg.statsFile)
local buildDb    = loadDb(cfg.buildsFile)
local historyDb  = loadDb(cfg.historyFile)
local missingCounted, missingNotified = {}, {}
local sentAt     = {}   -- request id -> Zeitpunkt der letzten Lieferung
local firstSeen  = {}   -- request id -> Zeitpunkt, an dem die Anfrage zuerst gesehen wurde
local delivered  = {}   -- "zielPos|item|hash" -> {t=Zeitpunkt, n=Menge}
local exportBuffer = {}
local pendingBuild = {}   -- "builder|item|hash" -> {g0 = Bedarf bei Lieferung, n = unterwegs, t = Zeit}
local sentAmount = {}     -- request id -> bisher geliefert
local resendCount = {}    -- request id -> wie oft nachgeliefert
local stockCache = {}   -- item -> {t, list}: zuletzt gelesener ME-Bestand (jede Abfrage geht das ganze ME durch)
local updateWaiting = false   -- Update steht an: keine neuen Crafts, installieren sobald keine mehr laufen

-- =====================================================================
-- Chat (optional)
-- =====================================================================
-- Ereignis-Log
local logEvent, eventLog, saveEvents
do -- ereignisse
local EVENT_FILE = "ae2colony_events.db"
local dirty = false
eventLog = loadDb(EVENT_FILE)
local function kindOf(text)
  local l = text:lower()
  if l:find("vorbei") or l:find("fertig") or l:find("abgeschlossen") then
    if not l:find("nicht") then return "gut" end
  end
  if l:find("raid") or l:find("angegriffen") or l:find("gestorben") or l:find("fehler") or l:find("nicht gestartet")
    or l:find("haengt") or l:find("knapp") or l:find("offline") or l:find("krank") then return "warn" end
  if l:find("fertig") or l:find("abgeschlossen") or l:find("vorbei") then return "gut" end
  if l:find("update") then return "update" end
  return "info"
end
function logEvent(text, kind)
  text = asc(text)
  table.insert(eventLog, 1, {t=os.epoch("utc"), k=kind or kindOf(text), x=text})
  while #eventLog > 150 do table.remove(eventLog) end
  dirty = true
end
function saveEvents()
  if dirty then saveDb(EVENT_FILE, eventLog); dirty = false end
end
end -- ereignisse

local findChatBox, chat, flushChat
do -- chat
local chatQueue, chatBox = {}, nil
function findChatBox()
  if not cfg.chatEnabled then chatBox = nil; return end
  if chatBox then
    local ok, name = pcall(peripheral.getName, chatBox)
    if ok and name and peripheral.isPresent(name) then return end
  end
  chatBox = peripheral.find("chat_box")
end
function chat(msg)
  logEvent(msg)
  if not cfg.chatEnabled then return end
  logLine("[CHAT] "..msg)
  chatQueue[#chatQueue+1] = {text=asc(msg), tries=0}
end
function flushChat()
  if #chatQueue == 0 then return end
  if not chatBox then
    if #chatQueue > 20 then table.remove(chatQueue, 1) end
    return
  end
  local m = chatQueue[1]
  local opts = {prefix=cfg.chatPrefix}
  if cfg.chatPlayer ~= "" then opts.player = cfg.chatPlayer end
  if cfg.chatRange and cfg.chatRange >= 0 then opts.range = cfg.chatRange end
  local ok, res = pcall(chatBox.sendMessage, m.text, opts)
  m.tries = m.tries + 1
  if (ok and res == true) or m.tries >= 5 then table.remove(chatQueue, 1) end
end
end -- chat
-- Alarm nur beim Wechsel von "aus" nach "an" melden
local alertActive = {}
local function alert(key, active, msg)
  if active and not alertActive[key] then chat(msg) end
  alertActive[key] = active and true or nil
end

-- =====================================================================
-- Statistik & fehlende Patterns
-- =====================================================================
local function statsToday()
  local day = os.date("%Y-%m-%d")
  if statsDb.day ~= day then statsDb.day = day; statsDb.sent = 0; statsDb.crafts = 0; statsDb.reqN = 0; statsDb.reqSum = 0 end
  statsDb.items = statsDb.items or {}
  return statsDb
end
-- Verlauf: ein Eintrag pro Stunde (Ortszeit), die letzten 48 Stunden
local hourKey, histSample, statDelivered, statCraft
do -- verlauf
function hourKey() return math.floor(os.epoch("local") / 3600000) end
local function histBucket()
  local k = hourKey()
  historyDb.h = historyDb.h or {}
  local b = historyDb.h[k]
  if not b then
    b = {sent=0, crafts=0}
    historyDb.h[k] = b
    for old in pairs(historyDb.h) do if old < k - 47 then historyDb.h[old] = nil end end
  end
  return b
end
function histSample(field, v)
  if type(v) ~= "number" then return end
  local b = histBucket()
  b[field] = v
end

function statDelivered(name, label, n)
  local s = statsToday()
  local hb = histBucket(); hb.sent = hb.sent + n
  s.sent = s.sent + n
  local e = s.items[name] or {n=0}
  e.n = e.n + n; e.label = label or e.label
  s.items[name] = e
end
function statCraft() local s = statsToday(); s.crafts = s.crafts + 1; local hb = histBucket(); hb.crafts = hb.crafts + 1 end
end -- verlauf

local function recordMissing(name, display, countKey, silent)
  if cfg.trackMissingPatterns and not missingCounted[countKey] then
    local e = missingDb[name] or {count=0}
    missingCounted[countKey] = true
    e.count = e.count + 1; e.last = now(); e.display = display or e.display
    missingDb[name] = e; saveDb(cfg.missingPatternFile, missingDb)
  end
  if not silent and cfg.chatOnMissingPattern and not missingNotified[name] then
    missingNotified[name] = true
    chat("Kein Pattern: "..tostring(display or shortName(name)))
  end
end
local function clearMissing(name)
  if missingDb[name] then missingDb[name] = nil; saveDb(cfg.missingPatternFile, missingDb) end
end

-- =====================================================================
-- Peripherals
-- =====================================================================
-- Kolonie-Relais: Stellvertreter-Objekt, das jeden Aufruf per Funk an den Lager-Computer schickt
local function relayColony(id)
  local seq, downUntil, warnedS = 0, 0, nil
  local function down()
    if warnedS ~= S then
      warnedS = S
      addError("Kolonie-Relais (Computer "..id..") nicht erreichbar - Lager-Computer an? Chunk geladen?")
    end
    error("Kolonie-Relais nicht erreichbar", 0)
  end
  local function remote(m, ...)
    if os.epoch("utc") < downUntil then down() end
    for _ = 1, 2 do
      seq = seq + 1
      local my = seq
      rednet.send(id, {id=my, m=m, a=table.pack(...)}, "ae2colony_colony")
      local deadline = os.epoch("utc") + 4000
      while true do
        local left = (deadline - os.epoch("utc")) / 1000
        if left <= 0 then break end
        local from, r = rednet.receive("ae2colony_colony_r", left)
        if from == id and type(r) == "table" and r.id == my then
          if not r.ok then error(tostring(r.err), 0) end
          return table.unpack(r.r or {}, 1, r.r and r.r.n or 0)
        end
      end
    end
    downUntil = os.epoch("utc") + 20000
    down()
  end
  return setmetatable({}, {__index=function(t, k)
    local f = function(...) return remote(k, ...) end
    t[k] = f
    return f
  end})
end
local function setupPeripherals()
  local b = peripheral.find("me_bridge") or error("me_bridge nicht gefunden")
  local c = peripheral.find("colony_integrator")
  if not c then
    if not rednet.isOpen() then error("colony_integrator nicht gefunden (oder Funk-Modem fuer das Kolonie-Relais)") end
    local id = tonumber(cfg.colonyRelayId) or 0
    while id == 0 do
      print("Kein Colony Integrator angeschlossen - suche Kolonie-Relais (ae2colony_lager) per Funk ...")
      local ids = {rednet.lookup("ae2colony_colony")}
      table.sort(ids)
      if #ids > 1 then print("Mehrere Relais gefunden: "..table.concat(ids, ", ").." - nehme "..ids[1].." (Config: colonyRelayId)") end
      id = ids[1] or 0
      if id == 0 then sleep(10) end
    end
    print("Kolonie-Relais: Computer "..id)
    c = relayColony(id)
    while not pcall(c.isInColony) do
      print("Kolonie-Relais "..id.." antwortet nicht - neuer Versuch in 20 s")
      sleep(20)
    end
  end
  local ok, inColony = pcall(c.isInColony)
  if not ok or not inColony then error("colony_integrator steht nicht in einer Kolonie") end
  return b, c
end
local function bridgeStatus(b)
  local a, x = pcall(b.isConnected); local c, y = pcall(b.isOnline)
  local okAll = a and x == true and c and y == true
  local s = not (a and c) and "BRIDGE FEHLER" or (not x and "KEIN NETZ" or (not y and "NETZ OFFLINE" or "AE2 ONLINE"))
  return okAll, s
end
local function call(p, fn, ...)
  if not p or not p[fn] then return nil end
  local ok, v = pcall(p[fn], ...)
  if ok then return v end
  logLine("[CALL] "..fn..": "..tostring(v))
  return nil
end

-- =====================================================================
-- Kolonie-, ME-, Buerger-, Gebaeude-Daten
-- =====================================================================
local readColony, readBuildings, targetName
do -- kolonie
local lastGraves = nil
local buildingNames = {}  -- "x,y,z" -> Name
function readColony(c)
  local col = {
    happy = call(c, "getHappiness"), cit = call(c, "getCitizenCount"), lim = call(c, "getCitizenLimit"),
    graves = call(c, "getGraveCount"), sites = call(c, "amountOfConstructionSites"),
    attack = call(c, "isUnderAttack") == true, raid = call(c, "isUnderRaid") == true,
    name = call(c, "getColonyName"),
  }
  S.colony = col
  if col.raid then addAlert("RAID auf die Kolonie!") elseif col.attack then addAlert("Die Kolonie wird angegriffen!") end
  if cfg.chatOnAttack then
    alert("raid", col.raid, "RAID! Die Kolonie wird ueberfallen!")
    alert("attack", col.attack and not col.raid, "Die Kolonie wird angegriffen!")
  end
  if col.graves then
    if lastGraves and col.graves > lastGraves then
      local d = col.graves - lastGraves
      addAlert(d == 1 and "Ein Buerger ist gestorben" or (d.." Buerger sind gestorben"))
      if cfg.chatOnDeath then chat(d == 1 and "Ein Buerger ist gestorben (neues Grab)." or (d.." Buerger sind gestorben.")) end
    end
    lastGraves = col.graves
  end
  if col.happy and cfg.chatHappinessBelow > 0 then
    alert("happy", col.happy < cfg.chatHappinessBelow, string.format("Zufriedenheit niedrig: %.1f", col.happy))
  end
end

function readBuildings(c)
  buildingNames = {}
  local list = call(c, "getBuildings")
  if type(list) ~= "table" then return end
  for _, b in ipairs(list) do
    local name = pretty(b.displayName or b.type or "?")
    buildingNames[formatPos(b.pos)] = name
    local lvl, maxLvl = tonumber(b.level) or 0, tonumber(b.maxLevel) or 0
    if type(b.pos) == "table" and b.pos.x then
      local st = type(b.structure) == "table" and b.structure or {}
      local a, c = st.cornerA, st.cornerB
      local x1, z1, x2, z2 = b.pos.x, b.pos.z, b.pos.x, b.pos.z
      if type(a) == "table" and type(c) == "table" and a.x and c.x then
        x1, x2 = math.min(a.x, c.x), math.max(a.x, c.x)
        z1, z2 = math.min(a.z, c.z), math.max(a.z, c.z)
      end
      S.mapBuildings[#S.mapBuildings+1] = {key=formatPos(b.pos), name=name, type=tostring(b.type or ""),
        x1=x1, z1=z1, x2=x2, z2=z2, level=lvl, maxLevel=maxLvl, working=b.isWorking == true,
        built=b.built ~= false and lvl > 0, residents=type(b.citizens) == "table" and #b.citizens or 0,
        guarded=b.guarded == true}
    end
    if b.isWorking then
      S.buildingsWorking[#S.buildingsWorking+1] = {name=name, level=lvl}
    elseif lvl < maxLvl then
      S.buildingsUpgrade[#S.buildingsUpgrade+1] = {name=name, level=lvl, maxLevel=maxLvl, built=b.built ~= false}
    end
  end
  table.sort(S.buildingsUpgrade, function(a, b) if a.level ~= b.level then return a.level < b.level end return a.name < b.name end)
end
function targetName(pos)
  local p = formatPos(pos)
  return buildingNames[p] or p
end
end -- kolonie

-- Jobs: Haupt- und Nebenskill (MineColonies), Gebaeude-Typ und Anzeigename
local jobName, skillDe, jobScore, jobAdvice, skillText, readCitizens
do -- buerger

local jobInfo = {
  builder={"Adaptability", "Athletics", "builder", "Builder"},
  deliveryman={"Agility", "Adaptability", "deliveryman", "Kurier"},
  miner={"Strength", "Stamina", "miner", "Minenarbeiter"},
  lumberjack={"Strength", "Focus", "lumberjack", "Holzfaeller"},
  farmer={"Stamina", "Athletics", "farmer", "Bauer"},
  fisherman={"Focus", "Agility", "fisherman", "Fischer"},
  baker={"Knowledge", "Dexterity", "bakery", "Baecker"},
  cook={"Adaptability", "Knowledge", "cook", "Koch"},
  smelter={"Athletics", "Strength", "smeltery", "Schmelzer"},
  stonemason={"Creativity", "Dexterity", "stonemason", "Steinmetz"},
  sawmill={"Knowledge", "Dexterity", "sawmill", "Saegewerk"},
  blacksmith={"Strength", "Focus", "blacksmith", "Schmied"},
  shepherd={"Focus", "Strength", "shepherd", "Schaefer"},
  cowboy={"Athletics", "Stamina", "cowboy", "Kuhhirte"},
  swineherder={"Strength", "Athletics", "swineherder", "Schweinehirte"},
  chickenherder={"Adaptability", "Agility", "chickenherder", "Huehnerhirte"},
  rabbitherder={"Agility", "Athletics", "rabbithutch", "Kaninchenhirte"},
  composter={"Stamina", "Athletics", "composter", "Kompostierer"},
  florist={"Dexterity", "Agility", "florist", "Florist"},
  crusher={"Stamina", "Strength", "crusher", "Brecher"},
  sifter={"Focus", "Strength", "sifter", "Sieber"},
  enchanter={"Mana", "Knowledge", "enchanter", "Verzauberer"},
  glassblower={"Creativity", "Focus", "glassblower", "Glasblaeser"},
  dyer={"Creativity", "Dexterity", "dyer", "Faerber"},
  fletcher={"Dexterity", "Creativity", "fletcher", "Pfeilmacher"},
  mechanic={"Knowledge", "Agility", "mechanic", "Mechaniker"},
  planter={"Agility", "Dexterity", "plantation", "Plantage"},
  concretemixer={"Stamina", "Dexterity", "concretemixer", "Betonmischer"},
  beekeeper={"Dexterity", "Adaptability", "beekeeper", "Imker"},
  healer={"Mana", "Knowledge", "hospital", "Heiler"},
  researcher={"Knowledge", "Mana", "university", "Forscher"},
  teacher={"Knowledge", "Mana", "school", "Lehrer"},
  alchemist={"Dexterity", "Mana", "alchemist", "Alchemist"},
  netherworker={"Adaptability", "Strength", "netherworker", "Netherarbeiter"},
  knight={"Adaptability", "Stamina", "guardtower", "Ritter"},
  ranger={"Agility", "Adaptability", "guardtower", "Bogenschuetze"},
  druid={"Mana", "Focus", "guardtower", "Druide"},
}
skillDe = {Athletics="Athletik", Dexterity="Geschick", Strength="Staerke", Agility="Beweglichk.", Stamina="Ausdauer",
  Mana="Mana", Adaptability="Anpassung", Focus="Fokus", Creativity="Kreativitaet", Knowledge="Wissen", Intelligence="Intelligenz"}
function jobName(id) local j = jobInfo[id]; return j and j[4] or pretty(id) end
function jobScore(c, id)
  local j = jobInfo[id]; if not j then return nil end
  return 2 * (c.skills[j[1]] or 0) + (c.skills[j[2]] or 0)
end
-- beste Jobs fuer einen Buerger; bevorzugt Jobs, deren Gebaeude es in der Kolonie gibt
function jobAdvice(c, n)
  local present = {}
  for _, b in ipairs(S.mapBuildings) do present[b.type:lower():gsub("^.*[:/]", "")] = true end
  if present.barracks or present.barrackstower then present.guardtower = true end
  local list, anyPresent = {}, next(present) ~= nil
  for id, j in pairs(jobInfo) do
    if not anyPresent or present[j[3]] then list[#list+1] = {id=id, score=jobScore(c, id)} end
  end
  table.sort(list, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.id < b.id end)
  local out = {}
  for i = 1, math.min(n or 2, #list) do out[i] = list[i] end
  return out
end
function skillText(c, id)
  local j = jobInfo[id]; if not j then return "" end
  return (skillDe[j[1]] or j[1]).." "..(c.skills[j[1]] or 0)..", "..(skillDe[j[2]] or j[2]).." "..(c.skills[j[2]] or 0)
end

local diseaseSeen = {}
function readCitizens(c)
  local list = call(c, "getCitizens")
  if type(list) ~= "table" then return end
  S.citizenCount = #list
  local active = {}
  for _, ct in ipairs(list) do
    if type(ct.pos) == "table" and ct.pos.x then S.citizenPos[#S.citizenPos+1] = {x=ct.pos.x, z=ct.pos.z} end
    local issues, severity = {}, 0
    local function add(text, sev) issues[#issues+1] = text; if sev > severity then severity = sev end end
    if ct.disease then
      local dn = pretty(ct.disease)
      add("krank ("..dn..")", 3)
      local key = tostring(ct.id)..":"..tostring(ct.disease); active[key] = true
      if cfg.chatOnDisease and not diseaseSeen[key] then chat(asc(ct.name).." ist krank: "..dn) end
      diseaseSeen[key] = true
    end
    if ct.health and ct.maxHealth and ct.maxHealth > 0 and ct.health < ct.maxHealth*0.5 then
      add(string.format("verletzt %d/%d", math.floor(ct.health), math.floor(ct.maxHealth)), 3)
    end
    if ct.saturation and ct.saturation < cfg.citizenHungerBelow then add("hungrig", 2) end
    if ct.needsBetterFood then add("braucht besseres Essen", 1) end
    if ct.isMourning then add("trauert", 1) end
    if not ct.isChild then
      if ct.homeBuilding == nil then add("kein Zuhause", 2) end
      if ct.workBuilding == nil then add("arbeitslos", 1) end
    end
    if ct.happiness and ct.happiness < cfg.citizenHappinessBelow then add(string.format("unzufrieden %.1f", ct.happiness), 1) end
    local jobId = ct.workBuilding and ct.workBuilding.job and tostring(ct.workBuilding.job):lower():gsub("^.*:", "") or nil
    local job = jobId and jobName(jobId) or (ct.isChild and "Kind" or "-")
    if #issues > 0 then
      S.citizens[#S.citizens+1] = {name=asc(ct.name), job=job, issues=table.concat(issues, ", "), severity=severity}
    end
    local skills = {}
    if type(ct.skills) == "table" then
      for k, sv in pairs(ct.skills) do skills[tostring(k)] = type(sv) == "table" and tonumber(sv.level) or tonumber(sv) or 0 end
    end
    local c = {id=ct.id, name=asc(ct.name), jobId=jobId, job=job, isChild=ct.isChild == true,
      happy=tonumber(ct.happiness), sat=tonumber(ct.saturation), health=tonumber(ct.health), maxHealth=tonumber(ct.maxHealth),
      armor=tonumber(ct.armor), skills=skills, pos=ct.pos, state=ct.state and asc(ct.state) or nil,
      home=ct.homeBuilding and pretty(ct.homeBuilding.displayName or ct.homeBuilding.type or "?") or nil,
      work=ct.workBuilding and pretty(ct.workBuilding.displayName or ct.workBuilding.type or "?") or nil,
      issues=table.concat(issues, ", "), severity=severity}
    S.allCitizens[#S.allCitizens+1] = c
    if jobId == "knight" or jobId == "ranger" or jobId == "druid" then S.guards[#S.guards+1] = c end
  end
  for k in pairs(diseaseSeen) do if not active[k] then diseaseSeen[k] = nil end end
  table.sort(S.citizens, function(a, b) if a.severity ~= b.severity then return a.severity > b.severity end return a.name < b.name end)
end
end -- buerger

local readVisitors
do -- besucher
local visitorNotified = {}
function readVisitors(list, byName)
  if type(list) ~= "table" then return end
  local present = {}
  for _, v in ipairs(list) do
    local cost = v.recruitCost
    local have = 0
    if cost and cost.name and byName then
      for _, s in ipairs(byName[cost.name] or {}) do have = have + (tonumber(s.count) or 0) end
    end
    local e = {name=asc(v.name), costName=cost and itemLabel(cost) or "?",
      costCount=cost and tonumber(cost.count) or 0, have=have,
      costItem=cost and cost.name, costHash=cost and itemHash(cost)}
    e.enough = byName ~= nil and e.costCount > 0 and have >= e.costCount
    S.visitors[#S.visitors+1] = e
    present[e.name] = true
    if e.enough and cfg.chatOnVisitor and not visitorNotified[e.name] then
      visitorNotified[e.name] = true
      chat("Besucher "..e.name.." kann angeworben werden ("..e.costCount.."x "..e.costName.." im ME)")
    end
  end
  for name in pairs(visitorNotified) do if not present[name] then visitorNotified[name] = nil end end
end
end -- besucher

-- Essen im ME zaehlen (Tag c:foods bzw. Whitelist)
local readFood
do -- essen
function readFood(b)
  -- Tag-Filter: AP prueft serverseitig und wandelt nur Lebensmittel um
  local ok, list = pcall(b.getItems, {name="#c:foods"})
  if not ok or type(list) ~= "table" then return end
  local n = 0
  for _, it in ipairs(list) do n = n + (tonumber(it.count) or 0) end
  histSample("food", n)
  -- Verbrauch aus dem Verlauf der letzten 6 Stunden
  local k, rate = hourKey(), nil
  local h = historyDb.h or {}
  for back = 6, 1, -1 do
    local b = h[k - back]
    if b and b.food then
      if b.food > n then rate = (b.food - n) / back end
      break
    end
  end
  local eta = rate and rate > 0 and (n / rate) or nil   -- Stunden
  local satSum, satN = 0, 0
  for _, c in ipairs(S.allCitizens) do if c.sat then satSum = satSum + c.sat; satN = satN + 1 end end
  S.food = {count=n, rate=rate, etaH=eta, avgSat=satN > 0 and satSum / satN or nil}
  local low = cfg.foodWarnHours > 0 and eta and eta < cfg.foodWarnHours
  if low then addAlert(string.format("Essen im ME reicht nur noch ca. %s", fmtAge(eta * 3600000))) end
  if cfg.chatOnFood then alert("food", low, string.format("Essen wird knapp: %d im ME, reicht ca. %s", n, fmtAge((eta or 0) * 3600000))) end
end
end -- essen

-- Lager (MineColonies Warehouse): kombiniertes Inventar aller Racks
local readWarehouse, lagerMessage, warehouseCount
do -- lager
local remote, remoteT = nil, nil
local function isWarehouse(name)
  if name:lower():find("warehouse") then return true end
  local types = {peripheral.getType(name)}
  for _, t in ipairs(types) do if tostring(t):lower():find("warehouse") then return true end end
  return false
end
local function findWarehouse()
  if cfg.warehousePeripheral ~= "" then return peripheral.wrap(cfg.warehousePeripheral) end
  if not peripheral.getNames then return nil end
  for _, name in ipairs(peripheral.getNames()) do
    if isWarehouse(name) then
      local p = peripheral.wrap(name)
      if p and p.list and p.size then return p end
    end
  end
end
-- Menge eines Items im Lager; nil, wenn das Lager nicht lesbar ist (bzw. alter Funk-Sender)
function warehouseCount(name)
  local w = S.warehouse
  if not w or w.missing or type(w.items) ~= "table" then return nil end
  return tonumber(w.items[name]) or 0
end
function lagerMessage(msg)
  if type(msg) == "table" and tonumber(msg.size) then remote, remoteT = msg, now() end
end
local direct, directT = nil, nil   -- direkt gelesene Daten (gedrosselt, warehouseInterval)
function readWarehouse()
  local w
  local p
  if not directT or now() - directT >= cfg.warehouseInterval * 1000 then
    directT, direct = now(), nil
    p = findWarehouse()
  end
  if p then
    local okS, size = pcall(p.size)
    local okL, list = pcall(p.list)
    if okS and okL and type(list) == "table" and tonumber(size) then
      local used, total, by = 0, 0, {}
      for _, it in pairs(list) do
        local n = tonumber(it.count) or 0
        used, total = used + 1, total + n
        by[it.name] = (by[it.name] or 0) + n
      end
      local top, kinds = {}, 0
      for nm, n in pairs(by) do top[#top+1] = {name=nm, n=n}; kinds = kinds + 1 end
      table.sort(top, function(a, b) return a.n > b.n end)
      while #top > 8 do table.remove(top) end
      direct = {size=tonumber(size), used=used, total=total, top=top, kinds=kinds, src="direkt", items=by}
    end
  end
  w = direct
  if not w and remote and now() - remoteT < math.max(120000, cfg.scanInterval * 3000) then
    w = remote
    w.src, w.age = "Funk", now() - remoteT
  end
  if not w then S.warehouse = {missing=true}; return end
  w.pct = w.size > 0 and w.used / w.size * 100 or 0
  S.warehouse = w
  histSample("lager", w.pct)
  local full = cfg.warehouseWarnPercent > 0 and w.pct >= cfg.warehouseWarnPercent
  if full then addAlert(string.format("Lager (Warehouse) fast voll: %d%%", math.floor(w.pct))) end
  if cfg.chatOnStorage then alert("lager", full, string.format("Lager (Warehouse) fast voll (%d%%)", math.floor(w.pct))) end
end
end -- lager

-- Forschung (teure Abfrage -> nur alle researchInterval Sekunden)
local research, lastResearchT, readResearch
do -- forschung
research = nil      -- {running, available, done, total, branches}
local researchStatus = {} -- id -> Status beim letzten Abruf
lastResearchT = nil
function readResearch(c)
  if lastResearchT and now() - lastResearchT < cfg.researchInterval * 1000 then return end
  lastResearchT = now()
  local tree = call(c, "getResearches")
  if type(tree) ~= "table" then return end
  local r = {running={}, available={}, done=0, total=0, branches={}}
  local function walk(branch, list, parentDone)
    for _, it in ipairs(list or {}) do
      local st = tostring(it.status or "NOT_STARTED")
      local name = asc(it.displayName or it.id or "?")
      local br = r.branches[branch]
      r.total = r.total + 1; br.total = br.total + 1
      if st == "FINISHED" then r.done = r.done + 1; br.done = br.done + 1 end
      if st == "IN_PROGRESS" then
        local req = tonumber(it.requiredTime) or 0
        local pct = req > 0 and math.min(99, math.floor((tonumber(it.progress) or 0) / req * 100)) or nil
        r.running[#r.running+1] = {name=name, branch=branch, pct=pct}
      elseif st == "NOT_STARTED" and parentDone then
        local ok = true
        for _, q in ipairs(it.requirements or {}) do if q.fulfilled == false then ok = false end end
        if ok then
          local cost = {}
          for _, cst in ipairs(it.cost or {}) do
            local vi = type(cst.validItems) == "table" and cst.validItems[1] or nil
            if vi then cost[#cost+1] = {name=vi.name, label=itemLabel(vi), count=tonumber(cst.count) or 1, alts=cst.validItems} end
          end
          r.available[#r.available+1] = {name=name, branch=branch, cost=cost}
        end
      end
      local prev = researchStatus[it.id or name]
      if prev == "IN_PROGRESS" and st == "FINISHED" and cfg.chatOnResearch then chat("Forschung abgeschlossen: "..name) end
      researchStatus[it.id or name] = st
      walk(branch, it.children, st == "FINISHED")
    end
  end
  for branchId, list in pairs(tree) do
    local branch = pretty(branchId)
    r.branches[branch] = {done=0, total=0}
    walk(branch, list, true)
  end
  table.sort(r.available, function(a, b) if a.branch ~= b.branch then return a.branch < b.branch end return a.name < b.name end)
  research = r
end
end -- forschung

local function readME(b)
  local me = {}
  local used, max = call(b, "getUsedItemStorage"), call(b, "getMaxItemStorage")
  if type(used) == "number" and type(max) == "number" and max > 0 then me.storagePct = used/max*100 end
  local st, cap = call(b, "getStoredEnergy"), call(b, "getEnergyCapacity")
  if type(st) == "number" and type(cap) == "number" and cap > 0 then me.energyPct = st/cap*100 end
  me.usage, me.input = call(b, "getEnergyUsage"), call(b, "getAverageEnergyInput")
  S.me = me
  local full = cfg.storageWarnPercent > 0 and me.storagePct and me.storagePct >= cfg.storageWarnPercent
  local low = cfg.energyWarnPercent > 0 and me.energyPct and me.energyPct <= cfg.energyWarnPercent
  if full then addAlert(string.format("ME-Speicher fast voll: %d%%", math.floor(me.storagePct))) end
  if low then addAlert(string.format("ME-Energie niedrig: %d%%", math.floor(me.energyPct))) end
  if cfg.chatOnStorage then
    alert("storage", full, string.format("ME-Speicher fast voll (%d%%)", math.floor(me.storagePct or 0)))
    alert("energy", low, string.format("ME-Energie niedrig (%d%%)", math.floor(me.energyPct or 0)))
  end
end

-- =====================================================================
-- ME-Inventar, Export, Crafting
-- =====================================================================
-- Nur die benoetigten Items nachschlagen. getItems() ohne Filter wandelt JEDES Item im ME
-- (mit Komponenten, Tags, Hash) um und bremst bei grossen Systemen den Server aus.
-- names: item -> maximales Alter des Bestands in Sekunden. Dringendes (Anfragen) zuerst,
-- hoechstens maxStockLookups Abfragen pro Scan; der Rest nimmt den letzten bekannten Stand.
local readStock
do -- bestand
local function copyList(list)
  local out = {}
  for i, it in ipairs(list) do local c = {}; for k, v in pairs(it) do c[k] = v end; out[i] = c end
  return out
end
function readStock(b, names)
  local byName, asked, failed, lastErr = {}, 0, 0, nil
  local t = now()
  local todo = {}
  for name, maxAge in pairs(names) do
    local c = stockCache[name]
    if c and t - c.t <= maxAge * 1000 then byName[name] = copyList(c.list)
    else todo[#todo+1] = {name=name, age=maxAge} end
  end
  table.sort(todo, function(a, b2) if a.age ~= b2.age then return a.age < b2.age end return a.name < b2.name end)
  for i, e in ipairs(todo) do
    local name = e.name
    if i > cfg.maxStockLookups then
      local c = stockCache[name]
      byName[name] = c and copyList(c.list) or {}
    else
      asked = asked + 1
      local ok, res = pcall(b.getItems, {name=name})
      local list = {}
      if ok and type(res) == "table" then
        for _, it in ipairs(res) do if it.name == name then list[#list+1] = it end end
      elseif not ok then
        failed, lastErr = failed + 1, res
      end
      if ok then stockCache[name] = {t=t, list=list} end
      byName[name] = copyList(list)
    end
  end
  for name, c in pairs(stockCache) do if t - c.t > 1800000 then stockCache[name] = nil end end
  if asked > 0 and failed == asked then addError("ME getItems: "..tostring(lastErr)); return nil end
  return byName
end
end -- bestand
local function findBridgeItem(byName, name, hash)
  for _, v in ipairs(byName[name] or {}) do
    if itemHash(v) == hash and (tonumber(v.count) or 0) > 0 then return v end
  end
  return nil
end
local function takeStock(found, n) found.count = (tonumber(found.count) or 0) - n end
local function stockOf(byName, name)
  local n = 0
  for _, v in ipairs(byName and byName[name] or {}) do n = n + (tonumber(v.count) or 0) end
  return n
end

-- Crafting-CPUs: Auslastung + was gerade gecraftet wird
local readCpus
do -- cpus
local cpuCountSeen = nil   -- Anzahl CPUs beim letzten Scan
local dynamicCpus = false  -- CPU-Anzahl aendert sich -> Quantum Computer o.ae., freie CPUs nicht zaehlbar
function readCpus(b)
  local cpus = call(b, "getCraftingCPUs")
  if type(cpus) ~= "table" then return end
  local pctBy = {}
  local tasks = call(b, "getCraftingTasks")
  if type(tasks) == "table" then
    for _, tk in ipairs(tasks) do
      local r = type(tk) == "table" and tk.resource
      if type(r) == "table" and r.name and tonumber(tk.completion) then pctBy[r.name] = math.floor(tk.completion * 100) end
    end
  end
  local list, free, jobs = {}, 0, {}
  for i, cpu in ipairs(cpus) do
    local name = (type(cpu.name) == "string" and cpu.name ~= "" and cpu.name ~= "Unnamed") and asc(cpu.name) or ("CPU "..i)
    local job = type(cpu.craftingJob) == "table" and cpu.craftingJob or nil
    local res = job and type(job.resource) == "table" and job.resource or nil
    local e = {name=name, busy=cpu.isBusy == true, item=res and res.name, label=res and itemLabel(res),
      qty=job and tonumber(job.quantity), storage=tonumber(cpu.storage), co=tonumber(cpu.coProcessors)}
    if not e.busy then free = free + 1 end
    if e.busy and e.item then e.pct = pctBy[e.item]; jobs[e.item] = e end
    list[#list+1] = e
  end
  if cpuCountSeen and cpuCountSeen ~= #list and not dynamicCpus then
    dynamicCpus = true
    logEvent("Crafting-CPUs entstehen dynamisch (Quantum Computer?) - CPU-Pruefung aus", "info")
  end
  cpuCountSeen = #list
  -- freeCpus = nil heisst: nicht begrenzen (tryCraft prueft dann keine Reserve)
  local gate = cfg.cpuCheck and not dynamicCpus and #list > 0
  S.cpus, S.freeCpus, S.cpuJobs, S.cpuDynamic = list, gate and free or nil, jobs, dynamicCpus or #list == 0
end
end -- cpus

-- Vom Skript gestartete Crafts verfolgen
local crafts = {}
local updateCrafts, deliveryKey, recentDelivery, queueExport, processExportBuffer, tryCraft
do -- crafts
local craftSeq = 0
local craftFailedAt = {}   -- item -> Zeitpunkt des letzten nicht gestarteten Crafts
local craftableCache = {}  -- "item|hash" -> {v = craftbar, t = Zeitpunkt}
local function trackCraft(name, hash, count, info)
  craftSeq = craftSeq + 1
  crafts[#crafts+1] = {id=craftSeq, name=name, hash=hash, count=count, t=now(), state="START",
    label=info.label or shortName(name), source=info.source or "", stock=info.stock or 0}
  logEvent("Craft gestartet: "..count.."x "..(info.label or shortName(name))..(info.source and info.source ~= "" and (" fuer "..info.source) or ""), "craft")
end
function updateCrafts(byName)
  local t, keep = now(), {}
  for _, c in ipairs(crafts) do
    local job = S.cpuJobs and S.cpuJobs[c.name]
    if c.state == "START" or c.state == "LAEUFT" then
      if job then
        c.seen, c.state, c.pct, c.cpu = true, "LAEUFT", job.pct, job.name
        job.tracked = true
        if cfg.craftStuckMinutes > 0 and t - c.t >= cfg.craftStuckMinutes * 60000 then
          c.stuck = true
          if cfg.chatOnStuckCraft then alert("craft:"..c.id, true, "Craft haengt seit "..fmtAge(t - c.t)..": "..c.label) end
        end
      elseif c.seen or (byName and stockOf(byName, c.name) > c.stock) then
        c.state, c.doneAt, c.stuck = "FERTIG", t, nil
        logEvent("Craft fertig: "..c.count.."x "..c.label.." ("..fmtAge(t - c.t)..")", "craft")
      elseif S.cpuJobs and t - c.t > 90000 then
        c.state, c.doneAt = "FEHLER", t
        c.note = "nicht gestartet - Zutaten fehlen?"
        local last = craftFailedAt[c.name]
        if cfg.chatOnStuckCraft and not (last and t - last < 1800000) then
          chat("Craft nicht gestartet (Zutaten fehlen?): "..c.count.."x "..c.label)
        end
        craftFailedAt[c.name] = t
      end
    end
    local ttl = c.state == "FERTIG" and 600000 or 1800000
    if not c.doneAt or t - c.doneAt < ttl then keep[#keep+1] = c else alertActive["craft:"..c.id] = nil end
  end
  crafts = keep
  local stuck, failed = 0, 0
  for _, c in ipairs(crafts) do
    if c.stuck and c.state == "LAEUFT" then stuck = stuck + 1 end
    if c.state == "FEHLER" then failed = failed + 1 end
  end
  if stuck > 0 then addAlert(stuck.." Craft(s) laufen laenger als "..cfg.craftStuckMinutes.." min") end
  if failed > 0 then addAlert(failed.." Craft(s) nicht gestartet - siehe Reiter Crafts") end
end

function deliveryKey(pos, name, hash) return pos.."|"..name.."|"..tostring(hash) end
function recentDelivery(key, cooldown)
  local d = delivered[key]
  if d and now()-d.t < cooldown*1000 then return d end
  return nil
end
-- e = {name, hash, count, side, label, key, cooldown, reqId, entry}
function queueExport(e)
  if e.name and e.count and e.count > 0 then exportBuffer[#exportBuffer+1] = e end
end
function processExportBuffer(b)
  local summary, total = {}, 0
  for _, it in ipairs(exportBuffer) do
    local side = it.side or cfg.exportSide
    local filter = {name=it.name, count=it.count, nbtHash=it.hash or ""}
    local ok, moved, err = pcall(b.exportItem, side, filter)
    logLine("[EXPORT] "..side.." "..dump(filter).." ok="..tostring(ok).." res="..tostring(moved).." err="..tostring(err))
    local entry = it.entry
    if ok and type(moved) == "number" and moved > 0 then
      statDelivered(it.name, it.label, moved)
      total = total + moved
      local sc = stockCache[it.name]
      if sc then
        for _, e in ipairs(sc.list) do
          if itemHash(e) == it.hash then e.count = math.max(0, (tonumber(e.count) or 0) - moved) end
        end
        if moved < it.count then sc.t = 0 end
      end
      summary[#summary+1] = moved.."x "..(it.label or shortName(it.name))
      if it.reqId then
        sentAt[it.reqId] = now()
        sentAmount[it.reqId] = (sentAmount[it.reqId] or 0) + moved
      end
      if it.buildKey then
        pendingBuild[it.buildKey] = {g0=it.buildGap, n=(it.buildOut or 0) + moved, t=now()}
      end
      if it.key then
        local d = recentDelivery(it.key, it.cooldown or cfg.resendCooldown)
        if d then d.n = d.n + moved; d.t = now() else delivered[it.key] = {t=now(), n=moved} end
      end
      if entry then
        entry.delivered = (entry.delivered or 0) + moved
        if moved < it.count then entry.state = "FEHLER"; entry.note = string.format("nur %d/%d - Ziel voll?", moved, it.count) end
      end
    else
      local reason = (not ok) and tostring(moved) or tostring(err or "0 bewegt - Ziel voll?")
      if reason == "INVENTORY_NOT_FOUND" then reason = "kein Inventar bei "..side end
      addError("Export "..shortName(it.name)..": "..reason)
      if entry then entry.state = "FEHLER"; entry.note = reason end
    end
  end
  if #summary > 0 then
    local more = #summary > 4 and (" +"..(#summary - 4).." weitere") or ""
    while #summary > 4 do table.remove(summary) end
    logEvent("Geliefert ("..total.."): "..table.concat(summary, ", ")..more, "lief")
  end
end

-- Rueckgabe: "started", "running", "nopattern", "nocpu", "limit", "failed" oder "error"
-- info = {label, source, stock, reserve (CPUs, die frei bleiben muessen), noStart}
function tryCraft(b, name, hash, count, quiet, info)
  info = info or {}
  if cfg.craftMaxStack then count = math.max(count, 64) end
  if count <= 0 then count = 1 end
  -- nbtHash "" = nur die normale Variante ohne Components. Sonst nimmt AP evtl. ein gebrauchtes/
  -- verzaubertes Exemplar aus dem ME als Craft-Ziel, fuer das es kein Pattern gibt -> Craft startet nicht.
  local filter = {name=name, count=count, nbtHash=hash or ""}
  -- laeuft schon? -> aus der einen CPU-Abfrage pro Scan statt einem Aufruf pro Item
  local running
  if S.cpuJobs then running = S.cpuJobs[name] ~= nil
  else local okR, r = pcall(b.isCrafting, {name=name, nbtHash=hash}); running = okR and r == true end
  if not running then
    -- eigene, noch nicht auf einer CPU sichtbare Crafts (AE2 rechnet noch) zaehlen auch als laufend
    for _, c in ipairs(crafts) do
      if c.name == name and (c.state == "START" or c.state == "LAEUFT") then running = true; break end
    end
  end
  if running then clearMissing(name); return "running" end
  -- Pattern vorhanden? -> zwischengespeichert (ja: 10 min, nein: 2 min)
  local ck = name.."|"..tostring(hash)
  local cc = craftableCache[ck]
  local craftable
  if cc and now() - cc.t < (cc.v and 600000 or 120000) then
    craftable = cc.v
  else
    -- AP isCraftable kennt nur Patterns in Pattern Providern. getCraftableItems fragt AE2s eigene
    -- Liste aller craftbaren Items ab (z.B. auch Rezepte aus dem Advanced AE Quantum Crafter).
    local ok, res, err
    if b.getCraftableItems then
      ok, res, err = pcall(b.getCraftableItems, {name=name, nbtHash=hash or ""})
      if ok and type(res) == "table" then res = #res > 0 end
    else
      ok, res, err = pcall(b.isCraftable, filter)
    end
    if not ok or res == nil then
      local msg = "Craftbarkeit "..shortName(name)..": "..tostring(ok and err or res)
      if quiet then logLine(msg) else addError(msg) end
      return "error"
    end
    craftable = res == true
    craftableCache[ck] = {v=craftable, t=now()}
  end
  if not craftable then return "nopattern" end
  if craftFailedAt[name] and now() - craftFailedAt[name] < 300000 then return "failed" end
  if not cfg.craftingEnabled then return "disabled" end
  if updateWaiting then return "paused" end
  if info.noStart then return "limit" end
  if S.freeCpus and S.freeCpus <= (info.reserve or 0) then return "nocpu" end
  local ok2, job, err2 = pcall(b.craftItem, filter)
  if not (ok2 and job) then craftableCache[ck] = nil end
  if ok2 and job then
    clearMissing(name); statCraft()
    if S.freeCpus then S.freeCpus = S.freeCpus - 1 end
    trackCraft(name, hash, count, info)
    return "started"
  end
  addError("Craft abgelehnt "..shortName(name)..": "..tostring(ok2 and err2 or job))
  return "error"
end
end -- crafts

-- =====================================================================
-- Werkzeuge & Ruestung
-- =====================================================================
local handleRequests, requestItemNames
do -- anfragen
local toolTiers  = {"wood", "stone", "iron", "diamond", "netherite"}
local armorTiers = {"leather", "gold", "chain", "iron", "diamond", "netherite"}
local tierPrefix = {
  wood="minecraft:wooden", leather="minecraft:leather", stone="minecraft:stone", chain="minecraft:chainmail",
  iron="minecraft:iron", gold="minecraft:golden", diamond="minecraft:diamond", netherite="minecraft:netherite",
}
local gearTypes = {   -- Reihenfolge wichtig: "pickaxe" vor "axe"!
  {"chestplate", true}, {"leggings", true}, {"helmet", true}, {"boots", true},
  {"sword", false}, {"pickaxe", false}, {"shovel", false}, {"hoe", false}, {"axe", false},
}
local function rankOf(list, word)
  if not word then return nil end
  for i, v in ipairs(list) do if v == word then return i end end
  if word == "better" then return #list end
  return nil
end
local function gearCandidates(req)
  local desc = string.lower((req.description or "").." "..(req.displayName or ""))
  local maxW = desc:match("maximal level:%s*(%a+)")
  if not maxW then return nil end
  local minW = desc:match("minimal level:%s*(%a+)")
  local typ, isArmor
  for _, gt in ipairs(gearTypes) do
    if desc:find(gt[1], 1, true) then typ, isArmor = gt[1], gt[2]; break end
  end
  if not typ then return nil end
  local tiers = isArmor and armorTiers or toolTiers
  local maxR = rankOf(tiers, maxW) or #tiers
  local minR = rankOf(tiers, minW) or 1
  local capR = rankOf(tiers, isArmor and cfg.maxArmorTier or cfg.maxToolTier) or #tiers
  local list = {}
  for r = math.min(maxR, capR), minR, -1 do list[#list+1] = tierPrefix[tiers[r]].."_"..typ end
  return list
end

-- =====================================================================
-- Anfragen
-- =====================================================================
local function findDomumBridgeItem(byName, it)
  local candidates = byName[it.name] or {}
  if #candidates == 0 then return nil end
  local hash = itemHash(it)
  for _, v in ipairs(candidates) do if itemHash(v) == hash then return v end end
  local wanted = it.components and it.components["domum_ornamentum:texture_data"]
  if type(wanted) ~= "table" then return nil end
  local key = dump(wanted); local match
  for _, v in ipairs(candidates) do
    local got = v.components and v.components["domum_ornamentum:texture_data"]
    if type(got) == "table" and dump(got) == key then
      if match then return nil end
      match = v
    end
  end
  return match
end

local function handleDomum(req, it, count, tpos, byName, entry)
  local found = findDomumBridgeItem(byName, it)
  local send = math.min(found and (tonumber(found.count) or 0) or 0, count)
  if send > 0 then
    takeStock(found, send)
    queueExport({name=it.name, hash=itemHash(found), count=send, label=entry.label, reqId=req.id,
      key=deliveryKey(tpos, it.name, itemHash(it)), entry=entry})
  end
  if count-send > 0 then
    local mats = {}
    local td = it.components and it.components["domum_ornamentum:texture_data"]
    if type(td) == "table" then for _, v in pairs(td) do mats[#mats+1] = shortName(type(v) == "table" and dump(v) or v) end end
    entry.state = "MANUELL"
    entry.note = (send > 0 and ("x"..send.." geliefert, ") or "").."Architect's Cutter"..(#mats > 0 and (": "..table.concat(mats, "+")) or "")
  else
    entry.state = "OK"; entry.note = "geliefert"
  end
end

local function handleGeneric(req, count, tpos, byName, b, entry)
  local candidates, seen = {}, {}
  local function add(name, hash, src)
    if not name then return end
    local key = name.."|"..tostring(hash)
    if seen[key] then return end
    seen[key] = true
    if src and hasBlacklistedTag(src) and not cfg.whitelistItemName[name] then return end
    candidates[#candidates+1] = {name=name, hash=hash}
  end
  local gear = gearCandidates(req)
  if gear then
    if #gear == 0 then
      entry.state = "MANUELL"
      entry.note = "ueber Stufenlimit ("..(cfg.maxToolTier or "?").."/"..(cfg.maxArmorTier or "?")..")"
      return
    end
    for _, n in ipairs(gear) do add(n, nil, nil) end
  else
    for _, ri in ipairs(req.items or {}) do add(ri.name, itemHash(ri), ri) end
  end
  if #candidates == 0 then entry.state = "SKIP"; entry.note = "Blacklist"; return end

  local remaining, sent = count, 0
  for _, c in ipairs(candidates) do
    if remaining <= 0 then break end
    local found = findBridgeItem(byName, c.name, c.hash)
    if found then
      local send = math.min(remaining, tonumber(found.count) or 0)
      if send > 0 then
        takeStock(found, send)
        queueExport({name=c.name, hash=c.hash, count=send, label=entry.label, reqId=req.id,
          key=deliveryKey(tpos, c.name, c.hash), entry=entry})
        remaining = remaining - send; sent = sent + send
        if c.name ~= req.items[1].name then entry.label = shortName(c.name) end
      end
    end
  end
  if remaining <= 0 then entry.state = "OK"; entry.note = "geliefert"; return end

  local prefix = sent > 0 and ("x"..sent.." geliefert, ") or ""
  local anyError = false
  for i, c in ipairs(candidates) do
    if i > cfg.maxCraftCandidates then break end
    local r = tryCraft(b, c.name, c.hash, remaining, i > 1,
      {label=entry.label, source=entry.target, stock=stockOf(byName, c.name)})
    if r == "started" then entry.state = "CRAFT"; entry.note = prefix.."x"..remaining.." beauftragt"; return end
    if r == "running" then entry.state = "LAEUFT"; entry.note = prefix.."Crafting laeuft"; return end
    if r == "nocpu" then entry.state = "WARTET"; entry.note = prefix.."alle Crafting-CPUs belegt"; return end
    if r == "failed" then entry.state = "FEHLT"; entry.note = prefix.."Craft startet nicht - Zutaten?"; return end
    if r == "disabled" then entry.state = "MANUELL"; entry.note = prefix.."Auto-Crafting aus (Optionen)"; return end
    if r == "paused" then entry.state = "WARTET"; entry.note = prefix.."Crafting pausiert (Update)"; return end
    if r == "error" then anyError = true end
  end
  if not anyError then recordMissing(candidates[1].name, entry.label, "req:"..tostring(req.id)) end
  entry.state = "FEHLT"
  local tried = ""
  if gear then
    local names = {}
    for i, c in ipairs(candidates) do if i <= cfg.maxCraftCandidates then names[#names+1] = shortName(c.name) end end
    tried = " ("..table.concat(names, ", ")..")"
  end
  entry.note = prefix..(anyError and "Fehler, siehe Start" or ("x"..remaining.." kein Pattern"..tried))
end

-- Welche Items die Anfragen brauchen (fuer die gezielte ME-Abfrage)
function requestItemNames(requests, add)
  for _, req in ipairs(type(requests) == "table" and requests or {}) do
    if not skipStates[req.state or ""] then
      local gear = gearCandidates(req)
      if gear then
        for _, g in ipairs(gear) do add(g) end
      else
        for i, it in ipairs(req.items or {}) do
          if i > math.max(cfg.maxCraftCandidates, 3) then break end
          add(it.name)
        end
      end
    end
  end
end

local reqMeta = {}   -- request id -> Anzeigename (fuer die Wartezeit-Statistik)
function handleRequests(b, requests, byName)
  if type(requests) ~= "table" then addError("getRequests fehlgeschlagen"); return end
  local t, activeIds = now(), {}
  local oldCount = 0
  for _, req in ipairs(requests) do
    local it = req.items and req.items[1]
    local count = tonumber(req.count) or 0
    if req.id then
      activeIds[req.id] = true
      firstSeen[req.id] = firstSeen[req.id] or t
    end
    if it and it.name and count > 0 and not skipStates[req.state or ""] then
      local tpos = formatPos(req.target)
      local entry = {state="?", count=count, label=asc(req.displayName or itemLabel(it)), item=it.name,
        target=targetName(req.target), tpos=tpos, note="", age=req.id and (t-firstSeen[req.id]) or 0}
      if req.id then reqMeta[req.id] = entry.label end
      S.requests[#S.requests+1] = entry
      local last = req.id and sentAt[req.id]
      local pre = recentDelivery(deliveryKey(tpos, it.name, itemHash(it)), cfg.prestockCooldown)
      local inWh = warehouseCount(it.name)
      local already = req.id and sentAmount[req.id] or 0
      local resendWait = cfg.resendAfterMinutes * 60000
      local deliver = count
      if inWh and inWh >= count then
        -- liegt schon im Lager: der Kurier bringt es, mehr liefern fuellt nur die Racks
        entry.state = "WARTET"; entry.note = "liegt im Lager (x"..inWh..") - Kurier holt ab"
        deliver = 0
      elseif last and already >= count then
        if (t - last) < resendWait or (resendCount[req.id] or 0) >= cfg.maxResends then
          entry.state = "WARTET"
          entry.note = (t - last) < resendWait and ("geliefert vor "..fmtAge(t - last)..", wartet auf Kurier")
            or "geliefert, nicht abgeholt - Lager/Kurier pruefen"
          deliver = 0
        else
          -- lange nicht abgeholt und nicht im Lager (verloren?): einmal nachliefern
          resendCount[req.id] = (resendCount[req.id] or 0) + 1
          sentAmount[req.id] = 0
          logEvent("Nachlieferung: "..count.."x "..entry.label.." ("..entry.target..")", "info")
        end
      elseif last and (t - last) < cfg.resendCooldown * 1000 and already > 0 then
        deliver = count - already   -- Teillieferung ergaenzen
      elseif pre and not last and pre.n >= count then
        entry.state = "WARTET"; entry.note = "x"..pre.n.." vorgeliefert"
        deliver = 0
      end
      if deliver > 0 then
        if it.name:find("domum_ornamentum", 1, true) then
          handleDomum(req, it, deliver, tpos, byName, entry)
        else
          handleGeneric(req, deliver, tpos, byName, b, entry)
        end
      end
      if cfg.oldRequestMinutes > 0 and entry.age >= cfg.oldRequestMinutes*60000 and entry.state ~= "SKIP" then
        entry.old = true; oldCount = oldCount + 1
        if cfg.chatOnOldRequest then
          alert("old:"..tostring(req.id), true, "Anfrage haengt seit "..fmtAge(entry.age)..": "..entry.label.." ("..entry.target..")")
        end
      end
    end
  end
  if oldCount > 0 then addAlert(oldCount.." Anfrage(n) offen seit > "..cfg.oldRequestMinutes.." min") end
  for id in pairs(sentAt) do if not activeIds[id] then sentAt[id] = nil; sentAmount[id] = nil; resendCount[id] = nil end end
  -- erledigte Anfragen: Wartezeit fuer die Statistik
  local st = statsToday()
  st.reqTimes = st.reqTimes or {}
  for id, t0 in pairs(firstSeen) do
    if not activeIds[id] and reqMeta[id] then
      local d = t - t0
      local label = reqMeta[id]
      local e = st.reqTimes[label] or {n=0, sum=0, max=0}
      e.n, e.sum, e.max = e.n + 1, e.sum + d, math.max(e.max, d)
      st.reqTimes[label] = e
      st.reqN, st.reqSum = (st.reqN or 0) + 1, (st.reqSum or 0) + d
    end
  end
  for id in pairs(reqMeta) do if not activeIds[id] then reqMeta[id] = nil end end
  for id in pairs(firstSeen) do if not activeIds[id] then firstSeen[id] = nil; alertActive["old:"..tostring(id)] = nil end end
end
end -- anfragen

-- =====================================================================
-- Baustellen: Fortschritt + Vorlieferung
-- =====================================================================
local buildBanner, handleBuilds, readOrders
do -- baustellen
local stageNames = {
  CLEAR="Raeumen", BUILD_SOLID="Rohbau", WEAK_SOLID="Rohbau 2", CLEAR_WATER="Wasser entfernen",
  CLEAR_NON_SOLIDS="Aufraeumen", DECORATE="Deko", SPAWN="Abschluss", REMOVE="Abriss", REMOVE_WATER="Abriss",
}
local buildEta
-- Fortschritt = Bereich der aktuellen Bauphase + Materialfortschritt innerhalb der Phase.
-- So stimmt die Groessenordnung auch, wenn das Skript erst mitten im Bau startet.
local stageRanges = {
  CLEAR={0, 10}, BUILD_SOLID={10, 55}, WEAK_SOLID={55, 65}, CLEAR_WATER={65, 70},
  CLEAR_NON_SOLIDS={70, 75}, DECORATE={75, 95}, SPAWN={95, 99},
  REMOVE={0, 90}, REMOVE_WATER={90, 99},
}
local buildStages  = {"CLEAR", "BUILD_SOLID", "WEAK_SOLID", "CLEAR_WATER", "CLEAR_NON_SOLIDS", "DECORATE", "SPAWN"}
local removeStages = {"REMOVE", "REMOVE_WATER"}
local function stageIndex(stage)
  for i, s in ipairs(buildStages) do if s == stage then return i, #buildStages end end
  for i, s in ipairs(removeStages) do if s == stage then return i, #removeStages end end
  return nil
end

-- Restzeit aus dem Fortschritt der letzten Stunde (Proben alle 2 Minuten)
function buildEta(rec, pct)
  local t = now()
  rec.samples = rec.samples or {}
  local last = rec.samples[#rec.samples]
  if not last or t - last.t >= 120000 then
    rec.samples[#rec.samples+1] = {t=t, p=pct}
    while #rec.samples > 0 and t - rec.samples[1].t > 3600000 do table.remove(rec.samples, 1) end
    saveDb(cfg.buildsFile, buildDb)
  end
  local first = rec.samples[1]
  if not first or t - first.t < 300000 or pct <= first.p then return nil end
  local rate = (pct - first.p) / (t - first.t)       -- Prozent pro ms
  return (100 - pct) / rate
end

local function buildProgress(wo, res)
  local total = 0
  for _, r in ipairs(res or {}) do total = total + math.max(0, tonumber(r.needs) or 0) end
  local key = tostring(wo.id)
  local rec = buildDb[key]
  local stage = wo.stage
  if rec and rec.v ~= 2 then rec = nil end   -- Eintrag im alten Format (v0.8.0) verwerfen
  if not rec then
    -- erstmals gesehen: wie weit die aktuelle Phase schon ist, ist unbekannt -> Schaetzung
    rec = {v=2, stage=stage, base=total, approx=stage ~= nil}
    buildDb[key] = rec; saveDb(cfg.buildsFile, buildDb)
  elseif rec.stage ~= stage then
    -- Phasenwechsel beobachtet: ab hier ist der Wert exakt
    rec.stage, rec.base, rec.approx = stage, total, false
    saveDb(cfg.buildsFile, buildDb)
  elseif total > rec.base then
    rec.base = total; saveDb(cfg.buildsFile, buildDb)
  end

  local range = stage and stageRanges[stage]
  if not range then
    -- unbekannte/keine Phase: nur Material seit Beobachtungsbeginn
    local pct = rec.base > 0 and math.floor((rec.base-total)/rec.base*100) or 0
    return math.max(0, math.min(99, pct)), rec.approx
  end
  local frac = rec.base > 0 and (rec.base-total)/rec.base or 0
  local pct = math.floor(range[1] + (range[2]-range[1])*math.max(0, math.min(1, frac)))
  pct = math.max(0, math.min(99, pct))
  return pct, rec.approx, buildEta(rec, pct)
end

local knownOrders = {}   -- id -> {name, target, pos, type, missingSince}
local pendingFinish = false   -- true = ein Auftrag ist verschwunden, Gebaeude neu lesen
buildBanner = nil  -- {t, text}
local function checkFinishedOrders(active)
  pendingFinish = false
  for id, o in pairs(knownOrders) do
    if not active[id] then
      local lvl
      for _, b in ipairs(S.mapBuildings) do if b.key == o.pos then lvl = b.level end end
      local isRemove = o.type and o.type:find("REMOVE")
      if (lvl and lvl >= o.target and o.target > 0) or isRemove then
        local text = isRemove and (o.name.." wurde abgerissen") or (o.name.." Stufe "..o.target.." ist fertig!")
        buildBanner = {t=now(), text=text}
        logLine("[BAU] "..text)
        if not cfg.chatOnBuildDone then logEvent(text, "gut") end
        if cfg.chatOnBuildDone then chat(text) end
        knownOrders[id] = nil
      else
        -- Gebaeudestufe evtl. noch nicht aktualisiert: bis zu 5 min warten, Gebaeude neu abfragen lassen
        o.missingSince = o.missingSince or now()
        pendingFinish = true
        if now() - o.missingSince > 300000 then knownOrders[id] = nil end   -- abgebrochen o.ae.
      end
    end
  end
end

local orderSeen = {}   -- id -> erstmals gesehen
local resCache = {}    -- id -> {t, res}
-- Bauauftraege und deren Materiallisten (Materiallisten nur alle builderResourceInterval Sekunden)
function readOrders(c)
  local orders = call(c, "getWorkOrders")
  if type(orders) ~= "table" then return nil, {} end
  local res, t = {}, now()
  for _, wo in ipairs(orders) do
    if wo.isClaimed and wo.builderHome and wo.id then
      local k = tostring(wo.id)
      local e = resCache[k]
      if not e or t - e.t >= cfg.builderResourceInterval * 1000 then
        e = {t=t, res=call(c, "getWorkOrderResources", wo.id)}
        resCache[k] = e
      end
      res[k] = e.res
    end
  end
  for k in pairs(resCache) do if not res[k] then resCache[k] = nil end end
  return orders, res
end

function handleBuilds(b, orders, resources, byName)
  if type(orders) ~= "table" then return end
  local budget = cfg.prestockMaxPerScan
  local wh = S.warehouse
  local whFull = wh and not wh.missing and cfg.warehouseStopPercent > 0 and wh.pct >= cfg.warehouseStopPercent
  if whFull and cfg.prestockEnabled then addAlert("Lager zu "..math.floor(wh.pct).."% voll - Vorlieferung pausiert") end
  local active = {}
  local started = 0
  local tNow = now()
  for _, wo in ipairs(orders) do
    if wo.id then
      knownOrders[tostring(wo.id)] = {name=asc(wo.displayName or "Bau"), target=tonumber(wo.targetLevel) or 0,
        pos=formatPos(wo.pos), type=tostring(wo.type or "")}
    end
  end
  for _, wo in ipairs(orders) do
    active[tostring(wo.id)] = true
    local entry = {
      name = asc(wo.displayName or ("Auftrag "..tostring(wo.id))),
      level = tonumber(wo.level) or 0, targetLevel = tonumber(wo.targetLevel) or 0,
      stage = wo.stage and (function()
        local i, n = stageIndex(wo.stage)
        return (stageNames[wo.stage] or pretty(wo.stage))..(i and (" "..i.."/"..n) or "")
      end)() or nil,
      claimed = wo.isClaimed == true, pct = 0, res = {}, open = 0, missing = 0, pos = formatPos(wo.pos),
      builder = wo.builderHome and pretty(wo.builderHome.displayName or "Builder") or nil,
      builderPos = wo.builderHome and wo.builderHome.pos and formatPos(wo.builderHome.pos) or nil,
      wait = 0,
    }
    if wo.id then
      orderSeen[tostring(wo.id)] = orderSeen[tostring(wo.id)] or tNow
      entry.wait = tNow - orderSeen[tostring(wo.id)]
    end
    S.builds[#S.builds+1] = entry
    if wo.isClaimed and wo.builderHome and wo.id then
      local builderPos = formatPos(wo.builderHome.pos)
      local res = resources[tostring(wo.id)]
      if type(res) == "table" then
        entry.pct, entry.approx, entry.eta = buildProgress(wo, res)
        local noPattern = 0
        for _, r in ipairs(res) do
          local it = r.item
          if it and it.name then
            -- gap = was dem Builder fehlt (weder bei ihm noch zu ihm unterwegs)
            local gap = (tonumber(r.needs) or 0) - (tonumber(r.available) or 0) - (tonumber(r.delivering) or 0)
            local hash = itemHash(it)
            local key = deliveryKey(builderPos, it.name, hash)
            -- schon geliefert, aber noch nicht beim Builder (liegt im Lager / beim Kurier)?
            local outstanding = 0
            local pb = pendingBuild[key]
            if pb then
              local arrived = math.max(0, pb.g0 - gap)
              outstanding = math.max(0, pb.n - arrived)
              if outstanding == 0 or now() - pb.t > 3600000 then pendingBuild[key] = nil; outstanding = 0 end
            end
            local inWh = warehouseCount(it.name) or 0
            local need = gap - math.max(outstanding, inWh)
            for _, q in ipairs(exportBuffer) do if q.key == key then need = need - q.count end end
            if gap > 0 and need <= 0 then
              -- Bedarf ist gedeckt, die Ware ist nur noch nicht beim Builder
              local row = {label=asc(r.displayName or itemLabel(it)), count=gap, state="WARTET",
                note=outstanding > 0 and ("x"..outstanding.." geliefert, Kurier bringt es") or ("im Lager: "..inWh)}
              entry.res[#entry.res+1] = row
            end
            if need > 0 then
              entry.open = entry.open + 1
              local row = {label=asc(r.displayName or itemLabel(it)), count=need, state="OFFEN", note=""}
              entry.res[#entry.res+1] = row
              local found = findBridgeItem(byName, it.name, hash)
              local stock = found and (tonumber(found.count) or 0) or 0
              local send = 0
              if cfg.prestockEnabled and whFull then
                row.note = "Lager voll - pausiert"
              elseif cfg.prestockEnabled then
                send = math.max(0, math.min(need, stock, cfg.prestockMaxPerItem, budget))
                if send > 0 then
                  budget = budget - send
                  takeStock(found, send)
                  queueExport({name=it.name, hash=hash, count=send, side=cfg.prestockSide,
                    label=row.label, key=key, cooldown=cfg.prestockCooldown, entry=row,
                    buildKey=key, buildGap=gap, buildOut=outstanding})
                  row.state = "OK"; row.note = "x"..send.." geliefert"
                elseif stock > 0 then
                  row.note = "naechster Scan (Mengenlimit)"
                end
              end
              -- ohne Vorlieferung zaehlt der ME-Bestand als "bereit"
              -- craften nur, was im ME wirklich fehlt (nicht, was nur wegen Mengenlimit/Lager-Pause wartet)
              local rest = need - stock
              local pre = send > 0 and ("x"..send.." geliefert, ") or ""
              if rest <= 0 then
                if not cfg.prestockEnabled then row.state = "OK"; row.note = "im ME: "..stock end
              elseif not cfg.prestockCraft then
                row.state = "FEHLT"; entry.missing = entry.missing + 1
                row.note = pre..(stock > 0 and not cfg.prestockEnabled and ("im ME: "..stock) or "fehlt")
              else
                local amount = math.min(rest, cfg.prestockMaxCraft)
                local r2 = tryCraft(b, it.name, hash, amount, true, {label=row.label, source="Bau: "..entry.name,
                  stock=stockOf(byName, it.name), reserve=cfg.craftReserveCpus,
                  noStart=started >= cfg.prestockMaxCraftsPerScan})
                if r2 == "started" then started = started + 1; row.state = "CRAFT"; row.note = pre.."x"..amount.." beauftragt"
                elseif r2 == "running" then row.state = "LAEUFT"; row.note = pre.."Crafting laeuft"
                elseif r2 == "nocpu" then row.state = "OFFEN"; row.note = pre.."wartet auf freie CPU"
                elseif r2 == "limit" then row.state = "OFFEN"; row.note = pre.."wird gecraftet (naechster Scan)"
                else
                  row.state = "FEHLT"; entry.missing = entry.missing + 1
                  row.note = pre..(r2 == "nopattern" and "kein Pattern" or (r2 == "failed" and "Craft startet nicht - Zutaten?"
                    or (r2 == "disabled" and "Auto-Crafting aus" or (r2 == "paused" and "pausiert (Update)" or "fehlt"))))
                  if r2 == "nopattern" then
                    noPattern = noPattern + 1
                    recordMissing(it.name, row.label, "build:"..key, true)
                  end
                end
              end
            end
          end
        end
        local order = {FEHLER=1, FEHLT=2, OFFEN=3, CRAFT=4, LAEUFT=5, OK=6}
        table.sort(entry.res, function(a, b2) return (order[a.state] or 9) < (order[b2.state] or 9) end)
        if cfg.chatOnMissingPattern and noPattern > 0 and not missingNotified["wo:"..tostring(wo.id)] then
          missingNotified["wo:"..tostring(wo.id)] = true
          chat(string.format("Baustelle %s: %d Items ohne Pattern", entry.name, noPattern))
        end
      end
    end
  end
  checkFinishedOrders(active)
  for id in pairs(orderSeen) do if not active[id] then orderSeen[id] = nil end end
  local changed = false
  for k in pairs(buildDb) do if not active[k] then buildDb[k] = nil; changed = true end end
  if changed then saveDb(cfg.buildsFile, buildDb) end
  return pendingFinish
end
end -- baustellen

-- =====================================================================
-- Scan
-- =====================================================================
local bridge, colony = nil, nil
local lastByName = nil
-- ---------- Update-Pruefung ----------
local updateInfo = nil
local updateMsg, pendingVersion, checkUpdate
do -- update
local lastUpdateCheck = nil
updateMsg = nil        -- {t, color, text} Rueckmeldung zum Update
pendingVersion = nil   -- installiert, aber noch nicht neu gestartet
local function vparts(v)
  local t = {}
  for n in (tostring(v or ""):match("^[%d%.]+") or ""):gmatch("%d+") do t[#t+1] = tonumber(n) end
  return t
end
local function isNewer(a, b)
  local x, y = vparts(a), vparts(b)
  for i = 1, math.max(#x, #y) do
    if (x[i] or 0) ~= (y[i] or 0) then return (x[i] or 0) > (y[i] or 0) end
  end
  return false
end
-- Rueckgabe: "neu", "aktuell", "fehler" oder nil (nicht geprueft)
function checkUpdate(force)
  if not http then return force and "fehler" or nil end
  if not force and (tonumber(cfg.updateCheckHours) or 0) <= 0 then return end
  local now = os.epoch("utc")
  if not force and lastUpdateCheck and now - lastUpdateCheck < cfg.updateCheckHours * 3600000 then return end
  lastUpdateCheck = now
  local base = (cfg.updateUrl ~= "" and cfg.updateUrl) or UPDATE_URL
  if base:find("DEIN-NAME", 1, true) then return "fehler" end
  if base:sub(-1) ~= "/" then base = base.."/" end
  local ok, h = pcall(http.get, base.."ae2colony.lua?t="..now, {["Cache-Control"] = "no-cache"}, true)
  if not ok or not h then logLine("Update-Pruefung fehlgeschlagen: "..tostring(h)); return "fehler" end
  local body = h.readAll(); h.close()
  local remote = body and body:match('local scriptVersion%s*=%s*"([^"]+)"')
  if not remote then return "fehler" end
  if not isNewer(remote, pendingVersion or scriptVersion) then return "aktuell" end
  local first = not updateInfo or updateInfo ~= remote
  updateInfo = remote
  if not first then return "neu" end
  logLine("Update verfuegbar: v"..remote)
  if cfg.autoUpdate and shell and fs.exists("update.lua") then
    -- erst installieren, wenn keine selbst gestarteten Crafts mehr laufen (siehe runPendingUpdate)
    updateWaiting = true
    chat("Update v"..remote.." wird installiert, sobald keine Crafts mehr laufen")
  else
    chat("Update v"..remote.." verfuegbar - am Monitor auf 'Jetzt updaten' tippen")
  end
  return "neu"
end
end -- update

-- Drosselung: true, wenn "key" wieder dran ist (beim ersten Mal immer)
local lastRun = {}
local function due(key, seconds)
  local t = now()
  if lastRun[key] and t - lastRun[key] < seconds * 1000 then return false end
  lastRun[key] = t
  return true
end
-- Werte aus dem vorherigen Scan uebernehmen (wenn eine Abfrage diesmal ausgelassen wird)
local function carry(prev, fields) for _, f in ipairs(fields) do S[f] = prev[f] end end

local function scan()
  exportBuffer = {}
  local prev = S
  S = newState()
  findChatBox()
  readColony(colony)
  histSample("happy", S.colony.happy)
  local raid = S.colony.raid
  if raid or due("colony", cfg.colonyInterval) then
    readBuildings(colony)
    readCitizens(colony)
  else
    carry(prev, {"buildingsWorking", "buildingsUpgrade", "mapBuildings", "citizenPos", "citizenCount", "citizens", "allCitizens", "guards"})
  end
  local okW, errW = pcall(readWarehouse)   -- drosselt das direkte Auslesen selbst, Funk-Daten sofort
  if not okW then logLine("Lager: "..tostring(errW)) end
  local visitors = call(colony, "getVisitors")
  local online, status = bridgeStatus(bridge)
  S.online, S.meStatus = online, status
  if cfg.chatOnOffline then alert("offline", not online, "ME-Netz nicht erreichbar: "..status) end
  if not online then addAlert("ME Bridge: "..status); readVisitors(visitors, nil); return end
  readME(bridge)
  histSample("storage", S.me.storagePct)
  -- Erst die Kolonie fragen, was gebraucht wird, dann gezielt nur diese Items im ME nachschlagen
  readResearch(colony)
  local requests = call(colony, "getRequests")
  local orders, resources = readOrders(colony)
  local names = {}
  local age = 15
  local function add(name)
    if type(name) == "string" and (not names[name] or names[name] > age) then names[name] = age end
  end
  requestItemNames(requests, add)                  -- Anfragen: Bestand hoechstens 15 s alt
  age = 60
  for _, c in ipairs(crafts) do add(c.name) end    -- laufende Crafts (Fertig-Erkennung)
  age = 120
  for _, res in pairs(resources) do                -- Baumaterial
    for _, r in ipairs(type(res) == "table" and res or {}) do add(r.item and r.item.name) end
  end
  age = 600
  for _, v in ipairs(type(visitors) == "table" and visitors or {}) do add(v.recruitCost and v.recruitCost.name) end
  if research then
    for _, it in ipairs(research.available) do
      for _, c in ipairs(it.cost) do for i, alt in ipairs(c.alts or {}) do if i <= 3 then add(alt.name) end end end
    end
  end
  local byName = readStock(bridge, names)
  readCpus(bridge)
  updateCrafts(byName)
  readVisitors(visitors, byName)
  if not byName then return end
  lastByName = byName
  if due("food", cfg.foodInterval) then readFood(bridge) else carry(prev, {"food"}) end
  handleRequests(bridge, requests, byName)          -- Requests zuerst (Buerger warten bereits)
  -- verschwundener Bauauftrag -> beim naechsten Scan Gebaeude sofort neu lesen (Fertig-Erkennung)
  if handleBuilds(bridge, orders, resources, byName) then lastRun.colony = nil end
  processExportBuffer(bridge)
  saveDb(cfg.statsFile, statsToday())
  saveDb(cfg.historyFile, historyDb)
end

-- =====================================================================
-- UI
-- =====================================================================
local TABS = {
  {id="start", label="Start", short="Home"}, {id="todo", label="Zu tun", short="Todo"},
  {id="anfragen", label="Anfragen", short="Anfr"},
  {id="bau", label="Bau", short="Bau"}, {id="crafts", label="Crafts", short="Craft"},
  {id="buerger", label="Buerger", short="Buer"}, {id="kolonie", label="Kolonie", short="Kol"},
  {id="forschung", label="Forschung", short="Fors"}, {id="karte", label="Karte", short="Map"},
  {id="stats", label="Stats", short="Stat"}, {id="log", label="Log", short="Log"},
  {id="optionen", label="Optionen", short="Opt"},
}
local stateStyle = {
  FEHLER={colors.red, "FEHLER"}, FEHLT={colors.orange, "FEHLT"}, MANUELL={colors.cyan, "MANUELL"},
  CRAFT={colors.green, "CRAFT"}, LAEUFT={colors.green, "LAEUFT"}, OK={colors.lime, "OK"},
  START={colors.lightBlue, "START"}, FERTIG={colors.lime, "FERTIG"}, HAENGT={colors.red, "HAENGT"},
  WARTET={colors.lightBlue, "WARTET"}, SKIP={colors.gray, "SKIP"}, OFFEN={colors.lightGray, "OFFEN"},
}
local stateRank = {FEHLER=1, FEHLT=2, MANUELL=3, CRAFT=4, LAEUFT=5, OFFEN=6, OK=7, WARTET=8, SKIP=9}

-- Eine Zeile = Liste von Segmenten {t=Text, fg=Farbe, bg=Farbe, alt=Ersatzzeichen fuer s/w}
local function seg(t, fg, bg, alt) return {t=t, fg=fg or colors.white, bg=bg, alt=alt} end
local function fit(s, n, right)
  s = tostring(s or "")
  if n <= 0 then return "" end
  if #s > n then return n > 1 and (s:sub(1, n-1)..".") or s:sub(1, n) end
  local pad = string.rep(" ", n-#s)
  return right and (pad..s) or (s..pad)
end
local function bar(pct, width, color)
  local filled = math.floor(math.max(0, math.min(100, pct))/100*width + 0.5)
  return seg(string.rep(" ", filled), colors.white, color or colors.green, "#"),
         seg(string.rep(" ", width-filled), colors.white, colors.gray, ".")
end
local function heading(t, w) return {seg(("- "..t.." "..string.rep("-", w)):sub(1, w), colors.white)} end
local function blank() return {seg("")} end
local function textRow(t, fg) return {seg(t, fg)} end

local function requestRow(e, w)
  local st = stateStyle[e.state] or {colors.white, e.state}
  local wTarget = w >= 40 and math.min(14, math.floor(w*0.2)) or 0
  local wNote = w >= 60 and math.floor(w*0.3) or 0
  local wItem = w - 8 - 6 - wTarget - wNote
  local labelColor = e.old and colors.red or colors.white
  local row = {
    seg(fit(st[2], 8), st[1]),
    seg(fit(tostring(e.count), 5, true).." ", colors.lightGray),
    seg(fit(e.label..(e.old and (" ("..fmtAge(e.age)..")") or ""), wItem), labelColor),
  }
  if wTarget > 0 then row[#row+1] = seg(fit(e.target, wTarget), colors.gray) end
  if wNote > 0 then row[#row+1] = seg(fit(" "..(e.note or ""), wNote), colors.lightGray) end
  return row
end
local function buildBarRow(e, w)
  local pctText = (e.approx and "ca." or "")..e.pct.."%"
  if not e.claimed then return {seg(fit(e.name, w-20), colors.white), seg(fit("wartet auf Builder", 20, true), colors.gray)} end
  local wName = math.min(math.max(8, math.floor(w*0.35)), 22)
  local wBar = math.max(5, w - wName - 8)
  local f, r = bar(e.pct, wBar, e.missing > 0 and colors.orange or colors.green)
  return {seg(fit(e.name, wName)), f, r, seg(fit(pctText, 8, true), e.approx and colors.lightGray or colors.white)}
end

local function colonyLine(w)
  local col = S.colony or {}
  local parts = {}
  if col.happy then parts[#parts+1] = string.format("Zufr %.1f", col.happy) end
  if col.cit then parts[#parts+1] = "Buerger "..col.cit..(col.lim and ("/"..col.lim) or "") end
  if col.graves then parts[#parts+1] = "Graeber "..col.graves end
  if col.sites then parts[#parts+1] = "Bau "..col.sites end
  local alarm = col.attack or col.raid
  local fg = alarm and colors.red or (col.happy and col.happy < cfg.chatHappinessBelow and colors.orange or colors.white)
  return {seg(fit("Kolonie", 9), colors.lightGray), seg(table.concat(parts, "  "), fg)}
end
local function meLine(w)
  local me = S.me or {}
  local row = {seg(fit("ME", 9), colors.lightGray)}
  if not S.online then row[#row+1] = seg(S.meStatus, colors.red); return row end
  local function pctSeg(label, v, bad)
    if not v then return seg("") end
    return seg(string.format("%s %d%%  ", label, math.floor(v)), bad and colors.red or colors.white)
  end
  row[#row+1] = pctSeg("Speicher", me.storagePct, cfg.storageWarnPercent > 0 and me.storagePct and me.storagePct >= cfg.storageWarnPercent)
  row[#row+1] = pctSeg("Energie", me.energyPct, cfg.energyWarnPercent > 0 and me.energyPct and me.energyPct <= cfg.energyWarnPercent)
  if type(me.usage) == "number" and type(me.input) == "number" then
    row[#row+1] = seg(string.format("%d/%d AE/t", math.floor(me.usage), math.floor(me.input)),
      me.usage > me.input and colors.orange or colors.lightGray)
  end
  return row
end
local function todayLine()
  local s = statsToday()
  local missing = 0
  for _, e in ipairs(S.requests) do if e.state == "FEHLT" or e.state == "FEHLER" then missing = missing + 1 end end
  return {seg(fit("Heute", 9), colors.lightGray), seg(s.sent.." geliefert  ", colors.lime),
    seg(s.crafts.." Crafts  ", colors.green), seg(missing.." Probleme", missing > 0 and colors.orange or colors.lightGray)}
end

-- Besucher anwerben: Kosten in eine Kiste legen (zweimal tippen)
local recruitArm, recruitMsg = nil, nil
local updateArm = nil         -- Zeitpunkt, bis zu dem der zweite Tipp das Update startet
local updateTap, updateCheckNow, runPendingUpdate   -- werden weiter unten gesetzt
local function recruitTap(v)
  if recruitArm and recruitArm.name == v.name and now() < recruitArm.untilT then
    recruitArm = nil
    local filter = {name=v.costItem, count=v.costCount, nbtHash=v.costHash or ""}
    local ok, moved, err = pcall(bridge.exportItem, cfg.recruitSide, filter)
    if ok and type(moved) == "number" and moved > 0 then
      recruitMsg = {t=now(), color=colors.lime, text=moved.."x "..v.costName.." fuer "..v.name.." in die Kiste gelegt"}
      logLine("[RECRUIT] "..v.name.." "..moved.."x "..tostring(v.costItem))
    else
      local reason = (not ok) and tostring(moved) or tostring(err or "Kiste voll?")
      if reason == "INVENTORY_NOT_FOUND" then reason = "keine Kiste bei "..cfg.recruitSide end
      recruitMsg = {t=now(), color=colors.red, text="Ausgabe fehlgeschlagen: "..reason}
    end
  else
    recruitArm = {name=v.name, untilT=now() + 8000}
  end
end

local renderers = {}
local gotoTab   -- wird weiter unten gesetzt (setTab)
local raidMode = false
local function bannerRow(w)
  if buildBanner and now() - buildBanner.t < 600000 then
    local t = " * "..buildBanner.text.." * "
    local pad = math.max(0, math.floor((w - #t) / 2))
    local row = {seg(string.rep(" ", pad)..t..string.rep(" ", math.max(0, w - pad - #t)), colors.black, colors.lime)}
    row.action = function() buildBanner = nil end
    return row
  end
end
local function etaText(e) return e.eta and ("fertig in ca. "..fmtAge(e.eta)) or nil end

-- ---------- Kacheln ----------
do -- kacheln
local function fitSegs(segs, width)
  local out, used = {}, 0
  for _, sg in ipairs(segs) do
    if used >= width then break end
    local t = sg.t:sub(1, width - used)
    out[#out+1] = seg(t, sg.fg, sg.bg, sg.alt); used = used + #t
  end
  if used < width then out[#out+1] = seg(string.rep(" ", width - used)) end
  return out
end
local tileColor = {ok=colors.green, warn=colors.yellow, bad=colors.red, info=colors.lightBlue}
local function tileRows(w, tiles, cols)
  local rows, gap = {}, 1
  local tw = math.floor((w - gap*(cols-1)) / cols)
  for i = 1, #tiles, cols do
    local group = {}
    for j = i, math.min(i+cols-1, #tiles) do group[#group+1] = tiles[j] end
    local height = 0
    for _, t in ipairs(group) do height = math.max(height, #t.lines) end
    for line = 0, height do   -- 0 = Titelzeile
      local row, acts, x = {}, {}, 1
      for gi, t in ipairs(group) do
        local segs
        if line == 0 then
          local bg = tileColor[t.state or "info"]
          local badge = t.badge and (t.badge.." ") or ""
          segs = {seg(fit(" "..t.title, tw - #badge), colors.black, bg), seg(badge, colors.black, bg)}
        else
          segs = {seg(" ")}
          for _, s2 in ipairs(t.lines[line] or {}) do segs[#segs+1] = s2 end
        end
        for _, s2 in ipairs(fitSegs(segs, tw)) do row[#row+1] = s2 end
        if t.tab then acts[#acts+1] = {from=x, to=x+tw-1, tab=t.tab} end
        x = x + tw
        if gi < #group then row[#row+1] = seg(string.rep(" ", gap)); x = x + gap end
      end
      row.actionAt = function(v, px)
        for _, a in ipairs(acts) do if px >= a.from and px <= a.to then gotoTab(v, a.tab); return true end end
      end
      rows[#rows+1] = row
    end
    rows[#rows+1] = blank()
  end
  return rows
end
-- kleiner Balken mit Prozent: "######....  93%"
local function miniBar(pct, width, color)
  local f, r = bar(pct or 0, math.max(1, width - 5), color)
  return f, r, seg(fit(pct and (math.floor(pct).."%") or "-", 5, true), colors.white)
end
local function dashboardTiles(w, tw)
  local tiles = {}
  local col = S.colony or {}
  -- Kolonie
  local vis, canRecruit = #S.visitors, 0
  for _, v in ipairs(S.visitors) do if v.enough then canRecruit = canRecruit + 1 end end
  local happyBad = col.happy and col.happy < cfg.chatHappinessBelow
  tiles[#tiles+1] = {title="KOLONIE", tab="kolonie",
    state=(col.attack or col.raid) and "bad" or (happyBad and "warn" or "ok"),
    badge=(col.raid and "RAID!") or (col.attack and "ANGRIFF!") or nil,
    lines={
      {seg(asc(col.name or "?"), colors.yellow)},
      {seg("Zufriedenheit ", colors.lightGray), seg(col.happy and string.format("%.1f", col.happy) or "-", happyBad and colors.orange or colors.lime)},
      {seg("Buerger ", colors.lightGray), seg((col.cit or "?")..(col.lim and ("/"..col.lim) or "")), seg("  Graeber ", colors.lightGray), seg(tostring(col.graves or 0))},
      {seg("Besucher ", colors.lightGray), seg(tostring(vis)), seg(canRecruit > 0 and ("  "..canRecruit.." anwerbbar") or "", colors.lime)},
    }}
  -- ME
  local me = S.me or {}
  local full = cfg.storageWarnPercent > 0 and me.storagePct and me.storagePct >= cfg.storageWarnPercent
  local low = cfg.energyWarnPercent > 0 and me.energyPct and me.energyPct <= cfg.energyWarnPercent
  local barW = tw - 1 - 10
  local meLines
  if S.online then
    meLines = {
      {seg(fit("Speicher", 10), colors.lightGray), miniBar(me.storagePct, barW, full and colors.red or colors.cyan)},
      {seg(fit("Energie", 10), colors.lightGray), miniBar(me.energyPct, barW, low and colors.red or colors.yellow)},
      {seg(fit("Verbrauch", 10), colors.lightGray), seg(type(me.usage) == "number" and string.format("%d/%d AE/t", math.floor(me.usage), math.floor(me.input or 0)) or "-",
        (type(me.usage) == "number" and type(me.input) == "number" and me.usage > me.input) and colors.orange or colors.white)},
    }
    local wh = S.warehouse
    if wh and not wh.missing then
      local whFull = cfg.warehouseWarnPercent > 0 and wh.pct >= cfg.warehouseWarnPercent
      meLines[#meLines+1] = {seg(fit("Lager", 10), colors.lightGray), miniBar(wh.pct, barW, whFull and colors.red or colors.brown)}
      if whFull then full = true end
    end
  else
    meLines = {{seg(S.meStatus or "offline", colors.red)}, {seg("Keine Lieferungen moeglich", colors.lightGray)}}
  end
  tiles[#tiles+1] = {title="ME-NETZ", tab="stats", state=(not S.online or full or low) and "bad" or "ok", lines=meLines,
    badge=not S.online and "OFFLINE" or nil}
  -- Heute
  local st = statsToday()
  local probs, open = 0, 0
  for _, e in ipairs(S.requests) do
    if e.state == "FEHLT" or e.state == "FEHLER" or e.state == "MANUELL" then probs = probs + 1 end
    if e.state ~= "OK" and e.state ~= "SKIP" then open = open + 1 end
  end
  tiles[#tiles+1] = {title="HEUTE", tab="anfragen", state=probs > 0 and "warn" or "ok",
    lines={
      {seg(fit(tostring(st.sent), 7, true), colors.lime), seg(" Items geliefert")},
      {seg(fit(tostring(st.crafts), 7, true), colors.green), seg(" Crafts gestartet")},
      {seg(fit(tostring(open), 7, true), colors.white), seg(" Anfragen offen")},
      {seg(fit(tostring(probs), 7, true), probs > 0 and colors.orange or colors.lightGray), seg(" brauchen dich", probs > 0 and colors.orange or colors.white)},
    }}
  -- Baustellen
  local bLines, missing = {}, false
  for i, e in ipairs(S.builds) do
    if e.missing > 0 then missing = true end
    if i <= 3 then
      local nw = math.min(12, math.floor((tw - 2) * 0.45))
      if e.claimed then
        bLines[#bLines+1] = {seg(fit(e.name, nw)), seg(" "), miniBar(e.pct, tw - 2 - nw, e.missing > 0 and colors.orange or colors.green)}
        if e.eta and i == 1 and #S.builds <= 2 then bLines[#bLines+1] = {seg("  "..etaText(e), colors.lightGray)} end
      else
        bLines[#bLines+1] = {seg(fit(e.name, nw)), seg(" wartet auf Builder", colors.gray)}
      end
    end
  end
  if #S.builds > 3 then bLines[#bLines+1] = {seg("+"..(#S.builds - 3).." weitere", colors.gray)} end
  if #S.builds == 0 then bLines[1] = {seg("Keine Bauauftraege", colors.lime)} end
  tiles[#tiles+1] = {title="BAUSTELLEN", tab="bau", state=missing and "warn" or (#S.builds > 0 and "info" or "ok"),
    badge=#S.builds > 0 and tostring(#S.builds) or nil, lines=bLines}
  -- Crafts
  local cLines, stuck, running = {}, 0, {}
  for _, c in ipairs(crafts) do
    if c.state == "FEHLER" or (c.stuck and c.state == "LAEUFT") then stuck = stuck + 1 end
    if c.state == "LAEUFT" or c.state == "START" then running[#running+1] = c end
  end
  local cpuWarn = false
  if S.cpus then
    local free = 0; for _, c in ipairs(S.cpus) do if not c.busy then free = free + 1 end end
    cpuWarn = S.freeCpus ~= nil and free <= cfg.craftReserveCpus
    local r = {seg(fit("CPUs", 6), colors.lightGray)}
    for i, c in ipairs(S.cpus) do if i <= tw - 18 then r[#r+1] = seg(" ", colors.white, c.busy and colors.orange or colors.green, c.busy and "#" or ".") end end
    r[#r+1] = seg(" "..free.."/"..#S.cpus.." frei", free > 0 and colors.white or colors.orange)
    cLines[#cLines+1] = r
  end
  for i = 1, math.min(2, #running) do
    local c = running[i]
    cLines[#cLines+1] = {seg(fit(c.label, tw - 8)), seg(fit(c.pct and (c.pct.."%") or "...", 6, true), colors.lightGray)}
  end
  if #running == 0 then cLines[#cLines+1] = {seg("keine laufenden Crafts", colors.gray)} end
  if stuck > 0 then cLines[#cLines+1] = {seg(stuck.." haengt / fehlgeschlagen", colors.red)} end
  tiles[#tiles+1] = {title="CRAFTS", tab="crafts", state=stuck > 0 and "bad" or (cpuWarn and "warn" or "ok"),
    badge=#running > 0 and tostring(#running) or nil, lines=cLines}
  -- Buerger
  local sick, hungry, homeless = 0, 0, 0
  for _, ct in ipairs(S.citizens) do
    if ct.severity >= 3 then sick = sick + 1 end
    if ct.issues:find("hungrig", 1, true) then hungry = hungry + 1 end
    if ct.issues:find("kein Zuhause", 1, true) then homeless = homeless + 1 end
  end
  local cz = {}
  if #S.citizens == 0 then cz[1] = {seg("Alle in Ordnung", colors.lime)}
  else
    cz[#cz+1] = {seg(fit(tostring(#S.citizens), 4, true), colors.yellow), seg(" mit Problemen")}
    if sick > 0 then cz[#cz+1] = {seg(fit(tostring(sick), 4, true), colors.red), seg(" krank/verletzt")} end
    if hungry > 0 then cz[#cz+1] = {seg(fit(tostring(hungry), 4, true), colors.orange), seg(" hungrig")} end
    if homeless > 0 then cz[#cz+1] = {seg(fit(tostring(homeless), 4, true), colors.orange), seg(" ohne Zuhause")} end
  end
  local foodLow = false
  if S.food then
    local f = S.food
    foodLow = cfg.foodWarnHours > 0 and f.etaH and f.etaH < cfg.foodWarnHours
    cz[#cz+1] = {seg("Essen ", colors.lightGray), seg(tostring(f.count), foodLow and colors.red or colors.white),
      seg(f.etaH and ("  ~"..fmtAge(f.etaH * 3600000)) or "  stabil", foodLow and colors.red or colors.lightGray)}
  end
  tiles[#tiles+1] = {title="BUERGER", tab="buerger", state=(sick > 0 or foodLow) and "bad" or (#S.citizens > 0 and "warn" or "ok"), lines=cz}
  return tiles
end

function renderers.start(w, v)
  if cfg.dashboardMinWidth > 0 and w >= cfg.dashboardMinWidth then
    local rows = {}
    local cols = w >= 100 and 3 or (w >= 60 and 3 or 2)
    local tw = math.floor((w - (cols - 1)) / cols)
    if updateInfo then
      local vv = updateInfo:match("^[%d%.]+") or updateInfo
      local armed = updateArm and now() < updateArm
      local btn = armed and (updateWaiting and "[ Trotzdem? Nochmal! ]" or "[ Nochmal tippen! ]")
        or (updateWaiting and "[ Wartet auf Crafts ]" or "[ Jetzt updaten ]")
      local row = {seg(fit("Update "..vv.." verfuegbar", math.max(0, w - #btn - 1)), colors.yellow),
        seg(" "), seg(btn, colors.black, armed and colors.orange or colors.yellow)}
      row.action = function() updateTap() end
      rows[#rows+1] = row
    end
    if updateMsg and (updateMsg.t == math.huge or now() - updateMsg.t < 60000) then rows[#rows+1] = textRow(fit(updateMsg.text, w), updateMsg.color) end
    local bn = bannerRow(w); if bn then rows[#rows+1] = bn end
    for _, r in ipairs(tileRows(w, dashboardTiles(w, tw), cols)) do rows[#rows+1] = r end
    for _, a in ipairs(S.alerts) do rows[#rows+1] = textRow(fit("! "..a, w), colors.red) end
    for _, e in ipairs(S.errors) do rows[#rows+1] = textRow(fit("x "..e, w), colors.red) end
    local problems = {}
    for _, e in ipairs(S.requests) do
      if e.state == "FEHLT" or e.state == "MANUELL" or e.state == "FEHLER" or e.old then problems[#problems+1] = e end
    end
    table.sort(problems, function(a, b) return (stateRank[a.state] or 9) < (stateRank[b.state] or 9) end)
    if #problems > 0 then
      rows[#rows+1] = heading("Braucht dich", w)
      for _, e in ipairs(problems) do rows[#rows+1] = requestRow(e, w) end
    end
    return rows
  end
  local rows = {}
  -- Pocket-Code nur am Computer-Bildschirm (nicht auf Monitoren, die jeder sieht)
  if v and not v.isMon and cfg.pocketEnabled and cfg.pocketCode ~= "" then
    rows[#rows+1] = textRow(fit("Pocket-Code: "..cfg.pocketCode.."  (am Pocket: Reiter Ctl)", w), colors.cyan)
  end
  local bn = bannerRow(w); if bn then rows[#rows+1] = bn end
  if cfg.showColonyStatus then rows[#rows+1] = colonyLine(w) end
  rows[#rows+1] = meLine(w)
  rows[#rows+1] = todayLine()
  local any = false
  if updateInfo then
    local v = updateInfo:match("^[%d%.]+") or updateInfo
    local armed = updateArm and now() < updateArm
    local btn = armed and (updateWaiting and "[ Trotzdem? Nochmal! ]" or "[ Nochmal tippen! ]")
      or (updateWaiting and "[ Wartet auf Crafts ]" or "[ Jetzt updaten ]")
    local row = {seg(fit("Update "..v.." verfuegbar", math.max(0, w - #btn - 1)), colors.yellow),
      seg(" "), seg(btn, colors.black, armed and colors.orange or colors.yellow)}
    row.action = function() updateTap() end
    rows[#rows+1] = row
  end
  if updateMsg and (updateMsg.t == math.huge or now() - updateMsg.t < 60000) then rows[#rows+1] = textRow(fit(updateMsg.text, w), updateMsg.color) end
  if #S.alerts > 0 or #S.errors > 0 then
    rows[#rows+1] = heading("Achtung", w)
    for _, a in ipairs(S.alerts) do rows[#rows+1] = textRow("! "..a, colors.red) end
    for _, e in ipairs(S.errors) do rows[#rows+1] = textRow("x "..e, colors.red) end
    any = true
  end
  local problems = {}
  for _, e in ipairs(S.requests) do
    if e.state == "FEHLT" or e.state == "MANUELL" or e.state == "FEHLER" or e.old then problems[#problems+1] = e end
  end
  table.sort(problems, function(a, b) return (stateRank[a.state] or 9) < (stateRank[b.state] or 9) end)
  if #problems > 0 then
    rows[#rows+1] = heading("Braucht dich", w)
    for _, e in ipairs(problems) do rows[#rows+1] = requestRow(e, w) end
    any = true
  end
  if #S.builds > 0 then
    rows[#rows+1] = heading("Baustellen", w)
    for _, e in ipairs(S.builds) do rows[#rows+1] = buildBarRow(e, w) end
    any = true
  end
  if #S.citizens > 0 then
    local sev = 0; for _, ct in ipairs(S.citizens) do if ct.severity >= 3 then sev = sev + 1 end end
    rows[#rows+1] = textRow(string.format("Buerger: %d mit Problemen%s", #S.citizens, sev > 0 and (", "..sev.." krank/verletzt") or ""),
      sev > 0 and colors.orange or colors.yellow)
  end
  if not any then rows[#rows+1] = blank(); rows[#rows+1] = textRow("Alles erledigt.", colors.lime) end

  return rows
end
end -- kacheln
function renderers.anfragen(w)
  local rows = {}
  local list = {}
  for _, e in ipairs(S.requests) do list[#list+1] = e end
  table.sort(list, function(a, b)
    local ra, rb = stateRank[a.state] or 9, stateRank[b.state] or 9
    if ra ~= rb then return ra < rb end
    return a.label < b.label
  end)
  local counts = {}
  for _, e in ipairs(list) do counts[e.state] = (counts[e.state] or 0) + 1 end
  local summary = {seg(#list.." Anfragen  ", colors.white)}
  for _, k in ipairs({"FEHLER","FEHLT","MANUELL","CRAFT","LAEUFT","OK","WARTET","SKIP"}) do
    if counts[k] then summary[#summary+1] = seg(counts[k].." "..stateStyle[k][2]:lower().."  ", stateStyle[k][1]) end
  end
  rows[#rows+1] = summary
  if #list == 0 then rows[#rows+1] = blank(); rows[#rows+1] = textRow("Keine offenen Anfragen.", colors.lime); return rows end
  local hdr = {seg(fit("Status", 8), colors.gray), seg(fit("Menge", 5, true).." ", colors.gray)}
  local wTarget = w >= 40 and math.min(14, math.floor(w*0.2)) or 0
  local wNote = w >= 60 and math.floor(w*0.3) or 0
  hdr[#hdr+1] = seg(fit("Item", w-14-wTarget-wNote), colors.gray)
  if wTarget > 0 then hdr[#hdr+1] = seg(fit("Ziel", wTarget), colors.gray) end
  if wNote > 0 then hdr[#hdr+1] = seg(fit(" Info", wNote), colors.gray) end
  rows[#rows+1] = hdr
  for _, e in ipairs(list) do rows[#rows+1] = requestRow(e, w) end
  return rows
end
do -- bauUI
local function builderRows(w)
  local rows = {}
  local builders = {}
  for _, b in ipairs(S.mapBuildings) do
    if b.type:lower():gsub("^.*[:/]", "") == "builder" then builders[#builders+1] = {b=b, orders={}} end
  end
  if #builders == 0 then return rows end
  local byPos = {}
  for _, bl in ipairs(builders) do byPos[bl.b.key] = bl end
  local waiting = {}
  for _, e in ipairs(S.builds) do
    if e.claimed and e.builderPos and byPos[e.builderPos] then table.insert(byPos[e.builderPos].orders, e)
    elseif not e.claimed then waiting[#waiting+1] = e end
  end
  rows[#rows+1] = heading("Builder ("..#builders..")", w)
  local free = {}
  for i, bl in ipairs(builders) do
    local b = bl.b
    local label = fit("  "..b.name.." "..i.." (Lvl "..b.level..")", math.min(24, math.floor(w*0.45)))
    if b.residents == 0 then
      rows[#rows+1] = {seg(label), seg("kein Arbeiter zugewiesen", colors.orange)}
    elseif #bl.orders == 0 then
      free[#free+1] = b
      rows[#rows+1] = {seg(label), seg("frei", colors.lime)}
    else
      local e = bl.orders[1]
      local txt = e.name.." "..(e.approx and "ca." or "")..e.pct.."%"..(e.eta and (", ~"..fmtAge(e.eta)) or "")
      rows[#rows+1] = {seg(label), seg(fit(txt, w - #label), colors.lightBlue)}
    end
  end
  for _, e in ipairs(waiting) do
    local warn = e.wait >= 600000
    rows[#rows+1] = {seg(fit("  wartet: "..e.name.." Lvl "..e.targetLevel, math.min(30, math.floor(w*0.6))), warn and colors.orange or colors.white),
      seg(" seit "..fmtAge(e.wait), warn and colors.orange or colors.gray)}
  end
  if #waiting > 0 then
    local best
    for _, b in ipairs(free) do if not best or b.level > best.level then best = b end end
    local need = 0
    for _, e in ipairs(waiting) do need = math.max(need, e.targetLevel) end
    if best and best.level >= need then
      rows[#rows+1] = textRow(fit("  Tipp: Builder frei - Auftrag in der Huette zuweisen", w), colors.yellow)
    elseif best then
      rows[#rows+1] = textRow(fit("  Tipp: freier Builder hat Stufe "..best.level..", Auftrag braucht "..need, w), colors.yellow)
    elseif #free == 0 then
      rows[#rows+1] = textRow(fit("  Alle Builder beschaeftigt", w), colors.gray)
    end
  end
  return rows
end

function renderers.bau(w)
  local rows = {}
  local bn = bannerRow(w); if bn then rows[#rows+1] = bn end
  for _, r in ipairs(builderRows(w)) do rows[#rows+1] = r end
  if #S.builds == 0 then rows[#rows+1] = textRow("Keine Bauauftraege.", colors.lime); return rows end
  rows[#rows+1] = heading("Auftraege", w)
  for i, e in ipairs(S.builds) do
    if i > 1 then rows[#rows+1] = blank() end
    local lvl = e.targetLevel > 0 and (" Lvl "..e.level.."->"..e.targetLevel) or ""
    rows[#rows+1] = {seg(e.name..lvl, colors.yellow),
      seg(e.stage and ("  ["..e.stage.."]") or "", colors.lightGray),
      seg(e.builder and ("  "..e.builder) or "", colors.gray)}
    rows[#rows+1] = buildBarRow({name="Fortschritt", pct=e.pct, approx=e.approx, claimed=e.claimed, missing=e.missing}, w)
    if e.claimed then
      rows[#rows+1] = textRow(fit("  "..(etaText(e) or "Restzeit: wird nach ein paar Minuten geschaetzt"), w), e.eta and colors.lightBlue or colors.gray)
    end
    if e.claimed then
      if #e.res == 0 then
        rows[#rows+1] = textRow("  Material komplett beim Builder", colors.lime)
      else
        for _, r in ipairs(e.res) do
          local st = stateStyle[r.state] or {colors.white, r.state}
          local wNote = w >= 45 and math.floor(w*0.35) or 0
          local row = {seg("  "), seg(fit(st[2], 8), st[1]), seg(fit(tostring(r.count), 5, true).." ", colors.lightGray),
            seg(fit(r.label, w-16-wNote))}
          if wNote > 0 then row[#row+1] = seg(fit(" "..r.note, wNote), colors.lightGray) end
          rows[#rows+1] = row
        end
      end
    end
  end
  if S.me and S.online == false then rows[#rows+1] = textRow("ME offline - keine Vorlieferung", colors.red) end
  return rows
end
end -- bauUI
do -- buergerUI
local citizenSel = nil   -- id des angetippten Buergers
function renderers.buerger(w)
  local rows = {}
  local f = S.food
  local head = {seg(string.format("%d Buerger, %d mit Problemen", S.citizenCount, #S.citizens), colors.white)}
  if f then
    local low = cfg.foodWarnHours > 0 and f.etaH and f.etaH < cfg.foodWarnHours
    head[#head+1] = seg("   Essen im ME: "..f.count, low and colors.red or colors.lightGray)
    head[#head+1] = seg(f.etaH and (" (~"..fmtAge(f.etaH * 3600000)..")") or " (stabil)", low and colors.red or colors.gray)
  end
  rows[#rows+1] = head
  if f and f.avgSat then rows[#rows+1] = textRow(string.format("Durchschnittliche Saettigung %.1f/20", f.avgSat), f.avgSat < cfg.citizenHungerBelow * 2 and colors.orange or colors.gray) end

  -- Steckbrief
  local sel
  for _, c in ipairs(S.allCitizens) do if c.id == citizenSel then sel = c end end
  if sel then
    local r1 = {seg(fit(sel.name.."  -  "..sel.job, w - 4), colors.yellow), seg("[x]", colors.red)}
    r1.action = function() citizenSel = nil end
    rows[#rows+1] = heading("Steckbrief", w)
    rows[#rows+1] = r1
    local hp = sel.health and sel.maxHealth and string.format("%d/%d", math.floor(sel.health), math.floor(sel.maxHealth)) or "-"
    rows[#rows+1] = {seg("Zufr ", colors.lightGray), seg(sel.happy and string.format("%.1f", sel.happy) or "-"),
      seg("  Saett ", colors.lightGray), seg(sel.sat and string.format("%.0f/20", sel.sat) or "-"),
      seg("  HP ", colors.lightGray), seg(hp), seg("  Ruest ", colors.lightGray), seg(sel.armor and tostring(math.floor(sel.armor)) or "-")}
    if sel.state then rows[#rows+1] = {seg("Status ", colors.lightGray), seg(fit(sel.state, w - 7))} end
    rows[#rows+1] = {seg("Wohnt ", colors.lightGray), seg(fit(sel.home or "-", math.floor((w-12)/2))), seg(" Arbeit ", colors.lightGray), seg(fit(sel.work or "-", math.floor((w-12)/2)))}
    if type(sel.pos) == "table" and sel.pos.x then rows[#rows+1] = {seg("Ort ", colors.lightGray), seg(formatPos(sel.pos))} end
    -- Skills, beste zuerst, zwei Spalten
    local sk = {}
    for k, v in pairs(sel.skills) do sk[#sk+1] = {k=k, v=v} end
    table.sort(sk, function(a, b) if a.v ~= b.v then return a.v > b.v end return a.k < b.k end)
    local colW = math.floor(w / 2)
    for i = 1, #sk, 2 do
      local r = {}
      for j = i, math.min(i + 1, #sk) do
        r[#r+1] = seg(fit("  "..(skillDe[sk[j].k] or sk[j].k), colW - 4), colors.lightGray)
        r[#r+1] = seg(fit(tostring(sk[j].v), 4, true), sk[j].v >= 20 and colors.lime or colors.white)
      end
      rows[#rows+1] = r
    end
    -- Job-Berater
    local adv = jobAdvice(sel, 2)
    if not sel.isChild and #adv > 0 then
      local cur = sel.jobId and jobScore(sel, sel.jobId)
      if cur and adv[1].id ~= sel.jobId and adv[1].score >= cur * 1.3 + 2 then
        rows[#rows+1] = textRow(fit("Besser geeignet: "..jobName(adv[1].id).." ("..skillText(sel, adv[1].id)..")", w), colors.orange)
      elseif cur then
        rows[#rows+1] = textRow(fit("Passt gut zum Job ("..skillText(sel, sel.jobId)..")", w), colors.lime)
      else
        rows[#rows+1] = textRow(fit("Vorschlag: "..jobName(adv[1].id).." ("..skillText(sel, adv[1].id)..")", w), colors.lightBlue)
      end
    end
  end

  -- Arbeitslose mit Job-Vorschlag
  local idle = {}
  for _, c in ipairs(S.allCitizens) do if not c.jobId and not c.isChild then idle[#idle+1] = c end end
  if #idle > 0 then
    rows[#rows+1] = heading("Arbeitslos - Job-Vorschlag ("..#idle..")", w)
    for _, c in ipairs(idle) do
      local adv = jobAdvice(c, 2)
      local txt = #adv > 0 and (jobName(adv[1].id)..(adv[2] and (" / "..jobName(adv[2].id)) or "")) or "-"
      local r = {seg(fit(c.name, math.min(18, math.floor(w*0.35))), colors.white), seg(fit(" "..txt, w - math.min(18, math.floor(w*0.35))), colors.lightBlue)}
      r.action = function() citizenSel = c.id end
      rows[#rows+1] = r
    end
  end

  -- Alle Buerger (Probleme zuerst)
  rows[#rows+1] = heading("Alle Buerger - antippen fuer Steckbrief", w)
  local list = {}
  for _, c in ipairs(S.allCitizens) do list[#list+1] = c end
  table.sort(list, function(a, b) if a.severity ~= b.severity then return a.severity > b.severity end return a.name < b.name end)
  local sevColor = {colors.yellow, colors.orange, colors.red}
  local wName = math.min(18, math.floor(w*0.3))
  local wJob = w >= 50 and 14 or 0
  for _, c in ipairs(list) do
    local r = {seg(fit(c.name, wName), c.id == citizenSel and colors.yellow or colors.white)}
    if wJob > 0 then r[#r+1] = seg(fit(c.job, wJob), colors.gray) end
    r[#r+1] = seg(fit(" "..(c.issues ~= "" and c.issues or "ok"), w - wName - wJob), sevColor[c.severity] or colors.lime)
    r.action = function() citizenSel = c.id end
    rows[#rows+1] = r
  end
  return rows
end
end -- buergerUI
function renderers.kolonie(w)
  local rows = {}
  local col = S.colony or {}
  if col.name then rows[#rows+1] = textRow(asc(col.name), colors.yellow) end
  if cfg.showColonyStatus then rows[#rows+1] = colonyLine(w) end
  rows[#rows+1] = heading("Im Bau ("..#S.buildingsWorking..")", w)
  if #S.buildingsWorking == 0 then rows[#rows+1] = textRow("  -", colors.gray) end
  for _, b in ipairs(S.buildingsWorking) do rows[#rows+1] = textRow("  "..b.name.." (Lvl "..b.level..")", colors.lightBlue) end
  rows[#rows+1] = heading("Ausbau moeglich ("..#S.buildingsUpgrade..")", w)
  if #S.buildingsUpgrade == 0 then rows[#rows+1] = textRow("  alles auf Maximalstufe", colors.lime) end
  for _, b in ipairs(S.buildingsUpgrade) do
    rows[#rows+1] = {seg(fit("  "..b.name, w-14)), seg(fit("Lvl "..b.level.."/"..b.maxLevel, 10, true), colors.lightGray),
      seg(b.built and "" or " *", colors.orange)}
  end
  -- Lager
  local wh = S.warehouse
  rows[#rows+1] = heading("Lager (Warehouse)", w)
  if not wh or wh.missing then
    rows[#rows+1] = textRow(fit("  Kein Zugriff auf das Lager. Entweder Wired Modem am Lager-", w), colors.gray)
    rows[#rows+1] = textRow(fit("  Huettenblock anschliessen oder per Funk: ae2colony_lager", w), colors.gray)
  else
    local whFull = cfg.warehouseWarnPercent > 0 and wh.pct >= cfg.warehouseWarnPercent
    local f, r = bar(wh.pct, math.max(4, w - 24), whFull and colors.red or colors.brown)
    rows[#rows+1] = {seg(fit("  Belegt", 9), colors.lightGray), f, r, seg(fit(math.floor(wh.pct).."%", 5, true)),
      seg(fit(" "..wh.used.."/"..wh.size, 10, true), colors.gray)}
    rows[#rows+1] = {seg("  "..wh.total.." Items in "..(wh.kinds or "?").." Sorten, "..(wh.size - wh.used).." Slots frei", colors.white),
      seg(wh.src == "Funk" and ("  (Funk, vor "..math.floor((wh.age or 0) / 1000).."s)") or "", colors.gray)}
    for i, it in ipairs(wh.top or {}) do
      if i > 5 then break end
      rows[#rows+1] = {seg(fit(tostring(it.n), 9, true).."  ", colors.lightGray), seg(fit(asc(it.label or shortName(it.name)), w - 11))}
    end
  end
  -- Verteidigung
  local unguarded = {}
  for _, b in ipairs(S.mapBuildings) do
    local t = b.type:lower()
    if b.built and not b.guarded and not t:find("guard") and not t:find("barrack") then unguarded[#unguarded+1] = b.name end
  end
  local kinds = {knight=0, ranger=0, druid=0}
  for _, g in ipairs(S.guards) do kinds[g.jobId] = (kinds[g.jobId] or 0) + 1 end
  rows[#rows+1] = heading("Verteidigung", w)
  rows[#rows+1] = {seg("Wachen "..#S.guards, #S.guards > 0 and colors.white or colors.orange),
    seg(string.format("  (Ritter %d, Bogen %d, Druiden %d)", kinds.knight, kinds.ranger, kinds.druid), colors.gray)}
  rows[#rows+1] = {seg("Ungeschuetzt: ", colors.lightGray), seg(#unguarded == 0 and "keine Gebaeude" or (#unguarded.." Gebaeude"), #unguarded > 0 and colors.orange or colors.lime),
    seg(#unguarded > 0 and "  (Karte: Ansicht Verteidigung)" or "", colors.gray)}
  if #unguarded > 0 then rows[#rows+1] = textRow(fit("  "..table.concat(unguarded, ", "), w), colors.orange) end
  for _, g in ipairs(S.guards) do
    local hp = g.health and g.maxHealth and g.maxHealth > 0 and (g.health / g.maxHealth) or nil
    rows[#rows+1] = {seg(fit("  "..g.name, math.min(20, math.floor(w*0.4)))), seg(fit(jobName(g.jobId), 14), colors.gray),
      seg(fit(hp and string.format("HP %d%%", math.floor(hp*100)) or "HP -", 9), hp and hp < 0.5 and colors.red or colors.white),
      seg(g.armor and ("Ruest "..math.floor(g.armor)) or "", (g.armor or 0) < 10 and colors.orange or colors.lightGray)}
  end
  rows[#rows+1] = heading("Besucher in der Taverne ("..#S.visitors..")", w)
  if #S.visitors == 0 then rows[#rows+1] = textRow("  keine", colors.gray) end
  local canRecruit = cfg.recruitSide ~= ""
  if #S.visitors > 0 then
    rows[#rows+1] = textRow(fit(canRecruit and "  Gruen = bezahlbar, 2x tippen = Kosten in Kiste"
      or "  Gruen = bezahlbar (Ausgabe: recruitSide setzen)", w), colors.gray)
  end
  if #S.visitors > 0 then
    if recruitMsg and now() - recruitMsg.t < 15000 then rows[#rows+1] = textRow(fit("  "..recruitMsg.text, w), recruitMsg.color)
    else rows[#rows+1] = blank() end
  end
  for _, v in ipairs(S.visitors) do
    local wName = math.min(18, math.floor(w*0.35))
    local armed = recruitArm and recruitArm.name == v.name and now() < recruitArm.untilT
    local row = {seg(fit("  "..v.name, wName), v.enough and colors.lime or colors.white),
      seg(fit(armed and "Nochmal tippen!" or (v.costCount.."x "..v.costName), w-wName-12), armed and colors.yellow or colors.white),
      seg(fit("ME: "..v.have, 12, true), v.enough and colors.lime or colors.orange)}
    if canRecruit and v.enough then row.action = function() recruitTap(v) end end
    rows[#rows+1] = row
  end
  return rows
end

function renderers.crafts(w)
  local rows = {}
  if S.cpus then
    local busy = #S.cpus - (S.freeCpus or 0)
    local free = 0; for _, c in ipairs(S.cpus) do if not c.busy then free = free + 1 end end
    rows[#rows+1] = {seg(fit("CPUs", 9), colors.lightGray), seg(free.." von "..#S.cpus.." frei", free > cfg.craftReserveCpus and colors.lime or colors.orange),
      seg(S.freeCpus and ("   Reserve fuer Anfragen: "..cfg.craftReserveCpus) or "   (keine CPU-Begrenzung)", colors.gray)}
    if S.cpuDynamic then
      rows[#rows+1] = textRow(fit("  CPUs entstehen pro Auftrag (z.B. Quantum Computer)", w), colors.lightBlue)
    end
    local wBar = math.max(4, math.min(#S.cpus, w - 10))
    if #S.cpus > 0 and wBar >= #S.cpus then
      local r = {seg(fit("", 9))}
      for _, c in ipairs(S.cpus) do r[#r+1] = seg(" ", colors.white, c.busy and colors.orange or colors.green, c.busy and "#" or ".") end
      rows[#rows+1] = r
    end
  else
    rows[#rows+1] = textRow("CPU-Daten nicht verfuegbar", colors.gray)
  end
  local t = now()
  local running, done = {}, {}
  for _, c in ipairs(crafts) do
    if c.state == "START" or c.state == "LAEUFT" then running[#running+1] = c else done[#done+1] = c end
  end
  local wNote = w >= 60 and math.floor(w*0.35) or (w >= 45 and 14 or 0)
  local function craftRow(c)
    local state = c.stuck and c.state == "LAEUFT" and "HAENGT" or c.state
    local st = stateStyle[state] or {colors.white, state}
    local info
    if state == "LAEUFT" or state == "HAENGT" or state == "START" then
      info = (c.pct and (c.pct.."% ") or "")..fmtAge(t - c.t)..(c.cpu and (" "..c.cpu) or "")
    elseif state == "FEHLER" then info = c.note or "fehlgeschlagen"
    else info = "vor "..fmtAge(t - (c.doneAt or t)) end
    local row = {seg(fit(st[2], 8), st[1]), seg(fit(tostring(c.count), 5, true).." ", colors.lightGray),
      seg(fit(c.label, w - 14 - wNote))}
    if wNote > 0 then row[#row+1] = seg(fit(" "..info, wNote), state == "HAENGT" and colors.red or colors.lightGray) end
    return row
  end
  rows[#rows+1] = heading("Vom Skript gestartet ("..#running..")", w)
  if #running == 0 then rows[#rows+1] = textRow("  keine laufenden Crafts", colors.gray) end
  for _, c in ipairs(running) do
    rows[#rows+1] = craftRow(c)
    if c.source ~= "" and w >= 30 then rows[#rows+1] = textRow(fit("         fuer "..c.source, w), colors.gray) end
  end
  local others = {}
  for _, c in ipairs(S.cpus or {}) do if c.busy and not (S.cpuJobs[c.item or ""] or {}).tracked then others[#others+1] = c end end
  if #others > 0 then
    rows[#rows+1] = heading("Andere Crafts im ME ("..#others..")", w)
    for _, c in ipairs(others) do
      rows[#rows+1] = {seg(fit("LAEUFT", 8), colors.green), seg(fit(tostring(c.qty or "?"), 5, true).." ", colors.lightGray),
        seg(fit(c.label or "?", w - 14 - wNote)), seg(fit(wNote > 0 and (" "..(c.pct and (c.pct.."% ") or "")..c.name) or "", wNote), colors.lightGray)}
    end
  end
  if #done > 0 then
    rows[#rows+1] = heading("Zuletzt beendet", w)
    table.sort(done, function(a, b) return (a.doneAt or 0) > (b.doneAt or 0) end)
    for _, c in ipairs(done) do rows[#rows+1] = craftRow(c) end
  end
  return rows
end

-- Balkendiagramm der letzten Stunden. get(bucket) liefert den Wert oder nil.
do -- diagramme
local function chartRows(title, w, get, opts)
  local rows = {}
  local height = opts.height or 5
  local labelW = 5
  local avail = w - labelW - 1
  local bw = avail >= 48 and 2 or 1
  local n = math.min(24, math.floor(avail / bw))
  local k0 = hourKey() - n + 1
  local vals, maxV = {}, opts.max or 0
  for i = 1, n do
    local b = historyDb.h and historyDb.h[k0 + i - 1]
    local v = b and get(b)
    vals[i] = v
    if not opts.max and v and v > maxV then maxV = v end
  end
  if maxV <= 0 then maxV = 1 end
  rows[#rows+1] = heading(title, w)
  local function fmtV(v) if v >= 10000 then return math.floor(v/1000).."k" end return tostring(math.floor(v + 0.5)) end
  for r = height, 1, -1 do
    local yl = r == height and fmtV(maxV) or (r == 1 and "0" or "")
    local row = {seg(fit(yl, labelW, true).." ", colors.gray)}
    local threshold = maxV * (r - 0.5) / height
    for i = 1, n do
      local v = vals[i]
      local filled = v and v >= threshold and v > 0
      local color = filled and (opts.color and opts.color(v) or colors.green) or nil
      row[#row+1] = seg(string.rep(filled and " " or (r == 1 and (v and "_" or ".") or " "), bw),
        colors.gray, color, filled and "#" or nil)
    end
    rows[#rows+1] = row
  end
  -- Zeitachse: alle 6 Stunden eine Beschriftung
  local axis = string.rep(" ", labelW + 1)
  local txt = string.rep(" ", n * bw)
  for i = 1, n do
    local hour = (k0 + i - 1) % 24   -- Schluessel = Stunden seit 1970 in Ortszeit
    if hour % 6 == 0 then
      local pos = (i - 1) * bw + 1
      local label = string.format("%02d", hour)
      if pos + 1 <= #txt then txt = txt:sub(1, pos - 1)..label..txt:sub(pos + 2) end
    end
  end
  rows[#rows+1] = {seg(axis..txt, colors.gray)}
  return rows
end

function renderers.stats(w)
  local rows = {}
  local s = statsToday()
  rows[#rows+1] = {seg("Heute ("..s.day.."): ", colors.lightGray), seg(s.sent.." geliefert, ", colors.lime), seg(s.crafts.." Crafts", colors.green)}
  local function add(list) for _, r in ipairs(list) do rows[#rows+1] = r end end
  add(chartRows("Geliefert pro Stunde (24h)", w, function(b) return b.sent end, {height=5}))
  add(chartRows("ME-Speicher % (24h)", w, function(b) return b.storage end, {height=4, max=100,
    color=function(v) return (cfg.storageWarnPercent > 0 and v >= cfg.storageWarnPercent) and colors.red or colors.cyan end}))
  add(chartRows("Lager-Fuellstand % (24h)", w, function(b) return b.lager end, {height=4, max=100,
    color=function(v) return (cfg.warehouseWarnPercent > 0 and v >= cfg.warehouseWarnPercent) and colors.red or colors.brown end}))
  add(chartRows("Zufriedenheit (24h)", w, function(b) return b.happy end, {height=4, max=10,
    color=function(v) return v < cfg.chatHappinessBelow and colors.orange or colors.lime end}))
  -- Liefer-Statistik
  rows[#rows+1] = heading("Wartezeiten der Anfragen", w)
  if (s.reqN or 0) > 0 then
    rows[#rows+1] = {seg("  Heute "..s.reqN.." erledigt, im Schnitt ", colors.lightGray), seg(fmtAge(s.reqSum / s.reqN), colors.white), seg(" offen", colors.lightGray)}
  else
    rows[#rows+1] = textRow("  heute noch keine erledigten Anfragen", colors.gray)
  end
  local rt = {}
  for label, e in pairs(s.reqTimes or {}) do rt[#rt+1] = {label=label, avg=e.sum / e.n, n=e.n, max=e.max} end
  if #rt > 0 then
    table.sort(rt, function(a, b) return a.avg > b.avg end)
    rows[#rows+1] = textRow("  Am langsamsten (Schnitt / max / Anzahl):", colors.lightGray)
    for i = 1, math.min(5, #rt) do
      local e = rt[i]
      rows[#rows+1] = {seg(fit("    "..e.label, w - 22)), seg(fit(fmtAge(e.avg), 7, true), e.avg >= 600000 and colors.orange or colors.white),
        seg(fit(fmtAge(e.max), 7, true), colors.gray), seg(fit(e.n.."x", 6, true), colors.gray)}
    end
    table.sort(rt, function(a, b) return a.n > b.n end)
    rows[#rows+1] = textRow("  Am haeufigsten angefragt:", colors.lightGray)
    for i = 1, math.min(5, #rt) do
      rows[#rows+1] = {seg(fit("    "..rt[i].label, w - 8)), seg(fit(rt[i].n.."x", 6, true), colors.lime)}
    end
  end
  rows[#rows+1] = heading("Meistgeliefert (gesamt)", w)
  local items = {}
  for name, e in pairs(s.items or {}) do items[#items+1] = {name=name, n=e.n, label=e.label} end
  table.sort(items, function(a, b) return a.n > b.n end)
  if #items == 0 then rows[#rows+1] = textRow("  noch nichts geliefert", colors.gray) end
  for i = 1, math.min(cfg.statsShowTop, #items) do
    rows[#rows+1] = {seg(fit(items[i].n.."x", 8, true).."  ", colors.lime), seg(fit(asc(items[i].label or shortName(items[i].name)), w-10))}
  end
  if cfg.trackMissingPatterns then
    rows[#rows+1] = heading("Fehlende Patterns (haeufigste zuerst)", w)
    local list = {}
    for name, e in pairs(missingDb) do list[#list+1] = {name=name, e=e} end
    table.sort(list, function(a, b) return a.e.count > b.e.count end)
    if #list == 0 then rows[#rows+1] = textRow("  keine", colors.lime) end
    for i = 1, math.min(cfg.missingPatternShowTop, #list) do
      rows[#rows+1] = {seg(fit(list[i].e.count.."x", 8, true).."  ", colors.pink),
        seg(fit(asc(list[i].e.display or shortName(list[i].name)), w-10))}
    end
  end
  return rows
end
end -- diagramme

-- ---------- Zu tun ----------
function renderers.todo(w)
  local rows = {}
  -- 1) selbst craften / besorgen
  local need, order = {}, {}
  local function add(label, count, reason, source)
    local e = need[label]
    if not e then e = {label=label, count=0, reasons={}, sources={}}; need[label] = e; order[#order+1] = e end
    e.count = e.count + (count or 0)
    if reason and reason ~= "" then e.reasons[reason] = true end
    if source and source ~= "" then e.sources[source] = true end
  end
  local function reasonOf(note)
    note = note or ""
    if note:find("Pattern") then return "kein Pattern" end
    if note:find("Cutter") then return "Architect's Cutter" end
    if note:find("Stufenlimit") then return "ueber Stufenlimit" end
    if note:find("Zutaten") then return "Zutaten fehlen" end
    return "fehlt"
  end
  for _, e in ipairs(S.requests) do
    if e.state == "FEHLT" or e.state == "MANUELL" then add(e.label, e.count, reasonOf(e.note), e.target) end
  end
  for _, b in ipairs(S.builds) do
    for _, r in ipairs(b.res) do if r.state == "FEHLT" then add(r.label, r.count, reasonOf(r.note), "Bau "..b.name) end end
  end
  for _, c in ipairs(crafts) do if c.state == "FEHLER" then add(c.label, c.count, "Zutaten fehlen", c.source) end end
  rows[#rows+1] = heading("Selbst craften / besorgen ("..#order..")", w)
  if #order == 0 then rows[#rows+1] = textRow("  Nichts - alles laeuft automatisch.", colors.lime) end
  local wR = w >= 60 and 20 or 14
  for _, e in ipairs(order) do
    local reasons, sources = {}, {}
    for r in pairs(e.reasons) do reasons[#reasons+1] = r end
    for x in pairs(e.sources) do sources[#sources+1] = x end
    table.sort(reasons); table.sort(sources)
    local rc = reasons[1] == "kein Pattern" and colors.pink or colors.orange
    rows[#rows+1] = {seg(fit(tostring(e.count), 6, true).." ", colors.white), seg(fit(e.label, w - 7 - wR - (w >= 60 and 16 or 0))),
      seg(fit(table.concat(reasons, ", "), wR), rc), seg(w >= 60 and fit(" "..table.concat(sources, ", "), 16) or "", colors.gray)}
  end
  -- 2) Forschungskosten, die im ME fehlen
  if research and #research.available > 0 then
    local miss = {}
    for _, it in ipairs(research.available) do
      for _, c in ipairs(it.cost) do
        local have = 0
        for _, alt in ipairs(c.alts or {}) do have = have + stockOf(lastByName, alt.name) end
        if have < c.count then miss[#miss+1] = {txt=(c.count - have).."x "..c.label, res=it.name} end
      end
    end
    if #miss > 0 then
      rows[#rows+1] = heading("Fuer Forschungen fehlt ("..#miss..")", w)
      for _, m in ipairs(miss) do rows[#rows+1] = {seg(fit("  "..m.txt, math.floor(w*0.5))), seg(fit(" fuer "..m.res, w - math.floor(w*0.5)), colors.gray)} end
    end
  end
  -- 3) Patterns, die sich lohnen
  if cfg.trackMissingPatterns then
    local now_ = now()
    local list = {}
    for name, e in pairs(missingDb) do
      local label = asc(e.display or shortName(name))
      local current = need[label] ~= nil
      list[#list+1] = {label=label, count=e.count, last=e.last, current=current, score=e.count + (current and 100 or 0)}
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    rows[#rows+1] = heading("Pattern anlegen lohnt sich ("..#list..")", w)
    if #list == 0 then rows[#rows+1] = textRow("  keine fehlenden Patterns bekannt", colors.lime) end
    for i = 1, math.min(15, #list) do
      local e = list[i]
      rows[#rows+1] = {seg(e.current and " JETZT " or "       ", colors.black, e.current and colors.pink or nil),
        seg(fit(" "..e.label, w - 33)), seg(fit(e.count.."x angefragt", 14, true), colors.lightGray),
        seg(fit(e.last and (" vor "..fmtAge(now_ - e.last)) or "", 12), colors.gray)}
    end
    rows[#rows+1] = textRow(fit("Patterns im Pattern Encoding Terminal anlegen (AP kann das nicht).", w), colors.gray)
  end
  return rows
end

-- ---------- Ereignis-Log ----------
do -- logUI
local logFilter = "alle"
function renderers.log(w)
  local rows = {}
  local kindStyle = {warn={colors.red, "!"}, gut={colors.lime, "+"}, update={colors.yellow, "U"},
    craft={colors.green, "C"}, lief={colors.lightBlue, ">"}, info={colors.white, "-"}}
  local head = {seg("Filter: ", colors.lightGray), seg("["..(logFilter == "alle" and "Alle" or "Wichtig").."]", colors.cyan),
    seg("  (antippen zum Umschalten)  "..#eventLog.." Eintraege", colors.gray)}
  head.action = function() logFilter = logFilter == "alle" and "wichtig" or "alle" end
  rows[#rows+1] = head
  local today = os.date("%d.%m")
  for _, e in ipairs(eventLog) do
    if logFilter == "alle" or e.k == "warn" or e.k == "gut" or e.k == "update" then
      local st = kindStyle[e.k] or kindStyle.info
      local d = os.date("%d.%m", e.t / 1000)
      local tm = (d == today and "" or (d.." "))..os.date("%H:%M", e.t / 1000)
      rows[#rows+1] = {seg(fit(tm, d == today and 6 or 12), colors.gray), seg(st[2].." ", st[1]), seg(fit(e.x, w - (d == today and 8 or 14)), e.k == "warn" and colors.orange or colors.white)}
    end
  end
  if #eventLog == 0 then rows[#rows+1] = textRow("Noch keine Ereignisse.", colors.gray) end
  return rows
end
end -- logUI

-- ---------- Forschung ----------
function renderers.forschung(w)
  local rows = {}
  if not research then
    rows[1] = textRow("Forschungsdaten werden geladen ...", colors.gray)
    return rows
  end
  local r = research
  rows[#rows+1] = {seg(string.format("%d von %d Forschungen abgeschlossen", r.done, r.total), colors.white),
    seg(lastResearchT and ("   (Stand vor "..fmtAge(now() - lastResearchT)..")") or "", colors.gray)}
  rows[#rows+1] = heading("Laeuft gerade ("..#r.running..")", w)
  if #r.running == 0 then rows[#rows+1] = textRow("  nichts - in der Universitaet eine Forschung starten", colors.orange) end
  local wName = math.min(28, math.floor(w * 0.45))
  for _, it in ipairs(r.running) do
    local f, rest = bar(it.pct or 0, math.max(4, w - wName - 17), colors.lightBlue)
    rows[#rows+1] = {seg(fit("  "..it.name, wName)), seg(fit(it.branch, 9).." ", colors.gray), f, rest,
      seg(fit(it.pct and (it.pct.."%") or "?", 5, true))}
  end
  rows[#rows+1] = heading("Kann gestartet werden ("..#r.available..")", w)
  if #r.available == 0 then rows[#rows+1] = textRow("  keine (Gebaeude-Stufen fehlen?)", colors.gray) end
  for _, it in ipairs(r.available) do
    local parts, allOk = {}, true
    for _, c in ipairs(it.cost) do
      local have = 0
      for _, alt in ipairs(c.alts or {}) do have = have + stockOf(lastByName, alt.name) end
      if have < c.count then allOk = false end
      parts[#parts+1] = c.count.."x "..c.label
    end
    local costText = #parts > 0 and table.concat(parts, ", ") or "keine Kosten"
    rows[#rows+1] = {seg(fit("  "..it.name, wName), allOk and colors.lime or colors.white), seg(fit(it.branch, 9).." ", colors.gray),
      seg(fit(costText, w - wName - 10), allOk and colors.lime or colors.orange)}
  end
  rows[#rows+1] = heading("Zweige", w)
  local br = {}
  for name, b in pairs(r.branches) do br[#br+1] = {name=name, b=b} end
  table.sort(br, function(a, b) return a.name < b.name end)
  for _, x in ipairs(br) do
    local pct = x.b.total > 0 and x.b.done / x.b.total * 100 or 0
    local f, rest = bar(pct, math.max(4, w - 30), colors.green)
    rows[#rows+1] = {seg(fit("  "..x.name, 14)), f, rest, seg(fit(x.b.done.."/"..x.b.total, 9, true), colors.lightGray)}
  end
  rows[#rows+1] = textRow(fit("Gruen = Kosten liegen im ME", w), colors.gray)
  return rows
end

-- ---------- Karte ----------
do -- karte
local mapSel = nil   -- Schluessel des angetippten Gebaeudes
local mapMode = "status"   -- "status" oder "verteidigung"
local typeAbbr = {
  townhall="TH", warehouse="WH", builder="Bu", residence="Wo", citizen="Wo", cook="Re", restaurant="Re",
  farmer="Fa", fisherman="Fi", lumberjack="Ho", miner="Mi", guardtower="GT", barracks="Ka", barrackstower="KT",
  baker="Bk", bakery="Bk", smeltery="Sm", deliveryman="Ku", courier="Ku", library="Bi", school="Sc", hospital="KH",
  university="Un", tavern="Ta", graveyard="Fr", blacksmith="Sc", stonemason="St", sawmill="Sa", composter="Ko",
  cowboy="Ku", shepherd="Sh", swineherder="Sw", chickenherder="Hu", rabbithutch="Ka", beekeeper="Im",
  crusher="Cr", sifter="Si", florist="Bl", enchanter="En", glassblower="Gl", dyer="Fa", fletcher="Pf",
  mechanic="Me", plantation="Pl", concretemixer="Be", netherworker="Ne", alchemist="Al", archery="Bo",
  combatacademy="Ka", mysticalsite="My", stonesmeltery="SS", postbox="Po", stash="Ve",
}
local function abbrOf(b)
  local t = b.type:lower():gsub("^.*[:/]", "")
  return typeAbbr[t] or (b.name:gsub("[^%a]", ""):sub(1, 2))
end
local function buildingStatus(b, probs)
  if mapMode == "verteidigung" or raidMode then
    local t = b.type:lower()
    if t:find("guard") or t:find("barrack") then return colors.lightBlue, "Wachgebaeude" end
    if not b.built then return colors.gray, "nicht gebaut" end
    if b.guarded then return colors.green, "geschuetzt" end
    return colors.red, "UNGESCHUETZT"
  end
  if (probs[b.key] or 0) > 0 then return colors.red, "offene Anfragen" end
  if b.working then return colors.lightBlue, "im Bau" end
  if not b.built then return colors.gray, "nicht gebaut" end
  if b.level < b.maxLevel then return colors.yellow, "ausbaubar" end
  return colors.green, "Maximalstufe"
end

function renderers.karte(w, v)
  local rows = {}
  local list = S.mapBuildings
  if #list == 0 then rows[1] = textRow("Keine Gebaeudedaten.", colors.gray); return rows end
  local _, h = v.dev.getSize()
  local H = math.max(4, h - 4 - 2 - (raidMode and 1 or 0))   -- Platz fuer Info- und Legendenzeile
  if raidMode then
    local hpSum, n = 0, 0
    for _, g in ipairs(S.guards) do if g.health and g.maxHealth and g.maxHealth > 0 then hpSum = hpSum + g.health / g.maxHealth; n = n + 1 end end
    local col = S.colony or {}
    rows[#rows+1] = {seg(fit(" "..(col.raid and "RAID" or "ANGRIFF").."!  Wachen "..#S.guards..(n > 0 and string.format(", HP %d%%", math.floor(hpSum / n * 100)) or "")
      .."  Graeber "..tostring(col.graves or 0), w), colors.white, colors.red)}
  end
  local probs = {}
  for _, e in ipairs(S.requests) do
    if e.tpos and (e.state == "FEHLT" or e.state == "FEHLER" or e.state == "MANUELL") then probs[e.tpos] = (probs[e.tpos] or 0) + 1 end
  end
  local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
  for _, b in ipairs(list) do
    minX, maxX = math.min(minX, b.x1), math.max(maxX, b.x2)
    minZ, maxZ = math.min(minZ, b.z1), math.max(maxZ, b.z2)
  end
  minX, minZ, maxX, maxZ = minX - 3, minZ - 3, maxX + 3, maxZ + 3
  -- Zeichen sind ca. 1,5x so hoch wie breit
  local bx = math.max((maxX - minX + 1) / w, (maxZ - minZ + 1) / (H * 1.5), 0.25)
  local bz = bx * 1.5
  local usedW = math.ceil((maxX - minX + 1) / bx)
  local usedH = math.ceil((maxZ - minZ + 1) / bz)
  local offX = math.floor((w - usedW) / 2)
  local offY = math.floor((H - usedH) / 2)
  local function cx(x) return math.floor((x - minX) / bx) + 1 + offX end
  local function cy(z) return math.floor((z - minZ) / bz) + 1 + offY end
  local grid = {}
  for y = 1, H do grid[y] = {} end
  local function put(x, y, ch, fg, bg, b)
    if y >= 1 and y <= H and x >= 1 and x <= w then grid[y][x] = {ch=ch, fg=fg, bg=bg, b=b} end
  end
  -- grosse Gebaeude zuerst, damit kleine sichtbar bleiben
  local order = {}
  for _, b in ipairs(list) do order[#order+1] = b end
  table.sort(order, function(a, b2) return (a.x2-a.x1)*(a.z2-a.z1) > (b2.x2-b2.x1)*(b2.z2-b2.z1) end)
  for _, b in ipairs(order) do
    local color = buildingStatus(b, probs)
    local sel = mapSel == b.key
    for y = cy(b.z1), cy(b.z2) do
      for x = cx(b.x1), cx(b.x2) do put(x, y, " ", colors.black, sel and colors.white or color, b) end
    end
  end
  -- Buerger als Punkte
  if cfg.mapShowCitizens then
    for _, p in ipairs(S.citizenPos) do
      local x, y = cx(p.x), cy(p.z)
      if y >= 1 and y <= H and x >= 1 and x <= w then
        local c = grid[y][x]
        if c then c.ch = "\7"; c.fg = colors.black else put(x, y, "\7", colors.lightGray, nil, nil) end
      end
    end
  end
  -- Kuerzel in die Mitte schreiben
  for _, b in ipairs(order) do
    local ab = abbrOf(b)
    local x1, x2 = cx(b.x1), cx(b.x2)
    local y = math.floor((cy(b.z1) + cy(b.z2)) / 2)
    local width = x2 - x1 + 1
    if width < #ab then ab = ab:sub(1, width) end
    local sx = x1 + math.floor((width - #ab) / 2)
    for i = 1, #ab do
      local c = grid[y] and grid[y][sx + i - 1]
      if c and c.b == b then c.ch = ab:sub(i, i); c.fg = colors.black end
    end
  end
  -- Zeilen bauen (gleich formatierte Zellen zusammenfassen)
  for y = 1, H do
    local row, cur = {}, nil
    local cells = grid[y]
    for x = 1, w do
      local c = cells[x]
      local ch, fg, bg = c and c.ch or " ", c and c.fg or colors.gray, c and c.bg or nil
      if cur and cur.fg == fg and cur.bg == bg then cur.t = cur.t..ch
      else cur = seg(ch, fg, bg, bg and "#" or nil); row[#row+1] = cur end
    end
    -- auf s/w-Monitoren das Kuerzel statt "#" zeigen
    for _, sg in ipairs(row) do if sg.alt and sg.t:find("%S") then sg.alt = nil end end
    row.actionAt = function(_, px)
      local c = cells[px]
      mapSel = c and c.b and c.b.key or nil
      return true
    end
    rows[#rows+1] = row
  end
  -- Info zum ausgewaehlten Gebaeude
  local info
  if mapSel then
    for _, b in ipairs(list) do
      if b.key == mapSel then
        local _, stText = buildingStatus(b, probs)
        local extra = ""
        for _, e in ipairs(S.builds) do
          if e.pos == b.key and e.claimed then extra = "  "..(e.approx and "ca." or "")..e.pct.."%"..(e.eta and (" ~"..fmtAge(e.eta)) or "") end
        end
        info = {seg(b.name, colors.yellow), seg("  Lvl "..b.level.."/"..b.maxLevel, colors.white),
          seg("  "..stText..extra, colors.lightGray),
          seg((probs[b.key] or 0) > 0 and ("  "..probs[b.key].." Anfrage(n)") or "", colors.red),
          seg(b.residents > 0 and ("  "..b.residents.." Bewohner/Arbeiter") or "", colors.gray)}
      end
    end
  end
  rows[#rows+1] = info or {seg("Gebaeude antippen fuer Details", colors.gray)}
  local legend
  if mapMode == "verteidigung" or raidMode then
    legend = {seg(" ", colors.black, colors.green, "G"), seg(" geschuetzt "), seg(" ", colors.black, colors.red, "R"), seg(" ungeschuetzt "),
      seg(" ", colors.black, colors.lightBlue, "B"), seg(" Wache "), seg("[Status]", colors.cyan)}
  else
    legend = {seg(" ", colors.black, colors.green, "G"), seg(" Max "), seg(" ", colors.black, colors.yellow, "Y"), seg(" Ausb "),
      seg(" ", colors.black, colors.lightBlue, "B"), seg(" Bau "), seg(" ", colors.black, colors.red, "R"), seg(" Anfr "),
      seg(" ", colors.black, colors.gray, "-"), seg(" leer "), seg("[Verteid.]", colors.cyan)}
  end
  legend.action = function() mapMode = mapMode == "status" and "verteidigung" or "status" end
  rows[#rows+1] = legend
  return rows
end
end -- karte

-- ---------- Optionen ----------
local SETTINGS = {
  {head="Lieferung & Crafting"},
  {key="prestockEnabled", label="Baumaterial vorliefern"},
  {key="craftingEnabled", label="Auto-Crafting ueber ME Bridge"},
  {key="prestockCraft", label="Baumaterial vorab craften"},
  {key="craftReserveCpus", label="CPUs fuer Anfragen reservieren", choices={0, 1, 2, 3, 4}},
  {key="cpuCheck", label="Freie CPUs pruefen (aus: Quantum Computer)"},
  {key="prestockMaxCraftsPerScan", label="Baumaterial-Crafts pro Scan", choices={1, 2, 3, 5, 10}},
  {key="craftMaxStack", label="Immer mind. 64 craften"},
  {key="maxToolTier", label="Werkzeuge bis Stufe", choices={"wood", "stone", "iron", "diamond", "netherite"}},
  {key="maxArmorTier", label="Ruestung bis Stufe", choices={"leather", "gold", "chain", "iron", "diamond", "netherite"}},
  {key="scanInterval", label="Scan-Intervall (Sek.)", choices={10, 20, 30, 60, 120}},
  {head="Chat"},
  {key="chatEnabled", label="Chat-Nachrichten"},
  {key="chatOnMissingPattern", label="Fehlende Patterns"},
  {key="chatOnAttack", label="Angriff / Raid"},
  {key="chatOnDeath", label="Buerger gestorben"},
  {key="chatOnDisease", label="Buerger krank"},
  {key="chatOnStorage", label="ME-Speicher / Energie"},
  {key="chatOnOldRequest", label="Haengende Anfragen"},
  {key="chatOnStuckCraft", label="Haengende Crafts"},
  {key="chatOnVisitor", label="Besucher anwerbbar"},
  {key="chatOnBuildDone", label="Bau fertig"},
  {key="chatOnResearch", label="Forschung fertig"},
  {key="chatOnFood", label="Essen wird knapp"},
  {head="Raid-Modus"},
  {key="raidSwitchMonitors", label="Monitore auf Verteidigung schalten"},
  {key="raidScanInterval", label="Scan-Intervall im Raid (Sek.)", choices={2, 5, 10, 30}},
  {head="Updates"},
  {button="Pruefen", label="Jetzt suchen", run=function() updateCheckNow() end},
  {key="updateCheckHours", label="Automatisch suchen alle X Std. (0=aus)", choices={1, 3, 6, 12, 24, 0}},
  {key="autoUpdate", label="Updates automatisch installieren"},
  {head="Sonstiges"},
  {key="monitorScale", label="Monitor-Textgroesse", choices={0.5, 1, 1.5, 2}},
  {key="dashboardMinWidth", label="Kacheln ab Breite (0=nie)", choices={0, 40, 60, 80}},
  {key="mapShowCitizens", label="Buerger auf der Karte"},
  {key="trackMissingPatterns", label="Fehlende Patterns merken"},
  {key="doLog", label="Logdateien schreiben"},
}

local writeConfigValue
do -- config
local function luaValue(v)
  if type(v) == "string" then return string.format("%q", v) end
  return tostring(v)
end
-- Wert in der Config-Datei ersetzen (Kommentare bleiben erhalten)
function writeConfigValue(key, value)
  local f = fs.open(CONFIG_FILE, "r"); if not f then return false end
  local src = f.readAll(); f.close()
  local out, found = {}, false
  for line in (src.."\n"):gmatch("([^\n]*)\n") do
    if not found and line:match("^%s*"..key.."%s*=") then
      local pre, rest = line:match("^(%s*"..key.."%s*=%s*)[^,]*(.*)$")
      if pre then line = pre..luaValue(value)..rest; found = true end
    end
    out[#out+1] = line
  end
  if out[#out] == "" then out[#out] = nil end
  if not found then
    for i = #out, 1, -1 do
      if out[i]:match("^%s*}") then table.insert(out, i, "  "..key.." = "..luaValue(value)..","); found = true; break end
    end
  end
  if not found then return false end
  local newSrc = table.concat(out, "\n").."\n"
  local fn = load(newSrc, "config", "t", {})
  local ok, res = pcall(fn or error)
  if not ok or type(res) ~= "table" or res[key] ~= value then return false end
  local w = fs.open(CONFIG_FILE, "w"); w.write(newSrc); w.close()
  return true
end
end -- config

local applySetting   -- wird weiter unten gesetzt (braucht views)
local settingsMsg = nil

function renderers.optionen(w, v)
  local rows = {}
  local locked = cfg.lockSettings and v and v.isMon
  rows[#rows+1] = textRow(locked and "Gesperrt (lockSettings) - aendern nur am Terminal" or "Antippen zum Umschalten. Wird sofort gespeichert.",
    locked and colors.orange or colors.lightGray)
  if v and cfg.pocketEnabled and cfg.pocketCode ~= "" then
    if not v.isMon or (v.revealUntil and now() < v.revealUntil) then
      rows[#rows+1] = textRow(fit("Pocket-Code: "..cfg.pocketCode.."  (am Pocket: Reiter Ctl)", w), colors.cyan)
    elseif not locked then
      -- auf Monitoren nur auf Wunsch kurz zeigen (Monitore sieht jeder)
      local r = textRow("[ Pocket-Code zeigen ]", colors.cyan)
      r.action = function(view) view.revealUntil = now() + 15000 end
      rows[#rows+1] = r
    end
  end
  -- feste Zeile fuer Rueckmeldungen, damit sich die Zeilen beim Tippen nicht verschieben
  if settingsMsg and now() - settingsMsg.t < 10000 then rows[#rows+1] = textRow(fit(settingsMsg.text, w), settingsMsg.color)
  else rows[#rows+1] = blank() end
  for _, st in ipairs(SETTINGS) do
    if st.head then
      rows[#rows+1] = heading(st.head, w)
    elseif st.button then
      local row = {seg(fit("["..st.button.."]", 11), colors.cyan), seg(fit(st.label.." (du hast "..(scriptVersion:match("^[%d%.]+") or scriptVersion)..")", w - 11))}
      if not locked then row.action = st.run end
      rows[#rows+1] = row
      if updateMsg and (updateMsg.t == math.huge or now() - updateMsg.t < 60000) then rows[#rows+1] = textRow(fit("  "..updateMsg.text, w), updateMsg.color) end
    else
      local val = cfg[st.key]
      local txt, color
      if st.choices then txt, color = tostring(val), colors.yellow
      else txt, color = val and "AN" or "AUS", val and colors.lime or colors.red end
      local box = fit("["..txt.."]", 11)
      local row = {seg(box, color), seg(fit(st.label, w - 11))}
      if not locked then row.action = function() applySetting(st) end end
      rows[#rows+1] = row
    end
  end
  return rows
end

-- ---------- Zeichnen ----------
local views = {}      -- name -> {dev, name, tab, page, pages, isMon, tabX, nav}
local scanTick = cfg.scanInterval   -- -1 = Scan laeuft gerade
local lastScanMs = nil              -- Dauer des letzten Scans
local shownS = nil                  -- letzter vollstaendiger Scan-Stand (fuer die Anzeige waehrend eines Scans)

local function drawRow(t, y, w, row, color)
  t.setCursorPos(1, y); t.setBackgroundColor(colors.black); t.clearLine()
  local x = 1
  for _, s in ipairs(row) do
    if x > w then break end
    local text = s.t:sub(1, w-x+1)
    if not color and s.alt and s.bg then
      text = string.rep(s.alt, #text)
      t.setBackgroundColor(colors.black); t.setTextColor(colors.white)
    else
      t.setBackgroundColor(color and s.bg or colors.black)
      t.setTextColor(color and s.fg or colors.white)
    end
    t.setCursorPos(x, y); t.write(text)
    x = x + #text
  end
  t.setBackgroundColor(colors.black)
end

local function drawFooter(v)
  local t = v.dev
  local ok, w, h = pcall(t.getSize)
  if not ok then return end
  local color = t.isColor()
  local nav = string.format("[<] %d/%d [>]", v.page, v.pages)
  if v.pages <= 1 then nav = "" end
  local scanText
  if scanTick < 0 then scanText = " Scan laeuft... "
  else
    scanText = " Scan "..scanTick.."s "
    if lastScanMs and lastScanMs >= 5000 then scanText = " (dauerte "..math.floor(lastScanMs / 1000).."s)"..scanText end
  end
  local barW = math.max(0, w - #nav - #scanText - 1)
  local filled = math.max(0, math.min(barW, math.floor(math.max(0, scanTick)/cfg.scanInterval*barW + 0.5)))
  local row = {seg(nav, colors.lightGray), seg(" "), seg(string.rep(" ", filled), colors.white, colors.gray, "#"),
    seg(string.rep(" ", barW-filled), colors.white, colors.black, " "), seg(scanText, colors.gray)}
  drawRow(t, h, w, row, color)
  v.nav = (v.pages > 1) and {prev={1, 3}, next={#nav-2, #nav}} or nil
end

local drawViewInner
-- Waehrend ein Scan laeuft, ist S halb gefuellt -> den letzten vollstaendigen Stand anzeigen
local function drawView(v)
  local live = S
  if shownS then S = shownS end
  local ok, err = pcall(drawViewInner, v)
  S = live
  if not ok then error(err, 0) end
end
function drawViewInner(v)
  local dev = v.dev
  local ok, w, h = pcall(dev.getSize)
  if not ok then return end
  local color = dev.isColor()
  local win = window.create(dev, 1, 1, w, h, false)
  win.setBackgroundColor(colors.black); win.clear()

  -- Zeile 1: Titel + ME-Status
  local title = scriptName..(S.colony and S.colony.name and (" - "..asc(S.colony.name)) or "")
  local status = S.meStatus or ""
  local alarm = (S.colony and (S.colony.attack or S.colony.raid))
  local upd = updateInfo and (w >= 40 and " UPDATE VERFUEGBAR " or " UPDATE ") or ""
  drawRow(win, 1, w, {seg(fit(title, w-#status-#upd-1), alarm and colors.red or colors.orange),
    seg(upd, colors.black, colors.yellow), seg(" "..status, S.online and colors.lime or colors.red)}, color)
  v.updX = updateInfo and {w-#status-#upd, w-#status-1} or nil

  -- Zeile 2: Reiter
  -- Anzahl Probleme als Markierung am Reiter
  local badge = {}
  local nReq = 0
  for _, e in ipairs(S.requests) do if e.state == "FEHLT" or e.state == "FEHLER" or e.state == "MANUELL" then nReq = nReq + 1 end end
  if nReq > 0 then badge.anfragen = nReq end
  if #S.citizens > 0 then badge.buerger = #S.citizens end
  local nTodo = 0
  for _, e in ipairs(S.requests) do if e.state == "FEHLT" or e.state == "MANUELL" then nTodo = nTodo + 1 end end
  for _, b in ipairs(S.builds) do nTodo = nTodo + (b.missing or 0) end
  if nTodo > 0 then badge.todo = nTodo end
  local nCraft = 0
  for _, c in ipairs(crafts) do if c.state == "FEHLER" or (c.stuck and c.state == "LAEUFT") then nCraft = nCraft + 1 end end
  if nCraft > 0 then badge.crafts = nCraft end
  -- Breite stufenweise reduzieren, bis alle Reiter passen
  local variants = {
    function(i, tb) return " "..tb.label..(badge[tb.id] and ("("..badge[tb.id]..")") or "").." ", 1 end,
    function(i, tb) return " "..tb.label..(badge[tb.id] and ("("..badge[tb.id]..")") or "").." ", 0 end,
    function(i, tb) return " "..tb.label.." ", 0 end,
    function(i, tb) return " "..tb.short..(badge[tb.id] and "!" or "").." ", 0 end,
    function(i, tb) return " "..tb.short:sub(1, 3)..(badge[tb.id] and "!" or "").." ", 0 end,
    function(i, tb) return " "..tb.short:sub(1, 3).." ", 0 end,
    function(i, tb) return " "..i.." ", 0 end,
  }
  -- Reiter auf hoechstens maxRows Zeilen verteilen; nil wenn es nicht passt
  local function layout(fn, maxRows)
    local lines, cur, curW = {{}}, 1, 0
    for i, tb in ipairs(TABS) do
      local t2, g = fn(i, tb)
      local gp = curW > 0 and g or 0
      if curW + gp + #t2 > w then
        if cur >= maxRows then return nil end
        cur = cur + 1; lines[cur] = {}; curW = 0; gp = 0
      end
      table.insert(lines[cur], {tb=tb, t=t2, gap=gp})
      curW = curW + gp + #t2
    end
    return lines
  end
  local lines
  for _, fn in ipairs({variants[1], variants[2], variants[3], variants[4]}) do lines = layout(fn, 1); if lines then break end end
  if not lines then
    for _, fn in ipairs({variants[2], variants[3], variants[4], variants[5], variants[6], variants[7]}) do lines = layout(fn, 2); if lines then break end end
  end
  lines = lines or layout(variants[7], 3) or {{}}
  v.tabX = {}
  for li, line in ipairs(lines) do
    local row, x = {}, 1
    for _, item in ipairs(line) do
      if item.gap > 0 then row[#row+1] = seg(string.rep(" ", item.gap), colors.black, colors.black); x = x + item.gap end
      local active = item.tb.id == v.tab
      row[#row+1] = seg(item.t, active and colors.white or colors.lightGray, active and colors.blue or colors.gray)
      v.tabX[#v.tabX+1] = {from=x, to=x+#item.t-1, id=item.tb.id, y=1+li}
      x = x + #item.t
    end
    drawRow(win, 1 + li, w, row, color)
  end
  v.tabRows = #lines
  if not color then  -- s/w: aktiven Reiter mit Pfeil markieren
    for _, tx in ipairs(v.tabX) do if tx.id == v.tab then win.setCursorPos(tx.from, tx.y); win.write(">") end end
  end

  -- Inhalt
  local okR, rows = pcall(renderers[v.tab], w, v)
  if not okR then
    logLine("[ANZEIGE] "..v.tab..": "..tostring(rows))
    rows = {textRow(fit("Anzeigefehler im Reiter "..v.tab..":", w), colors.red), textRow(fit(tostring(rows), w), colors.red)}
  end
  local top, bottom = math.max(4, 2 + (v.tabRows or 1) + 1), h-1
  local perPage = math.max(1, bottom-top+1)
  v.pages = math.max(1, math.ceil(#rows/perPage))
  if v.page > v.pages then v.page = v.pages end
  local first = (v.page-1)*perPage + 1
  v.rowAt = {}
  for i = 0, perPage-1 do
    local r = rows[first+i]
    if r then drawRow(win, top+i, w, r, color); v.rowAt[top+i] = r end
  end
  win.setVisible(true)
  drawFooter(v)
end

local function syncMonitors()
  local mons = {peripheral.find("monitor")}
  table.sort(mons, function(a, b) return peripheral.getName(a) < peripheral.getName(b) end)
  local seen = {}
  for i, m in ipairs(mons) do
    local name = peripheral.getName(m)
    seen[name] = true
    if not views[name] then
      pcall(m.setTextScale, cfg.monitorScale)
      local tab = cfg.monitorTabs[name] or (i == 2 and "anfragen") or "start"
      if not renderers[tab] then tab = "start" end
      views[name] = {dev=m, name=name, tab=tab, page=1, pages=1, isMon=true}
    end
  end
  for name, v in pairs(views) do if v.isMon and not seen[name] then views[name] = nil end end
end
local function drawAll() for _, v in pairs(views) do drawView(v) end end
-- Sekunden-Countdown nur am Terminal: jedes Beschreiben eines Monitors laesst CC den Monitor-Block
-- im naechsten Server-Tick neu synchronisieren - das sparen wir uns bei Monitoren
local function drawAllFooters(all)
  for _, v in pairs(views) do if all or not v.isMon then drawFooter(v) end end
end

updateCheckNow = function()
  updateMsg = {t=now(), color=colors.lightGray, text="Suche nach Updates ..."}
  drawAll()
  local r = checkUpdate(true)
  if r == "aktuell" and pendingVersion then
    updateMsg = {t=math.huge, color=colors.lime, text=(pendingVersion:match("^[%d%.]+") or pendingVersion).." installiert - bitte neu starten"}
  elseif r == "neu" then updateMsg = {t=now(), color=colors.yellow, text=(updateInfo:match("^[%d%.]+") or updateInfo).." verfuegbar - Start: Jetzt updaten"}
  elseif r == "aktuell" then updateMsg = {t=now(), color=colors.lime, text="Aktuell - keine neue Version"}
  else updateMsg = {t=now(), color=colors.red, text="Update-Pruefung fehlgeschlagen (HTTP?)"} end
end

-- selbst gestartete Crafts, die noch laufen (AP schickt dem Computer am Ende ein Ereignis)
local function runningCrafts()
  local n = 0
  for _, c in ipairs(crafts) do if c.state == "START" or c.state == "LAEUFT" then n = n + 1 end end
  return n
end

local function doUpdate()
  updateWaiting = false
  if not shell or not fs.exists("update.lua") then
    updateMsg = {t=now(), color=colors.red, text="update.lua fehlt - im Terminal neu installieren"}
    return
  end
  local target = updateInfo
  updateMsg = {t=now(), color=colors.yellow, text="Installiere "..target.." ..."}
  chat("Update auf v"..target.." wird installiert ...")
  flushChat()
  drawAll()
  logLine("[UPDATE] starte update -y fuer v"..target)
  shell.run("update", "-y")   -- startet bei Erfolg den Computer neu (wenn ein startup existiert)
  -- Hier landen wir nur ohne Neustart: pruefen, ob die neue Version installiert wurde
  local f = fs.open(PROGRAM_PATH, "r")
  local src = f and f.readAll() or ""
  if f then f.close() end
  local installed = src:match('local scriptVersion%s*=%s*"([^"]+)"')
  if installed == target then
    updateInfo, pendingVersion = nil, target
    updateMsg = {t=math.huge, color=colors.lime, text=(target:match("^[%d%.]+") or target).." installiert - bitte neu starten"}
  else
    updateMsg = {t=now(), color=colors.red, text="Update fehlgeschlagen - im Terminal 'update' ausfuehren"}
  end
end

updateTap = function()
  if not updateInfo then return end
  if not (updateArm and now() < updateArm) then updateArm = now() + 8000; return end
  updateArm = nil
  local n = runningCrafts()
  if n > 0 and not updateWaiting then
    -- Neustart jetzt wuerde bei AP 0.8.2a den Server crashen, sobald einer dieser Crafts fertig wird
    updateWaiting = true
    updateMsg = {t=math.huge, color=colors.yellow, text="Update wartet auf "..n.." laufende Craft(s) - neue Crafts pausiert"}
    logEvent("Update wartet auf "..n.." laufende Crafts", "update")
    return
  end
  if n > 0 then logEvent("Update trotz "..n.." laufender Crafts erzwungen", "warn") end
  doUpdate()
end

-- im Scan-Takt: wartendes Update installieren, sobald keine eigenen Crafts mehr laufen
runPendingUpdate = function()
  if not updateWaiting or not updateInfo then return end
  local n = runningCrafts()
  if n > 0 then
    updateMsg = {t=math.huge, color=colors.yellow, text="Update wartet auf "..n.." laufende Craft(s) - neue Crafts pausiert"}
    return
  end
  doUpdate()
end

applySetting = function(st)
  local cur = cfg[st.key]
  local new
  if st.choices then
    local idx = 0
    for i, c in ipairs(st.choices) do if c == cur then idx = i end end
    new = st.choices[idx % #st.choices + 1]
  else
    new = not cur
  end
  cfg[st.key] = new
  if st.key == "monitorScale" then
    for _, v in pairs(views) do if v.isMon then pcall(v.dev.setTextScale, new) end end
  elseif st.key == "doLog" and new and not fs.exists(logFolder) then
    fs.makeDir(logFolder)
  elseif st.key == "chatEnabled" then
    findChatBox()
  end
  local saved = writeConfigValue(st.key, new)
  local shown = type(new) == "boolean" and (new and "AN" or "AUS") or tostring(new)
  settingsMsg = saved and {t=now(), color=colors.lime, text=st.label..": "..shown.." (gespeichert)"}
    or {t=now(), color=colors.orange, text=st.label..": "..shown.." - nur bis Neustart (Config?)"}
  logLine("[OPTION] "..st.key.." = "..tostring(new))
end

-- ---------- Eingabe ----------
local function setTab(v, id) if v.tab ~= id then v.tab = id; v.page = 1 end; drawView(v) end
gotoTab = setTab
-- Pocket Computer: kompakter Status per Funk, Befehle mit Pocket-Code
local pocketStatus, pocketCommand
do -- pocket
local STATUS_PROTO, CMD_PROTO, ACK_PROTO = "ae2colony_status", "ae2colony_cmd", "ae2colony_ack"
local CONTROL = {craftingEnabled=true, prestockEnabled=true, prestockCraft=true, autoUpdate=true,
  chatEnabled=true, raidSwitchMonitors=true}

local function cut(list, n) local out = {}; for i = 1, math.min(n, #list) do out[i] = list[i] end; return out end
local function build()
  local st = shownS or S
  local col, me = st.colony or {}, st.me or {}
  local d = {v=scriptVersion, t=os.epoch("utc"), name=col.name and asc(col.name) or "?"}
  d.col = {happy=col.happy, cit=col.cit, lim=col.lim, graves=col.graves, raid=col.raid, attack=col.attack}
  d.me = {online=st.online, status=st.meStatus, storage=me.storagePct and math.floor(me.storagePct),
    energy=me.energyPct and math.floor(me.energyPct)}
  local wh = st.warehouse
  if wh and not wh.missing then d.wh = math.floor(wh.pct) end
  local today = statsToday()
  d.today = {sent=today.sent, crafts=today.crafts}
  d.alerts = cut(st.alerts or {}, 6)
  for _, e in ipairs(st.errors or {}) do if #d.alerts < 8 then d.alerts[#d.alerts+1] = e end end
  d.problems = {}
  for _, e in ipairs(st.requests or {}) do
    if (e.state == "FEHLT" or e.state == "MANUELL" or e.state == "FEHLER" or e.old) and #d.problems < 15 then
      d.problems[#d.problems+1] = {s=e.state, c=e.count, l=e.label, z=e.target, n=e.note}
    end
  end
  d.builds = {}
  for _, e in ipairs(st.builds or {}) do
    if #d.builds < 8 then
      d.builds[#d.builds+1] = {l=e.name, p=e.pct, a=e.approx, e=e.eta, c=e.claimed, m=e.missing, st=e.stage}
    end
  end
  d.crafts = {}
  for _, c in ipairs(crafts) do
    if #d.crafts < 10 then d.crafts[#d.crafts+1] = {s=(c.stuck and c.state == "LAEUFT") and "HAENGT" or c.state, c=c.count, l=c.label, p=c.pct} end
  end
  -- Zu tun: zusammengefasst je Item
  local need, order = {}, {}
  local function add(label, count, why)
    local e = need[label]
    if not e then e = {l=label, c=0, w=why}; need[label] = e; order[#order+1] = e end
    e.c = e.c + (count or 0)
  end
  for _, e in ipairs(st.requests or {}) do
    if e.state == "FEHLT" or e.state == "MANUELL" then add(e.label, e.count, e.note) end
  end
  for _, b in ipairs(st.builds or {}) do
    for _, r in ipairs(b.res or {}) do if r.state == "FEHLT" then add(r.label, r.count, r.note) end end
  end
  d.todo = cut(order, 15)
  d.log = {}
  for i = 1, math.min(15, #eventLog) do local e = eventLog[i]; d.log[i] = {t=e.t, k=e.k, x=e.x} end
  d.update, d.waiting = updateInfo, updateWaiting
  d.set = {}
  for k in pairs(CONTROL) do d.set[k] = cfg[k] end
  return d
end

function pocketStatus(target)
  if not cfg.pocketEnabled or not rednet or not rednet.isOpen() then return end
  local ok, d = pcall(build)
  if not ok then logLine("Pocket: "..tostring(d)); return end
  if target then rednet.send(target, d, STATUS_PROTO) else rednet.broadcast(d, STATUS_PROTO) end
end

local function ack(target, ok, msg) rednet.send(target, {ok=ok, msg=msg}, ACK_PROTO) end

-- Befehle: {cmd="status"} (ohne Code), {cmd="refresh"|"update"|"toggle", key=Code, arg=Option}
function pocketCommand(sender, msg)
  if not cfg.pocketEnabled or type(msg) ~= "table" then return end
  if msg.cmd == "status" then pocketStatus(sender); return end
  if cfg.pocketCode == "" or tostring(msg.key) ~= cfg.pocketCode then ack(sender, false, "Falscher Pocket-Code"); return end
  if msg.cmd == "refresh" then
    os.queueEvent("ae2colony_refresh"); ack(sender, true, "Scan gestartet")
  elseif msg.cmd == "update" then
    if not updateInfo then ack(sender, false, "Kein Update verfuegbar"); return end
    updateArm = now() + 8000   -- wie ein Doppeltipp: wartet auf laufende Crafts
    ack(sender, true, "Update angestossen")
    logEvent("Update per Pocket angestossen (Computer "..sender..")", "update")
    updateTap()
  elseif msg.cmd == "toggle" and CONTROL[msg.arg] then
    for _, st in ipairs(SETTINGS) do
      if st.key == msg.arg then
        applySetting(st)
        logEvent("Pocket: "..st.label.." = "..(cfg[st.key] and "AN" or "AUS"), "info")
        ack(sender, true, st.label..": "..(cfg[st.key] and "AN" or "AUS"))
        pocketStatus(sender)
        return
      end
    end
    ack(sender, false, "Option unbekannt")
  else
    ack(sender, false, "Unbekannter Befehl")
  end
end
end -- pocket

local inputLoop
do -- eingabe
local function nextPage(v, d) v.page = ((v.page-1+d) % v.pages) + 1; drawView(v) end
local function tabIndex(id) for i, tb in ipairs(TABS) do if tb.id == id then return i end end return 1 end

local function onTouch(v, x, y)
  local _, h = v.dev.getSize()
  if y == 1 then
    if v.updX and x >= v.updX[1] and x <= v.updX[2] then setTab(v, "start") else os.queueEvent("ae2colony_refresh") end
  elseif y >= 2 and y <= 1 + (v.tabRows or 1) then
    for _, tx in ipairs(v.tabX or {}) do if tx.y == y and x >= tx.from and x <= tx.to then setTab(v, tx.id); return end end
  elseif y == h then
    if v.nav and x >= v.nav.prev[1] and x <= v.nav.prev[2] then nextPage(v, -1)
    elseif v.nav and x >= v.nav.next[1] and x <= v.nav.next[2] then nextPage(v, 1)
    else os.queueEvent("ae2colony_refresh") end
  else
    local r = v.rowAt and v.rowAt[y]
    if r and r.actionAt and r.actionAt(v, x) then
      drawAll()
    elseif r and r.action then
      r.action(v)
      drawAll()
    else
      nextPage(v, 1)   -- Tippen in den Inhalt blaettert weiter
    end
  end
end

function inputLoop()
  while true do
    local ev, a, b2, c2 = os.pullEvent()
    if ev == "monitor_touch" then
      local v = views[a]; if v then onTouch(v, b2, c2) end
    elseif ev == "mouse_click" then
      local v = views.term; if v then onTouch(v, b2, c2) end
    elseif ev == "key" then
      local v = views.term
      if v then
        if a == keys.left then setTab(v, TABS[(tabIndex(v.tab)-2) % #TABS + 1].id)
        elseif a == keys.right or a == keys.tab then setTab(v, TABS[tabIndex(v.tab) % #TABS + 1].id)
        elseif a == keys.up or a == keys.pageUp then nextPage(v, -1)
        elseif a == keys.down or a == keys.pageDown then nextPage(v, 1)
        elseif a == keys.r then os.queueEvent("ae2colony_refresh")
        elseif a == keys.u and updateInfo then setTab(v, "start"); updateTap(); drawView(v) end
      end
    elseif ev == "char" and views.term then
      local n = tonumber(a); if n == 0 then n = 10 end
      if n and TABS[n] then setTab(views.term, TABS[n].id)
      elseif a == "o" or a == "O" then setTab(views.term, "optionen") end
    elseif ev == "rednet_message" then
      if c2 == "ae2colony_lager" then lagerMessage(b2)
      elseif c2 == "ae2colony_cmd" then pocketCommand(a, b2) end
    elseif ev == "monitor_resize" or ev == "term_resize" then
      drawAll()
    elseif ev == "peripheral" or ev == "peripheral_detach" then
      syncMonitors(); drawAll()
    end
  end
end
end -- eingabe

-- =====================================================================
-- Start
-- =====================================================================
cleanupOldLogs()
-- Funk-Modems oeffnen (Lager-Sender, Kolonie-Relais, Pocket)
pcall(function()
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" and peripheral.call(name, "isWireless") then rednet.open(name) end
  end
end)
bridge, colony = setupPeripherals()
views.term = {dev=term.current(), name="term", tab="start", page=1, pages=1}
if cfg.pocketCode == "" then
  math.randomseed(os.epoch("utc"))
  cfg.pocketCode = tostring(math.random(1000, 9999))
  pcall(writeConfigValue, "pocketCode", cfg.pocketCode)
end
syncMonitors()
findChatBox()
logLine(string.format("%s v%s gestartet - AP %s", scriptName, scriptVersion, apVersionText))

-- Raid-Modus: Monitore auf Verteidigung, Redstone, schnellere Scans
local updateRaid
do -- raid
local raidInfo = nil
function updateRaid()
  local col = S.colony or {}
  -- nur echte Raids: "isUnderAttack" ist schon wahr, wenn irgendein Mob einen Buerger angreift
  local active = col.raid == true
  if active and not raidMode then
    raidMode = true
    raidInfo = {t=now(), graves=col.graves or 0}
    if not cfg.chatOnAttack then logEvent(col.raid and "RAID gestartet!" or "Die Kolonie wird angegriffen!", "warn") end
    if cfg.raidSwitchMonitors then
      for _, v in pairs(views) do
        if v.isMon then v.preRaidTab = v.tab; v.tab = "karte"; v.page = 1 end
      end
    end
    if cfg.raidRedstoneSide ~= "" and redstone then pcall(redstone.setOutput, cfg.raidRedstoneSide, true) end
  elseif not active and raidMode then
    raidMode = false
    local dead = math.max(0, (col.graves or 0) - (raidInfo and raidInfo.graves or 0))
    local msg = "Raid vorbei nach "..fmtAge(now() - (raidInfo and raidInfo.t or now()))..(dead > 0 and (", "..dead.." Buerger gestorben") or ", keine Toten")
    if cfg.chatOnAttack then chat(msg) else logEvent(msg, "gut") end
    for _, v in pairs(views) do
      if v.preRaidTab then v.tab = v.preRaidTab; v.preRaidTab = nil; v.page = 1 end
    end
    if cfg.raidRedstoneSide ~= "" and redstone then pcall(redstone.setOutput, cfg.raidRedstoneSide, false) end
    raidInfo = nil
  end
end
end -- raid

local function scanLoop()
  while true do
    scanTick = -1
    drawAllFooters(true)
    local t0 = now()
    local ok, err = pcall(scan)
    if not ok then addError("Scan abgebrochen: "..tostring(err)) end
    lastScanMs = now() - t0
    local okU, errU = pcall(checkUpdate)
    if not okU then logLine("Update-Pruefung: "..tostring(errU)) end
    local okR, errR = pcall(updateRaid)
    if not okR then logLine("Raid-Modus: "..tostring(errR)) end
    local okP, errP = pcall(runPendingUpdate)
    if not okP then logLine("Update: "..tostring(errP)) end
    pcall(saveEvents)
    shownS = S
    local okPk, errPk = pcall(pocketStatus)
    if not okPk then logLine("Pocket: "..tostring(errPk)) end
    syncMonitors()
    drawAll()
    scanTick = raidMode and math.min(cfg.raidScanInterval, cfg.scanInterval) or cfg.scanInterval
    while scanTick > 0 do
      flushChat()
      local timer = os.startTimer(1)
      local event, arg
      repeat event, arg = os.pullEvent() until event == "ae2colony_refresh" or (event == "timer" and arg == timer)
      if event == "ae2colony_refresh" then scanTick = 0 else scanTick = math.min(scanTick - 1, raidMode and cfg.raidScanInterval or cfg.scanInterval); drawAllFooters(scanTick % 10 == 0) end
    end
  end
end

-- Fehler abfangen statt abstuerzen: protokollieren, anzeigen, mit wachsender Pause weiterlaufen
-- (5 s, 30 s, 2 min, 5 min), damit ein wiederkehrender Fehler den Server nicht im Sekundentakt belastet.
-- Strg+T (Terminated) beendet das Programm weiterhin.
local CRASH_FILE = "ae2colony_crash.txt"
local crashCount, lastCrash = 0, 0
local backoff = {5, 30, 120, 300}
while true do
  local ok, err = pcall(parallel.waitForAny, scanLoop, inputLoop)
  if ok then break end
  if err == "Terminated" then error(err, 0) end
  local msg = tostring(err)
  if now() - lastCrash > 600000 then crashCount = 0 end   -- 10 min ohne Fehler: Zaehler zuruecksetzen
  crashCount, lastCrash = crashCount + 1, now()
  local pause = backoff[math.min(crashCount, #backoff)]
  pcall(function()
    local f = fs.open(CRASH_FILE, "a")
    f.writeLine("["..os.date("%Y-%m-%d %H:%M:%S").."] v"..scriptVersion..": "..msg)
    f.close()
  end)
  logLine("[ABSTURZ] "..msg)
  pcall(logEvent, "Fehler abgefangen: "..msg, "warn"); pcall(saveEvents)
  addError("Fehler abgefangen (siehe "..CRASH_FILE.."): "..msg)
  pcall(chat, "Fehler im Programm abgefangen: "..msg)
  for _, v in pairs(views) do
    pcall(function()
      local w, h = v.dev.getSize()
      v.dev.setBackgroundColor(colors.black); v.dev.setTextColor(colors.red)
      v.dev.setCursorPos(1, h); v.dev.clearLine()
      v.dev.write(("Fehler - Neustart in "..pause.."s: "..msg):sub(1, w))
    end)
  end
  sleep(pause)
end
