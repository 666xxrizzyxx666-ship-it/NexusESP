-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Movement/Noclip.lua
--   📁 Dossier : Modules/Movement/
--   Rôle : Noclip smooth — passe à travers les murs
-- ══════════════════════════════════════════════════════

local Noclip = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local enabled = false
local conn    = nil

function Noclip.Init(deps)
    LP.CharacterAdded:Connect(function()
        if enabled then Noclip._apply() end
    end)
    print("[Noclip] Initialisé ✓")
end

function Noclip._apply()
    conn = RunService.Stepped:Connect(function()
        local char = LP.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

function Noclip._reset()
    if conn then conn:Disconnect(); conn = nil end
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

function Noclip.Enable()
    if enabled then return end
    enabled = true
    Noclip._apply()
    print("[Noclip] Activé ✓")
end

function Noclip.Disable()
    if not enabled then return end
    enabled = false
    Noclip._reset()
    print("[Noclip] Désactivé")
end

function Noclip.Toggle()
    if enabled then Noclip.Disable() else Noclip.Enable() end
end

function Noclip.IsEnabled() return enabled end

return Noclip
