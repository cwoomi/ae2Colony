-- AE2 Colony - Lager-Sender
-- Liest den Fuellstand des MineColonies-Lagers (Warehouse) und funkt ihn an den Hauptcomputer.
--
-- Aufbau:
--   * Computer direkt an den Lager-Huettenblock stellen (oder per Wired Modem verbinden)
--   * Wireless oder Ender Modem an diesen Computer UND an den Hauptcomputer
--   * Installation:  wget https://raw.githubusercontent.com/cwoomi/ae2Colony/main/ae2colony_lager.lua startup.lua
--     (laeuft dann automatisch nach jedem Neustart)

local PROTOCOL = "ae2colony_lager"
local INTERVAL = 20   -- Sekunden zwischen zwei Sendungen

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

term.clear(); term.setCursorPos(1, 1)
print("AE2 Colony - Lager-Sender")
print("Modem: "..modemName.."   Intervall: "..INTERVAL.."s")

while true do
  local p, name = findWarehouse()
  local x, y = term.getCursorPos()
  term.setCursorPos(1, 4); term.clearLine()
  if not p then
    print("Lager nicht gefunden - Computer an den Lager-Huettenblock stellen")
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
      rednet.broadcast({size=size, used=used, total=total, kinds=kinds, top=top}, PROTOCOL)
      print(string.format("%s  %d/%d Slots (%d%%) gesendet", os.date("%H:%M:%S"), used, size,
        size > 0 and math.floor(used / size * 100) or 0))
    else
      print("Lesefehler: "..tostring(okS and list or size))
    end
  end
  sleep(INTERVAL)
end
