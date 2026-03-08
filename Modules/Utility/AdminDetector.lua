-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Utility/AdminDetector.lua
--   📁 Dossier : Modules/Utility/
--   Rôle : Détecte les admins et modérateurs
--          Alerte + cache l'UI automatiquement
-- ══════════════════════════════════════════════════════

local AdminDetector = {}

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local enabled   = false
local detected  = {}
local callbacks = {}

-- Badges admin connus
local ADMIN_BADGES = {
    "Admin", "Moderator", "Staff", "Developer",
    "Mod", "GameAdmin", "Owner", "CoOwner",
    "Community Manager", "Support",
}

-- Groupes admin connus (IDs Roblox)
local ADMIN_GROUPS = {
    1200769,  -- Roblox Staff
    2868472,  -- Roblox Moderation
}

local function isAdmin(player)
    if player.UserId < 0 then return true end -- NPCs

    -- Vérifie le nom
    for _, badge in ipairs(ADMIN_BADGES) do
        if player.Name:lower():find(badge:lower()) then
            return true
        end
    end

    -- Vérifie si owner du jeu
    if player.UserId == game.CreatorId then
        return true
    end

    -- Vérifie les groupes
    for _, groupId in ipairs(ADMIN_GROUPS) do
        local ok, inGroup = pcall(function()
            return player:IsInGroup(groupId)
        end)
        if ok and inGroup then return true end
    end

    return false
end

local function onPlayerAdded(player)
    if not enabled then return end
    if player == LP then return end

    task.spawn(function()
        task.wait(1)
        if isAdmin(player) then
            detected[player.UserId] = player.Name
            print("[AdminDetector] ⚠ ADMIN DÉTECTÉ : "..player.Name)

            -- Notifie
            for _, cb in ipairs(callbacks) do
                pcall(cb, player)
            end
        end
    end)
end

function AdminDetector.Init(deps)
    print("[AdminDetector] Initialisé ✓")
end

function AdminDetector.Enable()
    if enabled then return end
    enabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    print("[AdminDetector] Activé ✓")
end

function AdminDetector.Disable()
    enabled  = false
    detected = {}
    print("[AdminDetector] Désactivé")
end

function AdminDetector.OnDetected(cb)
    table.insert(callbacks, cb)
end

function AdminDetector.GetDetected()
    return detected
end

function AdminDetector.IsEnabled() return enabled end

return AdminDetector
