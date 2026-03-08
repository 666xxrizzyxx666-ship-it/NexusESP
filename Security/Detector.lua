-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Security/Detector.lua
--   Rôle : Détection automatique des anti-cheats
-- ══════════════════════════════════════════════════════

local Detector = {}

-- Signatures connues
local SIGNATURES = {
    Chickynoid  = {"Chickynoid", "chickynoid"},
    SecureRandom = {"SecureRandom", "Securecast", "securecast"},
    Pulsarr     = {"Pulsarr", "pulsarr"},
    NWave       = {"NWave", "nwave", "NetworkAC"},
    FairPlay    = {"FairPlay", "fairplay", "FairPlayAC"},
    Generic     = {"AntiCheat", "anticheat", "anti_cheat", "ACHandler",
                   "Detection", "Monitor", "Secure", "Shield", "Guard"},
}

local function scanScripts()
    local found = {}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
            local name = v.Name:lower()
            for acName, sigs in pairs(SIGNATURES) do
                for _, sig in ipairs(sigs) do
                    if name:find(sig:lower()) then
                        found[acName] = v.Name
                    end
                end
            end
        end
    end
    return found
end

local function scanRemotes()
    local found = {}
    local keywords = {"report", "cheat", "detect", "flag", "kick", "ban", "verify"}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local name = v.Name:lower()
            for _, kw in ipairs(keywords) do
                if name:find(kw) then
                    table.insert(found, v.Name)
                end
            end
        end
    end
    return found
end

local function scanHeartbeat()
    -- Détecte si quelque chose tourne en background très fréquemment
    local connections = 0
    pcall(function()
        local rs = game:GetService("RunService")
        connections = #(rs.Heartbeat:GetConnections and rs.Heartbeat:GetConnections() or {})
    end)
    return connections > 5
end

function Detector.Scan()
    local result = {
        hasAC    = false,
        acName   = "None",
        checks   = {
            scripts   = {},
            remotes   = {},
            heartbeat = false,
        },
    }

    result.checks.scripts   = scanScripts()
    result.checks.remotes   = scanRemotes()
    result.checks.heartbeat = scanHeartbeat()

    -- Détermine quel AC est présent
    for acName, scriptName in pairs(result.checks.scripts) do
        if acName ~= "Generic" then
            result.hasAC  = true
            result.acName = acName
            break
        end
    end

    if not result.hasAC and result.checks.scripts.Generic then
        result.hasAC  = true
        result.acName = "Generic"
    end

    return result
end

return Detector
