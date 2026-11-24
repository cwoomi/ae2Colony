-- AE2 Colony - Lager-Sender
-- Liest den Fuellstand des MineColonies-Lagers (Warehouse) und funkt ihn an den Hauptcomputer.
--
-- Aufbau:
--   * Computer direkt an den Lager-Huettenblock stellen (oder per Wired Modem verbinden)
--   * Wireless oder Ender Modem an diesen Computer UND an den Hauptcomputer
--   * Installation:  wget https://raw.githubusercontent.com/cwoomi/ae2Colony/main/ae2colony_lager.lua startup.lua
--     (laeuft dann automatisch nach jedem Neustart)
--
-- Kolonie-Relais (optional): Steht zusaetzlich ein Colony Integrator an diesem Computer (direkt oder per
-- Wired Modem), beantwortet er die Kolonie-Abfragen des Hauptcomputers per Funk. Der Hauptcomputer
-- braucht dann keinen eigenen Integrator und kann ausserhalb der Kolonie stehen.

local PROTOCOL = "ae2colony_lager"
local INTERVAL = 20   -- Sekunden zwischen zwei Sendungen
local RELAY_PROTO, REPLY_PROTO = "ae2colony_colony", "ae2colony_colony_r"

local function isWarehouse(name)
  if name:lower():find("warehouse") then return true end
  for _, t in ipairs({peripheral.getType(name)}) do
    if tostring(t):lower():find("warehouse") then return true end
  end
  return false
end
local function findWarehouse()
  for _, name in ipairs(peripheral.getNames()) do
    if isWarehouse(name) then
      local p = peripheral.wrap(name)
      if p and p.list and p.size then return p, name end
    end
  end
end

local modemName
for _, name in ipairs(peripheral.getNames()) do
  if peripheral.getType(name) == "modem" and peripheral.call(name, "isWireless") then modemName = name end
end
if not modemName then error("Kein Wireless- oder Ender-Modem gefunden", 0) end
rednet.open(modemName)

local integrator = peripheral.find("colony_integrator")
if integrator then rednet.host(RELAY_PROTO, "kolonie_"..os.getComputerID()) end

term.clear(); term.setCursorPos(1, 1)
print("AE2 Colony - Lager-Sender")
print("Modem: "..modemName.."   Intervall: "..INTERVAL.."s")
print(integrator and ("Kolonie-Relais aktiv (ID "..os.getComputerID()..")") or "Kein Colony Integrator - nur Lager-Fuellstand")

local function status(line, text)
  local x, y = term.getCursorPos()
  term.setCursorPos(1, line); term.clearLine(); term.write(text)
  term.setCursorPos(x, y)
end

-- Kolonie-Relais: Anfragen sammeln (eigene Coroutine, damit waehrend eines Integrator-Aufrufs
-- keine Funknachricht verloren geht) und der Reihe nach beantworten
local queue, served = {}, 0
local function receiveLoop()
  while true do
    local from, msg = rednet.receive(RELAY_PROTO)
    if type(msg) == "table" and type(msg.m) == "string" then
      queue[#queue+1] = {from=from, msg=msg}
      os.queueEvent("ae2colony_relay")
    end
  end
end
local function serveLoop()
  while true do
    if #queue == 0 then os.pullEvent("ae2colony_relay") end
    local job = table.remove(queue, 1)
    if job then
      local m, args = job.msg.m, job.msg.a or {}
      local reply = {id=job.msg.id}
      local fn = integrator and integrator[m]
      if type(fn) ~= "function" then
        reply.ok, reply.err = false, integrator and ("Unbekannte Methode "..m) or "Kein Colony Integrator am Relais"
      else
        local res = table.pack(pcall(fn, table.unpack(args, 1, args.n or #args)))
        reply.ok = res[1]
        if res[1] then reply.r = table.pack(table.unpack(res, 2, res.n)) else reply.err = res[2] end
      end
      local ok = pcall(rednet.send, job.from, reply, REPLY_PROTO)
      if not ok then reply.r, reply.ok, reply.err = nil, false, "Antwort zu gross"; pcall(rednet.send, job.from, reply, REPLY_PROTO) end
      served = served + 1
      status(5, os.date("%H:%M:%S").."  Relais: "..served.." Abfragen beantwortet")
    end
  end
end

local function lagerLoop()
while true do
  local p, name = findWarehouse()
  if not p then
    status(4, "Lager nicht gefunden - Computer an den Lager-Huettenblock stellen")
  else
    local okS, size = pcall(p.size)
    local okL, list = pcall(p.list)
    if okS and okL and type(list) == "table" then
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
      rednet.broadcast({size=size, used=used, total=total, kinds=kinds, top=top, items=by}, PROTOCOL)
      status(4, string.format("%s  %d/%d Slots (%d%%) gesendet", os.date("%H:%M:%S"), used, size,
        size > 0 and math.floor(used / size * 100) or 0))
    else
      status(4, "Lesefehler: "..tostring(okS and list or size))
    end
  end
  sleep(INTERVAL)
end
end

term.setCursorPos(1, 7)
parallel.waitForAny(lagerLoop, receiveLoop, serveLoop)
