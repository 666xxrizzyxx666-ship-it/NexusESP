-- ============================================================
--  NexusESP — Main.lua  |  RightCtrl = toggle UI
-- ============================================================

-- Version du script : MAJOR.MINOR.PATCH
-- Incrementer a chaque modification :
--   PATCH  (+0.0.1) = correction de bug
--   MINOR  (+0.1.0) = nouvelle feature
--   MAJOR  (+1.0.0) = refonte complete
local VERSION = "1.3.0"

local REPO_URL = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

local function include(path)
    local url = REPO_URL..path
    local ok, r = pcall(function() return loadstring(game:HttpGet(url,true))() end)
    if not ok then warn("[NexusESP] ERREUR: "..path.."\n"..tostring(r)); return nil end
    return r
end

print("[NexusESP] Chargement...")
local Library          = include("linoria.lua")
local SaveManager      = include("Addons/SaveManager.lua")
local Config           = include("Modules/Config.lua")
local Utils            = include("Modules/Utils.lua")
local Box              = include("Modules/Box.lua")
local CornerBox        = include("Modules/CornerBox.lua")
local Skeleton         = include("Modules/Skeleton.lua")
local Tracers          = include("Modules/Tracers.lua")
local Health           = include("Modules/Health.lua")
local NameMod          = include("Modules/Name.lua")
local Distance         = include("Modules/Distance.lua")
local ESP              = include("Modules/ESP.lua")
local PlayerList       = include("Modules/PlayerList.lua")
local FOV              = include("Modules/FOV.lua")
local Radar            = include("Modules/Radar.lua")

local cfg = Config:Init()

ESP.Init({
    Utils=Utils, Config=Config, Box=Box, CornerBox=CornerBox,
    Skeleton=Skeleton, Tracers=Tracers, Health=Health,
    Name=NameMod, Distance=Distance,
})

if FOV       then FOV.SetDependencies(Utils, Config)          end
if Radar     then Radar.SetDependencies(Utils, Config)        end
if PlayerList then PlayerList.SetDependencies(Utils, Config, ESP) end
if SaveManager then SaveManager:SetConfig(Config)             end

local function save() Config:Save() end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title="NexusESP  v"..VERSION, Center=true, AutoShow=true, TabPadding=8, MenuFadeTime=0.2,
})

local Tabs = {
    Visuals    = Window:AddTab("Visuals"),
    PlayerList = Window:AddTab("Player List"),
    Settings   = Window:AddTab("Settings"),
}

-- ════════════════════════════════════════════════════════════
--  VISUALS
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.Visuals:AddLeftGroupbox("ESP & Boxes")
    local Right = Tabs.Visuals:AddRightGroupbox("Labels & Extras")

    -- Master ESP
    Left:AddToggle("ESPEnabled", {
        Text="Activer ESP", Default=cfg.Enabled,
        Callback=function(v) if v then ESP.Enable() else ESP.Disable() end; save() end,
    })
    Left:AddToggle("TeamCheck",       {Text="Team Check",          Default=cfg.TeamCheck,       Callback=function(v) cfg.TeamCheck=v; save() end})
    Left:AddToggle("VisibilityCheck", {Text="Visibility Check",    Default=cfg.VisibilityCheck, Callback=function(v) cfg.VisibilityCheck=v; save() end})
    Left:AddToggle("PerformanceMode", {Text="Mode Performance",    Default=cfg.PerformanceMode, Callback=function(v) cfg.PerformanceMode=v; save() end})
    Left:AddSlider("MaxDist",         {Text="Distance Max (studs)",Default=cfg.Distance.MaxDist,
        Min=50,Max=2000,Rounding=0,
        Callback=function(v) cfg.Distance.MaxDist=v; save() end})

    Left:AddDivider()

    -- Box
    Left:AddToggle("BoxEnabled",{Text="Box (rectangle)",Default=cfg.Box.Enabled,
        Callback=function(v) cfg.Box.Enabled=v; save() end,
    }):AddColorPicker("BoxColor",{Title="Couleur Box",Default=Config.ToColor3(cfg.Box.Color),
        Callback=function(v) cfg.Box.Color=Config.FromColor3(v); save() end})

    Left:AddSlider("BoxThickness",{Text="Epaisseur Box",Default=cfg.Box.Thickness,Min=1,Max=8,Rounding=0,
        Callback=function(v) cfg.Box.Thickness=v; save() end})

    Left:AddToggle("BoxFilled",{Text="Box remplie",Default=cfg.Box.Filled,
        Callback=function(v) cfg.Box.Filled=v; save() end,
    }):AddColorPicker("BoxFillColor",{Title="Couleur fill",Default=Config.ToColor3(cfg.Box.FillColor),
        Callback=function(v) cfg.Box.FillColor=Config.FromColor3(v); save() end})

    Left:AddSlider("BoxFillTrans",{Text="Opacite fill",Default=math.floor((1-cfg.Box.FillTrans)*100),Min=0,Max=100,Rounding=0,
        Callback=function(v) cfg.Box.FillTrans=1-(v/100); save() end})

    Left:AddDivider()

    -- Corner Box
    Left:AddToggle("CornerBoxEnabled",{Text="Corner Box (coins L)",Default=cfg.CornerBox.Enabled,
        Callback=function(v) cfg.CornerBox.Enabled=v; save() end,
    }):AddColorPicker("CornerBoxColor",{Title="Couleur Corner",Default=Config.ToColor3(cfg.CornerBox.Color),
        Callback=function(v) cfg.CornerBox.Color=Config.FromColor3(v); save() end})

    Left:AddSlider("CornerBoxThick",{Text="Epaisseur Corner",Default=cfg.CornerBox.Thickness,Min=1,Max=6,Rounding=0,
        Callback=function(v) cfg.CornerBox.Thickness=v; save() end})

    Left:AddDivider()

    -- Health
    Left:AddToggle("HealthEnabled",{Text="Barre de sante",Default=cfg.Health.Enabled,
        Callback=function(v) cfg.Health.Enabled=v; save() end})
    Left:AddDropdown("HealthPos",{Text="Position barre",Values={"Left","Right","Top","Bottom"},Default=cfg.Health.Position,
        Callback=function(v) cfg.Health.Position=v; save() end})
    Left:AddSlider("HealthWidth",{Text="Largeur (px)",Default=cfg.Health.Width,Min=2,Max=12,Rounding=0,
        Callback=function(v) cfg.Health.Width=v; save() end})
    Left:AddToggle("HealthText",{Text="Afficher HP chiffres",Default=cfg.Health.ShowText,
        Callback=function(v) cfg.Health.ShowText=v; save() end})

    -- Skeleton
    Right:AddToggle("SkeletonEnabled",{Text="Skeleton",Default=cfg.Skeleton.Enabled,
        Callback=function(v) cfg.Skeleton.Enabled=v; save() end,
    }):AddColorPicker("SkeletonColor",{Title="Couleur Skeleton",Default=Config.ToColor3(cfg.Skeleton.Color),
        Callback=function(v) cfg.Skeleton.Color=Config.FromColor3(v); save() end})
    Right:AddSlider("SkeletonThick",{Text="Epaisseur Skeleton",Default=cfg.Skeleton.Thickness,Min=1,Max=6,Rounding=0,
        Callback=function(v) cfg.Skeleton.Thickness=v; save() end})

    Right:AddDivider()

    -- Tracers
    Right:AddToggle("TracerEnabled",{Text="Tracers",Default=cfg.Tracers.Enabled,
        Callback=function(v) cfg.Tracers.Enabled=v; save() end,
    }):AddColorPicker("TracerColor",{Title="Couleur Tracer",Default=Config.ToColor3(cfg.Tracers.Color),
        Callback=function(v) cfg.Tracers.Color=Config.FromColor3(v); save() end})
    Right:AddDropdown("TracerPos",{Text="Origine Tracer",Values={"Bottom","Center","Top"},Default=cfg.Tracers.Position,
        Callback=function(v) cfg.Tracers.Position=v; save() end})
    Right:AddSlider("TracerThick",{Text="Epaisseur Tracer",Default=cfg.Tracers.Thickness,Min=1,Max=6,Rounding=0,
        Callback=function(v) cfg.Tracers.Thickness=v; save() end})

    Right:AddDivider()

    -- Name
    Right:AddToggle("NameEnabled",{Text="Nom du joueur",Default=cfg.Name.Enabled,
        Callback=function(v) cfg.Name.Enabled=v; save() end,
    }):AddColorPicker("NameColor",{Title="Couleur Nom",Default=Config.ToColor3(cfg.Name.Color),
        Callback=function(v) cfg.Name.Color=Config.FromColor3(v); save() end})
    Right:AddSlider("NameSize",{Text="Taille police",Default=cfg.Name.Size,Min=8,Max=28,Rounding=0,
        Callback=function(v) cfg.Name.Size=v; save() end})

    -- Distance
    Right:AddToggle("DistanceEnabled",{Text="Distance",Default=cfg.Distance.Enabled,
        Callback=function(v) cfg.Distance.Enabled=v; save() end,
    }):AddColorPicker("DistanceColor",{Title="Couleur Distance",Default=Config.ToColor3(cfg.Distance.Color),
        Callback=function(v) cfg.Distance.Color=Config.FromColor3(v); save() end})

    Right:AddDivider()

    -- FOV
    Right:AddToggle("FOVEnabled",{Text="Cercle FOV",Default=cfg.FOV.Enabled,
        Callback=function(v)
            cfg.FOV.Enabled=v; save()
            if FOV then if v then FOV.Show(cfg.FOV) else FOV.Hide() end end
        end,
    }):AddColorPicker("FOVColor",{Title="Couleur FOV",Default=Config.ToColor3(cfg.FOV.Color),
        Callback=function(v) cfg.FOV.Color=Config.FromColor3(v); save() end})
    Right:AddSlider("FOVRadius",{Text="Rayon FOV",Default=cfg.FOV.Radius,Min=10,Max=600,Rounding=0,
        Callback=function(v) cfg.FOV.Radius=v; if FOV then FOV.UpdateRadius(v) end; save() end})

    Right:AddDivider()

    -- Radar
    Right:AddToggle("RadarEnabled",{Text="Radar mini-map",Default=cfg.Radar.Enabled,
        Callback=function(v)
            cfg.Radar.Enabled=v; save()
            if Radar then if v then Radar.Show() else Radar.Hide() end end
        end})
    Right:AddSlider("RadarRange",{Text="Portee Radar",Default=cfg.Radar.Range,Min=50,Max=800,Rounding=0,
        Callback=function(v) cfg.Radar.Range=v; save() end})
    Right:AddToggle("RadarNames",{Text="Noms sur Radar",Default=cfg.Radar.ShowNames,
        Callback=function(v) cfg.Radar.ShowNames=v; save() end})

    Right:AddDivider()

    -- Preview
    Right:AddButton({Text="Mode Preview ON",  Func=function() ESP.ShowPreview()  end})
    Right:AddButton({Text="Mode Preview OFF", Func=function() ESP.RemovePreview() end})
end

-- ════════════════════════════════════════════════════════════
--  PLAYER LIST
-- ════════════════════════════════════════════════════════════
do
    local Left = Tabs.PlayerList:AddLeftGroupbox("Options Player List")

    Left:AddToggle("PLEnabled",{Text="Afficher Player List",Default=cfg.PlayerList.Enabled,
        Callback=function(v)
            cfg.PlayerList.Enabled=v; save()
            if PlayerList then if v then PlayerList.Show() else PlayerList.Hide() end end
        end})

    Left:AddDivider()
    Left:AddLabel("La fenetre est draggable depuis le header.")
    Left:AddLabel("Redimensionnable via le coin bas-droit.")
    Left:AddLabel("Filtres: Tous / Ennemis / Allies")
    Left:AddLabel("Fleche ▼ = infos detaillees par joueur")
    Left:AddLabel("Onglet Spectate = apparait lors du spec.")
    Left:AddDivider()

    Left:AddButton({Text="Spectate par nom", Func=function()
        local opt=(getgenv().Options or {}).SpecNameInput
        if opt and opt.Value and opt.Value~="" then
            if PlayerList then PlayerList.StartSpectateByName(opt.Value) end
        end
    end})
    Left:AddInput("SpecNameInput",{Text="Nom du joueur a spec",Default="",Placeholder="Nom exact...",Callback=function(_)end})
    Left:AddButton({Text="Arreter spectate", Func=function()
        if PlayerList then PlayerList.StopSpectate() end
    end})
end

-- ════════════════════════════════════════════════════════════
--  SETTINGS
-- ════════════════════════════════════════════════════════════
do
    local Left  = Tabs.Settings:AddLeftGroupbox("Profils de configuration")
    local Right = Tabs.Settings:AddRightGroupbox("Personnalisation UI")

    -- SaveManager
    if SaveManager then
        SaveManager:SetLibrary(Library)
        SaveManager:BuildConfigSection(Left, Config)
    end

    Left:AddDivider()
    Left:AddButton({Text="Reset config", Func=function()
        Config:Reset(); Library:Notify("Config remise a zero", 3)
    end})
    Left:AddButton({Text="Logs (10 derniers)", Func=function()
        local lg=Utils.GetLogs(); local s=math.max(1,#lg-9)
        print("-- NexusESP Logs --")
        for i=s,#lg do print(lg[i]) end
    end})
    Left:AddButton({Text="Profiling", Func=function()
        local pd=ESP.ProfileData
        local m=string.format("Box:%.3f Skel:%.3f Trac:%.3f HP:%.3f Name:%.3f Dist:%.3f",
            pd.Box,pd.Skeleton,pd.Tracers,pd.Health,pd.Name,pd.Distance)
        print(m); Library:Notify(m,6)
    end})

    -- ── UI Personalisation ───────────────────────────────────
    Right:AddLabel("Couleurs de l'interface NexusESP")
    Right:AddLabel("(Player List, Radar)")

    Right:AddToggle("UIAccentToggle",{Text="Couleur accent",Default=false,
        Callback=function(_) end,
    }):AddColorPicker("UIAccent",{Title="Couleur Accent",
        Default=Config.ToColor3(cfg.UI and cfg.UI.AccentColor),
        Callback=function(v)
            if not cfg.UI then cfg.UI={} end
            cfg.UI.AccentColor=Config.FromColor3(v); save()
            Library:Notify("Relancez pour appliquer", 2)
        end})

    Right:AddToggle("UIBgToggle",{Text="Fond de fenetre",Default=false,
        Callback=function(_) end,
    }):AddColorPicker("UIBackground",{Title="Couleur Fond",
        Default=Config.ToColor3(cfg.UI and cfg.UI.BackgroundColor),
        Callback=function(v)
            if not cfg.UI then cfg.UI={} end
            cfg.UI.BackgroundColor=Config.FromColor3(v); save()
        end})

    Right:AddToggle("UIRowToggle",{Text="Fond des rangees",Default=false,
        Callback=function(_) end,
    }):AddColorPicker("UIRow",{Title="Couleur Rangee",
        Default=Config.ToColor3(cfg.UI and cfg.UI.SecondaryColor),
        Callback=function(v)
            if not cfg.UI then cfg.UI={} end
            cfg.UI.SecondaryColor=Config.FromColor3(v); save()
        end})

    Right:AddToggle("UITextToggle",{Text="Couleur du texte",Default=false,
        Callback=function(_) end,
    }):AddColorPicker("UIText",{Title="Couleur Texte",
        Default=Config.ToColor3(cfg.UI and cfg.UI.TextColor),
        Callback=function(v)
            if not cfg.UI then cfg.UI={} end
            cfg.UI.TextColor=Config.FromColor3(v); save()
        end})

    Right:AddDivider()

    -- SHUTDOWN
    Right:AddButton({Text="SHUTDOWN — Quitter script", Func=function()
        Library:Notify("Arret de NexusESP...", 2)
        task.wait(0.5)
        ESP.Cleanup()
        if PlayerList then PlayerList.Cleanup() end
        if FOV        then FOV.Hide()           end
        if Radar      then Radar.Hide()         end
        pcall(function()
            for _,s in ipairs(Library.Signals or {}) do pcall(function() s:Disconnect() end) end
            Library.ScreenGui:Destroy()
        end)
        print("[NexusESP] Script arrete.")
    end})
end

-- ════════════════════════════════════════════════════════════
--  DEMARRAGE AUTO
-- ════════════════════════════════════════════════════════════
if cfg.Enabled          then task.wait(1); ESP.Enable()    end
if cfg.PlayerList.Enabled and PlayerList then PlayerList.Show() end
if cfg.FOV.Enabled      and FOV          then FOV.Show(cfg.FOV)  end
if cfg.Radar.Enabled    and Radar        then Radar.Show()       end

print("[NexusESP] v"..VERSION.." charge! RightCtrl = toggle UI")
