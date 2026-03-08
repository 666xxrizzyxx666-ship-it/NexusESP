-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Combat/PerfectHumanizer.lua
--   📁 Dossier : AI/Combat/
--   Rôle : Humanisation parfaite de toutes les actions
--          Simule des imperfections humaines réalistes
-- ══════════════════════════════════════════════════════

local PerfectHumanizer = {}

local RunService = game:GetService("RunService")

local LearningEngine = nil
local frame = 0

-- ── Bruit de Perlin simulé (sans lib externe) ─────────
local function noise(x, y)
    local n = math.sin(x * 127.1 + y * 311.7) * 43758.5453
    return n - math.floor(n)
end

local function smoothNoise(x, y)
    local corners = (noise(x-1,y-1)+noise(x+1,y-1)+noise(x-1,y+1)+noise(x+1,y+1)) / 16
    local sides   = (noise(x-1,y)+noise(x+1,y)+noise(x,y-1)+noise(x,y+1)) / 8
    local center  = noise(x,y) / 4
    return corners + sides + center
end

-- ── Micro-tremblements de main ────────────────────────
local tremorX = 0
local tremorY = 0
local tremorTime = 0

local function updateTremor()
    tremorTime = tremorTime + 0.016
    -- Tremor naturel : 8-12Hz comme la main humaine
    local freq = 10
    tremorX = smoothNoise(tremorTime * freq, 0) * 2 - 1
    tremorY = smoothNoise(0, tremorTime * freq) * 2 - 1
    -- Amplitude faible (0-1.5px)
    tremorX = tremorX * 1.5
    tremorY = tremorY * 1.2
end

-- ── Réactions avec délai humain ───────────────────────
local reactionQueue = {}

function PerfectHumanizer.React(action, minDelay, maxDelay, callback)
    minDelay = minDelay or 0.08
    maxDelay = maxDelay or 0.22
    local delay = minDelay + math.random() * (maxDelay - minDelay)
    table.insert(reactionQueue, {
        action   = action,
        callback = callback,
        delay    = delay,
        elapsed  = 0,
    })
end

-- ── Fatigue de session ────────────────────────────────
local sessionTime   = 0
local FATIGUE_START = 1200  -- 20 min

local function getFatigueMult()
    if sessionTime < FATIGUE_START then return 1 end
    local extra = (sessionTime - FATIGUE_START) / 600
    return math.min(2.0, 1 + extra * 0.3)
end

-- ── Erreur de visée variable ──────────────────────────
local currentError = 0
local errorVel     = 0

local function updateError()
    -- Spring-damper vers zéro avec micro-perturbations
    local target = (math.random() - 0.5) * 0.8 * getFatigueMult()
    errorVel = errorVel * 0.85 + (target - currentError) * 0.04
    currentError = currentError + errorVel
end

-- ── Pauses naturelles ─────────────────────────────────
local pauseTimer = math.random(300, 600)
local inPause    = false
local pauseLen   = 0

local function updatePause()
    if inPause then
        pauseLen = pauseLen - 1
        if pauseLen <= 0 then inPause = false end
        return true
    end
    pauseTimer = pauseTimer - 1
    if pauseTimer <= 0 then
        inPause    = true
        pauseLen   = math.random(3, 15)
        pauseTimer = math.random(200, 500)
        return true
    end
    return false
end

-- ── Update interne ────────────────────────────────────
local conn = nil

function PerfectHumanizer.Init(deps)
    LearningEngine = deps.LearningEngine

    conn = RunService.Heartbeat:Connect(function(dt)
        frame        = frame + 1
        sessionTime  = sessionTime + dt

        updateTremor()
        updateError()
        updatePause()

        -- Traite la queue de réactions
        local i = 1
        while i <= #reactionQueue do
            local r = reactionQueue[i]
            r.elapsed = r.elapsed + dt
            if r.elapsed >= r.delay then
                pcall(r.callback)
                table.remove(reactionQueue, i)
            else
                i = i + 1
            end
        end
    end)

    print("[AI/PerfectHuman] Initialisé ✓")
end

-- ── API publique ──────────────────────────────────────
function PerfectHumanizer.GetTremor()
    return Vector2.new(tremorX, tremorY)
end

function PerfectHumanizer.GetAimError()
    return currentError
end

function PerfectHumanizer.IsInPause()
    return inPause
end

function PerfectHumanizer.GetFatigue()
    return getFatigueMult()
end

function PerfectHumanizer.HumanizeSmooth(base)
    local fatigue = getFatigueMult()
    local noise_  = (math.random() - 0.5) * 3 * fatigue
    return math.max(1, math.floor(base * fatigue + noise_))
end

function PerfectHumanizer.HumanizeDelay(base)
    local fatigue = getFatigueMult()
    local jitter  = (math.random() - 0.5) * base * 0.4 * fatigue
    return math.max(0.01, base + jitter)
end

function PerfectHumanizer.ShouldMistake()
    -- Simule une erreur humaine (~5% des frames)
    return math.random(1, 20) == 1
end

function PerfectHumanizer.Destroy()
    if conn then conn:Disconnect() end
end

return PerfectHumanizer
