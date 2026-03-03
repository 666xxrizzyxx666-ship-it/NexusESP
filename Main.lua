-- ============================================================
--  Main.lua — Point d'entrée du framework ESP
--  ▸ Charge la librairie Linoria depuis GitHub
--  ▸ Charge tous les modules depuis GitHub
--  ▸ Construit l'UI complète (Visuals / ESP / PlayerList / Settings)
--  ▸ Initialise l'ESP et branche les callbacks UI
-- ============================================================

-- ┌─────────────────────────────────────────────────────────┐
-- │  CONFIGURATION — Remplacer par ton URL GitHub RAW       │
-- └─────────────────────────────────────────────────────────┘
local REPO_URL = "https://raw.githubusercontent.com/TON_USERNAME/TON_REPO/main/"
-- Exemple : "https://raw.githubusercontent.com/monpseudo/roblox-esp/main/"

-- ── Loader GitHub ────────────────────────────────────────────
local function include(path)
    local url = REPO_URL .. path
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if not ok then
        warn("[ESP Loader] Erreur chargement: " .. path .. "\n" .. tostring(result))
        return nil
    end
    return result
end

-- ── Chargement de Linoria UI ─────────────────────────────────
-- La librairie est hébergée à la racine du repo sous "linoria.lua"
print("[ESP] Chargement de la librairie UI Linoria...")
local Library   = include("linoria.lua")

-- ── Chargement SaveManager et ThemeManager de Linoria ────────
-- Ces modules sont standard dans l'écosystème Linoria
local SaveManager   = include("Addons/SaveManager.lua")
local InterfaceManager = include("Addons/InterfaceManager.lua")

-- ── Chargement des modules ESP ────────────────────────────────
print("[ESP] Chargement des modules...")

local Config     = include("Modules/Config.lua")
local Utils      = include("Modules/Utils.lua")
local Box        = include("Modules/Box.lua")
local Skeleton   = include("Modules/Skeleton.lua")
local Tracers    = include("Modules/Tracers.lua")
local Health     = include("Modules/Health.lua")
local NameMod    = include("Modules/Name.lua")
local Distance   = include("Modules/Distance.lua")
local ESP        = include("Modules/ESP.lua")
local PlayerList = include("Modules/PlayerList.lua")

-- ── Init Config ───────────────────────────────────────────────
local cfg = Config:Init()

-- ── Init ESP ──────────────────────────────────────────────────
ESP.Init({
    Utils    = Utils,
    Config   = Config,
    Box      = Box,
    Skeleton = Skeleton,
    Tracers  = Tracers,
    Health   = Health,
    Name     = NameMod,
    Distance = Distance,
})

-- ── Init PlayerList ───────────────────────────────────────────
PlayerList.SetDependencies(Utils, Config, ESP)

-- ── Raccourci : sauvegarder config après chaque changement ───
local function save()
    Config:Save()
end

-- ════════════════════════════════════════════════════════════
--  CONSTRUCTION DE L'UI LINORIA
-- ════════════════════════════════════════════════════════════

local Window = Library:CreateWindow({
    Title          = "🎯 RobloxESP Framework",
    Center         = true,
    AutoShow       = true,
    TabPadding     = 8,
    MenuFadeTime   = 0.2,
})

-- ── Onglets principaux ────────────────────────────────────────
local Tabs = {
    Visuals    = Window:AddTab("Visuals"),
    ESP        = Window:AddTab("ESP"),
    PlayerList = Window:AddTab("Player List"),
    Settings   = Window:AddTab("Settings"),
}

-- ════════════════════════════════════════════════════════════
--  ONGLET : VISUALS
-- ════════════════════════════════════════════════════════════

do
    local Left  = Tabs.Visuals:AddLeftGroupbox("Box ESP")
    local Right = Tabs.Visuals:AddRightGroupbox("Skeleton & Tracers")

    -- ── Box ──────────────────────────────────────────────────
    Left:AddToggle("BoxEnabled", {
        Text    = "Activer la Box",
        Default = cfg.Box.Enabled,
        Tooltip = "Affiche un rectangle 2D autour des joueurs",
        Callback = function(val)
            cfg.Box.Enabled = val
            save()
        end,
    })

    Left:AddColorpicker("BoxColor", {
        Text    = "Couleur de la Box",
        Default = Config.ToColor3(cfg.Box.Color),
        Tooltip = "Couleur du contour de la bounding box",
        Callback = function(val)
            cfg.Box.Color = Config.FromColor3(val)
            save()
        end,
    })

    Left:AddSlider("BoxThickness", {
        Text    = "Épaisseur",
        Default = cfg.Box.Thickness,
        Min     = 1,
        Max     = 5,
        Rounding = 0,
        Tooltip = "Épaisseur du trait de la box (px)",
        Callback = function(val)
            cfg.Box.Thickness = val
            save()
        end,
    })

    Left:AddToggle("BoxFilled", {
        Text    = "Box remplie",
        Default = cfg.Box.Filled,
        Tooltip = "Remplit la box avec une couleur semi-transparente",
        Callback = function(val)
            cfg.Box.Filled = val
            save()
        end,
    })

    Left:AddColorpicker("BoxFillColor", {
        Text    = "Couleur fill",
        Default = Config.ToColor3(cfg.Box.FillColor),
        Tooltip = "Couleur du remplissage",
        Callback = function(val)
            cfg.Box.FillColor = Config.FromColor3(val)
            save()
        end,
    })

    Left:AddSlider("BoxFillTrans", {
        Text     = "Opacité fill",
        Default  = math.floor((1 - cfg.Box.FillTrans) * 100),
        Min      = 0,
        Max      = 100,
        Rounding = 0,
        Tooltip  = "Opacité du remplissage (0 = invisible, 100 = opaque)",
        Callback = function(val)
            cfg.Box.FillTrans = 1 - (val / 100)
            save()
        end,
    })

    -- ── Skeleton ─────────────────────────────────────────────
    Right:AddToggle("SkeletonEnabled", {
        Text    = "Activer le Skeleton",
        Default = cfg.Skeleton.Enabled,
        Tooltip = "Dessine les lignes du squelette (R6 / R15)",
        Callback = function(val)
            cfg.Skeleton.Enabled = val
            save()
        end,
    })

    Right:AddColorpicker("SkeletonColor", {
        Text    = "Couleur Skeleton",
        Default = Config.ToColor3(cfg.Skeleton.Color),
        Tooltip = "Couleur des lignes squelettiques",
        Callback = function(val)
            cfg.Skeleton.Color = Config.FromColor3(val)
            save()
        end,
    })

    Right:AddSlider("SkeletonThick", {
        Text     = "Épaisseur Skeleton",
        Default  = cfg.Skeleton.Thickness,
        Min      = 1,
        Max      = 4,
        Rounding = 0,
        Callback = function(val)
            cfg.Skeleton.Thickness = val
            save()
        end,
    })

    -- ── Tracers ───────────────────────────────────────────────
    Right:AddToggle("TracerEnabled", {
        Text    = "Activer les Tracers",
        Default = cfg.Tracers.Enabled,
        Tooltip = "Ligne depuis l'écran vers chaque joueur",
        Callback = function(val)
            cfg.Tracers.Enabled = val
            save()
        end,
    })

    Right:AddColorpicker("TracerColor", {
        Text    = "Couleur Tracer",
        Default = Config.ToColor3(cfg.Tracers.Color),
        Callback = function(val)
            cfg.Tracers.Color = Config.FromColor3(val)
            save()
        end,
    })

    Right:AddDropdown("TracerPosition", {
        Text    = "Position source Tracer",
        Values  = { "Bottom", "Center", "Top" },
        Default = cfg.Tracers.Position,
        Tooltip = "Point d'origine du tracer sur l'écran",
        Callback = function(val)
            cfg.Tracers.Position = val
            save()
        end,
    })

    Right:AddSlider("TracerThick", {
        Text     = "Épaisseur Tracer",
        Default  = cfg.Tracers.Thickness,
        Min      = 1,
        Max      = 4,
        Rounding = 0,
        Callback = function(val)
            cfg.Tracers.Thickness = val
            save()
        end,
    })
end

-- ════════════════════════════════════════════════════════════
--  ONGLET : ESP
-- ════════════════════════════════════════════════════════════

do
    local Left  = Tabs.ESP:AddLeftGroupbox("ESP Principal")
    local Right = Tabs.ESP:AddRightGroupbox("Health & Labels")

    -- ── ESP Global ────────────────────────────────────────────
    Left:AddToggle("ESPEnabled", {
        Text    = "Activer l'ESP",
        Default = cfg.Enabled,
        Tooltip = "Active/désactive tout le système ESP",
        Callback = function(val)
            if val then
                ESP.Enable()
            else
                ESP.Disable()
            end
            save()
        end,
    })

    Left:AddToggle("TeamCheck", {
        Text    = "Team Check",
        Default = cfg.TeamCheck,
        Tooltip = "Ne pas afficher les alliés",
        Callback = function(val)
            cfg.TeamCheck = val
            save()
        end,
    })

    Left:AddToggle("VisibilityCheck", {
        Text    = "Visibility Check",
        Default = cfg.VisibilityCheck,
        Tooltip = "Atténue les joueurs non visibles (raycast)",
        Callback = function(val)
            cfg.VisibilityCheck = val
            save()
        end,
    })

    Left:AddToggle("PerformanceMode", {
        Text    = "Mode Performance",
        Default = cfg.PerformanceMode,
        Tooltip = "Réduit la fréquence de certains calculs lourds",
        Callback = function(val)
            cfg.PerformanceMode = val
            save()
        end,
    })

    Left:AddSlider("MaxDist", {
        Text     = "Distance Max (studs)",
        Default  = cfg.Distance.MaxDist,
        Min      = 50,
        Max      = 2000,
        Rounding = 0,
        Tooltip  = "Distance maximale d'affichage ESP",
        Callback = function(val)
            cfg.Distance.MaxDist = val
            save()
        end,
    })

    Left:AddButton({
        Text    = "▶ Mode Preview",
        Tooltip = "Affiche un dummy pour tester les visualisations",
        Func    = function()
            ESP.ShowPreview()
        end,
    })

    Left:AddButton({
        Text    = "⏹ Stop Preview",
        Func    = function()
            ESP.RemovePreview()
        end,
    })

    -- ── Health Bar ───────────────────────────────────────────
    Right:AddToggle("HealthEnabled", {
        Text    = "Barre de santé",
        Default = cfg.Health.Enabled,
        Tooltip = "Affiche une barre de santé colorée",
        Callback = function(val)
            cfg.Health.Enabled = val
            save()
        end,
    })

    Right:AddDropdown("HealthPosition", {
        Text    = "Position de la barre",
        Values  = { "Left", "Right", "Top", "Bottom" },
        Default = cfg.Health.Position,
        Tooltip = "Côté où s'affiche la barre de santé",
        Callback = function(val)
            cfg.Health.Position = val
            save()
        end,
    })

    Right:AddSlider("HealthWidth", {
        Text     = "Largeur (px)",
        Default  = cfg.Health.Width,
        Min      = 2,
        Max      = 8,
        Rounding = 0,
        Callback = function(val)
            cfg.Health.Width = val
            save()
        end,
    })

    Right:AddToggle("HealthShowText", {
        Text    = "Afficher les HP",
        Default = cfg.Health.ShowText,
        Tooltip = "Affiche la valeur numérique de santé",
        Callback = function(val)
            cfg.Health.ShowText = val
            save()
        end,
    })

    -- ── Name Tag ─────────────────────────────────────────────
    Right:AddToggle("NameEnabled", {
        Text    = "Afficher le Nom",
        Default = cfg.Name.Enabled,
        Callback = function(val)
            cfg.Name.Enabled = val
            save()
        end,
    })

    Right:AddColorpicker("NameColor", {
        Text    = "Couleur du Nom",
        Default = Config.ToColor3(cfg.Name.Color),
        Callback = function(val)
            cfg.Name.Color = Config.FromColor3(val)
            save()
        end,
    })

    Right:AddSlider("NameSize", {
        Text     = "Taille police",
        Default  = cfg.Name.Size,
        Min      = 8,
        Max      = 20,
        Rounding = 0,
        Callback = function(val)
            cfg.Name.Size = val
            save()
        end,
    })

    Right:AddSlider("NameOffsetY", {
        Text     = "Offset Y",
        Default  = cfg.Name.OffsetY,
        Min      = 0,
        Max      = 20,
        Rounding = 0,
        Callback = function(val)
            cfg.Name.OffsetY = val
            save()
        end,
    })

    -- ── Distance Tag ─────────────────────────────────────────
    Right:AddToggle("DistanceEnabled", {
        Text    = "Afficher la Distance",
        Default = cfg.Distance.Enabled,
        Callback = function(val)
            cfg.Distance.Enabled = val
            save()
        end,
    })

    Right:AddColorpicker("DistanceColor", {
        Text    = "Couleur distance",
        Default = Config.ToColor3(cfg.Distance.Color),
        Callback = function(val)
            cfg.Distance.Color = Config.FromColor3(val)
            save()
        end,
    })
end

-- ════════════════════════════════════════════════════════════
--  ONGLET : PLAYER LIST
-- ════════════════════════════════════════════════════════════

do
    local Left  = Tabs.PlayerList:AddLeftGroupbox("Affichage")
    local Right = Tabs.PlayerList:AddRightGroupbox("Actions")

    Left:AddToggle("PLEnabled", {
        Text    = "Activer la Player List",
        Default = cfg.PlayerList.Enabled,
        Tooltip = "Affiche la liste overlay des joueurs",
        Callback = function(val)
            cfg.PlayerList.Enabled = val
            if val then
                PlayerList.Show()
            else
                PlayerList.Hide()
            end
            save()
        end,
    })

    Left:AddToggle("PLShowDist", {
        Text    = "Afficher la distance",
        Default = cfg.PlayerList.ShowDistance,
        Callback = function(val)
            cfg.PlayerList.ShowDistance = val
            save()
        end,
    })

    Left:AddToggle("PLShowHealth", {
        Text    = "Afficher la santé",
        Default = cfg.PlayerList.ShowHealth,
        Callback = function(val)
            cfg.PlayerList.ShowHealth = val
            save()
        end,
    })

    Left:AddToggle("PLShowTeam", {
        Text    = "Afficher l'équipe",
        Default = cfg.PlayerList.ShowTeam,
        Callback = function(val)
            cfg.PlayerList.ShowTeam = val
            save()
        end,
    })

    Left:AddToggle("PLShowVisible", {
        Text    = "Afficher la visibilité",
        Default = cfg.PlayerList.ShowVisible,
        Tooltip = "Indicateur vert/rouge si le joueur est en ligne de mire",
        Callback = function(val)
            cfg.PlayerList.ShowVisible = val
            save()
        end,
    })

    -- ── Sélecteur de joueur pour focus/toggle ────────────────
    Right:AddDropdown("FocusPlayerDrop", {
        Text         = "Sélectionner un joueur",
        SpecialType  = "Player",
        Values       = {},
        Tooltip      = "Choisir un joueur pour les actions ci-dessous",
        Callback     = function(_) end,
    })

    Right:AddButton({
        Text    = "🎯 Focus ce joueur",
        Tooltip = "Déplace la caméra vers ce joueur",
        Func    = function()
            local opt = Options["FocusPlayerDrop"]
            if opt and opt.Value then
                local p = game:GetService("Players"):FindFirstChild(opt.Value)
                if p then
                    PlayerList.FocusPlayer(p)
                end
            end
        end,
    })

    Right:AddButton({
        Text    = "👁 Toggle ESP joueur",
        Tooltip = "Active/désactive l'ESP pour ce joueur",
        Func    = function()
            local opt = Options["FocusPlayerDrop"]
            if opt and opt.Value then
                local p = game:GetService("Players"):FindFirstChild(opt.Value)
                if p then
                    PlayerList.TogglePlayerESP(p)
                end
            end
        end,
    })

    Right:AddButton({
        Text = "📷 Unfocus",
        Func = function()
            PlayerList.Unfocus()
        end,
    })
end

-- ════════════════════════════════════════════════════════════
--  ONGLET : SETTINGS
-- ════════════════════════════════════════════════════════════

do
    local Left  = Tabs.Settings:AddLeftGroupbox("Configuration")
    local Right = Tabs.Settings:AddRightGroupbox("Debug & Profiler")

    Left:AddButton({
        Text    = "💾 Sauvegarder Config",
        Tooltip = "Sauvegarde la configuration dans un fichier JSON",
        Func    = function()
            Config:Save()
            Library:Notify("Configuration sauvegardée !", 3)
        end,
    })

    Left:AddButton({
        Text    = "📂 Charger Config",
        Tooltip = "Charge la configuration depuis le fichier",
        Func    = function()
            Config:Load()
            Library:Notify("Configuration chargée !", 3)
        end,
    })

    Left:AddButton({
        Text    = "🔄 Reset Config",
        Tooltip = "Remet toutes les valeurs par défaut",
        Func    = function()
            Config:Reset()
            Library:Notify("Config remise à zéro", 3)
        end,
    })

    -- Keybind toggle UI
    Left:AddKeypicker("UIKeybind", {
        Text    = "Touche pour afficher/masquer l'UI",
        Default = "RightControl",
        Mode    = "Toggle",
        Tooltip = "Appuie sur cette touche pour ouvrir/fermer l'interface",
        Callback = function(val)
            Library.ToggleKeybind = Options["UIKeybind"]
        end,
    })

    Library.ToggleKeybind = Options["UIKeybind"]

    -- ── Debug ────────────────────────────────────────────────
    Right:AddToggle("DebugMode", {
        Text    = "Mode Debug",
        Default = cfg.DebugMode,
        Tooltip = "Active les logs dans la console",
        Callback = function(val)
            cfg.DebugMode = val
            save()
        end,
    })

    Right:AddButton({
        Text = "📋 Afficher les logs",
        Func = function()
            local logs = Utils.GetLogs()
            local last10 = {}
            local start = math.max(1, #logs - 9)
            for i = start, #logs do
                table.insert(last10, logs[i])
            end
            print("── ESP Logs ──")
            for _, l in ipairs(last10) do
                print(l)
            end
        end,
    })

    Right:AddButton({
        Text = "🗑 Vider les logs",
        Func = function()
            Utils.ClearLogs()
            Library:Notify("Logs vidés", 2)
        end,
    })

    -- ── Profiler ─────────────────────────────────────────────
    Right:AddButton({
        Text    = "⏱ Afficher profiling",
        Tooltip = "Affiche le temps d'exécution de chaque module (ms)",
        Func    = function()
            local pd = ESP.ProfileData
            local msg = string.format(
                "Box: %.3fms | Skel: %.3fms | Tracer: %.3fms\nHealth: %.3fms | Name: %.3fms | Dist: %.3fms",
                pd.Box, pd.Skeleton, pd.Tracers,
                pd.Health, pd.Name, pd.Distance
            )
            print("── Profiling ──\n" .. msg)
            Library:Notify(msg, 6)
        end,
    })

    -- ── Cleanup ───────────────────────────────────────────────
    Right:AddButton({
        Text    = "☠ Cleanup complet",
        Tooltip = "Supprime tous les Drawings et désactive l'ESP",
        Func    = function()
            ESP.Cleanup()
            PlayerList.Cleanup()
            Library:Notify("Cleanup effectué", 3)
        end,
    })
end

-- ════════════════════════════════════════════════════════════
--  SaveManager & InterfaceManager (Linoria Addons)
-- ════════════════════════════════════════════════════════════

if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "UIKeybind" })
    SaveManager:SetFolder("RobloxESP")

    -- Ajouter les boutons de sauvegarde dans Settings
    local SaveTab = Tabs.Settings:AddRightGroupbox("Profils de config")
    SaveManager:BuildConfigSection(SaveTab)
end

if InterfaceManager then
    InterfaceManager:SetLibrary(Library)
    InterfaceManager:SetFolder("RobloxESP")

    local ThemeTab = Tabs.Settings:AddLeftGroupbox("Thème UI")
    InterfaceManager:BuildInterfaceSection(ThemeTab)
end

-- ════════════════════════════════════════════════════════════
--  DÉMARRAGE AUTOMATIQUE
-- ════════════════════════════════════════════════════════════

-- Si ESP était activé à la dernière session, on le réactive
if cfg.Enabled then
    task.wait(1)  -- laisser le temps aux characters de charger
    ESP.Enable()
    Toggles["ESPEnabled"].Value = true
end

if cfg.PlayerList.Enabled then
    PlayerList.Show()
end

print("[ESP] Framework chargé avec succès ! (RightCtrl pour toggle UI)")
