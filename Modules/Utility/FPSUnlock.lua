-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Utility/FPSUnlock.lua
--   📁 Dossier : Modules/Utility/
--   Rôle : Débloque les FPS au-delà de 60
-- ══════════════════════════════════════════════════════

local FPSUnlock = {}

local enabled = false

function FPSUnlock.Init(deps)
    print("[FPSUnlock] Initialisé ✓")
end

function FPSUnlock.Enable(target)
    target = target or 144
    enabled = true
    pcall(function()
        setfpscap(target)
    end)
    pcall(function()
        game:GetService("RunService"):Set3dRenderingEnabled(true)
    end)
    print("[FPSUnlock] FPS débloqué à "..target.." ✓")
end

function FPSUnlock.Disable()
    enabled = false
    pcall(function() setfpscap(60) end)
    print("[FPSUnlock] FPS remis à 60")
end

function FPSUnlock.Toggle(target)
    if enabled then FPSUnlock.Disable() else FPSUnlock.Enable(target) end
end

function FPSUnlock.IsEnabled() return enabled end

return FPSUnlock
