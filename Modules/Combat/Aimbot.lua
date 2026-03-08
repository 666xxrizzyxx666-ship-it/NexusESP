-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Combat/Aimbot.lua
--   📁 Dossier : Modules/Combat/
--   Rôle : Aimbot smooth + snap + rage
--          AI-assisted targeting
-- ══════════════════════════════════════════════════════

local Aimbot = {}

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera         = workspace.CurrentCamera
local LP             = Players.LocalPlayer

local Utils    = nil
local Config   = nil

local enabled  = false
local target   = nil
local renderConn = nil

local FOVCircle = nil

-- ── FOV Circle (64 segments) ──────────────────────────
local fovLines = {}
local FOV_SEGMENTS = 64

local function createFOVCircle()
    for i = 1, FOV_SEGMENTS do
        local l = Drawing.new("Line")
        l.Visible   = false
        l.Thickness = 1
        l.ZIndex    = 5
        l.Outline   = false
        fovLines[i] = l
    end
end

local function updateFOVCircle(cfg)
    if not cfg or not cfg.ShowFOV then
        for i = 1, FOV_SEGMENTS do
            if fovLines[i] then fovLines[i].Visible = false end
        end
        return
    end

    local cx     = Camera.ViewportSize.X / 2
    local cy     = Camera.ViewportSize.Y / 2
    local radius = cfg.FOV or 100
    local color  = Color3.fromRGB(255,255,255)

    for i = 1, FOV_SEGMENTS do
        local a1 = (i - 1) / FOV_SEGMENTS * math.pi * 2
        local a2 = i       / FOV_SEGMENTS * math.pi * 2
        local l  = fovLines[i]
        l.From      = Vector2.new(cx + math.cos(a1) * radius, cy + math.sin(a1) * radius)
        l.To        = Vector2.new(cx + math.cos(a2) * radius, cy + math.sin(a2) * radius)
        l.Color     = color
        l.Thickness = 1
        l.Visible   = true
    end
end

-- ── Trouver la meilleure cible ────────────────────────
local function getBestTarget(cfg)
    local bestTarget  = nil
    local bestScore   = math.huge
    local fov         = cfg.FOV or 100
    local priority    = cfg.Priority or "Closest"
    local boneTarget  = cfg.Bone    or "Head"

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then end -- skip, pas de continue
        if player ~= LP then
            local char = player.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")

                if hum and hum.Health > 0 and root then
                    -- Team check
                    local sameTeam = Utils and Utils.IsSameTeam(player) or false
                    if not (cfg.TeamCheck and sameTeam) then

                        local bone = char:FindFirstChild(boneTarget)
                            or char:FindFirstChild("HumanoidRootPart")

                        if bone then
                            -- Wall check
                            local visible = true
                            if cfg.WallCheck then
                                visible = Utils and Utils.IsVisible(bone) or true
                            end

                            if visible then
                                local angle = Utils and Utils.GetAngleFromCenter(bone.Position) or 9999

                                if angle <= fov then
                                    local score

                                    if priority == "Closest" then
                                        score = angle
                                    elseif priority == "LowestHP" then
                                        score = hum.Health
                                    elseif priority == "MostVisible" then
                                        score = angle * 0.5
                                    else
                                        score = angle
                                    end

                                    if score < bestScore then
                                        bestScore  = score
                                        bestTarget = {
                                            player = player,
                                            char   = char,
                                            bone   = bone,
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-- ── Humanizer ─────────────────────────────────────────
local function humanize(smoothness, mode)
    local base = smoothness or 10
    if mode == "Rage" then return 0 end
    if mode == "Lite" then
        base = base * 1.5
        base = base + math.random(-3, 3)
    else
        base = base + math.random(-1, 1)
    end
    return math.max(1, base)
end

-- ── Viser ─────────────────────────────────────────────
local function aimAt(position, cfg)
    local mode       = cfg.Mode       or "Normal"
    local smoothness = cfg.Smoothness or 10

    local camCF  = Camera.CFrame
    local targetCF = CFrame.new(camCF.Position, position)

    if mode == "Rage" then
        Camera.CFrame = targetCF
    else
        local smooth = humanize(smoothness, mode)
        local newCF  = camCF:Lerp(targetCF, 1 / smooth)
        Camera.CFrame = newCF
    end
end

-- ── Render loop ───────────────────────────────────────
local function onRender()
    local cfg = Config and Config.Current and Config.Current.Aimbot
    if not cfg then return end

    updateFOVCircle(cfg)

    if not enabled then return end

    -- Vérifie si le bouton est maintenu
    local holding = false
    if cfg.HoldKey then
        holding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    else
        holding = true
    end

    if not holding then
        target = nil
        return
    end

    -- Trouve la cible
    target = getBestTarget(cfg)

    if target then
        local bone = target.bone
        if bone then
            local pos = bone.Position

            -- Prédiction
            if cfg.Prediction and cfg.Prediction > 0 then
                local vel   = bone.AssemblyLinearVelocity
                local ping  = Utils and Utils.GetPing() or 50
                pos = pos + vel * (ping / 1000) * (cfg.Prediction / 50)
            end

            aimAt(pos, cfg)
        end
    end
end

-- ── Init ──────────────────────────────────────────────
function Aimbot.Init(deps)
    Utils  = deps.Utils  or Utils
    Config = deps.Config or Config

    createFOVCircle()

    renderConn = RunService.RenderStepped:Connect(onRender)
    print("[Aimbot] Initialisé ✓")
end

function Aimbot.Enable()
    enabled = true
end

function Aimbot.Disable()
    enabled = false
    target  = nil
    for i = 1, FOV_SEGMENTS do
        if fovLines[i] then fovLines[i].Visible = false end
    end
end

function Aimbot.Toggle()
    if enabled then Aimbot.Disable() else Aimbot.Enable() end
end

function Aimbot.IsEnabled()
    return enabled
end

function Aimbot.GetTarget()
    return target
end

function Aimbot.Destroy()
    Aimbot.Disable()
    if renderConn then renderConn:Disconnect() end
    for i = 1, FOV_SEGMENTS do
        if fovLines[i] then pcall(function() fovLines[i]:Remove() end) end
    end
end

return Aimbot
