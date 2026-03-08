-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Combat/ThreatLevel.lua
--   📁 Dossier : AI/Combat/
--   Rôle : Évalue la menace de chaque ennemi
--          Priorise les cibles dangereuses
-- ══════════════════════════════════════════════════════

local ThreatLevel = {}

local Players = game:GetService("Players")
local Camera  = workspace.CurrentCamera
local LP      = Players.LocalPlayer

local LearningEngine = nil
local Utils          = nil

local THREAT = {
    CRITICAL = 4,  -- tire sur toi
    HIGH     = 3,  -- proche et armé
    MEDIUM   = 2,  -- dans la zone
    LOW      = 1,  -- loin ou désarmé
    NONE     = 0,
}

local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function evaluateThreat(player)
    local char = player.Character
    if not char then return THREAT.NONE, 0 end

    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root then return THREAT.NONE, 0 end

    local myRoot = getRoot()
    if not myRoot then return THREAT.NONE, 0 end

    local dist    = (myRoot.Position - root.Position).Magnitude
    local weapon  = Utils and Utils.GetWeapon(char) or nil
    local angle   = Utils and Utils.GetAngleFromCenter(root.Position) or 9999
    local hpPct   = hum.Health / math.max(1, hum.MaxHealth)

    -- Score de menace (0-100)
    local score = 0

    -- Distance
    if dist < 30  then score = score + 40
    elseif dist < 80  then score = score + 25
    elseif dist < 150 then score = score + 10
    else score = score + 2 end

    -- Armé
    if weapon then score = score + 20 end

    -- Regarde vers nous
    local lookDir = root.CFrame.LookVector
    local toMe    = (myRoot.Position - root.Position).Unit
    local dot     = lookDir:Dot(toMe)
    if dot > 0.8 then score = score + 25  -- nous regarde directement
    elseif dot > 0.4 then score = score + 10 end

    -- Santé (ennemi avec peu de vie = moins dangereux)
    if hpPct > 0.8 then score = score + 5
    elseif hpPct < 0.3 then score = score - 10 end

    -- Profil appris
    if LearningEngine then
        local ep = LearningEngine.GetEnemyProfile(player.UserId)
        if ep and ep.encounters > 5 and ep.hitRate > 0.6 then
            score = score + 15  -- ennemi précis = plus dangereux
        end
    end

    score = math.clamp(score, 0, 100)

    local level
    if score >= 70  then level = THREAT.CRITICAL
    elseif score >= 50 then level = THREAT.HIGH
    elseif score >= 30 then level = THREAT.MEDIUM
    elseif score >= 10 then level = THREAT.LOW
    else level = THREAT.NONE end

    return level, score
end

function ThreatLevel.Init(deps)
    LearningEngine = deps.LearningEngine
    Utils          = deps.Utils
    print("[AI/Threat] Initialisé ✓")
end

-- Retourne la liste triée par menace
function ThreatLevel.GetSorted()
    local threats = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local level, score = evaluateThreat(player)
            if level > THREAT.NONE then
                table.insert(threats, {
                    player = player,
                    level  = level,
                    score  = score,
                })
            end
        end
    end

    -- Tri par score décroissant
    table.sort(threats, function(a, b)
        return a.score > b.score
    end)

    return threats
end

function ThreatLevel.Get(player)
    return evaluateThreat(player)
end

function ThreatLevel.GetHighest()
    local sorted = ThreatLevel.GetSorted()
    return sorted[1]
end

function ThreatLevel.LEVELS() return THREAT end

return ThreatLevel
