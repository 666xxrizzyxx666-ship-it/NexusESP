-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Core/DecisionTree.lua
--   📁 Dossier : AI/Core/
--   Rôle : Arbre de décision — choisit la meilleure
--          action en fonction du contexte
-- ══════════════════════════════════════════════════════

local DecisionTree = {}

local LearningEngine = nil
local PatternEngine  = nil

-- ── Contexte de jeu ───────────────────────────────────
local ctx = {
    myHp         = 100,
    myMaxHp      = 100,
    nearestDist  = 9999,
    enemyCount   = 0,
    ammo         = 999,
    isExposed    = false,
    inCover      = false,
    teamAlive    = 1,
}

-- ── Actions possibles ─────────────────────────────────
local ACTIONS = {
    "engage",       -- viser et tirer
    "retreat",      -- reculer pour se soigner
    "hold",         -- tenir position
    "peek",         -- peak coin
    "strafe",       -- strafe actif
    "rush",         -- foncer sur l'ennemi
    "loot",         -- looter
    "rotate",       -- tourner autour de l'ennemi
}

-- ── Évaluation ────────────────────────────────────────
local function score(action)
    local hpPct = ctx.myHp / math.max(1, ctx.myMaxHp)

    if action == "engage" then
        local base = 0.5
        if ctx.nearestDist < 50  then base = base + 0.3 end
        if hpPct > 0.6           then base = base + 0.2 end
        if ctx.ammo > 10         then base = base + 0.1 end
        if ctx.isExposed         then base = base - 0.2 end
        return base

    elseif action == "retreat" then
        local base = 0.2
        if hpPct < 0.3           then base = base + 0.5 end
        if ctx.enemyCount > 2    then base = base + 0.2 end
        if ctx.ammo < 5          then base = base + 0.2 end
        return base

    elseif action == "hold" then
        local base = 0.3
        if ctx.inCover           then base = base + 0.3 end
        if hpPct > 0.5           then base = base + 0.1 end
        if ctx.nearestDist > 100 then base = base + 0.2 end
        return base

    elseif action == "peek" then
        local base = 0.3
        if ctx.inCover           then base = base + 0.3 end
        if hpPct > 0.7           then base = base + 0.1 end
        if ctx.nearestDist < 80  then base = base + 0.2 end
        return base

    elseif action == "strafe" then
        local base = 0.35
        if ctx.isExposed         then base = base + 0.3 end
        if hpPct > 0.4           then base = base + 0.1 end
        return base

    elseif action == "rush" then
        local base = 0.2
        if hpPct > 0.8           then base = base + 0.3 end
        if ctx.enemyCount == 1   then base = base + 0.2 end
        if ctx.ammo > 20         then base = base + 0.1 end
        return base

    elseif action == "loot" then
        local base = 0.1
        if ctx.enemyCount == 0   then base = base + 0.5 end
        if ctx.ammo < 10         then base = base + 0.3 end
        return base

    elseif action == "rotate" then
        local base = 0.25
        if ctx.enemyCount > 1    then base = base + 0.3 end
        return base
    end

    return 0
end

-- ── Décision ──────────────────────────────────────────
function DecisionTree.Decide(context)
    -- Met à jour le contexte
    if context then
        for k, v in pairs(context) do
            ctx[k] = v
        end
    end

    local bestAction = "hold"
    local bestScore  = -1

    for _, action in ipairs(ACTIONS) do
        local s = score(action)
        if s > bestScore then
            bestScore  = s
            bestAction = action
        end
    end

    return bestAction, bestScore
end

-- ── Urgences ──────────────────────────────────────────
function DecisionTree.IsEmergency()
    local hpPct = ctx.myHp / math.max(1, ctx.myMaxHp)
    return hpPct < 0.2 or ctx.ammo == 0
end

function DecisionTree.ShouldRetreat()
    local hpPct = ctx.myHp / math.max(1, ctx.myMaxHp)
    return hpPct < 0.25 or (ctx.enemyCount > 2 and hpPct < 0.5)
end

-- ── Init ──────────────────────────────────────────────
function DecisionTree.Init(deps)
    LearningEngine = deps.LearningEngine
    PatternEngine  = deps.PatternEngine
    print("[AI/Decision] Initialisé ✓")
end

function DecisionTree.GetContext() return ctx end

return DecisionTree
