-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Movement/InfiniteJump.lua
--   📁 Dossier : Modules/Movement/
--   Rôle : Infinite jump
-- ══════════════════════════════════════════════════════

local InfiniteJump = {}

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local LP      = Players.LocalPlayer

local enabled = false
local conn    = nil

local function getHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function InfiniteJump.Init(deps)
    print("[InfiniteJump] Initialisé ✓")
end

function InfiniteJump.Enable()
    if enabled then return end
    enabled = true

    conn = UIS.InputBegan:Connect(function(inp, gp)
        if gp or not enabled then return end
        if inp.KeyCode == Enum.KeyCode.Space then
            local hum = getHumanoid()
            if hum and hum.FloorMaterial == Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    print("[InfiniteJump] Activé ✓")
end

function InfiniteJump.Disable()
    if not enabled then return end
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    print("[InfiniteJump] Désactivé")
end

function InfiniteJump.Toggle()
    if enabled then InfiniteJump.Disable() else InfiniteJump.Enable() end
end

function InfiniteJump.IsEnabled() return enabled end

return InfiniteJump
