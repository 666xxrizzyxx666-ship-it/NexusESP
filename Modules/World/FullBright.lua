-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/World/FullBright.lua
--   📁 Dossier : Modules/World/
--   Rôle : FullBright — voit dans le noir
-- ══════════════════════════════════════════════════════

local FullBright = {}

local Lighting = game:GetService("Lighting")

local enabled  = false
local original = {}

function FullBright.Init(deps)
    print("[FullBright] Initialisé ✓")
end

function FullBright.Enable()
    if enabled then return end
    enabled = true

    -- Sauvegarde les valeurs originales
    original = {
        Brightness       = Lighting.Brightness,
        ClockTime        = Lighting.ClockTime,
        FogEnd           = Lighting.FogEnd,
        FogStart         = Lighting.FogStart,
        GlobalShadows    = Lighting.GlobalShadows,
        Ambient          = Lighting.Ambient,
        OutdoorAmbient   = Lighting.OutdoorAmbient,
    }

    Lighting.Brightness     = 2
    Lighting.ClockTime      = 14
    Lighting.FogEnd         = 100000
    Lighting.FogStart       = 0
    Lighting.GlobalShadows  = false
    Lighting.Ambient        = Color3.fromRGB(178,178,178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)

    -- Supprime les effets de lighting
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect")
        or effect:IsA("ColorCorrectionEffect")
        or effect:IsA("SunRaysEffect")
        or effect:IsA("BloomEffect") then
            effect.Enabled = false
        end
    end

    print("[FullBright] Activé ✓")
end

function FullBright.Disable()
    if not enabled then return end
    enabled = false

    for k, v in pairs(original) do
        pcall(function() Lighting[k] = v end)
    end

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect")
        or effect:IsA("ColorCorrectionEffect")
        or effect:IsA("SunRaysEffect")
        or effect:IsA("BloomEffect") then
            effect.Enabled = true
        end
    end

    print("[FullBright] Désactivé")
end

function FullBright.Toggle()
    if enabled then FullBright.Disable() else FullBright.Enable() end
end

function FullBright.IsEnabled() return enabled end

return FullBright
