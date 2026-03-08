-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Network/Firebase.lua
--   Rôle : Communication avec Firebase
--          Config live, whitelist, kill switch
-- ══════════════════════════════════════════════════════

local Firebase = {}

local HS = game:GetService("HttpService")

-- ── Config Firebase ───────────────────────────────────
-- Remplace par ton URL Firebase
local BASE_URL = "https://nexusesp-default-rtdb.firebaseio.com"
local API_KEY  = ""  -- optionnel

local cache    = {}
local CACHE_TTL = 30  -- secondes

-- ── Helpers ───────────────────────────────────────────
local function getCache(key)
    local entry = cache[key]
    if not entry then return nil end
    if os.time() - entry.time > CACHE_TTL then
        cache[key] = nil
        return nil
    end
    return entry.value
end

local function setCache(key, value)
    cache[key] = {value=value, time=os.time()}
end

local function request(path, method, data)
    local url = BASE_URL .. path .. ".json"
    if API_KEY ~= "" then
        url = url .. "?auth=" .. API_KEY
    end
    local opts = {
        Url    = url,
        Method = method or "GET",
    }
    if data then
        opts.Headers = {["Content-Type"] = "application/json"}
        opts.Body    = HS:JSONEncode(data)
    end
    local ok, res = pcall(function()
        return HS:RequestAsync(opts)
    end)
    if not ok or not res or res.StatusCode ~= 200 then
        return nil
    end
    local ok2, decoded = pcall(function()
        return HS:JSONDecode(res.Body)
    end)
    return ok2 and decoded or nil
end

-- ── Init ──────────────────────────────────────────────
function Firebase.Init()
    Firebase._connected = false
    -- Test connexion
    local test = request("/status")
    if test ~= nil then
        Firebase._connected = true
        print("[Firebase] Connecté ✓")
    else
        warn("[Firebase] Non connecté — mode offline")
    end
end

function Firebase.IsConnected()
    return Firebase._connected or false
end

-- ── Kill Switch ───────────────────────────────────────
function Firebase.CheckKillSwitch()
    if not Firebase._connected then return false end
    local cached = getCache("killswitch")
    if cached ~= nil then return cached end
    local data = request("/killswitch")
    local active = data == true or data == "true"
    setCache("killswitch", active)
    return active
end

-- ── Version Check ─────────────────────────────────────
function Firebase.GetLatestVersion()
    if not Firebase._connected then return nil end
    local cached = getCache("version")
    if cached then return cached end
    local data = request("/version")
    if data then setCache("version", data) end
    return data
end

-- ── MOTD ──────────────────────────────────────────────
function Firebase.GetMOTD()
    if not Firebase._connected then return nil end
    local cached = getCache("motd")
    if cached then return cached end
    local data = request("/motd")
    if data then setCache("motd", tostring(data)) end
    return data and tostring(data) or nil
end

-- ── Config live ───────────────────────────────────────
function Firebase.GetConfig()
    if not Firebase._connected then return nil end
    local cached = getCache("config")
    if cached then return cached end
    local data = request("/config")
    if data then setCache("config", data) end
    return data
end

-- ── Feature flags ─────────────────────────────────────
function Firebase.GetFeatureFlags()
    if not Firebase._connected then return {} end
    local cached = getCache("flags")
    if cached then return cached end
    local data = request("/flags")
    if data then setCache("flags", data) end
    return data or {}
end

function Firebase.IsFeatureEnabled(name)
    local flags = Firebase.GetFeatureFlags()
    if flags[name] == nil then return true end
    return flags[name] == true
end

-- ── Whitelist ─────────────────────────────────────────
function Firebase.CheckWhitelist(userId)
    if not Firebase._connected then return true end
    local path = "/whitelist/" .. tostring(userId)
    local data = request(path)
    return data ~= nil and data ~= false
end

-- ── Key validation ────────────────────────────────────
function Firebase.ValidateKey(key)
    if not Firebase._connected then
        -- Mode offline : accepte toutes les clés
        return {valid=true, tier="offline"}
    end
    local path = "/keys/" .. key:gsub("[^%w]", "_")
    local data = request(path)
    if not data then
        return {valid=false, reason="Clé introuvable"}
    end
    if data.active == false then
        return {valid=false, reason="Clé désactivée"}
    end
    if data.expires then
        -- Vérifie expiration
        local ok, ts = pcall(function()
            return tonumber(data.expires)
        end)
        if ok and ts and os.time() > ts then
            return {valid=false, reason="Clé expirée"}
        end
    end
    if data.userId and tostring(data.userId) ~= tostring(game:GetService("Players").LocalPlayer.UserId) then
        return {valid=false, reason="Clé liée à un autre compte"}
    end
    return {
        valid   = true,
        tier    = data.tier or "basic",
        expires = data.expires,
    }
end

-- ── Log anonyme ───────────────────────────────────────
function Firebase.Log(event, data)
    if not Firebase._connected then return end
    pcall(function()
        request("/logs", "POST", {
            event   = event,
            time    = os.time(),
            game    = game.PlaceId,
            data    = data,
        })
    end)
end

return Firebase
