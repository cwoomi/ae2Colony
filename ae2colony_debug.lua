-- AE2 Colony Diagnose: schreibt die Rohdaten der Bauauftraege in eine Datei
-- und laedt sie auf Wunsch zu Pastebin hoch.
-- Aufruf:  ae2colony_debug          (nur Datei)
--          ae2colony_debug upload   (Datei + Pastebin-Upload)

local OUT = "ae2colony_debug.txt"
local c = peripheral.find("colony_integrator") or error("colony_integrator nicht gefunden")

local lines = {}
local function add(s) lines[#lines+1] = s end
local function ser(v)
  local ok, s = pcall(textutils.serialize, v, {compact = true})
  if not ok then ok, s = pcall(textutils.serialize, v) end
  return ok and s or tostring(v)
end
local function call(fn, ...)
  local ok, v = pcall(c[fn], ...)
  if ok then return v end
  return "FEHLER: "..tostring(v)
end

add("== AE2 Colony Debug "..os.date("%Y-%m-%d %H:%M:%S"))
if advancedperipherals and advancedperipherals.getAPVersion then
  add("AP-Version: "..tostring(select(2, pcall(advancedperipherals.getAPVersion))))
end
add("Kolonie: "..tostring(call("getColonyName")).."  Baustellen: "..tostring(call("amountOfConstructionSites")))

local orders = call("getWorkOrders")
if type(orders) ~= "table" then
  add("getWorkOrders: "..tostring(orders))
else
  add("Anzahl Bauauftraege: "..#orders)
  for _, wo in ipairs(orders) do
    add("")
    add("==== Auftrag "..tostring(wo.id).." ====")
    add(ser(wo))
    local res = call("getWorkOrderResources", wo.id)
    if type(res) ~= "table" then
      add("Ressourcen: "..tostring(res))
    else
      local sumNeeds, sumAvail, sumDeliv = 0, 0, 0
      add(string.format("Ressourcen (%d Eintraege): needs | available | delivering | status | item", #res))
      for _, r in ipairs(res) do
        local n, a, d = tonumber(r.needs) or 0, tonumber(r.available) or 0, tonumber(r.delivering) or 0
        sumNeeds, sumAvail, sumDeliv = sumNeeds + n, sumAvail + a, sumDeliv + d
        add(string.format("  %6d | %6d | %6d | %-12s | %s (%s) nbt=%s", n, a, d, tostring(r.status),
          tostring(r.displayName), tostring(r.item and r.item.name), tostring(r.item and r.item.nbt)))
      end
      add(string.format("  SUMME needs=%d available=%d delivering=%d", sumNeeds, sumAvail, sumDeliv))
    end
  end
end

-- Gespeicherter Startwert fuer die Prozentanzeige
if fs.exists("ae2colony_builds.db") then
  local f = fs.open("ae2colony_builds.db", "r"); add(""); add("ae2colony_builds.db: "..f.readAll()); f.close()
end

local f = fs.open(OUT, "w"); f.write(table.concat(lines, "\n")); f.close()
print("Gespeichert: "..OUT.." ("..#lines.." Zeilen)")

if ({...})[1] == "upload" then
  if not http then print("HTTP ist auf diesem Server deaktiviert - bitte Datei anders weitergeben."); return end
  shell.run("pastebin", "put", OUT)
else
  print("Zum Hochladen:  ae2colony_debug upload")
end
