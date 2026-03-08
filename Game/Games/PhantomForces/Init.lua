-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Game/Games/PhantomForces/Init.lua
--   📁 Dossier : Game/Games/PhantomForces/
--   Rôle : Exploits Phantom Forces
--          Sécurité élevée — ESP + Aimbot only
-- ══════════════════════════════════════════════════════

local PhantomForces = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local Notify     = nil
local Utils      = nil

-- Phantom Forces a une très bonne sécurité côté serveur.
-- Seul le client est accessible.

-- ── Détection de l'équipe ─────────────────────────────
local function getTeamFolder()
    local ts = game:GetService("Teams")
    if not ts then return nil end
    local team = LP.Team
    return team
end

-- ── Trouver les ennemis via dossiers PF ───────────────
function PhantomForces.GetEnemies()
    local enemies = {}
    local myTeam  = LP.Team

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local sameTeam = myTeam and player.Team == myTeam
            if not sameTeam then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        table.insert(enemies, player)
                    end
                end
            end
        end
    end

    return enemies
end

-- ── Wall check PF-specific ────────────────────────────
function PhantomForces.IsVisible(part)
    if not part then return false end
    local cam    = workspace.CurrentCamera
    local origin = cam.CFrame.Position

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local toExclude = {}
    local char = LP.Character
    if char then table.insert(toExclude, char) end
    -- Exclut les effets PF
    local effects = workspace:FindFirstChild("Effects")
    if effects then table.insert(toExclude, effects) end

    params.FilterDescendantsInstances = toExclude

    local dir    = part.Position - origin
    local result = workspace:Raycast(origin, dir, params)
    if not result then return true end

    return Players:GetPlayerFromCharacter(result.Instance.Parent) ~= nil
end

-- ── Chams PF (SelectionBox) ───────────────────────────
local chamBoxes = {}

function PhantomForces.EnableChams(color)
    color = color or Color3.fromRGB(255,60,60)
    PhantomForces.DisableChams()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local box = Instance.new("SelectionBox")
                        box.Adornee             = part
                        box.Color3              = color
                        box.SurfaceColor3       = Color3.fromRGB(60,60,255)
                        box.SurfaceTransparency = 0.6
                        box.LineThickness       = 0.02
                        box.Parent              = workspace
                        table.insert(chamBoxes, box)
                    end
                end
            end
        end
    end
end

function PhantomForces.DisableChams()
    for _, box in ipairs(chamBoxes) do
        pcall(function() box:Destroy() end)
    end
    chamBoxes = {}
end

-- ── Infinite Ammo (client-side display) ───────────────
function PhantomForces.InfiniteAmmo()
    -- PF gère les munitions côté serveur.
    -- On peut uniquement modifier l'affichage client.
    local pChar = LP.Character
    if not pChar then return false end

    for _, v in ipairs(pChar:GetDescendants()) do
        if v:IsA("NumberValue") and (v.Name:lower():find("ammo") or v.Name:lower():find("mag")) then
            v.Value = 999
        end
    end
    if Notify then Notify.Info("Phantom Forces", "Ammo (client only)") end
    return true
end

-- ── No Spread (client-side) ───────────────────────────
function PhantomForces.NoSpread()
    pcall(function()
        for _, v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("NumberValue") and v.Name:lower():find("spread") then
                v.Value = 0
            end
        end
    end)
end

-- ── Radar ─────────────────────────────────────────────
function PhantomForces.GetAllPositions()
    local positions = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                table.insert(positions, {
                    name     = player.Name,
                    position = root.Position,
                    dist     = myRoot and (myRoot.Position - root.Position).Magnitude or 0,
                    team     = player.Team and player.Team.Name or "None",
                })
            end
        end
    end
    return positions
end

-- ── Init ──────────────────────────────────────────────
function PhantomForces.Init(deps)
    Notify = deps.Notify
    Utils  = deps.Utils
    print("[PhantomForces] Module initialisé ✓")
    print("[PhantomForces] Sécurité : ÉLEVÉE — ESP/Aim only")
end

return PhantomForces
