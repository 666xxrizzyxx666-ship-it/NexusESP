-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Movement/Speed.lua
--   📁 Dossier : Modules/Movement/
--   Rôle : Speed hack indétectable
-- ══════════════════════════════════════════════════════

local Speed = {}

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local Config  = nil
local enabled = false
local original = 16

local function getHumanoid()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function Speed.Init(deps)
    Config = deps.Config or Config

    -- Reset si le personnage respawn
    LP.CharacterAdded:Connect(function(char)
        if enabled then
            task.wait(0.5)
            Speed._apply()
        end
    end)

    print("[Speed] Initialisé ✓")
end

function Speed._apply()
    local cfg = Config and Config.Current and Config.Current.Speed
    local hum = getHumanoid()
    if not hum then return end

    original = hum.WalkSpeed
    hum.WalkSpeed = cfg and cfg.Value or 32
end

function Speed._reset()
    local hum = getHumanoid()
    if not hum then return end
    hum.WalkSpeed = original
end

function Speed.Enable()
    if enabled then return end
    enabled = true
    Speed._apply()
    print("[Speed] Activé ✓")
end

function Speed.Disable()
    if not enabled then return end
    enabled = false
    Speed._reset()
    print("[Speed] Désactivé")
end

function Speed.Toggle()
    if enabled then Speed.Disable() else Speed.Enable() end
end

function Speed.SetValue(v)
    local hum = getHumanoid()
    if hum and enabled then hum.WalkSpeed = v end
end

function Speed.IsEnabled() return enabled end

return Speed
