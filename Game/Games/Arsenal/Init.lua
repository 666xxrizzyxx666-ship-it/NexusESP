-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Game/Games/Arsenal/Init.lua
--   📁 Dossier : Game/Games/Arsenal/
--   Rôle : Exploits Arsenal
-- ══════════════════════════════════════════════════════

local Arsenal = {}

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer
local Notify  = nil

-- Arsenal a une sécurité correcte.
-- Kill/stats côté serveur. Exploits visuels possibles.

local function findRemote(name)
    return game:FindFirstChild(name, true)
end

-- ── Infinite Jumps ────────────────────────────────────
function Arsenal.InfiniteJump()
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.JumpPower  = 200
        if Notify then Notify.Success("Arsenal", "JumpPower → 200") end
    end
end

-- ── Kill Aura via RemoteEvent ─────────────────────────
function Arsenal.KillAura()
    local remote = findRemote("RemoteEvent")
    if not remote then
        if Notify then Notify.Warning("Arsenal", "KillAura : remote introuvable") end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    pcall(function() remote:FireServer("Kill", player) end)
                    task.wait(0.05)
                end
            end
        end
    end
end

-- ── Instant Respawn ───────────────────────────────────
function Arsenal.InstantRespawn()
    local remote = findRemote("Respawn")
    if remote then
        pcall(function() remote:FireServer() end)
    else
        LP:LoadCharacter()
    end
    if Notify then Notify.Info("Arsenal", "Respawn forcé") end
end

-- ── No Reload (client) ───────────────────────────────
function Arsenal.NoReload()
    pcall(function()
        for _, v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("NumberValue") and v.Name:lower():find("reload") then
                v.Value = 0
            end
        end
    end)
    if Notify then Notify.Success("Arsenal", "No reload (client)") end
end

-- ── Tracers (vanilla ESP amélioré) ───────────────────
function Arsenal.GetEnemies()
    local myTeam = LP.Team
    local enemies = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Team ~= myTeam then
            table.insert(enemies, p)
        end
    end
    return enemies
end

function Arsenal.Init(deps)
    Notify = deps.Notify
    print("[Arsenal] Module initialisé ✓")
    print("[Arsenal] Sécurité : CORRECTE — exploits limités")
end

return Arsenal
