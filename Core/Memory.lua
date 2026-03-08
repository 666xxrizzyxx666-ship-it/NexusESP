-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Core/Memory.lua
--   Rôle : Cache intelligent — évite de recalculer
--          les mêmes données à chaque frame
-- ══════════════════════════════════════════════════════

local Memory = {}

local cache     = {}
local hitCount  = 0
local missCount = 0

function Memory.Init()
    cache     = {}
    hitCount  = 0
    missCount = 0
end

-- Stocke une valeur avec TTL (time to live en frames)
function Memory.Set(key, value, ttlFrames)
    cache[key] = {
        value   = value,
        ttl     = ttlFrames or 1,
        counter = 0,
        time    = os.clock(),
    }
end

-- Récupère une valeur (nil si expirée)
function Memory.Get(key)
    local entry = cache[key]
    if not entry then
        missCount = missCount + 1
        return nil
    end
    entry.counter = entry.counter + 1
    if entry.counter >= entry.ttl then
        cache[key] = nil
        missCount  = missCount + 1
        return nil
    end
    hitCount = hitCount + 1
    return entry.value
end

-- Récupère ou calcule si absent/expiré
function Memory.Cache(key, fn, ttlFrames)
    local val = Memory.Get(key)
    if val ~= nil then return val end
    local ok, result = pcall(fn)
    if ok and result ~= nil then
        Memory.Set(key, result, ttlFrames or 1)
        return result
    end
    return nil
end

-- Invalide une clé
function Memory.Invalidate(key)
    cache[key] = nil
end

-- Vide tout le cache
function Memory.Clear()
    cache = {}
end

-- Vide les entrées expirées
function Memory.Cleanup()
    local now = os.clock()
    for key, entry in pairs(cache) do
        if entry.counter >= entry.ttl then
            cache[key] = nil
        end
        -- TTL absolu de 5 secondes
        if now - entry.time > 5 then
            cache[key] = nil
        end
    end
end

-- Stats du cache
function Memory.Stats()
    local total = hitCount + missCount
    return {
        hits      = hitCount,
        misses    = missCount,
        ratio     = total > 0 and (hitCount / total * 100) or 0,
        entries   = (function()
            local n = 0
            for _ in pairs(cache) do n = n + 1 end
            return n
        end)(),
    }
end

return Memory
