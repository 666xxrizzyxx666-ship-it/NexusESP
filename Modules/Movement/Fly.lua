-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Movement/Fly.lua
--   📁 Dossier : Modules/Movement/
--   Rôle : Fly indétectable via BodyVelocity
-- ══════════════════════════════════════════════════════

local Fly = {}

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera   = workspace.CurrentCamera
local LP       = Players.LocalPlayer

local Config   = nil
local enabled  = false
local conn     = nil
local bv       = nil
local bg       = nil

local speed_override = nil
local keys = {
    up   = false,
    down = false,
}

local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Fly.Init(deps)
    Config = deps.Config or Config

    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Space   then keys.up   = true end
        if inp.KeyCode == Enum.KeyCode.LeftControl then keys.down = true end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.KeyCode == Enum.KeyCode.Space       then keys.up   = false end
        if inp.KeyCode == Enum.KeyCode.LeftControl then keys.down = false end
    end)

    LP.CharacterAdded:Connect(function()
        if enabled then
            task.wait(0.5)
            Fly._start()
        end
    end)

    task.defer(function()end)
end

function Fly._start()
    local root = getRoot()
    if not root then return end

    -- Désactive la gravité
    local hum = getHumanoid()
    if hum then hum.PlatformStand = true end

    -- BodyVelocity
    bv = Instance.new("BodyVelocity", root)
    bv.Velocity        = Vector3.new(0,0,0)
    bv.MaxForce        = Vector3.new(1e5, 1e5, 1e5)

    -- BodyGyro pour stabiliser
    bg = Instance.new("BodyGyro", root)
    bg.MaxTorque       = Vector3.new(1e5, 1e5, 1e5)
    bg.D               = 100
    bg.CFrame          = root.CFrame

    conn = RunService.Heartbeat:Connect(function()
        local cfg = Config and Config.Current and Config.Current.Fly
        local speed = speed_override or (cfg and cfg.Speed) or 50
        local r = getRoot()
        if not r then return end

        local camDir = Camera.CFrame.LookVector
        local right  = Camera.CFrame.RightVector

        local vel = Vector3.new(0,0,0)
        local moveDir = Vector3.new(0,0,0)

        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camDir end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camDir end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right  end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right  end

        if keys.up   then moveDir = moveDir + Vector3.new(0,1,0) end
        if keys.down then moveDir = moveDir - Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then
            vel = moveDir.Unit * speed
        end

        bv.Velocity = vel
        bg.CFrame   = Camera.CFrame
    end)
end

function Fly._stop()
    if conn then conn:Disconnect(); conn = nil end
    if bv   then bv:Destroy();   bv   = nil end
    if bg   then bg:Destroy();   bg   = nil end

    local hum = getHumanoid()
    if hum then hum.PlatformStand = false end
end

function Fly.Enable()
    if enabled then return end
    enabled = true
    Fly._start()
    task.defer(function()end)
end

function Fly.Disable()
    if not enabled then return end
    enabled = false
    Fly._stop()
    task.defer(function()end)
end

function Fly.Toggle()
    if enabled then Fly.Disable() else Fly.Enable() end
end

function Fly.IsEnabled() return enabled end

return Fly

-- SetSpeed alias
function Fly.SetSpeed(v)
    if Config then Config:Set("Fly", {Speed=v}) end
    speed_override = v
end
