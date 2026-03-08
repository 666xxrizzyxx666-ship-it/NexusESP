-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Utility/ServerHop.lua
--   📁 Dossier : Modules/Utility/
--   Rôle : Server hop + Auto rejoin
-- ══════════════════════════════════════════════════════

local ServerHop = {}

local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local HS              = game:GetService("HttpService")
local LP              = Players.LocalPlayer

function ServerHop.Init(deps)
    print("[ServerHop] Initialisé ✓")
end

-- Hop vers un serveur aléatoire
function ServerHop.Hop()
    local placeId = game.PlaceId
    local ok, servers = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
        local res = game:HttpGet(url)
        return HS:JSONDecode(res)
    end)

    if not ok or not servers or not servers.data then
        -- Fallback : rejoin le même jeu
        TeleportService:Teleport(placeId, LP)
        return
    end

    local current = game.JobId
    local candidates = {}

    for _, server in ipairs(servers.data) do
        if server.id ~= current and server.playing < server.maxPlayers then
            table.insert(candidates, server.id)
        end
    end

    if #candidates == 0 then
        warn("[ServerHop] Aucun serveur disponible")
        TeleportService:Teleport(placeId, LP)
        return
    end

    local target = candidates[math.random(1, #candidates)]
    print("[ServerHop] Hop vers : "..target)
    TeleportService:TeleportToPlaceInstance(placeId, target, LP)
end

-- Rejoin le même serveur
function ServerHop.Rejoin()
    local placeId = game.PlaceId
    local jobId   = game.JobId
    print("[ServerHop] Rejoin...")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LP)
    end)
end

-- Auto rejoin si déconnecté
function ServerHop.AutoRejoin()
    game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Failed then
            task.wait(3)
            ServerHop.Rejoin()
        end
    end)
    print("[ServerHop] Auto rejoin activé ✓")
end

return ServerHop
