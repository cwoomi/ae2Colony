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

-- Autostart
local mainCmd = mainPath:gsub("%.lua$", "")
local hasStartup = fs.exists("startup.lua") or fs.exists("startup")
if not hasStartup and not autoYes and ask("Beim Start des Computers automatisch ausfuehren?") then
  writeFile("startup.lua", 'shell.run("'..mainCmd..'")\n')
  hasStartup = true
  say("startup.lua angelegt.", colors.lime)
end

if hasStartup then
  if autoYes or ask("Jetzt neu starten?") then
    say("Neustart ...")
    sleep(1)
    os.reboot()
  end
else
  say("Starten mit: "..mainCmd)
end
