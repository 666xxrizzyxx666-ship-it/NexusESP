-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Core/Thread.lua
--   Rôle : Gestion propre des threads/coroutines
--          Évite les memory leaks de threads orphelins
-- ══════════════════════════════════════════════════════

local Thread = {}

local threads    = {}
local threadId   = 0

function Thread.Init()
    threads  = {}
    threadId = 0
end

-- Spawn un thread avec ID trackable
function Thread.Spawn(fn, name)
    threadId = threadId + 1
    local id = threadId
    local t  = {
        id     = id,
        name   = name or ("thread_" .. id),
        active = true,
    }
    t.thread = task.spawn(function()
        local ok, err = pcall(fn)
        if not ok then
            warn("[NexusESP/Thread] Error in '" .. t.name .. "': " .. tostring(err))
        end
        t.active = false
        threads[id] = nil
    end)
    threads[id] = t
    return id
end

-- Spawn avec délai
function Thread.Delay(delay, fn, name)
    return Thread.Spawn(function()
        task.wait(delay)
        fn()
    end, name or "delayed")
end

-- Spawn en boucle avec intervalle
function Thread.Loop(interval, fn, name)
    threadId = threadId + 1
    local id = threadId
    local t  = {
        id     = id,
        name   = name or ("loop_" .. id),
        active = true,
        stop   = false,
    }
    t.thread = task.spawn(function()
        while not t.stop do
            local ok, err = pcall(fn)
            if not ok then
                warn("[NexusESP/Thread] Loop error in '" .. t.name .. "': " .. tostring(err))
            end
            task.wait(interval)
        end
        t.active = false
        threads[id] = nil
    end)
    threads[id] = t
    return id
end

-- Stop un thread
function Thread.Stop(id)
    local t = threads[id]
    if t then
        t.stop   = true
        t.active = false
        threads[id] = nil
    end
end

-- Stop tous les threads
function Thread.StopAll()
    for id, t in pairs(threads) do
        t.stop   = true
        t.active = false
    end
    threads = {}
end

-- Liste des threads actifs
function Thread.GetActive()
    local list = {}
    for _, t in pairs(threads) do
        if t.active then
            table.insert(list, {id=t.id, name=t.name})
        end
    end
    return list
end

function Thread.Count()
    local n = 0
    for _ in pairs(threads) do n = n + 1 end
    return n
end

return Thread
