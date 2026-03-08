-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Game/Games/DaHood/Init.lua
--   📁 Dossier : Game/Games/DaHood/
--   Rôle : Exploits spécifiques Da Hood
--          Money / Stats / Positions / Bypass
-- ══════════════════════════════════════════════════════

local DaHood = {}

local Players  = game:GetService("Players")
local HS       = game:GetService("HttpService")
local LP       = Players.LocalPlayer

local Notify   = nil

-- ── Remotes connus ────────────────────────────────────
local REMOTES = {
    GiveMoney   = "GiveCash",
    SetBounty   = "SetBounty",
    Arrest      = "ArrestPlayer",
    SetStats    = "SetStats",
    SpawnCar    = "SpawnVehicle",
    GiveItem    = "GiveItem",
    KillPlayer  = "KillPlayer",
}

local function findRemote(name)
    return game:FindFirstChild(name, true)
end

-- ── Money exploit ─────────────────────────────────────
function DaHood.GiveMoney(amount)
    amount = amount or 10000
    local remote = findRemote(REMOTES.GiveMoney)
    if remote then
        pcall(function() remote:FireServer(amount) end)
        if Notify then Notify.Success("Da Hood", "+"..amount.." cash envoyé") end
        return true
    end
    -- Fallback : cherche par pattern
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find("cash") then
            pcall(function() v:FireServer(amount) end)
            return true
        end
    end
    if Notify then Notify.Error("Da Hood", "Remote introuvable") end
    return false
end

-- ── Bounty exploit ────────────────────────────────────
function DaHood.SetBounty(player, amount)
    amount = amount or 99999
    local remote = findRemote(REMOTES.SetBounty)
    if remote then
        pcall(function() remote:FireServer(player, amount) end)
        if Notify then Notify.Success("Da Hood", "Bounty → "..player.Name.." : $"..amount) end
        return true
    end
    return false
end

-- ── Teleport to money ─────────────────────────────────
function DaHood.TeleportToMoney()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local best, bestDist = nil, 9999
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name:lower():find("cash") or v.Name:lower():find("money") or v.Name:lower():find("bag")) then
            local dist = (root.Position - v.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best     = v
            end
        end
    end

    if best then
        root.CFrame = CFrame.new(best.Position + Vector3.new(0,3,0))
        if Notify then Notify.Success("Da Hood", "Téléporté vers l'argent") end
        return true
    end
    if Notify then Notify.Warning("Da Hood", "Aucun argent trouvé") end
    return false
end

-- ── Auto rob ──────────────────────────────────────────
function DaHood.AutoRob()
    -- Cherche les remotes de rob/heist
    local robRemotes = {}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("rob") or n:find("heist") or n:find("steal") then
                table.insert(robRemotes, v)
            end
        end
    end

    local count = 0
    for _, remote in ipairs(robRemotes) do
        pcall(function() remote:FireServer() end)
        count = count + 1
        task.wait(0.1)
    end

    if Notify then
        if count > 0 then
            Notify.Success("Da Hood", "Auto-rob : "..count.." remotes fired")
        else
            Notify.Warning("Da Hood", "Aucun remote de rob trouvé")
        end
    end
end

-- ── Kill aura (local) ─────────────────────────────────
function DaHood.KillAura(radius)
    radius = radius or 20
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local remote = findRemote(REMOTES.KillPlayer)
    if not remote then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local r = char:FindFirstChild("HumanoidRootPart")
                if r and (root.Position - r.Position).Magnitude <= radius then
                    pcall(function() remote:FireServer(player) end)
                    task.wait(0.05)
                end
            end
        end
    end
end

-- ── Spawn vehicle ─────────────────────────────────────
function DaHood.SpawnCar(carName)
    carName = carName or "SportsCar"
    local remote = findRemote(REMOTES.SpawnCar)
    if remote then
        pcall(function() remote:FireServer(carName) end)
        if Notify then Notify.Success("Da Hood", "Véhicule spawné : "..carName) end
        return true
    end
    return false
end

-- ── ESP custom DaHood ─────────────────────────────────
function DaHood.GetPlayerStats(player)
    local stats = {}
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            stats[v.Name] = v.Value
        end
    end
    return stats
end

-- ── Init ──────────────────────────────────────────────
function DaHood.Init(deps)
    Notify = deps.Notify
    print("[Da Hood] Module initialisé ✓")
    print("[Da Hood] Sécurité : FAIBLE — exploitation maximale")
end

return DaHood
