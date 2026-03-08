-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Network/Updater.lua
--   Rôle : Vérification et auto-update du script
-- ══════════════════════════════════════════════════════

local Updater = {}

local REPO = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

local function compareVersions(v1, v2)
    local function parse(v)
        local a, b, c = v:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(a)*10000 + tonumber(b)*100 + tonumber(c)
    end
    local ok1, n1 = pcall(parse, v1)
    local ok2, n2 = pcall(parse, v2)
    if not ok1 or not ok2 then return 0 end
    return n1 - n2
end

function Updater.Check(currentVersion)
    local Firebase = getgenv().NexusESP and getgenv().NexusESP.Firebase
    if not Firebase or not Firebase.IsConnected() then
        print("[Updater] Offline — skip version check")
        return
    end
    local latest = Firebase.GetLatestVersion()
    if not latest then return end
    local diff = compareVersions(latest, currentVersion)
    if diff > 0 then
        warn("[Updater] Mise à jour disponible : v" .. latest)
        warn("[Updater] Version actuelle : v" .. currentVersion)
    else
        print("[Updater] À jour ✓ (v" .. currentVersion .. ")")
    end
end

function Updater.HotReload()
    print("[Updater] Hot reload...")
    local ok, err = pcall(function()
        loadstring(game:HttpGet(REPO .. "Main.lua", true))()
    end)
    if not ok then
        warn("[Updater] Hot reload échoué : " .. tostring(err))
    end
end

return Updater
