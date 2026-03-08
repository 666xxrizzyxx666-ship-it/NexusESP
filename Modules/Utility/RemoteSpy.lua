-- ══════════════════════════════════════════════════════
--   Aurora v3.1.3 — Modules/Utility/RemoteSpy.lua
--   Rôle : Intercepte les RemoteEvents (optionnel)
-- ══════════════════════════════════════════════════════

local RemoteSpy = {}

local MAX_LOG   = 200
local log       = {}
local enabled   = false
local callbacks = {}
local blacklist = {"Heartbeat","Update","Tick","Ping","KeepAlive","PlayerInput","CameraChanged","CharacterMoved"}
local original  = nil

local function isBlacklisted(name)
    for _, bl in ipairs(blacklist) do
        if name:lower():find(bl:lower()) then return true end
    end
    return false
end

local function serialize(v)
    local t = typeof(v)
    if t == "string"   then return '"'..tostring(v)..'"'
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Vector3" then return "V3("..math.floor(v.X)..","..math.floor(v.Y)..","..math.floor(v.Z)..")"
    elseif t == "Instance" then return t..":"..v.Name
    else return t end
end

local function serializeArgs(args)
    local parts = {}
    for _, v in ipairs(args) do
        table.insert(parts, serialize(v))
    end
    return table.concat(parts, ", ")
end

function RemoteSpy.Init(deps)
    print("[RemoteSpy] Initialisé ✓")
end

function RemoteSpy.Enable()
    if enabled then return end
    -- Vérifie que les fonctions nécessaires existent
    if not getrawmetatable or not setreadonly or not newcclosure or not getnamecallmethod then
        warn("[RemoteSpy] Exécuteur incompatible — désactivé")
        return
    end
    enabled = true
    pcall(function()
        local mt  = getrawmetatable(game)
        original  = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}
            if enabled and (method == "FireServer" or method == "InvokeServer") then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    if not isBlacklisted(self.Name) then
                        local entry = {
                            name   = self.Name,
                            method = method,
                            path   = self:GetFullName(),
                            args   = serializeArgs(args),
                            time   = os.clock(),
                        }
                        table.insert(log, 1, entry)
                        if #log > MAX_LOG then table.remove(log) end
                        for _, cb in ipairs(callbacks) do pcall(cb, entry) end
                    end
                end
            end
            return original(self, ...)
        end)
        setreadonly(mt, true)
    end)
    print("[RemoteSpy] Activé ✓")
end

function RemoteSpy.Disable()
    if not enabled then return end
    enabled = false
    pcall(function()
        if original then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = original
            setreadonly(mt, true)
            original = nil
        end
    end)
    print("[RemoteSpy] Désactivé")
end

function RemoteSpy.Toggle()
    if enabled then RemoteSpy.Disable() else RemoteSpy.Enable() end
end

function RemoteSpy.OnLog(cb) table.insert(callbacks, cb) end
function RemoteSpy.GetLog()  return log end
function RemoteSpy.Clear()   log = {} end
function RemoteSpy.IsEnabled() return enabled end

return RemoteSpy
