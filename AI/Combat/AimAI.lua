-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Combat/AimAI.lua
--   📁 Dossier : AI/Combat/
--   Rôle : Visée assistée par IA
--          S'adapte au style de jeu de l'ennemi
-- ══════════════════════════════════════════════════════

local AimAI = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

local LearningEngine = nil
local PatternEngine  = nil
local Utils          = nil
local Config         = nil

local enabled   = false
local conn      = nil
local lastTarget = nil
local missStreak = 0

local function getBestTarget(cfg)
    local bestPlayer = nil
    local bestScore  = math.huge
    local fov = cfg.FOV or 100

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")
                if hum and hum.Health > 0 and head then
                    local sameTeam = Utils and Utils.IsSameTeam(player) or false
                    if not (cfg.TeamCheck and sameTeam) then
                        local angle = Utils and Utils.GetAngleFromCenter(head.Position) or 9999
                        if angle <= fov then
                            -- Bonus si ennemi connu du learning engine
                            local ep = LearningEngine and LearningEngine.GetEnemyProfile(player.UserId)
                            local knownBonus = ep and (ep.encounters * 0.5) or 0
                            local s = angle - knownBonus
                            if s < bestScore then
                                bestScore  = s
                                bestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPlayer
end

local function getPredictedPos(player, bone, cfg)
    if not bone then return nil end

    local pattern = PatternEngine and PatternEngine.GetPattern(player.UserId) or "unknown"
    local conf    = PatternEngine and PatternEngine.GetConfidence(player.UserId) or 0
    local ping    = Utils and Utils.GetPing() or 60
    local pred    = PatternEngine and PatternEngine.Predict(player.UserId, ping/1000 * 1.2)

    if pred and conf > 0.5 then
        return pred
    end

    -- Fallback : prédiction basique via vélocité
    local vel = bone.AssemblyLinearVelocity
    return bone.Position + vel * (ping/1000)
end

local function adaptSmooth(cfg)
    local base = cfg.Smoothness or 10
    if LearningEngine then
        local optimal = LearningEngine.GetOptimalSmooth()
        -- Blend entre config utilisateur et optimal AI
        local blend = cfg.AIBlend or 0.5
        return math.floor(base * (1 - blend) + optimal * blend)
    end
    return base
end

function AimAI.Init(deps)
    LearningEngine = deps.LearningEngine
    PatternEngine  = deps.PatternEngine
    Utils          = deps.Utils
    Config         = deps.Config
    print("[AI/Aim] Initialisé ✓")
end

function AimAI.Enable()
    if enabled then return end
    enabled = true

    conn = RunService.RenderStepped:Connect(function()
        local cfg = Config and Config.Current and Config.Current.Aimbot
        if not cfg or not cfg.Enabled then return end

        local player = getBestTarget(cfg)
        if not player then
            lastTarget  = nil
            return
        end

        local char = player.Character
        local bone = char and (char:FindFirstChild(cfg.Bone or "Head") or char:FindFirstChild("HumanoidRootPart"))
        if not bone then return end

        -- Enregistre la position pour pattern
        if PatternEngine then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                PatternEngine.Record(player.UserId, root.Position, root.AssemblyLinearVelocity)
            end
        end

        -- Obtient la position prédite
        local targetPos = getPredictedPos(player, bone, cfg)
        if not targetPos then return end

        -- Adapte la smoothness via AI
        local smooth = adaptSmooth(cfg)

        -- Visée
        local camCF    = Camera.CFrame
        local targetCF = CFrame.new(camCF.Position, targetPos)
        Camera.CFrame  = camCF:Lerp(targetCF, 1 / math.max(1, smooth))

        -- Détecte si on touche (approximatif)
        if lastTarget == player then
            local angle = Utils and Utils.GetAngleFromCenter(targetPos) or 9999
            if angle < 5 then
                missStreak = 0
                if LearningEngine then LearningEngine.Reward("aim_hit") end
                if LearningEngine then LearningEngine.UpdateEnemy(player.UserId, {
                    speed   = bone.AssemblyLinearVelocity.Magnitude,
                    pattern = PatternEngine and PatternEngine.GetPattern(player.UserId),
                }) end
            else
                missStreak = missStreak + 1
                if missStreak > 30 and LearningEngine then
                    LearningEngine.Penalize("aim_miss")
                    missStreak = 0
                end
            end
        end

        lastTarget = player
    end)

    print("[AI/Aim] Activé ✓")
end

function AimAI.Disable()
    if not enabled then return end
    enabled    = false
    lastTarget = nil
    if conn then conn:Disconnect(); conn = nil end

    if LearningEngine then LearningEngine.Save() end
    print("[AI/Aim] Désactivé — profil sauvegardé")
end

function AimAI.Toggle()
    if enabled then AimAI.Disable() else AimAI.Enable() end
end

function AimAI.IsEnabled() return enabled end

return AimAI
