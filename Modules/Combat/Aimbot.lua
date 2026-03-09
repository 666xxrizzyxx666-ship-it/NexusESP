-- Aurora — Modules/Combat/Aimbot.lua v2.0
local Aimbot = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer

local Utils  = nil
local enabled   = false
local renderConn = nil

-- ── State interne ─────────────────────────────────────
local opt = {
    Smoothness = 10,
    FOV        = 120,
    Prediction = 0,
    Bone       = "Head",
    TeamCheck  = true,
    WallCheck  = false,
    HoldKey    = true,  -- maintenir clic droit
}

-- ── FOV Circle (64 segments, jamais auto-visible) ─────
local fovLines    = {}
local fovVisible  = false
local FOV_SEG     = 64

local function buildFOVCircle()
    for i = 1, FOV_SEG do
        local l = Drawing.new("Line")
        l.Visible   = false
        l.Thickness = 1
        l.ZIndex    = 5
        l.Outline   = false
        l.Color     = Color3.fromRGB(255, 255, 255)
        fovLines[i] = l
    end
end

local function renderFOVCircle()
    if not fovVisible then
        for i = 1, FOV_SEG do
            if fovLines[i] then fovLines[i].Visible = false end
        end
        return
    end
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    local r  = opt.FOV
    for i = 1, FOV_SEG do
        local a1 = (i-1)/FOV_SEG * math.pi*2
        local a2 = i    /FOV_SEG * math.pi*2
        local l  = fovLines[i]
        l.From    = Vector2.new(cx + math.cos(a1)*r, cy + math.sin(a1)*r)
        l.To      = Vector2.new(cx + math.cos(a2)*r, cy + math.sin(a2)*r)
        l.Visible = true
    end
end

-- ── Meilleure cible ───────────────────────────────────
local function getCenter()
    return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end

local function getScreenPos(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen
end

local function getBestTarget()
    local best, bestDist = nil, math.huge
    local center = getCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    -- Team check
                    local sameTeam = opt.TeamCheck
                        and LP.Team ~= nil
                        and player.Team ~= nil
                        and LP.Team == player.Team
                    if not sameTeam then
                        local bone = char:FindFirstChild(opt.Bone)
                            or char:FindFirstChild("HumanoidRootPart")
                        if bone then
                            -- Wall check
                            local pass = true
                            if opt.WallCheck then
                                local origin = Camera.CFrame.Position
                                local dir    = (bone.Position - origin).Unit
                                local ray    = Ray.new(origin, dir * 1000)
                                local hit    = workspace:FindPartOnRayWithIgnoreList(
                                    ray, {LP.Character, char}
                                )
                                pass = hit == nil
                            end

                            if pass then
                                local sp, onScreen = getScreenPos(bone.Position)
                                if onScreen then
                                    local dist = (sp - center).Magnitude
                                    if dist <= opt.FOV and dist < bestDist then
                                        bestDist = dist
                                        best     = {player=player, char=char, bone=bone}
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ── Viser ─────────────────────────────────────────────
local function aimAt(pos)
    local camCF    = Camera.CFrame
    local targetCF = CFrame.new(camCF.Position, pos)
    local smooth   = math.max(1, opt.Smoothness)
    Camera.CFrame  = camCF:Lerp(targetCF, 1 / smooth)
end

-- ── Render ────────────────────────────────────────────
local function onRender()
    renderFOVCircle()
    if not enabled then return end

    local holding = opt.HoldKey
        and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        or not opt.HoldKey

    if not holding then return end

    local t = getBestTarget()
    if not t then return end

    local pos = t.bone.Position
    -- Prédiction
    if opt.Prediction > 0 then
        local ok, vel = pcall(function()
            return t.bone.AssemblyLinearVelocity
        end)
        if ok and vel then
            local ping = LP:GetNetworkPing() * 1000
            pos = pos + vel * (ping/1000) * (opt.Prediction/50)
        end
    end

    aimAt(pos)
end

-- ── API ───────────────────────────────────────────────
function Aimbot.Init(deps)
    Utils = deps and deps.Utils or Utils
    buildFOVCircle()
    -- PAS de renderConn ici — seulement quand activé
end

function Aimbot.Enable()
    if renderConn then return end
    enabled    = true
    renderConn = RunService.RenderStepped:Connect(onRender)
end

function Aimbot.Disable()
    enabled = false
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    -- Cache le FOV circle
    fovVisible = false
    renderFOVCircle()
end

function Aimbot.SetOption(key, value)
    opt[key] = value
end

function Aimbot.ShowFOV(v)
    fovVisible = v
    if not renderConn then
        -- Lance juste le FOV circle sans l'aimbot
        renderConn = RunService.RenderStepped:Connect(onRender)
    end
    if not v and not enabled then
        if renderConn then renderConn:Disconnect(); renderConn = nil end
    end
end

return Aimbot
