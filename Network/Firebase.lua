-- ══════════════════════════════════════════════════════
--   Aurora v3.0.6 — Network/Firebase.lua
--   Rôle : Firebase optionnel — désactivé si pas configuré
-- ══════════════════════════════════════════════════════

local Firebase = {}

local HS       = game:GetService("HttpService")
local BASE_URL = ""   -- Mets ton URL Firebase ici quand prêt
local API_KEY  = ""

Firebase._connected  = false
Firebase._configured = BASE_URL ~= ""

-- Si pas configuré → tout les appels retournent nil silencieusement
local function request(path, method, data)
    if not Firebase._configured then return nil end
    local url = BASE_URL .. path .. ".json"
    if API_KEY ~= "" then url = url .. "?auth=" .. API_KEY end

    local opts = {Url=url, Method=method or "GET"}
    if data then
        opts.Headers = {["Content-Type"]="application/json"}
        opts.Body    = HS:JSONEncode(data)
    end

    local ok, res = pcall(function()
        return HS:RequestAsync(opts)
    end)
    if not ok or not res or res.StatusCode ~= 200 then return nil end

    local ok2, decoded = pcall(function() return HS:JSONDecode(res.Body) end)
    return ok2 and decoded or nil
end

function Firebase.Init()
    if not Firebase._configured then
        print("[Firebase] Non configuré — mode offline")
        return
    end
    local test = request("/status")
    Firebase._connected = test ~= nil
    print("[Firebase] " .. (Firebase._connected and "Connecté ✓" or "Offline"))
end

function Firebase.ValidateKey(key)
    if not Firebase._configured then
        return {valid=true, tier="dev"}
    end
    if not key or key == "" then
        return {valid=false, reason="Clé vide"}
    end
    local result = request("/keys/" .. key)
    if not result then
        return {valid=false, reason="Erreur réseau"}
    end
    if result.valid then
        return {valid=true, tier=result.tier or "free"}
    end
    return {valid=false, reason=result.reason or "Clé invalide"}
end

function Firebase.GetConfig(key)
    if not Firebase._configured then return nil end
    return request("/config/" .. (key or ""))
end

function Firebase.GetMOTD()
    if not Firebase._configured then return nil end
    return request("/motd")
end

function Firebase.IsConnected() return Firebase._connected end

return Firebase
