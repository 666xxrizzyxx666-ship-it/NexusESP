-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/ESP.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Moteur ESP principal
--          Gère tous les joueurs et leurs drawings
-- ══════════════════════════════════════════════════════

local ESP = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

local Utils    = nil
local Config   = nil
local EventBus = nil

local playerData = {}
local enabled    = false
local renderConn = nil

local REPO = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

local function loadModule(name)
    local ok, m = pcall(function()
        return loadstring(game:HttpGet(REPO..name, true))()
    end)
    return ok and m or nil
end

-- ── Init ──────────────────────────────────────────────
function ESP.Init(deps)
    Utils    = deps.Utils    or Utils
    Config   = deps.Config   or Config
    EventBus = deps.EventBus or EventBus

    -- Charge les sous-modules
    ESP.Box         = loadModule("Modules/ESP/Box.lua")
    ESP.CornerBox   = loadModule("Modules/ESP/CornerBox.lua")
    ESP.Skeleton    = loadModule("Modules/ESP/Skeleton.lua")
    ESP.Tracers     = loadModule("Modules/ESP/Tracers.lua")
    ESP.Health      = loadModule("Modules/ESP/Health.lua")
    ESP.Name        = loadModule("Modules/ESP/Name.lua")
    ESP.Distance    = loadModule("Modules/ESP/Distance.lua")
    ESP.Chams       = loadModule("Modules/ESP/Chams.lua")

    -- Ajoute les joueurs existants
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            ESP._addPlayer(p)
        end
    end

    -- Événements joueurs
    Players.PlayerAdded:Connect(function(p)
        ESP._addPlayer(p)
    end)
    Players.PlayerRemoving:Connect(function(p)
        ESP._removePlayer(p)
    end)

    task.defer(function()end)
end

-- ── Ajouter joueur ────────────────────────────────────
function ESP._addPlayer(player)
    if playerData[player] then return end

    playerData[player] = {
        player   = player,
        drawings = {},
        enabled  = true,
    }

    -- Attend le personnage
    if player.Character then
        ESP._setupCharacter(player, player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        ESP._setupCharacter(player, char)
    end)
end

-- ── Setup character ───────────────────────────────────
function ESP._setupCharacter(player, char)
    local data = playerData[player]
    if not data then return end

    -- Nettoie les anciens drawings
    ESP._clearDrawings(player)

    data.char = char

    -- Crée les drawings pour chaque module actif
    local cfg = Config and Config.Current or {}

    if ESP.Box      then data.drawings.box      = ESP.Box.Create()         end
    if ESP.CornerBox then data.drawings.corner  = ESP.CornerBox.Create()   end
    if ESP.Skeleton then data.drawings.skeleton = ESP.Skeleton.Create()    end
    if ESP.Tracers  then data.drawings.tracers  = ESP.Tracers.Create()     end
    if ESP.Health   then data.drawings.health   = ESP.Health.Create()      end
    if ESP.Name     then data.drawings.name     = ESP.Name.Create()        end
    if ESP.Distance then data.drawings.distance = ESP.Distance.Create()    end
end

-- ── Clear drawings ────────────────────────────────────
function ESP._clearDrawings(player)
    local data = playerData[player]
    if not data then return end

    for _, drawings in pairs(data.drawings) do
        if type(drawings) == "table" then
            for _, d in pairs(drawings) do
                if typeof(d) == "Instance" or (type(d) == "table" and d.Remove) then
                    pcall(function()
                        if d.Remove then d:Remove()
                        elseif d.Destroy then d:Destroy()
                        end
                    end)
                end
            end
        end
    end
    data.drawings = {}
end

-- ── Remove player ─────────────────────────────────────
function ESP._removePlayer(player)
    if not playerData[player] then return end
    ESP._clearDrawings(player)
    playerData[player] = nil
end

-- ── Render loop ───────────────────────────────────────
function ESP._render()
    local cfg = Config and Config.Current or {}

    for player, data in pairs(playerData) do
        if not player or not player.Parent then
            ESP._removePlayer(player)
        else
            local char = data.char or player.Character
            if not char then
                -- Cache tout
                ESP._hideAll(data)
            else
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum  = char:FindFirstChildOfClass("Humanoid")

                local alive   = hum and hum.Health > 0
                local _, onScreen = Camera:WorldToViewportPoint(
                    root and root.Position or Vector3.new(0,0,0)
                )
                local dist = root and Utils.GetDistance(root.Position) or 9999
                local maxDist = (cfg.Distance and cfg.Distance.MaxDist) or 800

                local shouldShow = enabled
                    and data.enabled
                    and alive
                    and onScreen
                    and dist <= maxDist
                    and (not (cfg.TeamCheck) or not Utils.IsSameTeam(player))

                if shouldShow then
                    local bb = Utils.GetBoundingBox(char)
                    if bb then
                        -- Box
                        if ESP.Box and data.drawings.box and cfg.Box and cfg.Box.Enabled then
                            ESP.Box.Update(data.drawings.box, bb, cfg.Box)
                        elseif data.drawings.box then
                            ESP.Box.Hide(data.drawings.box)
                        end

                        -- CornerBox
                        if ESP.CornerBox and data.drawings.corner and cfg.CornerBox and cfg.CornerBox.Enabled then
                            ESP.CornerBox.Update(data.drawings.corner, bb, cfg.CornerBox)
                        elseif data.drawings.corner then
                            ESP.CornerBox.Hide(data.drawings.corner)
                        end

                        -- Skeleton
                        if ESP.Skeleton and data.drawings.skeleton and cfg.Skeleton and cfg.Skeleton.Enabled then
                            ESP.Skeleton.Update(data.drawings.skeleton, char, cfg.Skeleton)
                        elseif data.drawings.skeleton then
                            ESP.Skeleton.Hide(data.drawings.skeleton)
                        end

                        -- Tracers
                        if ESP.Tracers and data.drawings.tracers and cfg.Tracers and cfg.Tracers.Enabled then
                            ESP.Tracers.Update(data.drawings.tracers, bb, cfg.Tracers)
                        elseif data.drawings.tracers then
                            ESP.Tracers.Hide(data.drawings.tracers)
                        end

                        -- Health
                        if ESP.Health and data.drawings.health and cfg.Health and cfg.Health.Enabled then
                            local hp, maxHp = Utils.GetHealth(char)
                            ESP.Health.Update(data.drawings.health, bb, hp, maxHp, cfg.Health)
                        elseif data.drawings.health then
                            ESP.Health.Hide(data.drawings.health)
                        end

                        -- Name
                        if ESP.Name and data.drawings.name and cfg.Name and cfg.Name.Enabled then
                            ESP.Name.Update(data.drawings.name, bb, player.Name, cfg.Name)
                        elseif data.drawings.name then
                            ESP.Name.Hide(data.drawings.name)
                        end

                        -- Distance
                        if ESP.Distance and data.drawings.distance and cfg.Distance and cfg.Distance.Enabled then
                            ESP.Distance.Update(data.drawings.distance, bb, dist, cfg.Distance)
                        elseif data.drawings.distance then
                            ESP.Distance.Hide(data.drawings.distance)
                        end
                    else
                        ESP._hideAll(data)
                    end
                else
                    ESP._hideAll(data)
                end
            end
        end
    end
end

function ESP._hideAll(data)
    if not data or not data.drawings then return end
    for moduleName, drawings in pairs(data.drawings) do
        if ESP[moduleName:sub(1,1):upper()..moduleName:sub(2)] then
            local mod = ESP[moduleName:sub(1,1):upper()..moduleName:sub(2)]
            if mod and mod.Hide then
                pcall(function() mod.Hide(drawings) end)
            end
        end
    end
end

-- ── Enable / Disable ──────────────────────────────────
function ESP.Enable()
    if enabled then return end
    enabled    = true
    renderConn = RunService.RenderStepped:Connect(ESP._render)
    task.defer(function()end)
end

function ESP.Disable()
    if not enabled then return end
    enabled = false
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    -- Cache tout
    for player, data in pairs(playerData) do
        ESP._hideAll(data)
    end
    task.defer(function()end)
end

function ESP.Toggle()
    if enabled then ESP.Disable() else ESP.Enable() end
end

function ESP.HideAll()
    for _, data in pairs(playerData) do
        ESP._hideAll(data)
    end
end

function ESP.IsEnabled()
    return enabled
end

-- Toggle par joueur
function ESP.TogglePlayer(player)
    if not playerData[player] then return end
    playerData[player].enabled = not playerData[player].enabled
end

-- SetOption — modifie une option à la volée
function ESP.SetOption(key, value)
    if not Config or not Config.Current then return end
    -- MaxDist est dans Distance.MaxDist
    if key == "MaxDist" then
        Config.Current.Distance = Config.Current.Distance or {}
        Config.Current.Distance.MaxDist = value
        return
    end
    -- Enabled flags
    local target = Config.Current[key]
    if type(target) == "table" then
        target.Enabled = value
    else
        -- Crée la structure si besoin
        Config.Current[key] = {Enabled=value}
    end
end

return ESP
