-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Bot/BotCore.lua
--   📁 Dossier : AI/Bot/
--   Rôle : Bot IA — joue de façon autonome
--          Navigation + Combat + Objectifs
-- ══════════════════════════════════════════════════════

local BotCore = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

local DecisionTree   = nil
local ThreatLevel    = nil
local PredictionAI   = nil
local PerfectHuman   = nil
local Utils          = nil

local enabled     = false
local state       = "idle"
local conn        = nil
local actionTimer = 0
local currentAction = nil

local function getChar()
    return LP.Character
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ── Actions ───────────────────────────────────────────
local Actions = {}

Actions.engage = function()
    local threats = ThreatLevel and ThreatLevel.GetSorted() or {}
    if #threats == 0 then return end

    local target = threats[1].player
    local char   = target.Character
    if not char then return end

    local head = char:FindFirstChild("Head")
    if not head then return end

    -- Vise la tête via PredictionAI
    local pos = PredictionAI and PredictionAI.GetBonePredicted(target, "Head") or head.Position

    local camCF    = Camera.CFrame
    local targetCF = CFrame.new(camCF.Position, pos)
    local smooth   = PerfectHuman and PerfectHuman.HumanizeSmooth(8) or 8
    Camera.CFrame  = camCF:Lerp(targetCF, 1/smooth)

    -- Tire si bien visé
    local angle = Utils and Utils.GetAngleFromCenter(pos) or 9999
    if angle < 8 then
        -- Simule clic
        pcall(function()
            local VIS = game:GetService("VirtualInputManager")
            local delay = PerfectHuman and PerfectHuman.HumanizeDelay(0.1) or 0.1
            task.delay(delay, function()
                VIS:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                task.wait(0.05)
                VIS:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end)
    end
end

Actions.retreat = function()
    local hum  = getHum()
    local root = getRoot()
    if not hum or not root then return end

    -- Trouve la direction opposée à la menace principale
    local threats = ThreatLevel and ThreatLevel.GetSorted() or {}
    if #threats > 0 then
        local threat = threats[1].player.Character
        if threat then
            local tr = threat:FindFirstChild("HumanoidRootPart")
            if tr then
                local away = (root.Position - tr.Position).Unit
                local targetPos = root.Position + away * 30
                hum:MoveTo(targetPos)
                return
            end
        end
    end
    -- Fallback : recule
    hum:MoveTo(root.Position + root.CFrame.LookVector * -20)
end

Actions.hold = function()
    -- Reste en place, regarde autour
    local hum = getHum()
    if hum then hum:MoveTo(getRoot() and getRoot().Position or Vector3.new(0,0,0)) end
end

Actions.strafe = function()
    local root = getRoot()
    local hum  = getHum()
    if not root or not hum then return end

    local side = root.CFrame.RightVector
    local dir  = math.sin(os.clock() * 3) > 0 and 1 or -1
    hum:MoveTo(root.Position + side * dir * 15)
end

Actions.loot = function()
    -- Cherche les items proches
    local root = getRoot()
    if not root then return end
    local hum  = getHum()

    local closestTool, closestDist = nil, 50
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("Tool") then
            local part = item:FindFirstChildOfClass("BasePart")
            if part then
                local dist = (root.Position - part.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestTool = part
                end
            end
        end
    end

    if closestTool and hum then
        hum:MoveTo(closestTool.Position)
    end
end

-- ── Boucle principale ─────────────────────────────────
local function botLoop(dt)
    if not enabled then return end
    if PerfectHuman and PerfectHuman.IsInPause() then return end

    actionTimer = actionTimer + dt

    -- Réévalue toutes les 0.5s
    if actionTimer >= 0.5 then
        actionTimer = 0

        local myHp    = 100
        local myMaxHp = 100
        local hum     = getHum()
        if hum then
            myHp    = hum.Health
            myMaxHp = hum.MaxHealth
        end

        local threats = ThreatLevel and ThreatLevel.GetSorted() or {}

        local action, score = DecisionTree and DecisionTree.Decide({
            myHp       = myHp,
            myMaxHp    = myMaxHp,
            enemyCount = #threats,
            nearestDist = (#threats > 0 and Utils and
                threats[1].player.Character and
                threats[1].player.Character:FindFirstChild("HumanoidRootPart") and
                Utils.GetDistance(threats[1].player.Character.HumanoidRootPart.Position)
            ) or 9999,
        }) or "hold", 0

        currentAction = action
        state = action
    end

    -- Exécute l'action courante
    if currentAction and Actions[currentAction] then
        pcall(Actions[currentAction])
    end
end

-- ── Init ──────────────────────────────────────────────
function BotCore.Init(deps)
    DecisionTree = deps.DecisionTree
    ThreatLevel  = deps.ThreatLevel
    PredictionAI = deps.PredictionAI
    PerfectHuman = deps.PerfectHuman
    Utils        = deps.Utils
    print("[AI/Bot] Initialisé ✓")
end

function BotCore.Enable()
    if enabled then return end
    enabled = true
    conn    = RunService.Heartbeat:Connect(botLoop)
    print("[AI/Bot] Bot activé — mode autonome ✓")
end

function BotCore.Disable()
    if not enabled then return end
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    currentAction = nil
    state         = "idle"
    print("[AI/Bot] Bot désactivé")
end

function BotCore.Toggle()
    if enabled then BotCore.Disable() else BotCore.Enable() end
end

function BotCore.GetState()  return state end
function BotCore.IsEnabled() return enabled end

return BotCore
