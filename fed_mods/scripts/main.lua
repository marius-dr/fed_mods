




---@type string directory of the mod.
local modDirectory = g_currentModDirectory or ""
---@type string name of the mod.
local modName = g_currentModName or "unknown"

---Init the mod.
local function init()
print(modName .. " - APalletSilo main.init");
    g_placeableSpecializationManager:addSpecialization("aPalletSilo", "APalletSilo", modDirectory .. "scripts/aPalletSilo.lua", nil)
    
    -- load event
    local path = modDirectory .. "scripts/SpawnPalletsAtSiloEvent.lua";
    source(path)
    
print(modName .. " - SiloObjectFillLevelSpezialisation main.init");
    g_placeableSpecializationManager:addSpecialization("siloObjectFillLevelSpezialisation", "SiloObjectFillLevelSpezialisation", modDirectory .. "scripts/siloObjectFillLevelSpezialisation.lua", nil)
end

init()