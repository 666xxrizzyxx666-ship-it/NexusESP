-- ============================================================
--  ESP.lua — Orchestrateur principal du système ESP
--  Gère le cycle de vie de chaque entité :
--    Create → Update (RenderStepped) → Remove
--  Intègre : TeamCheck, VisibilityCheck, PerformanceMode,
--            Preview Mode, système de profiling par module
-- ============================================================

local ESP = {}

-- ── Services ─────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

-- ── Modules (injectés depuis Main.lua) ──────────────────────
local Utils, Config, Box, Skeleton, Tracers, Health, NameMod, Distance

-- ── État interne ─────────────────────────────────────────────
local entities     = {}   -- [player] = { box, skeleton, tracers, health, name, dist }
local renderConn   = nil
local enabled      = false
local previewDummy = nil

-- ── Profiling accumulé ───────────────────────────────────────
ESP.ProfileData = {
    Box      = 0,
    Skeleton = 0,
    Tracers  = 0,
    Health   = 0,
    Name     = 0,
    Distance = 0,
}

-- ── Injection des dépendances ────────────────────────────────
function ESP.Init(deps)
    Utils    = deps.Utils
    Config   = deps.Config
    Box      = deps.Box
    Skeleton = deps.Skeleton
    Tracers  = deps.Tracers
    Health   = deps.Health
    NameMod  = deps.Name
    Distance = deps.Distance

    -- Propager Utils/Config aux sous-modules
    Box.SetDependencies(Utils, Config)
    Skeleton.SetDependencies(Utils, Config)
    Tracers.SetDependencies(Utils, Config)
    Health.SetDependencies(Utils, Config)
    NameMod.SetDependencies(Utils, Config)
    Distance.SetDependencies(Utils, Config)

    Utils.Log("ESP initialisé", "INFO")
end

-- ── Créer les drawings pour un joueur ────────────────────────
local function createEntity(player)
    if entities[player] then return end

    entities[player] = {
        box      = Box.Create(player),
        skeleton = Skeleton.Create(player),
        tracers  = Tracers.Create(player),
        health   = Health.Create(player),
        name     = NameMod.Create(player),
        distance = Distance.Create(player),
        disabled = false,  -- désactivation manuelle par PlayerList
    }

    Utils.Log("Entity créée pour " .. player.Name)
end

-- ── Supprimer les drawings d'un joueur ───────────────────────
local function removeEntity(player)
    local ent = entities[player]
    if not ent then return end

    ent.box:Remove()
    ent.skeleton:Remove()
    ent.tracers:Remove()
    ent.health:Remove()
    ent.name:Remove()
    ent.distance:Remove()

    entities[player] = nil
    Utils.Log("Entity supprimée pour " .. player.Name)
end

-- ── Cacher les drawings d'une entité ─────────────────────────
local function hideEntity(ent)
    ent.box:Hide()
    ent.skeleton:Hide()
    ent.tracers:Hide()
    ent.health:Hide()
    ent.name:Hide()
    ent.distance:Hide()
end

-- ── Mise à jour d'une entité ──────────────────────────────────
local frameCount = 0

local function updateEntity(player, ent)
    local cfg    = Config.Current
    local char   = player.Character
    local lp     = Players.LocalPlayer

    -- Sanity checks
    if not char or player == lp then
        hideEntity(ent)
        return
    end

    if ent.disabled then
        hideEntity(ent)
        return
    end

    -- TeamCheck
    if cfg.TeamCheck and Utils.SameTeam(player) then
        hideEntity(ent)
        return
    end

    local root = Utils.GetRoot(char)
    if not root then
        hideEntity(ent)
        return
    end

    -- Distance max (utilise cfg.Distance.MaxDist)
    local dist = Utils.GetDistance(root.Position)
    if dist > (cfg.Distance.MaxDist or 1000) then
        hideEntity(ent)
        return
    end

    -- VisibilityCheck (raycast) — optionnel, peut skip en PerformanceMode
    local isVisible = true
    if cfg.VisibilityCheck then
        isVisible = Utils.IsVisible(root.Position)
    end

    -- PerformanceMode : on réduit la fréquence de mise à jour skeleton
    local perfMode    = cfg.PerformanceMode
    local updateFull  = not perfMode or (frameCount % 2 == 0)

    -- ── Box ──────────────────────────────────────────────────
    Utils.ProfileStart("Box")
    ent.box:Update(char, cfg.Box)
    ESP.ProfileData.Box = Utils.ProfileEnd("Box")

    -- ── Skeleton (moins fréquent en perf mode) ──────────────
    if updateFull then
        Utils.ProfileStart("Skeleton")
        ent.skeleton:Update(char, cfg.Skeleton)
        ESP.ProfileData.Skeleton = Utils.ProfileEnd("Skeleton")
    end

    -- ── Tracers ──────────────────────────────────────────────
    Utils.ProfileStart("Tracers")
    ent.tracers:Update(char, cfg.Tracers)
    ESP.ProfileData.Tracers = Utils.ProfileEnd("Tracers")

    -- ── Health ───────────────────────────────────────────────
    Utils.ProfileStart("Health")
    ent.health:Update(char, cfg.Health)
    ESP.ProfileData.Health = Utils.ProfileEnd("Health")

    -- ── Name ─────────────────────────────────────────────────
    Utils.ProfileStart("Name")
    ent.name:Update(char, cfg.Name)
    ESP.ProfileData.Name = Utils.ProfileEnd("Name")

    -- ── Distance ─────────────────────────────────────────────
    Utils.ProfileStart("Distance")
    ent.distance:Update(char, cfg.Distance)
    ESP.ProfileData.Distance = Utils.ProfileEnd("Distance")

    -- Indication visuelle "not visible" (couleur atténuée)
    if cfg.VisibilityCheck and not isVisible then
        -- Atténuer légèrement la box
        if ent.box.Frame then
            ent.box.Frame.Transparency = 0.4
        end
    else
        if ent.box.Frame then
            ent.box.Frame.Transparency = 0
        end
    end
end

-- ── Boucle principale (RenderStepped) ────────────────────────
local function onRenderStepped()
    if not enabled then return end

    frameCount = frameCount + 1

    for player, ent in pairs(entities) do
        local ok, err = pcall(updateEntity, player, ent)
        if not ok then
            Utils.Log("Erreur update " .. player.Name .. ": " .. err, "ERROR")
        end
    end
end

-- ── Activer l'ESP ────────────────────────────────────────────
function ESP.Enable()
    if enabled then return end
    enabled = true

    -- Créer les entités pour tous les joueurs existants
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            createEntity(p)
        end
    end

    -- Écouter les nouveaux joueurs
    ESP._playerAddedConn = Players.PlayerAdded:Connect(function(p)
        -- Attendre le character
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            createEntity(p)
        end)
        task.wait(0.1)
        createEntity(p)
    end)

    ESP._playerRemovingConn = Players.PlayerRemoving:Connect(function(p)
        removeEntity(p)
    end)

    -- Connexion au render
    renderConn = RunService.RenderStepped:Connect(onRenderStepped)

    Utils.Log("ESP activé")
    Config.Current.Enabled = true
end

-- ── Désactiver l'ESP ─────────────────────────────────────────
function ESP.Disable()
    if not enabled then return end
    enabled = false

    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end

    if ESP._playerAddedConn then
        ESP._playerAddedConn:Disconnect()
        ESP._playerAddedConn = nil
    end

    if ESP._playerRemovingConn then
        ESP._playerRemovingConn:Disconnect()
        ESP._playerRemovingConn = nil
    end

    -- Cacher toutes les entités
    for _, ent in pairs(entities) do
        hideEntity(ent)
    end

    Utils.Log("ESP désactivé")
    Config.Current.Enabled = false
end

-- ── Toggle ────────────────────────────────────────────────────
function ESP.Toggle()
    if enabled then
        ESP.Disable()
    else
        ESP.Enable()
    end
end

-- ── Nettoyer toutes les entités ──────────────────────────────
function ESP.Cleanup()
    ESP.Disable()
    for player, _ in pairs(entities) do
        removeEntity(player)
    end
    ESP.RemovePreview()
    Utils.Log("ESP cleanup complet")
end

-- ── Activer/désactiver un joueur spécifique ──────────────────
function ESP.SetPlayerEnabled(player, state)
    local ent = entities[player]
    if ent then
        ent.disabled = not state
        if not state then
            hideEntity(ent)
        end
    end
end

-- ── Obtenir l'état d'un joueur ───────────────────────────────
function ESP.GetPlayerInfo(player)
    local char = player.Character
    local root = char and Utils.GetRoot(char)

    return {
        name     = player.Name,
        distance = root and Utils.GetDistance(root.Position) or -1,
        health   = char and Utils.GetHealthPercent(char) or 0,
        team     = player.Team and player.Team.Name or "N/A",
        visible  = root and Utils.IsVisible(root.Position) or false,
        position = root and root.Position or Vector3.new(0, 0, 0),
        enabled  = not (entities[player] and entities[player].disabled),
    }
end

-- ── Récupérer toutes les entités ─────────────────────────────
function ESP.GetEntities()
    return entities
end

-- ── Mode Preview (dummy statique) ────────────────────────────
function ESP.ShowPreview()
    ESP.RemovePreview()

    -- Créer un dummy dans le workspace
    local dummyFolder  = Instance.new("Folder")
    dummyFolder.Name   = "ESP_PreviewDummy"
    dummyFolder.Parent = Workspace

    local camera   = Workspace.CurrentCamera
    local dummyCF  = camera.CFrame * CFrame.new(0, 0, -15)

    -- Parts du dummy R15 simplifié
    local partDefs = {
        { name = "Head",           size = Vector3.new(2, 1, 1),   offset = Vector3.new(0, 3.5, 0) },
        { name = "UpperTorso",     size = Vector3.new(2, 1.5, 1), offset = Vector3.new(0, 2, 0)   },
        { name = "LowerTorso",     size = Vector3.new(2, 1, 1),   offset = Vector3.new(0, 0.75, 0)},
        { name = "RightUpperArm",  size = Vector3.new(1, 1.5, 1), offset = Vector3.new(1.5, 2, 0) },
        { name = "RightLowerArm",  size = Vector3.new(1, 1, 1),   offset = Vector3.new(1.5, 0.5, 0)},
        { name = "RightHand",      size = Vector3.new(1, 0.5, 1), offset = Vector3.new(1.5, -0.25,0)},
        { name = "LeftUpperArm",   size = Vector3.new(1, 1.5, 1), offset = Vector3.new(-1.5, 2, 0)},
        { name = "LeftLowerArm",   size = Vector3.new(1, 1, 1),   offset = Vector3.new(-1.5, 0.5, 0)},
        { name = "LeftHand",       size = Vector3.new(1, 0.5, 1), offset = Vector3.new(-1.5,-0.25,0)},
        { name = "RightUpperLeg",  size = Vector3.new(1, 1.5, 1), offset = Vector3.new(0.5, -1, 0)},
        { name = "RightLowerLeg",  size = Vector3.new(1, 1.5, 1), offset = Vector3.new(0.5, -2.5, 0)},
        { name = "RightFoot",      size = Vector3.new(1, 0.5, 1), offset = Vector3.new(0.5, -3.5, 0)},
        { name = "LeftUpperLeg",   size = Vector3.new(1, 1.5, 1), offset = Vector3.new(-0.5,-1, 0)},
        { name = "LeftLowerLeg",   size = Vector3.new(1, 1.5, 1), offset = Vector3.new(-0.5,-2.5,0)},
        { name = "LeftFoot",       size = Vector3.new(1, 0.5, 1), offset = Vector3.new(-0.5,-3.5,0)},
        { name = "HumanoidRootPart", size=Vector3.new(2,2,1),     offset= Vector3.new(0, 1.5, 0) },
    }

    for _, def in ipairs(partDefs) do
        local part         = Instance.new("Part")
        part.Name          = def.name
        part.Size          = def.size
        part.CFrame        = dummyCF * CFrame.new(def.offset)
        part.Anchored      = true
        part.CanCollide    = false
        part.Transparency  = 0.8
        part.Color         = Color3.fromRGB(100, 200, 255)
        part.Parent        = dummyFolder
    end

    -- Humanoid factice pour la santé
    local hum           = Instance.new("Humanoid")
    hum.Health          = 75
    hum.MaxHealth       = 100
    hum.Parent          = dummyFolder

    previewDummy = dummyFolder

    -- Créer un player fictif simulé
    local fakePlayer = {
        Name      = "PreviewPlayer",
        Character = dummyFolder,
        Team      = nil,
    }

    -- Drawings preview
    local previewEnt = {
        box      = Box.Create(fakePlayer),
        skeleton = Skeleton.Create(fakePlayer),
        tracers  = Tracers.Create(fakePlayer),
        health   = Health.Create(fakePlayer),
        name     = NameMod.Create(fakePlayer),
        distance = Distance.Create(fakePlayer),
        disabled = false,
    }

    entities["__preview__"] = previewEnt

    -- Connexion preview update
    ESP._previewConn = RunService.RenderStepped:Connect(function()
        local ok, err = pcall(updateEntity, fakePlayer, previewEnt)
        if not ok then
            Utils.Log("Preview error: " .. err, "ERROR")
        end
    end)

    Utils.Log("Mode Preview activé")
end

function ESP.RemovePreview()
    if ESP._previewConn then
        ESP._previewConn:Disconnect()
        ESP._previewConn = nil
    end

    local ent = entities["__preview__"]
    if ent then
        ent.box:Remove()
        ent.skeleton:Remove()
        ent.tracers:Remove()
        ent.health:Remove()
        ent.name:Remove()
        ent.distance:Remove()
        entities["__preview__"] = nil
    end

    if previewDummy then
        previewDummy:Destroy()
        previewDummy = nil
    end

    Utils.Log("Mode Preview désactivé")
end

return ESP
