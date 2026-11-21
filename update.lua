-- AE2 Colony Updater
-- Laedt die neueste Version von GitHub und installiert sie.
--
--   update          pruefen, Aenderungen zeigen, installieren
--   update check    nur pruefen
--   update force    neu installieren, auch wenn schon aktuell
--   update -y       ohne Rueckfragen (installiert und startet neu, falls ein Startup existiert)
--
-- Erstinstallation auf einem neuen Computer:
--   wget run <DOWNLOAD_URL>update.lua

local DEFAULT_URL = "https://raw.githubusercontent.com/cwoomi/ae2Colony/main/"
local STATE_FILE  = ".ae2colony_update"
local CONFIG_FILE = "ae2colony_config.lua"
local MARKER      = "AE2 Colony - ATM10 Edition"

local args = {...}
local autoYes, checkOnly, force = false, false, false
for _, a in ipairs(args) do
  if a == "-y" or a == "yes" then autoYes = true
  elseif a == "check" then checkOnly = true
  elseif a == "force" then force = true end
end

local function say(msg, color)
  if color and term.isColor() then term.setTextColor(color) end
  print(msg)
  if color and term.isColor() then term.setTextColor(colors.white) end
end
local function fail(msg) say("FEHLER: "..msg, colors.red); return false end
local function ask(q)
  if autoYes then return true end
  write(q.." (j/n) ")
  local a = (read() or ""):lower()
  return a:sub(1, 1) == "j" or a:sub(1, 1) == "y"
end

if not http then
  fail("HTTP ist auf diesem Server deaktiviert.")
  return
end

-- ---------- Einstellungen ----------
local function readFile(p)
  if not fs.exists(p) or fs.isDir(p) then return nil end
  local f = fs.open(p, "r"); if not f then return nil end
  local s = f.readAll(); f.close(); return s
end
local function writeFile(p, s)
  local f = fs.open(p, "w"); if not f then return false end
  f.write(s); f.close(); return true
end

local state = textutils.unserialize(readFile(STATE_FILE) or "") or {}

local baseUrl = DEFAULT_URL
do
  local fn = fs.exists(CONFIG_FILE) and loadfile(CONFIG_FILE, "t", {})
  if fn then
    local ok, c = pcall(fn)
    if ok and type(c) == "table" and type(c.updateUrl) == "string" and c.updateUrl ~= "" then baseUrl = c.updateUrl end
  end
end
if baseUrl:sub(-1) ~= "/" then baseUrl = baseUrl.."/" end
if baseUrl:find("DEIN-NAME", 1, true) then
  fail("Download-Adresse ist noch nicht eingetragen (DEFAULT_URL in update.lua bzw. updateUrl in "..CONFIG_FILE..").")
  return
end

-- ---------- Wo liegt das Hauptprogramm? ----------
local function findMain()
  if state.main and fs.exists(state.main) then return state.main end
  for _, name in ipairs(fs.list("/")) do
    if not fs.isDir(name) and not name:match("%.bak$") and not name:match("%.new$") then
      local f = fs.open(name, "r")
      if f then
        local head = f.read and f.read(200) or (f.readLine() or "")
        f.close()
        if type(head) == "string" and head:find(MARKER, 1, true) then return name end
      end
    end
  end
  return "ae2colony.lua"
end
local mainPath = findMain()

local selfPath = shell.getRunningProgram()
if not selfPath or selfPath:sub(1, 4) == "rom/" or selfPath:find("wget", 1, true) then selfPath = "update.lua" end

local FILES = {
  {src="ae2colony.lua",       dst=mainPath,              main=true},
  {src="ae2colony_debug.lua", dst="ae2colony_debug.lua"},
  {src="update.lua",          dst=selfPath},
}

-- ---------- Versionen ----------
local function versionOf(src) return src and src:match('local scriptVersion%s*=%s*"([^"]+)"') end
local function vparts(v)
  local t = {}
  for n in (tostring(v or ""):match("^[%d%.]+") or ""):gmatch("%d+") do t[#t+1] = tonumber(n) end
  return t
end
local function vcmp(a, b)
  local x, y = vparts(a), vparts(b)
  for i = 1, math.max(#x, #y) do
    local p, q = x[i] or 0, y[i] or 0
    if p ~= q then return p < q and -1 or 1 end
  end
  return 0
end
-- Aenderungen aus dem Kopfkommentar ("-- v0.9: ...") seit der installierten Version
local function changesSince(src, since)
  local out, cur = {}, nil
  for line in (src.."\n"):gmatch("([^\n]*)\n") do
    if not line:match("^%-%-") then break end
    local v, text = line:match("^%-%-%s*v([%d%.]+):%s*(.*)$")
    if v then cur = v
    elseif cur then text = line:match("^%-%-%s+(%S.*)$") end
    if cur and text and text ~= "" and (not since or vcmp(cur, since) > 0) then
      out[#out+1] = (v and ("v"..v..": ") or "   ")..text
    end
  end
  return out
end

-- ---------- Download ----------
local function fetch(name)
  local url = baseUrl..name.."?t="..os.epoch("utc")
  local h, err = http.get(url, {["Cache-Control"] = "no-cache"}, true)
  if not h then return nil, tostring(err) end
  local code = h.getResponseCode and h.getResponseCode() or 200
  local body = h.readAll(); h.close()
  if code ~= 200 then return nil, "HTTP "..tostring(code) end
  if not body or #body == 0 then return nil, "leere Datei" end
  return body
end

say("AE2 Colony Updater", colors.orange)
say("Quelle: "..baseUrl, colors.lightGray)

local installed = versionOf(readFile(mainPath))
local mainSrc, err = fetch("ae2colony.lua")
if not mainSrc then fail("Download von ae2colony.lua: "..err); return end
local remote = versionOf(mainSrc)
if not remote then fail("Keine Versionsnummer in der heruntergeladenen Datei gefunden."); return end

say("Installiert: "..(installed or "-").."   Verfuegbar: "..remote)
local newer = not installed or vcmp(remote, installed) > 0
if not newer and not force then
  say("Du hast bereits die aktuelle Version.", colors.lime)
  if not checkOnly then say("Neu installieren: update force", colors.lightGray) end
  return
end

local changes = changesSince(mainSrc, installed)
if #changes > 0 then
  say("Neu:", colors.yellow)
  for i = 1, math.min(#changes, 12) do print(" "..changes[i]) end
  if #changes > 12 then print(" ... ("..(#changes - 12).." weitere Zeilen)") end
end
if checkOnly then say("Installieren mit: update", colors.lightGray); return end
if not ask("Jetzt installieren?") then say("Abgebrochen."); return end

-- Alle Dateien erst laden und pruefen, dann ersetzen
local bodies = {}
for _, f in ipairs(FILES) do
  local body, e = f.main and mainSrc or nil, nil
  if not body then body, e = fetch(f.src) end
  if not body then fail("Download von "..f.src..": "..e); return end
  local ok, perr = load(body, "="..f.src, "t", {})
  if not ok then fail(f.src.." ist fehlerhaft ("..tostring(perr).."), nichts wurde geaendert."); return end
  bodies[f] = body
end

for _, f in ipairs(FILES) do
  local tmp = f.dst..".new"
  if not writeFile(tmp, bodies[f]) then fail("Kann "..tmp.." nicht schreiben (Speicher voll?)"); return end
  if fs.exists(f.dst) then
    if fs.exists(f.dst..".bak") then fs.delete(f.dst..".bak") end
    fs.move(f.dst, f.dst..".bak")
  end
  fs.move(tmp, f.dst)
  say("  "..f.dst, colors.lime)
end
state.main = mainPath
writeFile(STATE_FILE, textutils.serialize(state))
say("Version "..remote.." installiert. Alte Dateien liegen als .bak daneben.", colors.lime)

-- Autostart: auf Advanced Computern in einem eigenen Tab (Terminal bleibt frei)
local mainCmd = mainPath:gsub("%.lua$", "")
local function startupCode(cmd)
  return '-- AE2 Colony Autostart (angelegt von update.lua)\n'..
    'if multishell then\n'..
    '  local id = shell.openTab("'..cmd..'")\n'..
    '  multishell.setTitle(id, "AE2 Colony")\n'..
    'else\n'..
    '  shell.run("'..cmd..'")\n'..
    'end\n'
end
local hasStartup = fs.exists("startup.lua") or fs.exists("startup")
local oldStartup = readFile("startup.lua")
if oldStartup == 'shell.run("'..mainCmd..'")\n' then
  -- frueher vom Installer angelegt -> auf Hintergrund-Tab umstellen
  writeFile("startup.lua", startupCode(mainCmd))
  say("startup.lua auf Hintergrund-Tab umgestellt.", colors.lime)
elseif not hasStartup and not autoYes and ask("Beim Start des Computers automatisch ausfuehren?") then
  writeFile("startup.lua", startupCode(mainCmd))
  hasStartup = true
  say("startup.lua angelegt (laeuft im Hintergrund-Tab).", colors.lime)
end

-- Laufende ME-Crafts? AP 0.8.2a crasht den Server, wenn ein ueber die ME Bridge gestarteter Craft
-- fertig wird, nachdem der Computer neu gestartet wurde. Daher vorher warten bzw. warnen.
local function busyCpus()
  local b = peripheral and peripheral.find("me_bridge")
  if not b or not b.getCraftingCPUs then return 0 end
  local ok, cpus = pcall(b.getCraftingCPUs)
  if not ok or type(cpus) ~= "table" then return 0 end
  local n = 0
  for _, c in ipairs(cpus) do if c.isBusy then n = n + 1 end end
  return n
end
local safeToReboot = true
if hasStartup then
  local busy = busyCpus()
  if busy > 0 and autoYes then
    -- vom Programm aus gestartet: dessen eigene Crafts sind schon fertig; kurz auf den Rest warten
    say("Warte auf "..busy.." belegte Crafting-CPU(s) (max. 2 min) ...", colors.yellow)
    local t0 = os.epoch("utc")
    while busy > 0 and os.epoch("utc") - t0 < 120000 do sleep(5); busy = busyCpus() end
  elseif busy > 0 then
    say("Achtung: "..busy.." Crafting-CPU(s) sind belegt.", colors.yellow)
    say("Ein Neustart waehrend Crafts, die dieser Computer gestartet hat, kann mit", colors.yellow)
    say("Advanced Peripherals 0.8.2a den Server crashen.", colors.yellow)
    safeToReboot = ask("Trotzdem jetzt neu starten?")
    if not safeToReboot then say("Spaeter neu starten mit: reboot (wenn die Crafts fertig sind)") end
  end
end

if hasStartup and safeToReboot then
  if autoYes or ask("Jetzt neu starten?") then
    say("Neustart ...")
    sleep(1)
    os.reboot()
  end
else
  say("Starten mit: "..mainCmd)
end
