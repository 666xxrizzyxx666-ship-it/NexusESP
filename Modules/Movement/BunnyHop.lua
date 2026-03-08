-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Movement/BunnyHop.lua
--   📁 Dossier : Modules/Movement/
--   Rôle : BunnyHop — timing parfait automatique
-- ══════════════════════════════════════════════════════

local BunnyHop = {}

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local enabled = false
local conn    = nil
local holding = false

local function getHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function BunnyHop.Init(deps)
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Space then holding = true end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.KeyCode == Enum.KeyCode.Space then holding = false end
    end)
    print("[BunnyHop] Initialisé ✓")
end

function BunnyHop.Enable()
    if enabled then return end
    enabled = true

    conn = RunService.Heartbeat:Connect(function()
        if not holding then return end
        local hum = getHumanoid()
        if not hum then return end

        if hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    print("[BunnyHop] Activé ✓")
end

function BunnyHop.Disable()
    if not enabled then return end
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    print("[BunnyHop] Désactivé")
end

function BunnyHop.Toggle()
    if enabled then BunnyHop.Disable() else BunnyHop.Enable() end
end

function BunnyHop.IsEnabled() return enabled end

return BunnyHop
