-- Aurora — Modules/Combat/Aimbot.lua v2.1
local Aimbot = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LP               = Players.LocalPlayer

local enabled    = false
local renderConn = nil

local opt = {
    Smoothness = 10,
    FOV        = 120,
    Prediction = 0,
    Bone       = "Head",
    TeamCheck  = true,
    WallCheck  = false,
    HoldKey    = true,
}

local function getCenter()
    return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
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
                    local sameTeam = opt.TeamCheck
                        and LP.Team ~= nil and player.Team ~= nil
                        and LP.Team == player.Team
                    if not sameTeam then
                        local bone = char:FindFirstChild(opt.Bone)
                            or char:FindFirstChild("HumanoidRootPart")
                        if bone then
                            local pass = true
                            if opt.WallCheck then
                                local obscured = Camera:GetPartsObscuringTarget(
                                    {bone.Position}, {LP.Character, char}
                                )
                                pass = #obscured == 0
                            end
                            if pass then
                                local sp, onScreen = Camera:WorldToViewportPoint(bone.Position)
                                if onScreen then
                                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                    if dist <= opt.FOV and dist < bestDist then
                                        bestDist = dist
                                        best = {player=player, char=char, bone=bone}
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

local function aimAt(pos)
    local camCF    = Camera.CFrame
    local targetCF = CFrame.new(camCF.Position, pos)
    local smooth   = math.max(1, opt.Smoothness)
    Camera.CFrame  = camCF:Lerp(targetCF, 1/smooth)
end

local function onRender()
    if not enabled then return end
    local holding = not opt.HoldKey
        or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not holding then return end
    local t = getBestTarget()
    if not t then return end
    local pos = t.bone.Position
    if opt.Prediction > 0 then
        local ok, vel = pcall(function() return t.bone.AssemblyLinearVelocity end)
        if ok and vel then
            local ping = LP:GetNetworkPing()
            pos = pos + vel * ping * (opt.Prediction/50)
        end
    end
    aimAt(pos)
end

function Aimbot.Init(deps)
    -- Rien au démarrage, pas de renderConn, pas de Drawing
end

function Aimbot.Enable()
    if renderConn then return end
    enabled    = true
    renderConn = RunService.RenderStepped:Connect(onRender)
end

function Aimbot.Disable()
    enabled = false
    if renderConn then renderConn:Disconnect(); renderConn = nil end
end

function Aimbot.SetOption(key, value) opt[key] = value end
function Aimbot.GetOption(key) return opt[key] end

return Aimbot
