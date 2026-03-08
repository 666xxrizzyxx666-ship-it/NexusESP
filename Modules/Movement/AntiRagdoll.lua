-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Movement/AntiRagdoll.lua
--   📁 Dossier : Modules/Movement/
--   Rôle : Anti ragdoll + Anti knockback
-- ══════════════════════════════════════════════════════

local AntiRagdoll = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local enabled     = false
local connRagdoll = nil
local connKnock   = nil

local function getHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function AntiRagdoll.Init(deps)
    LP.CharacterAdded:Connect(function()
        if enabled then
            task.wait(0.5)
            AntiRagdoll._apply()
        end
    end)
    print("[AntiRagdoll] Initialisé ✓")
end

function AntiRagdoll._apply()
    -- Anti ragdoll
    local hum = getHumanoid()
    if hum then
        connRagdoll = hum.StateChanged:Connect(function(_, new)
            if not enabled then return end
            if new == Enum.HumanoidStateType.Ragdoll
            or new == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end

    -- Anti knockback
    connKnock = RunService.Heartbeat:Connect(function()
        if not enabled then return end
        local root = getRoot()
        if not root then return end
        local vel = root.AssemblyLinearVelocity
        -- Empêche les vélocités extrêmes causées par des knockbacks
        if vel.Magnitude > 100 then
            root.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
        end
    end)
end

function AntiRagdoll._reset()
    if connRagdoll then connRagdoll:Disconnect(); connRagdoll = nil end
    if connKnock   then connKnock:Disconnect();   connKnock   = nil end
end

function AntiRagdoll.Enable()
    if enabled then return end
    enabled = true
    AntiRagdoll._apply()
    print("[AntiRagdoll] Activé ✓")
end

function AntiRagdoll.Disable()
    if not enabled then return end
    enabled = false
    AntiRagdoll._reset()
    print("[AntiRagdoll] Désactivé")
end

function AntiRagdoll.Toggle()
    if enabled then AntiRagdoll.Disable() else AntiRagdoll.Enable() end
end

function AntiRagdoll.IsEnabled() return enabled end

return AntiRagdoll
