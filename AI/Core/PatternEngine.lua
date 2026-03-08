-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — AI/Core/PatternEngine.lua
--   📁 Dossier : AI/Core/
--   Rôle : Reconnaissance de patterns de mouvement
--          Prédit le comportement des ennemis
-- ══════════════════════════════════════════════════════

local PatternEngine = {}

local MAX_HISTORY = 60  -- frames gardées par joueur
local playerHistory = {}

function PatternEngine.Init(deps)
    print("[AI/Pattern] Initialisé ✓")
end

-- Enregistre la position d'un joueur
function PatternEngine.Record(userId, position, velocity)
    local id = tostring(userId)
    if not playerHistory[id] then
        playerHistory[id] = {
            positions  = {},
            velocities = {},
            pattern    = "unknown",
            confidence = 0,
        }
    end

    local h = playerHistory[id]
    table.insert(h.positions,  position)
    table.insert(h.velocities, velocity)

    if #h.positions > MAX_HISTORY then
        table.remove(h.positions,  1)
        table.remove(h.velocities, 1)
    end

    -- Analyse le pattern si assez de données
    if #h.positions >= 10 then
        PatternEngine._analyzePattern(id)
    end
end

-- Analyse le pattern de mouvement
function PatternEngine._analyzePattern(id)
    local h   = playerHistory[id]
    local pos = h.positions

    if #pos < 10 then return end

    -- Calcule la variation de direction
    local dirChanges = 0
    local totalSpeed = 0

    for i = 2, #pos do
        local prev = pos[i-1]
        local curr = pos[i]
        local dx   = curr.X - prev.X
        local dz   = curr.Z - prev.Z
        totalSpeed = totalSpeed + math.sqrt(dx*dx + dz*dz)

        if i >= 3 then
            local pprev = pos[i-2]
            local d1x = prev.X - pprev.X
            local d1z = prev.Z - pprev.Z
            local dot  = d1x*dx + d1z*dz
            if dot < 0 then dirChanges = dirChanges + 1 end
        end
    end

    local avgSpeed    = totalSpeed / (#pos - 1)
    local changeRate  = dirChanges / #pos

    -- Classification
    if avgSpeed < 2 then
        h.pattern    = "standing"
        h.confidence = 0.9
    elseif changeRate > 0.3 then
        h.pattern    = "strafing"
        h.confidence = 0.7
    elseif changeRate < 0.05 then
        h.pattern    = "linear"
        h.confidence = 0.85
    else
        h.pattern    = "erratic"
        h.confidence = 0.5
    end

    h.avgSpeed = avgSpeed
end

-- Prédit la position future
function PatternEngine.Predict(userId, lookahead)
    lookahead = lookahead or 0.1  -- secondes
    local id  = tostring(userId)
    local h   = playerHistory[id]

    if not h or #h.positions < 5 then return nil end

    local pattern = h.pattern
    local pos     = h.positions
    local vel     = h.velocities

    local lastPos = pos[#pos]
    local lastVel = vel[#vel]

    if pattern == "standing" then
        return lastPos

    elseif pattern == "linear" then
        -- Extrapolation linéaire
        return lastPos + lastVel * lookahead

    elseif pattern == "strafing" then
        -- Prédit avec légère correction
        local avgVel = Vector3.new(0,0,0)
        local count  = math.min(5, #vel)
        for i = #vel - count + 1, #vel do
            avgVel = avgVel + vel[i]
        end
        avgVel = avgVel / count
        return lastPos + avgVel * lookahead * 0.8

    else
        -- Erratic : extrapolation basique
        return lastPos + lastVel * lookahead * 0.5
    end
end

function PatternEngine.GetPattern(userId)
    local h = playerHistory[tostring(userId)]
    return h and h.pattern or "unknown"
end

function PatternEngine.GetConfidence(userId)
    local h = playerHistory[tostring(userId)]
    return h and h.confidence or 0
end

function PatternEngine.Clear(userId)
    playerHistory[tostring(userId)] = nil
end

function PatternEngine.ClearAll()
    playerHistory = {}
end

return PatternEngine
