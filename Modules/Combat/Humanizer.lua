-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Combat/Humanizer.lua
--   📁 Dossier : Modules/Combat/
--   Rôle : Humanisation de toutes les actions
--          Rend le comportement indétectable
-- ══════════════════════════════════════════════════════

local Humanizer = {}

local RunService = game:GetService("RunService")

local Config  = nil
local enabled = true

-- ── Micro erreurs de visée ────────────────────────────
local errorX = 0
local errorY = 0
local errorTimer = 0

local function updateErrors()
    errorTimer = errorTimer + 1
    if errorTimer >= math.random(10, 30) then
        errorTimer = 0
        errorX = (math.random() - 0.5) * 3
        errorY = (math.random() - 0.5) * 3
    end
    -- Smooth vers zéro
    errorX = errorX * 0.85
    errorY = errorY * 0.85
end

-- ── Délai humanisé ────────────────────────────────────
function Humanizer.Delay(base)
    if not enabled then return base end
    local jitter = (math.random() - 0.5) * base * 0.3
    return math.max(0.01, base + jitter)
end

-- ── Offset de visée humanisé ──────────────────────────
function Humanizer.AimOffset()
    if not enabled then return Vector2.new(0,0) end
    updateErrors()
    return Vector2.new(errorX, errorY)
end

-- ── Smoothness humanisée ──────────────────────────────
function Humanizer.Smoothness(base)
    if not enabled then return base end
    local noise = math.random(-2, 2)
    return math.max(1, base + noise)
end

-- ── Simule des pauses naturelles ──────────────────────
local pauseTimer    = 0
local pauseDuration = 0
local isPausing     = false

function Humanizer.ShouldPause()
    if not enabled then return false end
    pauseTimer = pauseTimer + 1

    if isPausing then
        pauseDuration = pauseDuration - 1
        if pauseDuration <= 0 then
            isPausing = false
        end
        return true
    end

    -- Pause aléatoire toutes les 200-500 frames
    if pauseTimer >= math.random(200, 500) then
        pauseTimer    = 0
        isPausing     = true
        pauseDuration = math.random(5, 20)
        return true
    end

    return false
end

-- ── Session manager ───────────────────────────────────
local sessionStart  = os.time()
local SESSION_LIMIT = 3600 -- 1 heure

function Humanizer.ShouldRest()
    local elapsed = os.time() - sessionStart
    return elapsed >= SESSION_LIMIT
end

function Humanizer.GetSessionTime()
    return os.time() - sessionStart
end

-- ── Init ──────────────────────────────────────────────
function Humanizer.Init(deps)
    Config = deps.Config or Config
    sessionStart = os.time()
    print("[Humanizer] Initialisé ✓")
end

function Humanizer.Enable()  enabled = true  end
function Humanizer.Disable() enabled = false end
function Humanizer.IsEnabled() return enabled end

return Humanizer
