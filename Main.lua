-- ============================================================
--  Main.lua — NexusESP Framework
-- ============================================================

local REPO_URL = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

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

print("[ESP] Chargement Linoria...")
local Library = include("linoria.lua")

local SaveManager      = include("Addons/SaveManager.lua")
local InterfaceManager = include("Addons/InterfaceManager.lua")

print("[ESP] Chargement modules...")
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

local cfg = Config:Init()

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

PlayerList.SetDependencies(Utils, Config, ESP)

local function save()
    Config:Save()
end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title        = "NexusESP",
    Center       = true,
    AutoShow     = true,
    TabPadding   = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Visuals    = Window:AddTab("Visuals"),
    ESP        = Window:AddTab("ESP"),
    PlayerList = Window:AddTab("Player List"),
    Settings   = Window:AddTab("Settings"),
}

-- ════════════════════════════════════════════════════════════
--  VISUALS
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.Visuals:AddLeftGroupbox("Box ESP")
    local Right = Tabs.Visuals:AddRightGroupbox("Skeleton & Tracers")

    -- Box : le ColorPicker se chaine sur le Toggle
    Left:AddToggle("BoxEnabled", {
        Text     = "Activer la Box",
        Default  = cfg.Box.Enabled,
        Tooltip  = "Affiche un rectangle 2D autour des joueurs",
        Callback = function(val) cfg.Box.Enabled = val save() end,
    }):AddColorPicker("BoxColor", {
        Title    = "Couleur Box",
        Default  = Config.ToColor3(cfg.Box.Color),
        Callback = function(val) cfg.Box.Color = Config.FromColor3(val) save() end,
    })

    Left:AddSlider("BoxThickness", {
        Text     = "Epaisseur Box",
        Default  = cfg.Box.Thickness,
        Min = 1, Max = 5, Rounding = 0,
        Callback = function(val) cfg.Box.Thickness = val save() end,
    })

    Left:AddToggle("BoxFilled", {
        Text     = "Box remplie",
        Default  = cfg.Box.Filled,
        Callback = function(val) cfg.Box.Filled = val save() end,
    }):AddColorPicker("BoxFillColor", {
        Title    = "Couleur fill",
        Default  = Config.ToColor3(cfg.Box.FillColor),
        Callback = function(val) cfg.Box.FillColor = Config.FromColor3(val) save() end,
    })

    Left:AddSlider("BoxFillTrans", {
        Text     = "Opacite fill",
        Default  = math.floor((1 - cfg.Box.FillTrans) * 100),
        Min = 0, Max = 100, Rounding = 0,
        Callback = function(val) cfg.Box.FillTrans = 1 - (val / 100) save() end,
    })

    -- Skeleton
    Right:AddToggle("SkeletonEnabled", {
        Text     = "Activer Skeleton",
        Default  = cfg.Skeleton.Enabled,
        Tooltip  = "Dessine le squelette (R6 / R15)",
        Callback = function(val) cfg.Skeleton.Enabled = val save() end,
    }):AddColorPicker("SkeletonColor", {
        Title    = "Couleur Skeleton",
        Default  = Config.ToColor3(cfg.Skeleton.Color),
        Callback = function(val) cfg.Skeleton.Color = Config.FromColor3(val) save() end,
    })

    Right:AddSlider("SkeletonThick", {
        Text     = "Epaisseur Skeleton",
        Default  = cfg.Skeleton.Thickness,
        Min = 1, Max = 4, Rounding = 0,
        Callback = function(val) cfg.Skeleton.Thickness = val save() end,
    })

    -- Tracers
    Right:AddToggle("TracerEnabled", {
        Text     = "Activer Tracers",
        Default  = cfg.Tracers.Enabled,
        Callback = function(val) cfg.Tracers.Enabled = val save() end,
    }):AddColorPicker("TracerColor", {
        Title    = "Couleur Tracer",
        Default  = Config.ToColor3(cfg.Tracers.Color),
        Callback = function(val) cfg.Tracers.Color = Config.FromColor3(val) save() end,
    })

    Right:AddDropdown("TracerPosition", {
        Text     = "Position Tracer",
        Values   = { "Bottom", "Center", "Top" },
        Default  = cfg.Tracers.Position,
        Callback = function(val) cfg.Tracers.Position = val save() end,
    })

    Right:AddSlider("TracerThick", {
        Text     = "Epaisseur Tracer",
        Default  = cfg.Tracers.Thickness,
        Min = 1, Max = 4, Rounding = 0,
        Callback = function(val) cfg.Tracers.Thickness = val save() end,
    })
end

-- ════════════════════════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.ESP:AddLeftGroupbox("ESP Principal")
    local Right = Tabs.ESP:AddRightGroupbox("Health & Labels")

    Left:AddToggle("ESPEnabled", {
        Text     = "Activer ESP",
        Default  = cfg.Enabled,
        Tooltip  = "Active/desactive tout le systeme ESP",
        Callback = function(val)
            if val then ESP.Enable() else ESP.Disable() end
            save()
        end,
    })

    Left:AddToggle("TeamCheck", {
        Text     = "Team Check",
        Default  = cfg.TeamCheck,
        Tooltip  = "Ne pas afficher les allies",
        Callback = function(val) cfg.TeamCheck = val save() end,
    })

    Left:AddToggle("VisibilityCheck", {
        Text     = "Visibility Check",
        Default  = cfg.VisibilityCheck,
        Callback = function(val) cfg.VisibilityCheck = val save() end,
    })

    Left:AddToggle("PerformanceMode", {
        Text     = "Mode Performance",
        Default  = cfg.PerformanceMode,
        Callback = function(val) cfg.PerformanceMode = val save() end,
    })

    Left:AddSlider("MaxDist", {
        Text     = "Distance Max (studs)",
        Default  = cfg.Distance.MaxDist,
        Min = 50, Max = 2000, Rounding = 0,
        Callback = function(val) cfg.Distance.MaxDist = val save() end,
    })

    Left:AddButton({ Text = "Mode Preview",  Func = function() ESP.ShowPreview()  end })
    Left:AddButton({ Text = "Stop Preview",  Func = function() ESP.RemovePreview() end })

    -- Health
    Right:AddToggle("HealthEnabled", {
        Text     = "Barre de sante",
        Default  = cfg.Health.Enabled,
        Callback = function(val) cfg.Health.Enabled = val save() end,
    })

    Right:AddDropdown("HealthPosition", {
        Text     = "Position barre sante",
        Values   = { "Left", "Right", "Top", "Bottom" },
        Default  = cfg.Health.Position,
        Callback = function(val) cfg.Health.Position = val save() end,
    })

    Right:AddSlider("HealthWidth", {
        Text     = "Largeur barre (px)",
        Default  = cfg.Health.Width,
        Min = 2, Max = 8, Rounding = 0,
        Callback = function(val) cfg.Health.Width = val save() end,
    })

    Right:AddToggle("HealthShowText", {
        Text     = "Afficher valeur HP",
        Default  = cfg.Health.ShowText,
        Callback = function(val) cfg.Health.ShowText = val save() end,
    })

    -- Name
    Right:AddToggle("NameEnabled", {
        Text     = "Afficher Nom",
        Default  = cfg.Name.Enabled,
        Callback = function(val) cfg.Name.Enabled = val save() end,
    }):AddColorPicker("NameColor", {
        Title    = "Couleur Nom",
        Default  = Config.ToColor3(cfg.Name.Color),
        Callback = function(val) cfg.Name.Color = Config.FromColor3(val) save() end,
    })

    Right:AddSlider("NameSize", {
        Text     = "Taille police Nom",
        Default  = cfg.Name.Size,
        Min = 8, Max = 20, Rounding = 0,
        Callback = function(val) cfg.Name.Size = val save() end,
    })

    -- Distance
    Right:AddToggle("DistanceEnabled", {
        Text     = "Afficher Distance",
        Default  = cfg.Distance.Enabled,
        Callback = function(val) cfg.Distance.Enabled = val save() end,
    }):AddColorPicker("DistanceColor", {
        Title    = "Couleur Distance",
        Default  = Config.ToColor3(cfg.Distance.Color),
        Callback = function(val) cfg.Distance.Color = Config.FromColor3(val) save() end,
    })
end

-- ════════════════════════════════════════════════════════════
--  PLAYER LIST
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.PlayerList:AddLeftGroupbox("Affichage")
    local Right = Tabs.PlayerList:AddRightGroupbox("Actions")

    Left:AddToggle("PLEnabled", {
        Text     = "Activer Player List",
        Default  = cfg.PlayerList.Enabled,
        Callback = function(val)
            cfg.PlayerList.Enabled = val
            if val then PlayerList.Show() else PlayerList.Hide() end
            save()
        end,
    })

    Left:AddToggle("PLShowDist",    { Text = "Afficher distance",  Default = cfg.PlayerList.ShowDistance, Callback = function(val) cfg.PlayerList.ShowDistance = val save() end })
    Left:AddToggle("PLShowHealth",  { Text = "Afficher sante",     Default = cfg.PlayerList.ShowHealth,   Callback = function(val) cfg.PlayerList.ShowHealth   = val save() end })
    Left:AddToggle("PLShowTeam",    { Text = "Afficher equipe",    Default = cfg.PlayerList.ShowTeam,     Callback = function(val) cfg.PlayerList.ShowTeam     = val save() end })
    Left:AddToggle("PLShowVisible", { Text = "Afficher visibilite",Default = cfg.PlayerList.ShowVisible,  Callback = function(val) cfg.PlayerList.ShowVisible  = val save() end })

    Right:AddDropdown("FocusPlayerDrop", {
        Text        = "Selectionner un joueur",
        SpecialType = "Player",
        Values      = {},
        Callback    = function(_) end,
    })

    Right:AddButton({ Text = "Focus joueur",    Func = function()
        local opt = Options["FocusPlayerDrop"]
        if opt and opt.Value then
            local p = game:GetService("Players"):FindFirstChild(opt.Value)
            if p then PlayerList.FocusPlayer(p) end
        end
    end})

    Right:AddButton({ Text = "Toggle ESP joueur", Func = function()
        local opt = Options["FocusPlayerDrop"]
        if opt and opt.Value then
            local p = game:GetService("Players"):FindFirstChild(opt.Value)
            if p then PlayerList.TogglePlayerESP(p) end
        end
    end})

    Right:AddButton({ Text = "Unfocus", Func = function() PlayerList.Unfocus() end })
end

-- ════════════════════════════════════════════════════════════
--  SETTINGS
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.Settings:AddLeftGroupbox("Configuration")
    local Right = Tabs.Settings:AddRightGroupbox("Debug & Profiler")

    Left:AddButton({ Text = "Sauvegarder Config", Func = function() Config:Save()  Library:Notify("Config sauvegardee!", 3) end })
    Left:AddButton({ Text = "Charger Config",     Func = function() Config:Load()  Library:Notify("Config chargee!", 3)    end })
    Left:AddButton({ Text = "Reset Config",       Func = function() Config:Reset() Library:Notify("Config reset!", 3)      end })

    Right:AddToggle("DebugMode", {
        Text     = "Mode Debug",
        Default  = cfg.DebugMode,
        Callback = function(val) cfg.DebugMode = val save() end,
    })

    Right:AddButton({ Text = "Afficher logs", Func = function()
        local logs = Utils.GetLogs()
        local s = math.max(1, #logs - 9)
        print("-- ESP Logs --")
        for i = s, #logs do print(logs[i]) end
    end})

    Right:AddButton({ Text = "Vider logs", Func = function()
        Utils.ClearLogs()
        Library:Notify("Logs vides", 2)
    end})

    Right:AddButton({ Text = "Profiling", Func = function()
        local pd = ESP.ProfileData
        local msg = string.format(
            "Box:%.3f Skel:%.3f Tracer:%.3f HP:%.3f Name:%.3f Dist:%.3f",
            pd.Box, pd.Skeleton, pd.Tracers, pd.Health, pd.Name, pd.Distance
        )
        print(msg)
        Library:Notify(msg, 6)
    end})

    Right:AddButton({ Text = "Cleanup", Func = function()
        ESP.Cleanup()
        PlayerList.Cleanup()
        Library:Notify("Cleanup effectue", 3)
    end})
end

-- ════════════════════════════════════════════════════════════
--  ADDONS
-- ════════════════════════════════════════════════════════════
if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder("NexusESP")
    local SaveTab = Tabs.Settings:AddRightGroupbox("Profils")
    SaveManager:BuildConfigSection(SaveTab)
end

if InterfaceManager then
    InterfaceManager:SetLibrary(Library)
    InterfaceManager:SetFolder("NexusESP")
    local ThemeTab = Tabs.Settings:AddLeftGroupbox("Theme UI")
    InterfaceManager:BuildInterfaceSection(ThemeTab)
end

-- ════════════════════════════════════════════════════════════
--  DEMARRAGE
-- ════════════════════════════════════════════════════════════
if cfg.Enabled then
    task.wait(1)
    ESP.Enable()
end

if cfg.PlayerList.Enabled then
    PlayerList.Show()
end

print("[NexusESP] Charge ! RightCtrl = toggle UI")
