-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Utility/RemoteSpy.lua
--   📁 Dossier : Modules/Utility/
--   Rôle : Intercepte tous les RemoteEvents
--          Log en temps réel
-- ══════════════════════════════════════════════════════

local RemoteSpy = {}

local MAX_LOG    = 200
local log        = {}
local enabled    = false
local callbacks  = {}
local blacklist  = {
    "Heartbeat", "Update", "Tick", "Ping", "KeepAlive",
    "PlayerInput", "CameraChanged", "CharacterMoved",
}

local function isBlacklisted(name)
    for _, bl in ipairs(blacklist) do
        if name:lower():find(bl:lower()) then return true end
    end
    return false
end

local function addLog(entry)
    table.insert(log, 1, entry)
    if #log > MAX_LOG then
        table.remove(log, #log)
    end
    for _, cb in ipairs(callbacks) do
        pcall(cb, entry)
    end
end

local function serializeArgs(args)
    local parts = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "string"  then table.insert(parts, '"'..tostring(v)..'"')
        elseif t == "number"  then table.insert(parts, tostring(v))
        elseif t == "boolean" then table.insert(parts, tostring(v))
        elseif t == "Vector3" then table.insert(parts, "V3("..math.floor(v.X)..","..math.floor(v.Y)..","..math.floor(v.Z)..")")
        elseif t == "Instance" then table.insert(parts, t..":"..v.Name)
        else table.insert(parts, t) end
    end
    return table.concat(parts, ", ")
end

function RemoteSpy.Init(deps)
    print("[RemoteSpy] Initialisé ✓")
end

function RemoteSpy.Enable()
    if enabled then return end
    enabled = true

    pcall(function()
        local mt  = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}

            if enabled then
                if (method == "FireServer" or method == "InvokeServer") then
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        if not isBlacklisted(self.Name) then
                            local entry = {
                                name   = self.Name,
                                method = method,
                                path   = self:GetFullName(),
                                args   = serializeArgs(args),
                                time   = os.clock(),
                            }
                            addLog(entry)
                        end
                    end
                end
            end

            return old(self, ...)
        end)

        setreadonly(mt, true)
    end)

    print("[RemoteSpy] Activé ✓")
end

function RemoteSpy.Disable()
    enabled = false
    print("[RemoteSpy] Désactivé")
end

function RemoteSpy.GetLog()
    return log
end

function RemoteSpy.ClearLog()
    log = {}
end

function RemoteSpy.OnLog(cb)
    table.insert(callbacks, cb)
end

function RemoteSpy.AddBlacklist(name)
    table.insert(blacklist, name)
end

function RemoteSpy.FireRemote(path, ...)
    local ok, remote = pcall(function()
        return game:FindFirstChild(path, true)
    end)
    if ok and remote then
        pcall(function() remote:FireServer(...) end)
        return true
    end
    return false
end

function RemoteSpy.IsEnabled() return enabled end

return RemoteSpy
