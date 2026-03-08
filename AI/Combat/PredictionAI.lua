-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Combat/PredictionAI.lua
--   📁 Dossier : AI/Combat/
--   Rôle : Prédiction avancée des positions ennemies
--          Compensation ping + pattern + vélocité
-- ══════════════════════════════════════════════════════

local PredictionAI = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local PatternEngine  = nil
local LearningEngine = nil
local Utils          = nil

local predCache = {}   -- cache des prédictions
local CACHE_TTL = 0.05 -- secondes

function PredictionAI.Init(deps)
    PatternEngine  = deps.PatternEngine
    LearningEngine = deps.LearningEngine
    Utils          = deps.Utils
    print("[AI/Prediction] Initialisé ✓")
end

-- Calcule la position prédite pour un joueur
function PredictionAI.GetPredicted(player, lookahead)
    if not player then return nil end

    local now = os.clock()
    local id  = player.UserId
    local cached = predCache[id]

    -- Retourne le cache si récent
    if cached and (now - cached.time) < CACHE_TTL then
        return cached.pos
    end

    local char = player.Character
    if not char then return nil end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local ping    = Utils and Utils.GetPing() or 60
    lookahead     = lookahead or (ping / 1000 * 1.5)

    local pattern = PatternEngine and PatternEngine.GetPattern(id) or "unknown"
    local conf    = PatternEngine and PatternEngine.GetConfidence(id) or 0

    local vel     = root.AssemblyLinearVelocity
    local pos     = root.Position
    local pred

    -- Sélectionne la méthode de prédiction selon le pattern
    if pattern == "standing" then
        pred = pos

    elseif pattern == "linear" and conf > 0.7 then
        -- Extrapolation linéaire pure
        pred = pos + vel * lookahead

    elseif pattern == "strafing" and conf > 0.6 then
        -- Moyenne des vélocités récentes
        local patternPred = PatternEngine and PatternEngine.Predict(id, lookahead)
        pred = patternPred or (pos + vel * lookahead * 0.7)

    elseif pattern == "erratic" then
        -- Prédiction conservative
        pred = pos + vel * lookahead * 0.4

    else
        -- Fallback standard
        pred = pos + vel * lookahead
    end

    -- Ajustement gravitationnel si en l'air
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.FloorMaterial == Enum.Material.Air then
        local gravity = workspace.Gravity
        pred = pred - Vector3.new(0, 0.5 * gravity * lookahead * lookahead, 0)
    end

    -- Cache le résultat
    predCache[id] = {pos = pred, time = now}

    return pred
end

-- Prédit pour un os spécifique
function PredictionAI.GetBonePredicted(player, boneName, lookahead)
    local char = player and player.Character
    if not char then return nil end

    local bone = char:FindFirstChild(boneName)
    if not bone then return nil end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return bone.Position end

    -- Offset entre la racine et l'os
    local offset = bone.Position - root.Position

    local rootPred = PredictionAI.GetPredicted(player, lookahead)
    if not rootPred then return bone.Position end

    return rootPred + offset
end

-- Nettoie le cache des joueurs déconnectés
function PredictionAI.Cleanup()
    local players = {}
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        players[p.UserId] = true
    end
    for id in pairs(predCache) do
        if not players[id] then
            predCache[id] = nil
        end
    end
end

return PredictionAI
