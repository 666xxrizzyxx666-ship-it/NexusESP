-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Game/Detector.lua
--   Rôle : Détection automatique du jeu par PlaceId
-- ══════════════════════════════════════════════════════

local Detector = {}

local GAMES = {
    -- Phantom Forces
    [292439477]  = "PhantomForces",
    -- Arsenal
    [286090429]  = "Arsenal",
    -- Da Hood
    [2788229376] = "DaHood",
    -- Murder Mystery 2
    [142823291]  = "MurderMystery",
    -- Bedwars
    [6872265039] = "Bedwars",
    -- Doors
    [6516141723] = "Doors",
    -- Fisch
    [16732694052]= "Fisch",
    -- Blox Fruits
    [2753915549] = "BloxFruits",
}

function Detector.Init(deps)
    -- rien à initialiser, juste pour compatibilité
end

function Detector.Detect()
    local placeId = game.PlaceId
    return GAMES[placeId] or "Generic"
end

function Detector.GetGameName()
    return Detector.Detect()
end

function Detector.IsGame(name)
    return Detector.Detect() == name
end

return Detector
