-- ============================================================
--  NexusESP — Main.lua
--  RightCtrl = Toggle UI
-- ============================================================

local REPO_URL = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

local function include(path)
    local url = REPO_URL .. path
    local ok, r = pcall(function() return loadstring(game:HttpGet(url, true))() end)
    if not ok then warn("[NexusESP] ERREUR: "..path.."\n"..tostring(r)); return nil end
    return r
end

-- ── Chargements ──────────────────────────────────────────────
print("[NexusESP] Chargement...")
local Library          = include("linoria.lua")
local SaveManager      = include("Addons/SaveManager.lua")
local InterfaceManager = include("Addons/InterfaceManager.lua")

local Config     = include("Modules/Config.lua")
local Utils      = include("Modules/Utils.lua")
local Box        = include("Modules/Box.lua")
local CornerBox  = include("Modules/CornerBox.lua")
local Skeleton   = include("Modules/Skeleton.lua")
local Tracers    = include("Modules/Tracers.lua")
local Health     = include("Modules/Health.lua")
local NameMod    = include("Modules/Name.lua")
local Distance   = include("Modules/Distance.lua")
local ESP        = include("Modules/ESP.lua")
local PlayerList = include("Modules/PlayerList.lua")
local FOV        = include("Modules/FOV.lua")
local Radar      = include("Modules/Radar.lua")

local cfg = Config:Init()

ESP.Init({
    Utils=Utils, Config=Config, Box=Box, CornerBox=CornerBox,
    Skeleton=Skeleton, Tracers=Tracers, Health=Health,
    Name=NameMod, Distance=Distance,
})

FOV.SetDependencies(Utils, Config)
Radar.SetDependencies(Utils, Config)
PlayerList.SetDependencies(Utils, Config, ESP)

local function save() Config:Save() end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "NexusESP", Center=true, AutoShow=true, TabPadding=8, MenuFadeTime=0.2,
})

local Tabs = {
    Visuals    = Window:AddTab("Visuals"),
    PlayerList = Window:AddTab("Player List"),
    Settings   = Window:AddTab("Settings"),
}

-- ════════════════════════════════════════════════════════════
--  ONGLET VISUALS (contient ESP + tout le visuel)
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.Visuals:AddLeftGroupbox("ESP & Box")
    local Right = Tabs.Visuals:AddRightGroupbox("Skeleton & Tracers")

    -- ── Master toggle ESP ────────────────────────────────────
    Left:AddToggle("ESPEnabled", {
        Text="Activer ESP", Default=cfg.Enabled,
        Tooltip="Active/desactive tout le systeme de visualisation",
        Callback=function(v) if v then ESP.Enable() else ESP.Disable() end; save() end,
    })

    Left:AddToggle("TeamCheck", {
        Text="Team Check", Default=cfg.TeamCheck,
        Tooltip="Masque les joueurs de ta propre equipe",
        Callback=function(v) cfg.TeamCheck=v; save() end,
    })

    Left:AddToggle("VisibilityCheck", {
        Text="Visibility Check", Default=cfg.VisibilityCheck,
        Tooltip="Attenue les joueurs non visibles (raycast)",
        Callback=function(v) cfg.VisibilityCheck=v; save() end,
    })

    Left:AddToggle("PerformanceMode", {
        Text="Mode Performance", Default=cfg.PerformanceMode,
        Tooltip="Reduit la frequence de certains calculs (moins de lag)",
        Callback=function(v) cfg.PerformanceMode=v; save() end,
    })

    Left:AddSlider("MaxDist", {
        Text="Distance Max", Default=cfg.Distance.MaxDist,
        Min=50, Max=2000, Rounding=0,
        Tooltip="Distance max d'affichage en studs",
        Callback=function(v) cfg.Distance.MaxDist=v; save() end,
    })

    Left:AddDivider()

    -- ── Box pleine ───────────────────────────────────────────
    Left:AddToggle("BoxEnabled", {
        Text="Box (rectangle)", Default=cfg.Box.Enabled,
        Tooltip="Rectangle 2D autour du joueur",
        Callback=function(v) cfg.Box.Enabled=v; save() end,
    }):AddColorPicker("BoxColor", {
        Title="Couleur Box", Default=Config.ToColor3(cfg.Box.Color),
        Callback=function(v) cfg.Box.Color=Config.FromColor3(v); save() end,
    })

    Left:AddSlider("BoxThickness", {
        Text="Epaisseur Box", Default=cfg.Box.Thickness,
        Min=1, Max=6, Rounding=0,
        Callback=function(v) cfg.Box.Thickness=v; save() end,
    })

    Left:AddToggle("BoxFilled", {
        Text="Box remplie", Default=cfg.Box.Filled,
        Callback=function(v) cfg.Box.Filled=v; save() end,
    }):AddColorPicker("BoxFillColor", {
        Title="Couleur fill", Default=Config.ToColor3(cfg.Box.FillColor),
        Callback=function(v) cfg.Box.FillColor=Config.FromColor3(v); save() end,
    })

    Left:AddSlider("BoxFillTrans", {
        Text="Opacite fill", Default=math.floor((1-cfg.Box.FillTrans)*100),
        Min=0, Max=100, Rounding=0,
        Callback=function(v) cfg.Box.FillTrans=1-(v/100); save() end,
    })

    Left:AddDivider()

    -- ── Corner Box ───────────────────────────────────────────
    Left:AddToggle("CornerBoxEnabled", {
        Text="Corner Box (coins en L)", Default=cfg.CornerBox.Enabled,
        Tooltip="Style coins uniquement, plus discret que la box pleine",
        Callback=function(v) cfg.CornerBox.Enabled=v; save() end,
    }):AddColorPicker("CornerBoxColor", {
        Title="Couleur Corner", Default=Config.ToColor3(cfg.CornerBox.Color),
        Callback=function(v) cfg.CornerBox.Color=Config.FromColor3(v); save() end,
    })

    Left:AddSlider("CornerBoxThick", {
        Text="Epaisseur Corner", Default=cfg.CornerBox.Thickness,
        Min=1, Max=5, Rounding=0,
        Callback=function(v) cfg.CornerBox.Thickness=v; save() end,
    })

    Left:AddDivider()

    -- ── Health ───────────────────────────────────────────────
    Left:AddToggle("HealthEnabled", {
        Text="Barre de sante", Default=cfg.Health.Enabled,
        Tooltip="Barre verte->rouge selon la sante du joueur",
        Callback=function(v) cfg.Health.Enabled=v; save() end,
    })

    Left:AddDropdown("HealthPosition", {
        Text="Position barre", Values={"Left","Right","Top","Bottom"}, Default=cfg.Health.Position,
        Callback=function(v) cfg.Health.Position=v; save() end,
    })

    Left:AddSlider("HealthWidth", {
        Text="Largeur (px)", Default=cfg.Health.Width, Min=2, Max=10, Rounding=0,
        Callback=function(v) cfg.Health.Width=v; save() end,
    })

    Left:AddToggle("HealthText", {
        Text="Valeur HP affichee", Default=cfg.Health.ShowText,
        Callback=function(v) cfg.Health.ShowText=v; save() end,
    })

    -- ── Skeleton ─────────────────────────────────────────────
    Right:AddToggle("SkeletonEnabled", {
        Text="Skeleton", Default=cfg.Skeleton.Enabled,
        Tooltip="Dessine les os (R6 et R15 supportes)",
        Callback=function(v) cfg.Skeleton.Enabled=v; save() end,
    }):AddColorPicker("SkeletonColor", {
        Title="Couleur Skeleton", Default=Config.ToColor3(cfg.Skeleton.Color),
        Callback=function(v) cfg.Skeleton.Color=Config.FromColor3(v); save() end,
    })

    Right:AddSlider("SkeletonThick", {
        Text="Epaisseur Skeleton", Default=cfg.Skeleton.Thickness,
        Min=1, Max=5, Rounding=0,
        Callback=function(v) cfg.Skeleton.Thickness=v; save() end,
    })

    Right:AddDivider()

    -- ── Tracers ──────────────────────────────────────────────
    Right:AddToggle("TracerEnabled", {
        Text="Tracers", Default=cfg.Tracers.Enabled,
        Tooltip="Ligne depuis ton ecran vers chaque joueur",
        Callback=function(v) cfg.Tracers.Enabled=v; save() end,
    }):AddColorPicker("TracerColor", {
        Title="Couleur Tracer", Default=Config.ToColor3(cfg.Tracers.Color),
        Callback=function(v) cfg.Tracers.Color=Config.FromColor3(v); save() end,
    })

    Right:AddDropdown("TracerPos", {
        Text="Origine Tracer", Values={"Bottom","Center","Top"}, Default=cfg.Tracers.Position,
        Callback=function(v) cfg.Tracers.Position=v; save() end,
    })

    Right:AddSlider("TracerThick", {
        Text="Epaisseur Tracer", Default=cfg.Tracers.Thickness,
        Min=1, Max=5, Rounding=0,
        Callback=function(v) cfg.Tracers.Thickness=v; save() end,
    })

    Right:AddDivider()

    -- ── Name Tag ─────────────────────────────────────────────
    Right:AddToggle("NameEnabled", {
        Text="Nom du joueur", Default=cfg.Name.Enabled,
        Callback=function(v) cfg.Name.Enabled=v; save() end,
    }):AddColorPicker("NameColor", {
        Title="Couleur Nom", Default=Config.ToColor3(cfg.Name.Color),
        Callback=function(v) cfg.Name.Color=Config.FromColor3(v); save() end,
    })

    Right:AddSlider("NameSize", {
        Text="Taille police", Default=cfg.Name.Size, Min=8, Max=22, Rounding=0,
        Callback=function(v) cfg.Name.Size=v; save() end,
    })

    -- ── Distance ─────────────────────────────────────────────
    Right:AddToggle("DistanceEnabled", {
        Text="Distance", Default=cfg.Distance.Enabled,
        Callback=function(v) cfg.Distance.Enabled=v; save() end,
    }):AddColorPicker("DistanceColor", {
        Title="Couleur Distance", Default=Config.ToColor3(cfg.Distance.Color),
        Callback=function(v) cfg.Distance.Color=Config.FromColor3(v); save() end,
    })

    Right:AddDivider()

    -- ── FOV Circle ───────────────────────────────────────────
    Right:AddToggle("FOVEnabled", {
        Text="Cercle FOV", Default=cfg.FOV.Enabled,
        Tooltip="Cercle autour de ton viseur (champ de vision aimbot)",
        Callback=function(v)
            cfg.FOV.Enabled=v; save()
            if v then FOV.Show(cfg.FOV) else FOV.Hide() end
        end,
    }):AddColorPicker("FOVColor", {
        Title="Couleur FOV", Default=Config.ToColor3(cfg.FOV.Color),
        Callback=function(v) cfg.FOV.Color=Config.FromColor3(v); save() end,
    })

    Right:AddSlider("FOVRadius", {
        Text="Rayon FOV", Default=cfg.FOV.Radius, Min=10, Max=500, Rounding=0,
        Callback=function(v) cfg.FOV.Radius=v; FOV.UpdateRadius(v); save() end,
    })

    Right:AddDivider()

    -- ── Radar ────────────────────────────────────────────────
    Right:AddToggle("RadarEnabled", {
        Text="Radar (mini-map)", Default=cfg.Radar.Enabled,
        Tooltip="Mini-map 2D en bas a gauche de l'ecran",
        Callback=function(v)
            cfg.Radar.Enabled=v; save()
            if v then Radar.Show() else Radar.Hide() end
        end,
    })

    Right:AddSlider("RadarRange", {
        Text="Portee Radar (studs)", Default=cfg.Radar.Range, Min=50, Max=1000, Rounding=0,
        Callback=function(v) cfg.Radar.Range=v; save() end,
    })

    Right:AddToggle("RadarNames", {
        Text="Noms sur Radar", Default=cfg.Radar.ShowNames,
        Callback=function(v) cfg.Radar.ShowNames=v; save() end,
    })

    Right:AddDivider()

    -- ── Preview ──────────────────────────────────────────────
    Right:AddButton({ Text="Mode Preview ON",  Func=function() ESP.ShowPreview()  end })
    Right:AddButton({ Text="Mode Preview OFF", Func=function() ESP.RemovePreview() end })
end

-- ════════════════════════════════════════════════════════════
--  ONGLET PLAYER LIST
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.PlayerList:AddLeftGroupbox("Options")
    local Right = Tabs.PlayerList:AddRightGroupbox("ESP par joueur")

    Left:AddToggle("PLEnabled", {
        Text="Afficher la Player List", Default=cfg.PlayerList.Enabled,
        Tooltip="Fenetre moderne draggable avec infos de chaque joueur",
        Callback=function(v)
            cfg.PlayerList.Enabled=v; save()
            if v then PlayerList.Show() else PlayerList.Hide() end
        end,
    })

    Left:AddToggle("PLShowDist",    { Text="Afficher distance",   Default=cfg.PlayerList.ShowDistance, Callback=function(v) cfg.PlayerList.ShowDistance=v; save() end })
    Left:AddToggle("PLShowHealth",  { Text="Afficher sante",      Default=cfg.PlayerList.ShowHealth,   Callback=function(v) cfg.PlayerList.ShowHealth=v;   save() end })
    Left:AddToggle("PLShowTeam",    { Text="Afficher equipe",     Default=cfg.PlayerList.ShowTeam,     Callback=function(v) cfg.PlayerList.ShowTeam=v;     save() end })
    Left:AddToggle("PLShowVisible", { Text="Indicateur visibilite",Default=cfg.PlayerList.ShowVisible, Callback=function(v) cfg.PlayerList.ShowVisible=v;  save() end })

    Left:AddDivider()
    Left:AddLabel("La fenetre Player List est")
    Left:AddLabel("draggable depuis son header.")
    Left:AddLabel("Filtres: Tous / Ennemis / Allies")
    Left:AddLabel("Bouton Spectate par joueur.")

    Right:AddDropdown("ESPTogglePlayer", {
        Text="Selectionner joueur", SpecialType="Player", Values={},
        Callback=function(_) end,
    })

    Right:AddButton({ Text="Toggle ESP ce joueur",
        Func=function()
            local opt = (getgenv().Options or {}).ESPTogglePlayer
            if opt and opt.Value then
                local p = game:GetService("Players"):FindFirstChild(opt.Value)
                if p then PlayerList.TogglePlayerESP(p) end
            end
        end,
    })

    Right:AddButton({ Text="Spectate joueur",
        Func=function()
            local opt = (getgenv().Options or {}).ESPTogglePlayer
            if opt and opt.Value then
                local p = game:GetService("Players"):FindFirstChild(opt.Value)
                if p then PlayerList.StartSpectate(p) end
            end
        end,
    })

    Right:AddButton({ Text="Arreter spectate", Func=function() PlayerList.StopSpectate() end })
end

-- ════════════════════════════════════════════════════════════
--  ONGLET SETTINGS
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.Settings:AddLeftGroupbox("Configuration")
    local Right = Tabs.Settings:AddRightGroupbox("Debug & Systeme")

    Left:AddButton({ Text="Sauvegarder config", Func=function()
        Config:Save(); Library:Notify("Config sauvegardee !", 3)
    end})
    Left:AddButton({ Text="Charger config", Func=function()
        Config:Load(); Library:Notify("Config chargee !", 3)
    end})
    Left:AddButton({ Text="Reset config", Func=function()
        Config:Reset(); Library:Notify("Reset effectue", 3)
    end})

    Left:AddDivider()

    -- Profils SaveManager
    if SaveManager then
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("NexusESP")
        SaveManager:BuildConfigSection(Left)
    end

    -- Theme
    if InterfaceManager then
        InterfaceManager:SetLibrary(Library)
        InterfaceManager:SetFolder("NexusESP")
        InterfaceManager:BuildInterfaceSection(Left)
    end

    -- Debug
    Right:AddToggle("DebugMode", {
        Text="Mode Debug", Default=cfg.DebugMode,
        Callback=function(v) cfg.DebugMode=v; save() end,
    })

    Right:AddButton({ Text="Logs (10 derniers)", Func=function()
        local lg = Utils.GetLogs()
        local s  = math.max(1, #lg-9)
        print("-- NexusESP Logs --")
        for i=s,#lg do print(lg[i]) end
    end})

    Right:AddButton({ Text="Vider logs", Func=function()
        Utils.ClearLogs(); Library:Notify("Logs vides", 2)
    end})

    Right:AddButton({ Text="Profiling (ms)", Func=function()
        local pd = ESP.ProfileData
        local m  = string.format("Box:%.3f Skel:%.3f Trac:%.3f HP:%.3f Name:%.3f Dist:%.3f",
            pd.Box, pd.Skeleton, pd.Tracers, pd.Health, pd.Name, pd.Distance)
        print("-- Profiling --\n"..m)
        Library:Notify(m, 6)
    end})

    Right:AddButton({ Text="Cleanup drawings", Func=function()
        ESP.Cleanup(); PlayerList.Cleanup(); FOV.Hide(); Radar.Hide()
        Library:Notify("Cleanup effectue", 3)
    end})

    Right:AddDivider()

    -- ── SHUTDOWN ─────────────────────────────────────────────
    Right:AddButton({ Text="SHUTDOWN (quitter script)", Func=function()
        Library:Notify("Arret de NexusESP...", 2)
        task.wait(0.5)
        -- Cleanup complet
        ESP.Cleanup()
        PlayerList.Cleanup()
        FOV.Hide()
        Radar.Hide()
        -- Fermer l'UI Linoria
        pcall(function()
            for _, sig in ipairs(Library.Signals) do
                sig:Disconnect()
            end
            Library.ScreenGui:Destroy()
        end)
        print("[NexusESP] Script arrete.")
    end})
end

-- ════════════════════════════════════════════════════════════
--  DEMARRAGE AUTOMATIQUE
-- ════════════════════════════════════════════════════════════
if cfg.Enabled then
    task.wait(1)
    ESP.Enable()
end
if cfg.PlayerList.Enabled then PlayerList.Show() end
if cfg.FOV.Enabled         then FOV.Show(cfg.FOV) end
if cfg.Radar.Enabled       then Radar.Show() end

print("[NexusESP] Charge ! RightCtrl = toggle UI")
