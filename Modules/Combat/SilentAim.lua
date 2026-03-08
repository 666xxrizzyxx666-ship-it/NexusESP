-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Combat/SilentAim.lua
--   📁 Dossier : Modules/Combat/
--   Rôle : Silent aim — dévie les projectiles
--          sans bouger la caméra
-- ══════════════════════════════════════════════════════

local SilentAim = {}

local Players  = game:GetService("Players")
local Camera   = workspace.CurrentCamera
local LP       = Players.LocalPlayer

local Utils    = nil
local Config   = nil

local enabled  = false
local hook     = nil

local function getBestTarget(cfg)
    local bestTarget = nil
    local bestAngle  = math.huge
    local fov        = cfg.FOV or 30

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")

                if hum and hum.Health > 0 and head then
                    local sameTeam = Utils and Utils.IsSameTeam(player) or false
                    if not (cfg.TeamCheck and sameTeam) then

                        local visible = true
                        if cfg.WallCheck then
                            visible = Utils and Utils.IsVisible(head) or true
                        end

                        if visible then
                            local angle = Utils and Utils.GetAngleFromCenter(head.Position) or 9999
                            if angle < fov and angle < bestAngle then
                                bestAngle  = angle
                                bestTarget = head
                            end
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

function SilentAim.Init(deps)
    Utils  = deps.Utils  or Utils
    Config = deps.Config or Config
    print("[SilentAim] Initialisé ✓")
end

function SilentAim.Enable()
    if enabled then return end
    enabled = true

    -- Hook FindPartOnRayWithIgnoreList / WorldRoot:Raycast
    local oldRaycast = workspace.FindPartOnRayWithIgnoreList
    hook = oldRaycast

    pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__index

        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local args   = {...}
            local method = getnamecallmethod()

            local cfg = Config and Config.Current and Config.Current.SilentAim
            if cfg and enabled and method == "FindPartOnRayWithIgnoreList" then
                local target = getBestTarget(cfg)
                if target then
                    local ray    = args[1]
                    local origin = ray.Origin
                    local newDir = (target.Position - origin).Unit * ray.Direction.Magnitude
                    args[1]      = Ray.new(origin, newDir)
                end
            end

            return old(self, table.unpack(args))
        end)
        setreadonly(mt, true)
    end)

    print("[SilentAim] Activé ✓")
end

function SilentAim.Disable()
    enabled = false
    print("[SilentAim] Désactivé")
end

function SilentAim.Toggle()
    if enabled then SilentAim.Disable() else SilentAim.Enable() end
end

function SilentAim.IsEnabled()
    return enabled
end

return SilentAim
