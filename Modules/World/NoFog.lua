-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/World/NoFog.lua
--   📁 Dossier : Modules/World/
--   Rôle : Supprime le brouillard + la météo
-- ══════════════════════════════════════════════════════

local NoFog = {}

local Lighting   = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local enabled   = false
local conn      = nil
local origFogEnd   = 100000
local origFogStart = 0

function NoFog.Init(deps)
    print("[NoFog] Initialisé ✓")
end

function NoFog.Enable()
    if enabled then return end
    enabled = true

    origFogEnd   = Lighting.FogEnd
    origFogStart = Lighting.FogStart

    -- Supprime fog en continu (certains jeux le remettent)
    conn = RunService.Heartbeat:Connect(function()
        if Lighting.FogEnd < 100000 then
            Lighting.FogEnd   = 100000
            Lighting.FogStart = 0
        end
    end)

    -- Supprime la météo
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Atmosphere") then
            v.Density   = 0
            v.Offset    = 0
        end
        if v.Name == "Rain" or v.Name == "Snow" or v.Name == "Fog" then
            pcall(function() v.Enabled = false end)
        end
    end

    print("[NoFog] Activé ✓")
end

function NoFog.Disable()
    if not enabled then return end
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    Lighting.FogEnd   = origFogEnd
    Lighting.FogStart = origFogStart
    print("[NoFog] Désactivé")
end

function NoFog.Toggle()
    if enabled then NoFog.Disable() else NoFog.Enable() end
end

function NoFog.IsEnabled() return enabled end

return NoFog
