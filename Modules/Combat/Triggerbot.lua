-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Combat/Triggerbot.lua
--   📁 Dossier : Modules/Combat/
--   Rôle : Tire automatiquement quand visé sur ennemi
-- ══════════════════════════════════════════════════════

local Triggerbot = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIS        = game:GetService("VirtualInputManager")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

local Utils   = nil
local Config  = nil
local enabled = false
local conn    = nil
local firing  = false

local function isAimingAtEnemy(cfg)
    local unitRay = Camera:ScreenPointToRay(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = LP.Character
    params.FilterDescendantsInstances = char and {char} or {}

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 2000, params)
    if not result then return false end

    local hit    = result.Instance
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if not player or player == LP then return false end

    if cfg.TeamCheck and Utils and Utils.IsSameTeam(player) then return false end

    return true
end

function Triggerbot.Init(deps)
    Utils  = deps.Utils  or Utils
    Config = deps.Config or Config
    print("[Triggerbot] Initialisé ✓")
end

function Triggerbot.Enable()
    if enabled then return end
    enabled = true

    conn = RunService.Heartbeat:Connect(function()
        local cfg = Config and Config.Current and Config.Current.Triggerbot
        if not cfg or not enabled then return end

        if isAimingAtEnemy(cfg) then
            if not firing then
                firing = true
                task.delay(cfg.Delay or 0.05, function()
                    if enabled and firing then
                        -- Simule click souris
                        pcall(function()
                            VIS:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                            task.wait(0.05)
                            VIS:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        end)
                    end
                    firing = false
                end)
            end
        else
            firing = false
        end
    end)

    print("[Triggerbot] Activé ✓")
end

function Triggerbot.Disable()
    enabled = false
    firing  = false
    if conn then conn:Disconnect(); conn = nil end
    print("[Triggerbot] Désactivé")
end

function Triggerbot.Toggle()
    if enabled then Triggerbot.Disable() else Triggerbot.Enable() end
end

function Triggerbot.IsEnabled()
    return enabled
end

return Triggerbot
