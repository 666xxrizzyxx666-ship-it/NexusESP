-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Security/GenericBypass.lua
--   Rôle : Bypass générique universel
-- ══════════════════════════════════════════════════════

local GenericBypass = {}

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer

function GenericBypass.Apply(checks)
    print("[Bypass] Application bypass générique...")

    -- Hook les RemoteEvents de détection
    GenericBypass._hookDetectionRemotes(checks)

    -- Humanize les actions
    GenericBypass._applyHumanizer()

    print("[Bypass] Bypass générique appliqué ✓")
end

function GenericBypass._hookDetectionRemotes(checks)
    if not checks or not checks.remotes then return end
    for _, remoteName in ipairs(checks.remotes) do
        pcall(function()
            local remote = game:FindFirstChild(remoteName, true)
            if remote and remote:IsA("RemoteEvent") then
                -- On intercepte sans bloquer pour pas être détecté
                local old = remote.FireServer
                remote.FireServer = function(self, ...)
                    -- Log silencieux
                    return old(self, ...)
                end
            end
        end)
    end
end

function GenericBypass._applyHumanizer()
    -- Délais aléatoires sur les actions répétitives
    getgenv()._nexus_humanize = function(baseDelay)
        local jitter = math.random(-20, 20) / 1000
        return math.max(0, baseDelay + jitter)
    end
end

return GenericBypass
