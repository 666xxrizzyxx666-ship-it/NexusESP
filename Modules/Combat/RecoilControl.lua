-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Combat/RecoilControl.lua
--   📁 Dossier : Modules/Combat/
--   Rôle : Contrôle du recul automatique
-- ══════════════════════════════════════════════════════

local RecoilControl = {}

local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera

local Config  = nil
local enabled = false
local firing  = false
local conn    = nil

function RecoilControl.Init(deps)
    Config = deps.Config or Config

    -- Détecte quand on tire
    UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            firing = true
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            firing = false
        end
    end)

    print("[RecoilControl] Initialisé ✓")
end

function RecoilControl.Enable()
    if enabled then return end
    enabled = true

    conn = RunService.RenderStepped:Connect(function()
        local cfg = Config and Config.Current and Config.Current.RecoilControl
        if not cfg or not enabled or not firing then return end

        local strength = (cfg.Strength or 50) / 100
        local compensation = Vector3.new(0, strength * 0.015, 0)

        pcall(function()
            Camera.CFrame = Camera.CFrame * CFrame.new(0, -compensation.Y, 0)
        end)
    end)

    print("[RecoilControl] Activé ✓")
end

function RecoilControl.Disable()
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    print("[RecoilControl] Désactivé")
end

function RecoilControl.Toggle()
    if enabled then RecoilControl.Disable() else RecoilControl.Enable() end
end

function RecoilControl.IsEnabled()
    return enabled
end

return RecoilControl
