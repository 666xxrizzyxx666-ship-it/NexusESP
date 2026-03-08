-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Movement/Teleport.lua
--   📁 Dossier : Modules/Movement/
--   Rôle : Téléportation vers joueur ou coordonnées
-- ══════════════════════════════════════════════════════

local Teleport = {}

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Teleport.Init(deps)
    print("[Teleport] Initialisé ✓")
end

-- Téléporte vers un joueur
function Teleport.ToPlayer(playerName, offset)
    offset = offset or Vector3.new(0, 0, 3)
    local target = Players:FindFirstChild(playerName)
    if not target then
        warn("[Teleport] Joueur introuvable : " .. playerName)
        return false
    end

    local targetChar = target.Character
    if not targetChar then return false end

    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end

    local root = getRoot()
    if not root then return false end

    root.CFrame = targetRoot.CFrame + offset
    return true
end

-- Téléporte vers des coordonnées
function Teleport.ToPosition(pos)
    local root = getRoot()
    if not root then return false end
    root.CFrame = CFrame.new(pos)
    return true
end

-- Téléporte vers la position de la souris (clic droit)
function Teleport.ToCursor()
    local mouse = LP:GetMouse()
    if not mouse then return false end
    local pos = mouse.Hit.Position + Vector3.new(0, 3, 0)
    return Teleport.ToPosition(pos)
end

-- Blink (téléporte devant toi)
function Teleport.Blink(distance)
    distance = distance or 20
    local root = getRoot()
    if not root then return false end
    local forward = root.CFrame.LookVector
    root.CFrame   = root.CFrame + forward * distance
    return true
end

return Teleport
