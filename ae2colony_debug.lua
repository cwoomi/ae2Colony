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

-- ===== Anfragen (Werkzeuge/Ruestung besonders) =====
-- Nur lesende Aufrufe: es wird nichts gecraftet oder exportiert.
local b = peripheral.find("me_bridge")
local function bcall(fn, ...)
  if not b or not b[fn] then return "keine ME Bridge" end
  local ok, v, e = pcall(b[fn], ...)
  if not ok then return "FEHLER: "..tostring(v) end
  if v == nil and e then return "nil ("..tostring(e)..")" end
  return v
end
local cfgOk, cfg = false, nil
if fs.exists("ae2colony_config.lua") then
  local fn = loadfile("ae2colony_config.lua", "t", {})
  if fn then cfgOk, cfg = pcall(fn) end
end
add("")
add("==== Konfiguration ====")
if cfgOk and type(cfg) == "table" then
  add("maxToolTier="..tostring(cfg.maxToolTier).."  maxArmorTier="..tostring(cfg.maxArmorTier)..
    "  maxCraftCandidates="..tostring(cfg.maxCraftCandidates).."  craftMaxStack="..tostring(cfg.craftMaxStack))
else
  add("Config nicht lesbar - Standardwerte")
end
add("Crafting-CPUs: "..ser(bcall("getCraftingCPUs")))

local reqs = call("getRequests")
if type(reqs) ~= "table" then
  add("getRequests: "..tostring(reqs))
else
  add("")
  add("==== Anfragen ("..#reqs..") ====")
  local tiers = {
    wooden=1, golden=1, stone=2, iron=3, diamond=4, netherite=5,
    leather=1, chainmail=3,
  }
  for _, r in ipairs(reqs) do
    local desc = tostring(r.description or "")
    local isGear = desc:lower():find("level:") ~= nil
    add("")
    add(string.format("[%s] %s  x%s  state=%s  ziel=%s", tostring(r.id):sub(1, 8), tostring(r.displayName),
      tostring(r.count), tostring(r.state), ser(r.target)))
    add("  description: "..desc)
    local items = type(r.items) == "table" and r.items or {}
    add("  items ("..#items.."):")
    for i, it in ipairs(items) do
      if i > (isGear and 30 or 5) then add("    ... "..(#items - i + 1).." weitere"); break end
      add(string.format("    %s  nbt=%s  count=%s", tostring(it.name), tostring(it.nbt), tostring(it.count)))
    end
    if isGear then
      -- Craftbarkeit der Vanilla-Varianten pruefen
      local typ
      for _, t in ipairs({"chestplate", "leggings", "helmet", "boots", "sword", "pickaxe", "shovel", "hoe", "axe"}) do
        if desc:lower():find(t, 1, true) then typ = t; break end
      end
      if typ then
        add("  Pruefung Vanilla-"..typ..":")
        for _, pre in ipairs({"wooden", "golden", "stone", "iron", "diamond", "netherite", "leather", "chainmail"}) do
          local name = "minecraft:"..pre.."_"..typ
          local cl = bcall("getCraftableItems", {name=name, nbtHash=""})
          local craftable = type(cl) == "table" and #cl > 0 or bcall("isCraftable", {name=name, count=1})
          local crafting = bcall("isCrafting", {name=name})
          local stock = bcall("getItem", {name=name})
          if craftable == true or (type(stock) == "table" and (stock.count or 0) > 0) or crafting == true then
            add(string.format("    %-28s craftbar=%s  laeuft=%s  im ME=%s", name, tostring(craftable), tostring(crafting),
              type(stock) == "table" and tostring(stock.count) or "0"))
          end
        end
      end
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
