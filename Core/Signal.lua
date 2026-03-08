-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Core/Signal.lua
--   Rôle : Système de signaux (events propres)
-- ══════════════════════════════════════════════════════

local Signal = {}
Signal.__index = Signal

local signals = {}

function Signal.Init()
    signals = {}
end

function Signal.new()
    local s = setmetatable({}, Signal)
    s._connections = {}
    return s
end

function Signal:Connect(fn)
    local conn = {
        fn         = fn,
        connected  = true,
        signal     = self,
    }
    conn.Disconnect = function()
        conn.connected = false
        for i, c in ipairs(self._connections) do
            if c == conn then
                table.remove(self._connections, i)
                break
            end
        end
    end
    table.insert(self._connections, conn)
    return conn
end

function Signal:Fire(...)
    for _, conn in ipairs(self._connections) do
        if conn.connected then
            pcall(conn.fn, ...)
        end
    end
end

function Signal:DisconnectAll()
    self._connections = {}
end

function Signal:Wait()
    local thread = coroutine.running()
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

return Signal
