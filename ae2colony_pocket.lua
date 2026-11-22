-- AE2 Colony - Pocket
-- Zeigt den Status des Hauptprogramms auf einem Pocket Computer und erlaubt Fernsteuerung.
--
-- Benoetigt: (Advanced) Pocket Computer mit Wireless- oder Ender-Modem,
--            am Hauptcomputer ebenfalls ein Wireless- oder Ender-Modem.
-- Installation: wget https://raw.githubusercontent.com/cwoomi/ae2Colony/main/ae2colony_pocket.lua startup.lua
--
-- Bedienung: Reiter oben antippen (oder Pfeil links/rechts), scrollen mit Mausrad / Pfeil hoch/runter.
-- Steuern (Reiter "Ctl") braucht den Pocket-Code, der am Hauptcomputer im Reiter Optionen steht.

local VERSION = "1.1"
local UPDATE_URL = "https://raw.githubusercontent.com/cwoomi/ae2Colony/main/ae2colony_pocket.lua"
local UPDATE_EVERY = 3600   -- Sekunden zwischen zwei Update-Pruefungen
local STATUS_PROTO, CMD_PROTO, ACK_PROTO = "ae2colony_status", "ae2colony_cmd", "ae2colony_ack"
local SETTINGS_FILE = ".ae2colony_pocket"

-- ---------- Selbst-Update ----------
-- Der Pocket startet keine Crafts, ein Neustart nach dem Update ist also gefahrlos.
local function isNewer(a, b)
  local x, y = {}, {}
  for n in tostring(a):gmatch("%d+") do x[#x+1] = tonumber(n) end
  for n in tostring(b):gmatch("%d+") do y[#y+1] = tonumber(n) end
  for i = 1, math.max(#x, #y) do
    if (x[i] or 0) ~= (y[i] or 0) then return (x[i] or 0) > (y[i] or 0) end
  end
  return false
end
-- Rueckgabe: Text fuer die Anzeige (bei Erfolg startet der Pocket neu)
local function selfUpdate()
  if not http then return "HTTP aus - kein Update moeglich" end
  local ok, h = pcall(http.get, UPDATE_URL.."?t="..os.epoch("utc"), nil, true)
  if not ok or not h then return "Update-Pruefung fehlgeschlagen" end
  local body = h.readAll(); h.close()
  local remote = body and body:match('local VERSION = "([^"]+)"')
  if not remote then return "Update-Pruefung fehlgeschlagen" end
  if not isNewer(remote, VERSION) then return "Pocket ist aktuell (v"..VERSION..")" end
  if not load(body, "=pocket", "t", {}) then return "Neue Version fehlerhaft - nicht installiert" end
  local path = shell and shell.getRunningProgram() or "startup.lua"
  if path:sub(1, 4) == "rom/" then path = "startup.lua" end
  local f = fs.open(path..".new", "w"); f.write(body); f.close()
  if fs.exists(path) then fs.delete(path) end
  fs.move(path..".new", path)
  term.setBackgroundColor(colors.black); term.clear(); term.setCursorPos(1, 1)
  print("Pocket aktualisiert auf v"..remote)
  print("Neustart ...")
  sleep(1)
  os.reboot()
end

-- ---------- Modem ----------
local modemSide
if pocket and peripheral.isPresent("back") and peripheral.getType("back") == "modem" then modemSide = "back" end
if not modemSide then
  for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" and peripheral.call(name, "isWireless") then modemSide = name end
  end
end
if not modemSide then error("Kein Wireless-/Ender-Modem gefunden (Pocket mit Modem craften)", 0) end
rednet.open(modemSide)

-- ---------- Einstellungen ----------
local settings = {}
if fs.exists(SETTINGS_FILE) then
  local f = fs.open(SETTINGS_FILE, "r"); settings = textutils.unserialize(f.readAll()) or {}; f.close()
end
local function saveSettings()
  local f = fs.open(SETTINGS_FILE, "w"); f.write(textutils.serialize(settings)); f.close()
end

-- ---------- Zustand ----------
local data, dataT, server = nil, nil, settings.server
local tabs = {{id="home", l="Hom"}, {id="prob", l="Prb"}, {id="bau", l="Bau"},
  {id="todo", l="Tdo"}, {id="log", l="Log"}, {id="ctl", l="Ctl"}}
local tab, scroll = 1, 0
local msg, msgT = nil, 0
local buttons = {}   -- {y, x1, x2, fn}

local W, H = term.getSize()
local color = term.isColor()
local function col(c) return color and c or colors.white end

local function fmtAge(ms)
  local m = math.floor(ms / 60000)
  if m < 1 then return math.floor(ms / 1000).."s" end
  if m < 60 then return m.."m" end
  return math.floor(m / 60).."h"..(m % 60).."m"
end
local function fit(s, n)
  s = tostring(s or "")
  if #s > n then return n > 1 and (s:sub(1, n - 1)..".") or s:sub(1, n) end
  return s..string.rep(" ", n - #s)
end
local function send(cmd, arg)
  if not server then msg, msgT = "Noch kein Hauptcomputer gefunden", (os.epoch("utc") / 1000); return end
  rednet.send(server, {cmd=cmd, key=settings.code, arg=arg}, CMD_PROTO)
end

-- ---------- Inhalt je Reiter: Liste von {text, farbe, [aktion]} ----------
local stateColor = {FEHLER=colors.red, FEHLT=colors.orange, MANUELL=colors.cyan, LAEUFT=colors.green,
  START=colors.lightBlue, FERTIG=colors.lime, HAENGT=colors.red, OK=colors.lime, WARTET=colors.lightBlue}

local function lines()
  local L = {}
  -- lange Zeilen an Leerzeichen umbrechen (Buttons nicht)
  local function add(t, c, fn)
    t = tostring(t or "")
    local first = true
    repeat
      local part = t
      if #t > W and not fn then
        local cutAt = t:sub(1, W):match("^.*() ")
        if not cutAt or cutAt < W / 2 then cutAt = W + 1 end
        part, t = t:sub(1, cutAt - 1), "  "..t:sub(cutAt):gsub("^%s+", "")
      else
        t = ""
      end
      L[#L+1] = {t=part, c=c or colors.white, fn=first and fn or nil}
      first = false
    until t == "" or fn
  end
  if not data then
    add("Warte auf Daten vom", colors.lightGray)
    add("Hauptcomputer ...", colors.lightGray)
    add("")
    add("Hauptcomputer braucht ein", colors.gray)
    add("Wireless/Ender Modem.", colors.gray)
    return L
  end
  local id = tabs[tab].id
  if id == "home" then
    local c = data.col or {}
    if c.raid then add(" RAID! ", colors.red) elseif c.attack then add(" Angriff! ", colors.orange) end
    add("Zufr. "..(c.happy and string.format("%.1f", c.happy) or "-").."  Buerger "..tostring(c.cit or "?").."/"..tostring(c.lim or "?"),
      (c.happy or 10) < 5 and colors.orange or colors.white)
    add("Graeber "..tostring(c.graves or 0), colors.lightGray)
    local me = data.me or {}
    if me.online then
      add("ME  Speicher "..tostring(me.storage or "-").."%", (me.storage or 0) >= 90 and colors.red or colors.white)
      add("    Energie  "..tostring(me.energy or "-").."%", (me.energy or 100) <= 10 and colors.red or colors.white)
    else
      add("ME  "..tostring(me.status or "offline"), colors.red)
    end
    if data.wh then add("Lager "..data.wh.."%", data.wh >= 90 and colors.red or colors.white) end
    add("Heute "..tostring(data.today and data.today.sent or 0).." geliefert", colors.lime)
    add("      "..tostring(data.today and data.today.crafts or 0).." Crafts", colors.green)
    if data.update then add("Update "..tostring(data.update)..(data.waiting and " wartet" or " da"), colors.yellow) end
    if #(data.alerts or {}) > 0 then
      add("")
      for _, a in ipairs(data.alerts) do add("! "..a, colors.red) end
    end
  elseif id == "prob" then
    if #(data.problems or {}) == 0 then add("Keine Probleme.", colors.lime) end
    for _, p in ipairs(data.problems or {}) do
      add(fit(p.s, 7).." "..tostring(p.c).."x "..tostring(p.l), stateColor[p.s] or colors.white)
      add("  "..tostring(p.z or "").." "..tostring(p.n or ""), colors.gray)
    end
    if #(data.crafts or {}) > 0 then
      add("")
      add("- Crafts -", colors.lightGray)
      for _, c in ipairs(data.crafts) do
        add(fit(c.s, 7).." "..tostring(c.c).."x "..tostring(c.l)..(c.p and (" "..c.p.."%") or ""), stateColor[c.s] or colors.white)
      end
    end
  elseif id == "bau" then
    if #(data.builds or {}) == 0 then add("Keine Bauauftraege.", colors.lime) end
    for _, b in ipairs(data.builds or {}) do
      add(tostring(b.l), colors.yellow)
      if b.c then
        local pct = tonumber(b.p) or 0
        local bw = W - 7
        local filled = math.floor(pct / 100 * bw + 0.5)
        add(string.rep("#", filled)..string.rep(".", bw - filled).." "..(b.a and "~" or "")..pct.."%",
          (b.m or 0) > 0 and colors.orange or colors.green)
        if b.e then add("  fertig in ca. "..fmtAge(b.e), colors.lightBlue) end
        if (b.m or 0) > 0 then add("  "..b.m.." Material fehlt", colors.orange) end
      else
        add("  wartet auf Builder", colors.gray)
      end
    end
  elseif id == "todo" then
    if #(data.todo or {}) == 0 then add("Nichts zu tun.", colors.lime) end
    for _, t in ipairs(data.todo or {}) do
      add(tostring(t.c).."x "..tostring(t.l), colors.white)
      if t.w and t.w ~= "" then add("  "..tostring(t.w), colors.gray) end
    end
  elseif id == "log" then
    for _, e in ipairs(data.log or {}) do
      local c = e.k == "warn" and colors.orange or (e.k == "gut" and colors.lime or colors.white)
      add(os.date("%H:%M", e.t / 1000).." "..tostring(e.x), c)
    end
  elseif id == "ctl" then
    if not settings.code then
      add("Zum Steuern den Pocket-Code eingeben. Er steht am Hauptcomputer im Reiter Optionen.", colors.lightGray)
    end
    add("[ Code eingeben ]", colors.cyan, function()
      term.setBackgroundColor(colors.black); term.clear(); term.setCursorPos(1, 1)
      term.setTextColor(colors.white)
      print("Pocket-Code eingeben:")
      local c = read()
      if c and c ~= "" then settings.code = c; saveSettings(); msg, msgT = "Code gespeichert", (os.epoch("utc") / 1000) end
    end)
    add("")
    add("[ Jetzt scannen ]", colors.lime, function() send("refresh") end)
    add("[ Pocket-Update suchen ]", colors.cyan, function() msg, msgT = selfUpdate(), (os.epoch("utc") / 1000) end)
    if data.update then
      add("[ Update "..tostring(data.update).." ]", colors.yellow, function() send("update") end)
    end
    add("")
    add("Pocket v"..VERSION.."  Hauptprogramm v"..tostring(data.v or "?"), colors.gray)
    local labels = {craftingEnabled="Auto-Crafting", prestockEnabled="Vorlieferung", prestockCraft="Bau craften",
      autoUpdate="Auto-Update", chatEnabled="Chat", raidSwitchMonitors="Raid-Monitore"}
    local keys = {"craftingEnabled", "prestockEnabled", "prestockCraft", "chatEnabled", "raidSwitchMonitors", "autoUpdate"}
    for _, k in ipairs(keys) do
      local v = data.set and data.set[k]
      if v ~= nil then
        add(fit("["..(v and "AN " or "AUS").."] "..labels[k], W), v and colors.lime or colors.red, function() send("toggle", k) end)
      end
    end
  end
  return L
end

-- ---------- Zeichnen ----------
local function draw()
  term.setBackgroundColor(colors.black); term.clear()
  buttons = {}
  -- Kopf
  term.setCursorPos(1, 1)
  local raid = data and data.col and (data.col.raid or data.col.attack)
  term.setBackgroundColor(col(raid and colors.red or colors.gray)); term.setTextColor(colors.white)
  term.write(fit(" "..(data and data.name or "AE2 Colony"), W))
  -- Reiter
  term.setCursorPos(1, 2)
  local x = 1
  local tw = math.floor(W / #tabs)
  for i, t in ipairs(tabs) do
    term.setCursorPos(x, 2)
    term.setBackgroundColor(col(i == tab and colors.blue or colors.black))
    term.setTextColor(col(i == tab and colors.white or colors.lightGray))
    term.write(fit((i == tab and ">" or " ")..t.l, tw))
    t.x1, t.x2 = x, x + tw - 1
    x = x + tw
  end
  term.setBackgroundColor(colors.black)
  -- Inhalt
  local L = lines()
  local top, rowsN = 3, H - 3
  scroll = math.max(0, math.min(scroll, #L - rowsN))
  for i = 1, rowsN do
    local l = L[i + scroll]
    if l then
      term.setCursorPos(1, top + i - 1)
      term.setTextColor(col(l.c))
      term.write(fit(l.t, W))
      if l.fn then buttons[#buttons+1] = {y=top + i - 1, fn=l.fn} end
    end
  end
  -- Fuss
  term.setCursorPos(1, H)
  term.setBackgroundColor(col(colors.gray))
  local foot
  if msg and (os.epoch("utc") / 1000) - msgT < 5 then
    foot = msg
  elseif dataT then
    local age = (os.epoch("utc") - dataT)
    foot = (age > 120000 and "keine Verbindung! " or "")..fmtAge(age).." alt"
    if age > 120000 then term.setBackgroundColor(col(colors.red)) end
  else
    foot = "verbinde ..."
  end
  term.setTextColor(colors.white)
  term.write(fit(" "..foot..(#L > rowsN and ("  "..(scroll + 1).."/"..(#L - rowsN + 1)) or ""), W))
  term.setBackgroundColor(colors.black)
end

-- ---------- Ablauf ----------
selfUpdate()                                   -- beim Start nach neuer Pocket-Version suchen
rednet.broadcast({cmd="status"}, CMD_PROTO)   -- sofort Daten anfordern
local timer = os.startTimer(1)
local updateTimer = os.startTimer(UPDATE_EVERY)
draw()
while true do
  local ev, a, b, c = os.pullEvent()
  if ev == "rednet_message" then
    if c == STATUS_PROTO and type(b) == "table" then
      data, dataT = b, os.epoch("utc")
      if server ~= a then server = a; settings.server = a; saveSettings() end
      draw()
    elseif c == ACK_PROTO and type(b) == "table" then
      msg, msgT = tostring(b.msg), (os.epoch("utc") / 1000)
      draw()
    end
  elseif ev == "timer" and a == updateTimer then
    selfUpdate()
    updateTimer = os.startTimer(UPDATE_EVERY)
  elseif ev == "timer" and a == timer then
    timer = os.startTimer(1)
    draw()
  elseif ev == "mouse_click" or ev == "monitor_touch" then
    local mx, my = b, c
    if my == 2 then
      for i, t in ipairs(tabs) do if mx >= t.x1 and mx <= t.x2 then tab, scroll = i, 0 end end
    else
      for _, bt in ipairs(buttons) do if bt.y == my then bt.fn(); break end end
    end
    draw()
  elseif ev == "mouse_scroll" then
    scroll = scroll + a
    draw()
  elseif ev == "key" then
    if a == keys.left then tab = (tab - 2) % #tabs + 1; scroll = 0
    elseif a == keys.right then tab = tab % #tabs + 1; scroll = 0
    elseif a == keys.up then scroll = scroll - 1
    elseif a == keys.down then scroll = scroll + 1
    elseif a == keys.r then send("refresh") end
    draw()
  end
end
