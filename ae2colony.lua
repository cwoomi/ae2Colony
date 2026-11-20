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

local scriptName = "AE2 Colony"
local scriptVersion = "0.9.0-ATM10"
local UPDATE_URL = "https://raw.githubusercontent.com/cwoomi/ae2Colony/main/"
local CONFIG_FILE = "ae2colony_config.lua"

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
  resendCooldown = 300,       -- Sekunden Wartezeit nach einer Lieferung, bevor erneut geliefert wird
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
  prestockMaxCraft = 512,     -- maximale Menge pro Craft-Auftrag fuer Baumaterial
  prestockCooldown = 600,     -- Sekunden, bevor fuer dieselbe Baustelle/Item nachgeliefert wird

  -- ===== Anzeige =====
  showColonyStatus = true,
  monitorScale = 0.5,         -- Textgroesse der Monitore (0.5 - 5)
  -- Start-Reiter je Monitor, z.B. { ["monitor_0"] = "start", ["monitor_1"] = "anfragen" }
  -- Reiter: "start", "anfragen", "bau", "buerger", "kolonie", "stats"
  -- Ohne Eintrag: 1. Monitor = start, 2. Monitor = anfragen
  monitorTabs = {},

  -- ===== Warnungen =====
  storageWarnPercent = 90,    -- ME-Speicher: Warnung ab diesem Fuellstand (0 = aus)
  energyWarnPercent = 10,     -- ME-Energie: Warnung unter diesem Stand (0 = aus)
  oldRequestMinutes = 10,     -- Anfragen, die laenger offen sind, gelten als "haengend" (0 = aus)
  citizenHappinessBelow = 5,  -- Buerger unter dieser Zufriedenheit gelten als unzufrieden
  citizenHungerBelow = 4,     -- Buerger unter dieser Saettigung gelten als hungrig (max 20)

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

  -- ===== Dateien & Statistik =====
  trackMissingPatterns = true,
  missingPatternFile = "ae2colony_missing.db",
  missingPatternShowTop = 5,
  statsFile = "ae2colony_stats.db",
  statsShowTop = 10,
  buildsFile = "ae2colony_builds.db",

  -- ===== Updates =====
  updateCheckHours = 6,       -- alle X Stunden nach neuer Version suchen (0 = aus)
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
local function nextLogFile()
  local nums = {}
  for _, f in ipairs(fs.list(logFolder)) do local n = f:match("^log_(%d+)%.log$"); if n then nums[#nums+1] = tonumber(n) end end
  table.sort(nums); return string.format("%s/log_%03d.log", logFolder, (nums[#nums] or 0)+1)
end
local function logLine(msg)
  if not cfg.doLog then return end
  local files = fs.list(logFolder); table.sort(files)
  local path = #files > 0 and (logFolder.."/"..files[#files]) or nextLogFile()
  if fs.exists(path) and fs.getSize(path) >= maxLogSize then path = nextLogFile() end
  local f = fs.open(path, "a")
  if f then f.writeLine("["..os.date("%H:%M:%S", os.epoch("local")/1000).."] "..tostring(msg)); f.close() end
end
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
local translit = {["\195\164"]="ae", ["\195\182"]="oe", ["\195\188"]="ue", ["\195\132"]="Ae",
  ["\195\150"]="Oe", ["\195\156"]="Ue", ["\195\159"]="ss"}
local function asc(s)
  s = tostring(s or "")
  s = s:gsub("[\192-\223][\128-\191]", function(c) return translit[c] or "?" end)
  return (s:gsub("[\128-\255]", ""))
end
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
    buildingsWorking = {}, buildingsUpgrade = {}, visitors = {},
    alerts = {}, errors = {}, colony = {}, me = {}, online = false, meStatus = "...",
  }
end
S = newState()
local function addError(msg) logLine("[ERROR] "..msg); S.errors[#S.errors+1] = asc(msg) end
local function addAlert(msg) logLine("[ALARM] "..msg); S.alerts[#S.alerts+1] = asc(msg) end

local missingDb  = cfg.trackMissingPatterns and loadDb(cfg.missingPatternFile) or {}
local statsDb    = loadDb(cfg.statsFile)
local buildDb    = loadDb(cfg.buildsFile)
local missingCounted, missingNotified = {}, {}
local sentAt     = {}   -- request id -> Zeitpunkt der letzten Lieferung
local firstSeen  = {}   -- request id -> Zeitpunkt, an dem die Anfrage zuerst gesehen wurde
local delivered  = {}   -- "zielPos|item|hash" -> {t=Zeitpunkt, n=Menge}
local exportBuffer = {}

-- =====================================================================
-- Chat (optional)
-- =====================================================================
local chatQueue, chatBox = {}, nil
local function findChatBox()
  if not cfg.chatEnabled then chatBox = nil; return end
  if chatBox then
    local ok, name = pcall(peripheral.getName, chatBox)
    if ok and name and peripheral.isPresent(name) then return end
  end
  chatBox = peripheral.find("chat_box")
end
local function chat(msg)
  if not cfg.chatEnabled then return end
  logLine("[CHAT] "..msg)
  chatQueue[#chatQueue+1] = {text=asc(msg), tries=0}
end
local function flushChat()
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
  if statsDb.day ~= day then statsDb.day = day; statsDb.sent = 0; statsDb.crafts = 0 end
  statsDb.items = statsDb.items or {}
  return statsDb
end
local function statDelivered(name, label, n)
  local s = statsToday()
  s.sent = s.sent + n
  local e = s.items[name] or {n=0}
  e.n = e.n + n; e.label = label or e.label
  s.items[name] = e
end
local function statCraft() local s = statsToday(); s.crafts = s.crafts + 1 end

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
local function setupPeripherals()
  local b = peripheral.find("me_bridge") or error("me_bridge nicht gefunden")
  local c = peripheral.find("colony_integrator") or error("colony_integrator nicht gefunden")
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
local lastGraves = nil
local buildingNames = {}  -- "x,y,z" -> Name
local function readColony(c)
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

local function readBuildings(c)
  buildingNames = {}
  local list = call(c, "getBuildings")
  if type(list) ~= "table" then return end
  for _, b in ipairs(list) do
    local name = pretty(b.displayName or b.type or "?")
    buildingNames[formatPos(b.pos)] = name
    local lvl, maxLvl = tonumber(b.level) or 0, tonumber(b.maxLevel) or 0
    if b.isWorking then
      S.buildingsWorking[#S.buildingsWorking+1] = {name=name, level=lvl}
    elseif lvl < maxLvl then
      S.buildingsUpgrade[#S.buildingsUpgrade+1] = {name=name, level=lvl, maxLevel=maxLvl, built=b.built ~= false}
    end
  end
  table.sort(S.buildingsUpgrade, function(a, b) if a.level ~= b.level then return a.level < b.level end return a.name < b.name end)
end
local function targetName(pos)
  local p = formatPos(pos)
  return buildingNames[p] or p
end

local diseaseSeen = {}
local function readCitizens(c)
  local list = call(c, "getCitizens")
  if type(list) ~= "table" then return end
  S.citizenCount = #list
  local active = {}
  for _, ct in ipairs(list) do
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
    if #issues > 0 then
      local job = ct.workBuilding and ct.workBuilding.job and pretty(ct.workBuilding.job) or (ct.isChild and "Kind" or "-")
      S.citizens[#S.citizens+1] = {name=asc(ct.name), job=job, issues=table.concat(issues, ", "), severity=severity}
    end
  end
  for k in pairs(diseaseSeen) do if not active[k] then diseaseSeen[k] = nil end end
  table.sort(S.citizens, function(a, b) if a.severity ~= b.severity then return a.severity > b.severity end return a.name < b.name end)
end

local function readVisitors(c, byName)
  local list = call(c, "getVisitors")
  if type(list) ~= "table" then return end
  for _, v in ipairs(list) do
    local cost = v.recruitCost
    local have = 0
    if cost and cost.name and byName then
      for _, s in ipairs(byName[cost.name] or {}) do have = have + (tonumber(s.count) or 0) end
    end
    S.visitors[#S.visitors+1] = {name=asc(v.name), costName=cost and itemLabel(cost) or "?",
      costCount=cost and tonumber(cost.count) or 0, have=have}
  end
end

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
local function readBridgeItems(b)
  local byName = {}
  local ok, res, err = pcall(b.getItems)
  if not ok or type(res) ~= "table" then addError("ME getItems: "..tostring(ok and err or res)); return nil end
  for _, it in ipairs(res) do
    if it.name then byName[it.name] = byName[it.name] or {}; table.insert(byName[it.name], it) end
  end
  return byName
end
local function findBridgeItem(byName, name, hash)
  for _, v in ipairs(byName[name] or {}) do
    if itemHash(v) == hash and (tonumber(v.count) or 0) > 0 then return v end
  end
  return nil
end
local function takeStock(found, n) found.count = (tonumber(found.count) or 0) - n end

local function deliveryKey(pos, name, hash) return pos.."|"..name.."|"..tostring(hash) end
local function recentDelivery(key, cooldown)
  local d = delivered[key]
  if d and now()-d.t < cooldown*1000 then return d end
  return nil
end
-- e = {name, hash, count, side, label, key, cooldown, reqId, entry}
local function queueExport(e)
  if e.name and e.count and e.count > 0 then exportBuffer[#exportBuffer+1] = e end
end
local function processExportBuffer(b)
  for _, it in ipairs(exportBuffer) do
    local side = it.side or cfg.exportSide
    local filter = {name=it.name, count=it.count, nbtHash=it.hash or ""}
    local ok, moved, err = pcall(b.exportItem, side, filter)
    logLine("[EXPORT] "..side.." "..dump(filter).." ok="..tostring(ok).." res="..tostring(moved).." err="..tostring(err))
    local entry = it.entry
    if ok and type(moved) == "number" and moved > 0 then
      statDelivered(it.name, it.label, moved)
      if it.reqId then sentAt[it.reqId] = now() end
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
end

-- Rueckgabe: "started", "running", "nopattern" oder "error"
local function tryCraft(b, name, hash, count, quiet)
  if cfg.craftMaxStack then count = math.max(count, 64) end
  if count <= 0 then count = 1 end
  local filter = {name=name, count=count}; if hash then filter.nbtHash = hash end
  local okR, running = pcall(b.isCrafting, {name=name, nbtHash=hash})
  if okR and running == true then clearMissing(name); return "running" end
  local ok, craftable, err = pcall(b.isCraftable, filter)
  if not ok or craftable == nil then
    local msg = "isCraftable "..shortName(name)..": "..tostring(ok and err or craftable)
    if quiet then logLine(msg) else addError(msg) end
    return "error"
  end
  if not craftable then return "nopattern" end
  local ok2, job, err2 = pcall(b.craftItem, filter)
  if ok2 and job then clearMissing(name); statCraft(); return "started" end
  addError("Craft abgelehnt "..shortName(name)..": "..tostring(ok2 and err2 or job))
  return "error"
end

-- =====================================================================
-- Werkzeuge & Ruestung
-- =====================================================================
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
    if #gear == 0 then entry.state = "MANUELL"; entry.note = "ueber Stufenlimit"; return end
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
    local r = tryCraft(b, c.name, c.hash, remaining, i > 1)
    if r == "started" then entry.state = "CRAFT"; entry.note = prefix.."x"..remaining.." beauftragt"; return end
    if r == "running" then entry.state = "LAEUFT"; entry.note = prefix.."Crafting laeuft"; return end
    if r == "error" then anyError = true end
  end
  if not anyError then recordMissing(candidates[1].name, entry.label, "req:"..tostring(req.id)) end
  entry.state = "FEHLT"
  entry.note = prefix..(anyError and "Fehler, siehe Start" or ("x"..remaining.." kein Pattern"))
end

local function handleRequests(b, c, byName)
  local requests = call(c, "getRequests")
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
      local entry = {state="?", count=count, label=asc(req.displayName or itemLabel(it)),
        target=targetName(req.target), note="", age=req.id and (t-firstSeen[req.id]) or 0}
      S.requests[#S.requests+1] = entry
      local last = req.id and sentAt[req.id]
      local pre = recentDelivery(deliveryKey(tpos, it.name, itemHash(it)), cfg.prestockCooldown)
      if last and (t-last) < cfg.resendCooldown*1000 then
        entry.state = "WARTET"
        entry.note = string.format("abholen, neu in %ds", math.ceil((cfg.resendCooldown*1000-(t-last))/1000))
      elseif pre and not last and pre.n >= count then
        entry.state = "WARTET"; entry.note = "x"..pre.n.." vorgeliefert"
      elseif it.name:find("domum_ornamentum", 1, true) then
        handleDomum(req, it, count, tpos, byName, entry)
      else
        handleGeneric(req, count, tpos, byName, b, entry)
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
  for id in pairs(sentAt) do if not activeIds[id] then sentAt[id] = nil end end
  for id in pairs(firstSeen) do if not activeIds[id] then firstSeen[id] = nil; alertActive["old:"..tostring(id)] = nil end end
end

-- =====================================================================
-- Baustellen: Fortschritt + Vorlieferung
-- =====================================================================
local stageNames = {
  CLEAR="Raeumen", BUILD_SOLID="Rohbau", WEAK_SOLID="Rohbau 2", CLEAR_WATER="Wasser entfernen",
  CLEAR_NON_SOLIDS="Aufraeumen", DECORATE="Deko", SPAWN="Abschluss", REMOVE="Abriss", REMOVE_WATER="Abriss",
}
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
  return math.max(0, math.min(99, pct)), rec.approx
end

local function handleBuilds(b, c, byName)
  local orders = call(c, "getWorkOrders")
  if type(orders) ~= "table" then return end
  local active = {}
  for _, wo in ipairs(orders) do
    active[tostring(wo.id)] = true
    local entry = {
      name = asc(wo.displayName or ("Auftrag "..tostring(wo.id))),
      level = tonumber(wo.level) or 0, targetLevel = tonumber(wo.targetLevel) or 0,
      stage = wo.stage and (function()
        local i, n = stageIndex(wo.stage)
        return (stageNames[wo.stage] or pretty(wo.stage))..(i and (" "..i.."/"..n) or "")
      end)() or nil,
      claimed = wo.isClaimed == true, pct = 0, res = {}, open = 0, missing = 0,
      builder = wo.builderHome and pretty(wo.builderHome.displayName or "Builder") or nil,
    }
    S.builds[#S.builds+1] = entry
    if wo.isClaimed and wo.builderHome and wo.id then
      local builderPos = formatPos(wo.builderHome.pos)
      local res = call(c, "getWorkOrderResources", wo.id)
      if type(res) == "table" then
        entry.pct, entry.approx = buildProgress(wo, res)
        local noPattern = 0
        for _, r in ipairs(res) do
          local it = r.item
          if it and it.name then
            local need = (tonumber(r.needs) or 0) - (tonumber(r.available) or 0) - (tonumber(r.delivering) or 0)
            local hash = itemHash(it)
            local key = deliveryKey(builderPos, it.name, hash)
            local d = recentDelivery(key, cfg.prestockCooldown)
            if d then need = need - d.n end
            for _, q in ipairs(exportBuffer) do if q.key == key then need = need - q.count end end
            if need > 0 then
              entry.open = entry.open + 1
              local row = {label=asc(r.displayName or itemLabel(it)), count=need, state="OFFEN", note=""}
              entry.res[#entry.res+1] = row
              local found = findBridgeItem(byName, it.name, hash)
              local stock = found and (tonumber(found.count) or 0) or 0
              if not cfg.prestockEnabled then
                row.note = stock > 0 and ("im ME: "..stock) or ""
              else
                local send = math.min(need, stock)
                if send > 0 then
                  takeStock(found, send)
                  queueExport({name=it.name, hash=hash, count=send, side=cfg.prestockSide,
                    label=row.label, key=key, cooldown=cfg.prestockCooldown, entry=row})
                  row.state = "OK"; row.note = "x"..send.." geliefert"
                end
                local rest = need - send
                if rest > 0 then
                  local r2 = cfg.prestockCraft and tryCraft(b, it.name, hash, math.min(rest, cfg.prestockMaxCraft), true) or "off"
                  if r2 == "started" then row.state = "CRAFT"; row.note = "x"..math.min(rest, cfg.prestockMaxCraft).." beauftragt"
                  elseif r2 == "running" then row.state = "LAEUFT"; row.note = "Crafting laeuft"
                  else
                    row.state = "FEHLT"; entry.missing = entry.missing + 1
                    row.note = (send > 0 and ("x"..send.." geliefert, ") or "")..(r2 == "nopattern" and "kein Pattern" or "fehlt")
                    if r2 == "nopattern" then
                      noPattern = noPattern + 1
                      recordMissing(it.name, row.label, "build:"..key, true)
                    end
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
  local changed = false
  for k in pairs(buildDb) do if not active[k] then buildDb[k] = nil; changed = true end end
  if changed then saveDb(cfg.buildsFile, buildDb) end
end

-- =====================================================================
-- Scan
-- =====================================================================
local bridge, colony = nil, nil
-- ---------- Update-Pruefung ----------
local updateInfo, lastUpdateCheck = nil, nil
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
local function checkUpdate()
  if not http or (tonumber(cfg.updateCheckHours) or 0) <= 0 then return end
  local now = os.epoch("utc")
  if lastUpdateCheck and now - lastUpdateCheck < cfg.updateCheckHours * 3600000 then return end
  lastUpdateCheck = now
  local base = (cfg.updateUrl ~= "" and cfg.updateUrl) or UPDATE_URL
  if base:find("DEIN-NAME", 1, true) then return end
  if base:sub(-1) ~= "/" then base = base.."/" end
  local ok, h = pcall(http.get, base.."ae2colony.lua?t="..now, {["Cache-Control"] = "no-cache"}, true)
  if not ok or not h then logLine("Update-Pruefung fehlgeschlagen: "..tostring(h)); return end
  local body = h.readAll(); h.close()
  local remote = body and body:match('local scriptVersion%s*=%s*"([^"]+)"')
  if not remote or not isNewer(remote, scriptVersion) then return end
  local first = not updateInfo or updateInfo ~= remote
  updateInfo = remote
  if not first then return end
  logLine("Update verfuegbar: v"..remote)
  if cfg.autoUpdate and shell and fs.exists("update.lua") then
    chat("Installiere Update v"..remote.." ...")
    flushChat()
    shell.run("update", "-y")   -- startet bei Erfolg den Computer neu
  else
    chat("Update v"..remote.." verfuegbar - im Terminal 'update' ausfuehren")
  end
end

local function scan()
  exportBuffer = {}
  S = newState()
  findChatBox()
  readColony(colony)
  readBuildings(colony)
  readCitizens(colony)
  local online, status = bridgeStatus(bridge)
  S.online, S.meStatus = online, status
  if cfg.chatOnOffline then alert("offline", not online, "ME-Netz nicht erreichbar: "..status) end
  if not online then addAlert("ME Bridge: "..status); readVisitors(colony, nil); return end
  readME(bridge)
  local byName = readBridgeItems(bridge)
  readVisitors(colony, byName)
  if not byName then return end
  handleRequests(bridge, colony, byName)   -- Requests zuerst (Buerger warten bereits)
  handleBuilds(bridge, colony, byName)     -- danach Baumaterial mit dem restlichen Bestand
  processExportBuffer(bridge)
  saveDb(cfg.statsFile, statsToday())
end

-- =====================================================================
-- UI
-- =====================================================================
local TABS = {
  {id="start", label="Start"}, {id="anfragen", label="Anfragen"}, {id="bau", label="Bau"},
  {id="buerger", label="Buerger"}, {id="kolonie", label="Kolonie"}, {id="stats", label="Stats"},
}
local stateStyle = {
  FEHLER={colors.red, "FEHLER"}, FEHLT={colors.orange, "FEHLT"}, MANUELL={colors.cyan, "MANUELL"},
  CRAFT={colors.green, "CRAFT"}, LAEUFT={colors.green, "LAEUFT"}, OK={colors.lime, "OK"},
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

local renderers = {}
function renderers.start(w)
  local rows = {}
  if cfg.showColonyStatus then rows[#rows+1] = colonyLine(w) end
  rows[#rows+1] = meLine(w)
  rows[#rows+1] = todayLine()
  local any = false
  if updateInfo then
    local v = updateInfo:match("^[%d%.]+") or updateInfo
    rows[#rows+1] = textRow(fit("Neue Version "..v.." - im Terminal: update", w), colors.yellow)
  end
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
function renderers.bau(w)
  local rows = {}
  if #S.builds == 0 then rows[#rows+1] = textRow("Keine Bauauftraege.", colors.lime); return rows end
  for i, e in ipairs(S.builds) do
    if i > 1 then rows[#rows+1] = blank() end
    local lvl = e.targetLevel > 0 and (" Lvl "..e.level.."->"..e.targetLevel) or ""
    rows[#rows+1] = {seg(e.name..lvl, colors.yellow),
      seg(e.stage and ("  ["..e.stage.."]") or "", colors.lightGray),
      seg(e.builder and ("  "..e.builder) or "", colors.gray)}
    rows[#rows+1] = buildBarRow({name="Fortschritt", pct=e.pct, approx=e.approx, claimed=e.claimed, missing=e.missing}, w)
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
function renderers.buerger(w)
  local rows = {}
  rows[#rows+1] = {seg(string.format("%d Buerger, %d mit Problemen", S.citizenCount, #S.citizens), colors.white)}
  if #S.citizens == 0 then rows[#rows+1] = blank(); rows[#rows+1] = textRow("Alle Buerger in Ordnung.", colors.lime); return rows end
  local sevColor = {colors.yellow, colors.orange, colors.red}
  local wName = math.min(18, math.floor(w*0.3))
  local wJob = w >= 50 and 12 or 0
  for _, ct in ipairs(S.citizens) do
    local row = {seg(fit(ct.name, wName), colors.white)}
    if wJob > 0 then row[#row+1] = seg(fit(ct.job, wJob), colors.gray) end
    row[#row+1] = seg(fit(" "..ct.issues, w-wName-wJob), sevColor[ct.severity] or colors.white)
    rows[#rows+1] = row
  end
  return rows
end
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
  rows[#rows+1] = heading("Besucher in der Taverne ("..#S.visitors..")", w)
  if #S.visitors == 0 then rows[#rows+1] = textRow("  keine", colors.gray) end
  for _, v in ipairs(S.visitors) do
    local enough = v.have >= v.costCount and v.costCount > 0
    local wName = math.min(18, math.floor(w*0.35))
    rows[#rows+1] = {seg(fit("  "..v.name, wName)), seg(fit(v.costCount.."x "..v.costName, w-wName-12)),
      seg(fit("ME: "..v.have, 12, true), enough and colors.lime or colors.orange)}
  end
  return rows
end
function renderers.stats(w)
  local rows = {}
  local s = statsToday()
  rows[#rows+1] = {seg("Heute ("..s.day.."): ", colors.lightGray), seg(s.sent.." geliefert, ", colors.lime), seg(s.crafts.." Crafts", colors.green)}
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

-- ---------- Zeichnen ----------
local views = {}      -- name -> {dev, name, tab, page, pages, isMon, tabX, nav}
local scanTick = cfg.scanInterval

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
  local scanText = " Scan "..scanTick.."s "
  local barW = math.max(0, w - #nav - #scanText - 1)
  local filled = math.floor(scanTick/cfg.scanInterval*barW + 0.5)
  local row = {seg(nav, colors.lightGray), seg(" "), seg(string.rep(" ", filled), colors.white, colors.gray, "#"),
    seg(string.rep(" ", barW-filled), colors.white, colors.black, " "), seg(scanText, colors.gray)}
  drawRow(t, h, w, row, color)
  v.nav = (v.pages > 1) and {prev={1, 3}, next={#nav-2, #nav}} or nil
end

local function drawView(v)
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
  drawRow(win, 1, w, {seg(fit(title, w-#status-1), alarm and colors.red or colors.orange),
    seg(" "..status, S.online and colors.lime or colors.red)}, color)

  -- Zeile 2: Reiter
  -- Anzahl Probleme als Markierung am Reiter
  local badge = {}
  local nReq = 0
  for _, e in ipairs(S.requests) do if e.state == "FEHLT" or e.state == "FEHLER" or e.state == "MANUELL" then nReq = nReq + 1 end end
  if nReq > 0 then badge.anfragen = nReq end
  if #S.citizens > 0 then badge.buerger = #S.citizens end
  -- Breite stufenweise reduzieren, bis alle Reiter passen
  local variants = {
    function(i, tb) return " "..tb.label..(badge[tb.id] and ("("..badge[tb.id]..")") or "").." ", 1 end,
    function(i, tb) return " "..tb.label..(badge[tb.id] and ("("..badge[tb.id]..")") or "").." ", 0 end,
    function(i, tb) return " "..tb.label.." ", 0 end,
    function(i, tb) return " "..tb.label:sub(1, 3)..(badge[tb.id] and "!" or "").." ", 0 end,
    function(i, tb) return " "..i.." ", 0 end,
  }
  local texts, gap
  for _, fn in ipairs(variants) do
    texts, gap = {}, 0
    local total = 0
    for i, tb in ipairs(TABS) do local t2, g = fn(i, tb); texts[i] = t2; gap = g; total = total + #t2 + g end
    if total <= w then break end
  end
  local row, x = {}, 1
  v.tabX = {}
  for i, tb in ipairs(TABS) do
    local active = tb.id == v.tab
    row[#row+1] = seg(texts[i], active and colors.white or colors.lightGray, active and colors.blue or colors.gray)
    v.tabX[#v.tabX+1] = {from=x, to=x+#texts[i]-1, id=tb.id}
    x = x + #texts[i]
    if gap > 0 then row[#row+1] = seg(" ", colors.black, colors.black); x = x + 1 end
  end
  drawRow(win, 2, w, row, color)
  if not color then  -- s/w: aktiven Reiter mit Pfeil markieren
    for _, tx in ipairs(v.tabX) do if tx.id == v.tab then win.setCursorPos(tx.from, 2); win.write(">") end end
  end

  -- Inhalt
  local rows = renderers[v.tab](w)
  local top, bottom = 4, h-1
  local perPage = math.max(1, bottom-top+1)
  v.pages = math.max(1, math.ceil(#rows/perPage))
  if v.page > v.pages then v.page = v.pages end
  local first = (v.page-1)*perPage + 1
  for i = 0, perPage-1 do
    local r = rows[first+i]
    if r then drawRow(win, top+i, w, r, color) end
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
local function drawAllFooters() for _, v in pairs(views) do drawFooter(v) end end

-- ---------- Eingabe ----------
local function setTab(v, id) if v.tab ~= id then v.tab = id; v.page = 1 end; drawView(v) end
local function nextPage(v, d) v.page = ((v.page-1+d) % v.pages) + 1; drawView(v) end
local function tabIndex(id) for i, tb in ipairs(TABS) do if tb.id == id then return i end end return 1 end

local function onTouch(v, x, y)
  local _, h = v.dev.getSize()
  if y == 1 then os.queueEvent("ae2colony_refresh")
  elseif y == 2 then
    for _, tx in ipairs(v.tabX or {}) do if x >= tx.from and x <= tx.to then setTab(v, tx.id); return end end
  elseif y == h then
    if v.nav and x >= v.nav.prev[1] and x <= v.nav.prev[2] then nextPage(v, -1)
    elseif v.nav and x >= v.nav.next[1] and x <= v.nav.next[2] then nextPage(v, 1)
    else os.queueEvent("ae2colony_refresh") end
  else
    nextPage(v, 1)   -- Tippen in den Inhalt blaettert weiter
  end
end

local function inputLoop()
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
        elseif a == keys.r then os.queueEvent("ae2colony_refresh") end
      end
    elseif ev == "char" and views.term then
      local n = tonumber(a); if n and TABS[n] then setTab(views.term, TABS[n].id) end
    elseif ev == "monitor_resize" or ev == "term_resize" then
      drawAll()
    elseif ev == "peripheral" or ev == "peripheral_detach" then
      syncMonitors(); drawAll()
    end
  end
end

-- =====================================================================
-- Start
-- =====================================================================
cleanupOldLogs()
bridge, colony = setupPeripherals()
views.term = {dev=term.current(), name="term", tab="start", page=1, pages=1}
syncMonitors()
findChatBox()
logLine(string.format("%s v%s gestartet - AP %s", scriptName, scriptVersion, apVersionText))

local function scanLoop()
  while true do
    local ok, err = pcall(scan)
    if not ok then addError("Scan abgebrochen: "..tostring(err)) end
    local okU, errU = pcall(checkUpdate)
    if not okU then logLine("Update-Pruefung: "..tostring(errU)) end
    syncMonitors()
    drawAll()
    scanTick = cfg.scanInterval
    while scanTick > 0 do
      flushChat()
      local timer = os.startTimer(1)
      local event, arg
      repeat event, arg = os.pullEvent() until event == "ae2colony_refresh" or (event == "timer" and arg == timer)
      if event == "ae2colony_refresh" then scanTick = 0 else scanTick = scanTick - 1; drawAllFooters() end
    end
  end
end

parallel.waitForAny(scanLoop, inputLoop)
