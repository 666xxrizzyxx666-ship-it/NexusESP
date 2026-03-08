-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Game/Games/Generic/Init.lua
--   Rôle : Module générique pour tous les jeux
-- ══════════════════════════════════════════════════════

local Generic = {}

function Generic.Init()
    print("[Game/Generic] Module générique chargé")
    Generic.AimbotBone  = "Head"
    Generic.ItemFolder  = nil
    Generic.TeamFolder  = nil
end

function Generic.GetWeapon(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

function Generic.GetAmmo(char)
    return nil
end

return Generic
