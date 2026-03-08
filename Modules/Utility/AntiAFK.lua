-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Utility/AntiAFK.lua
--   📁 Dossier : Modules/Utility/
--   Rôle : Anti AFK — empêche le kick automatique
-- ══════════════════════════════════════════════════════

local AntiAFK = {}

local Players    = game:GetService("Players")
local VIS        = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local enabled = false
local conn    = nil
local timer   = 0
local INTERVAL = 60 -- secondes

function AntiAFK.Init(deps)
    -- Hook le kick AFK natif de Roblox
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and self == LP then
                return -- bloque le kick AFK
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)

    print("[AntiAFK] Initialisé ✓")
end

function AntiAFK.Enable()
    if enabled then return end
    enabled = true
    timer   = 0

    conn = RunService.Heartbeat:Connect(function(dt)
        if not enabled then return end
        timer = timer + dt
        if timer >= INTERVAL then
            timer = 0
            -- Simule un mouvement minimal
            pcall(function()
                VIS:SendKeyEvent(true,  "W", false, game)
                task.wait(0.1)
                VIS:SendKeyEvent(false, "W", false, game)
            end)
        end
    end)

    print("[AntiAFK] Activé ✓")
end

function AntiAFK.Disable()
    if not enabled then return end
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    print("[AntiAFK] Désactivé")
end

function AntiAFK.Toggle()
    if enabled then AntiAFK.Disable() else AntiAFK.Enable() end
end

function AntiAFK.IsEnabled() return enabled end

return AntiAFK
