-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Main.lua
--   Point d'entrée unique du script
-- ══════════════════════════════════════════════════════

local REPO = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

-- Charge et lance Init
local ok, err = pcall(function()
    local Init = loadstring(game:HttpGet(REPO .. "Core/Init.lua", true))()
    Init.Start()
end)

if not ok then
    warn("[NexusESP] Erreur critique au démarrage : " .. tostring(err))
end
