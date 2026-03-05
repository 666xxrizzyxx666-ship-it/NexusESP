-- ╔══════════════════════════════════════════════════════╗
--   NexusESP  v2.1.0  —  Main.lua
-- ╚══════════════════════════════════════════════════════╝

local VERSION = "2.1.0"
local REPO    = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

local function load(path)
    local ok, r = pcall(function()
        return loadstring(game:HttpGet(REPO..path, true))()
    end)
    if not ok then warn("[NexusESP] FAILED: "..path.."\n"..tostring(r)) end
    return ok and r or nil
end

print("[NexusESP] v"..VERSION.." loading...")

local Library     = load("linoria.lua")
local SaveManager = load("Addons/SaveManager.lua")
local Config      = load("Modules/Config.lua")
local Utils       = load("Modules/Utils.lua")
local Box         = load("Modules/Box.lua")
local CornerBox   = load("Modules/CornerBox.lua")
local Skeleton    = load("Modules/Skeleton.lua")
local Tracers     = load("Modules/Tracers.lua")
local Health      = load("Modules/Health.lua")
local NameTag     = load("Modules/Name.lua")
local Distance    = load("Modules/Distance.lua")
local ESP         = load("Modules/ESP.lua")
local PlayerList  = load("Modules/PlayerList.lua")
local FOV         = load("Modules/FOV.lua")
local Radar       = load("Modules/Radar.lua")
local Preview     = load("Modules/Preview.lua")

if not Library or not Config or not Utils or not ESP then
    warn("[NexusESP] Critical load failure"); return
end

local cfg = Config:Init()

ESP.Init({
    Utils=Utils, Config=Config,
    Box=Box, CornerBox=CornerBox, Skeleton=Skeleton,
    Tracers=Tracers, Health=Health, Name=NameTag, Distance=Distance,
})

if FOV        then FOV.SetDependencies(Utils, Config)              end
if Radar      then Radar.SetDependencies(Utils, Config)            end
if PlayerList then PlayerList.SetDependencies(Utils, Config, ESP)  end
if Preview    then Preview.SetDependencies(Utils, Config, ESP)     end
if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:SetConfig(Config)
end

local function save() Config:Save() end

-- UI color instant apply: just rebuilds PL if open (no Radar restart)
local function applyUI()
    if PlayerList and cfg.PlayerList.Enabled then
        PlayerList.Hide(); PlayerList.Show()
    end
end

-- ── Window ───────────────────────────────────────────────────
local Win = Library:CreateWindow({
    Title        = "NexusESP  v"..VERSION,
    Center       = true,
    AutoShow     = true,
    TabPadding   = 8,
    MenuFadeTime = 0.2,
})

-- ╔══════════════════════════════════════════════════════╗
--   TAB 1 — VISUALS
-- ╚══════════════════════════════════════════════════════╝
local VT = Win:AddTab("Visuals")
local VL = VT:AddLeftGroupbox("ESP")
local VR = VT:AddRightGroupbox("Labels & Extras")

-- Master
VL:AddToggle("ESPEnabled", { Text="Enable ESP", Default=cfg.Enabled,
    Callback=function(v) if v then ESP.Enable() else ESP.Disable() end; save() end })
VL:AddToggle("TeamCheck",  { Text="Team check", Default=cfg.TeamCheck,
    Callback=function(v) cfg.TeamCheck=v; save() end })
VL:AddToggle("PerfMode",   { Text="Performance mode (update every 3 frames)", Default=cfg.PerformanceMode,
    Callback=function(v) cfg.PerformanceMode=v; save() end })
VL:AddSlider("MaxDist", { Text="Max distance (studs)", Default=cfg.Distance.MaxDist,
    Min=50, Max=2000, Rounding=0,
    Callback=function(v) cfg.Distance.MaxDist=v; save() end })

VL:AddDivider()

-- Box (4 Lines = reliable thickness)
VL:AddToggle("BoxOn", { Text="Box", Default=cfg.Box.Enabled,
    Callback=function(v) cfg.Box.Enabled=v; save() end,
}):AddColorPicker("BoxCol", { Title="Box color", Default=Config.ToC3(cfg.Box.Color),
    Callback=function(v) cfg.Box.Color=Config.FromC3(v); save() end })
VL:AddSlider("BoxThick", { Text="Box thickness", Default=cfg.Box.Thickness, Min=1, Max=10, Rounding=0,
    Callback=function(v) cfg.Box.Thickness=v; save() end })
VL:AddToggle("BoxFill", { Text="Box filled", Default=cfg.Box.Filled,
    Callback=function(v) cfg.Box.Filled=v; save() end,
}):AddColorPicker("BoxFillCol", { Title="Fill color", Default=Config.ToC3(cfg.Box.FillColor),
    Callback=function(v) cfg.Box.FillColor=Config.FromC3(v); save() end })
VL:AddSlider("BoxFillOpacity", { Text="Fill opacity %",
    Default=math.floor((1-cfg.Box.FillTrans)*100), Min=0, Max=100, Rounding=0,
    Callback=function(v) cfg.Box.FillTrans=1-(v/100); save() end })

VL:AddDivider()

-- Corner Box
VL:AddToggle("CBoxOn", { Text="Corner box", Default=cfg.CornerBox.Enabled,
    Callback=function(v) cfg.CornerBox.Enabled=v; save() end,
}):AddColorPicker("CBoxCol", { Title="Corner color", Default=Config.ToC3(cfg.CornerBox.Color),
    Callback=function(v) cfg.CornerBox.Color=Config.FromC3(v); save() end })
VL:AddSlider("CBoxThick", { Text="Corner thickness", Default=cfg.CornerBox.Thickness, Min=1, Max=10, Rounding=0,
    Callback=function(v) cfg.CornerBox.Thickness=v; save() end })

VL:AddDivider()

-- Health bar (independent from HP text)
VL:AddToggle("HpBar",  { Text="Health bar",              Default=cfg.Health.Enabled,
    Callback=function(v) cfg.Health.Enabled=v; save() end })
VL:AddToggle("HpText", { Text="HP numbers (independent)", Default=cfg.Health.ShowText,
    Callback=function(v) cfg.Health.ShowText=v; save() end })
VL:AddDropdown("HpPos", { Text="Bar position", Values={"Left","Right","Top","Bottom"}, Default=cfg.Health.Position,
    Callback=function(v) cfg.Health.Position=v; save() end })
VL:AddSlider("HpWidth", { Text="Bar width px", Default=cfg.Health.Width, Min=2, Max=14, Rounding=0,
    Callback=function(v) cfg.Health.Width=v; save() end })

-- Skeleton
VR:AddToggle("SkelOn", { Text="Skeleton", Default=cfg.Skeleton.Enabled,
    Callback=function(v) cfg.Skeleton.Enabled=v; save() end,
}):AddColorPicker("SkelCol", { Title="Skeleton color", Default=Config.ToC3(cfg.Skeleton.Color),
    Callback=function(v) cfg.Skeleton.Color=Config.FromC3(v); save() end })
VR:AddSlider("SkelThick", { Text="Skeleton thickness", Default=cfg.Skeleton.Thickness, Min=1, Max=10, Rounding=0,
    Callback=function(v) cfg.Skeleton.Thickness=v; save() end })

VR:AddDivider()

-- Tracers
VR:AddToggle("TracOn", { Text="Tracers", Default=cfg.Tracers.Enabled,
    Callback=function(v) cfg.Tracers.Enabled=v; save() end,
}):AddColorPicker("TracCol", { Title="Tracer color", Default=Config.ToC3(cfg.Tracers.Color),
    Callback=function(v) cfg.Tracers.Color=Config.FromC3(v); save() end })
VR:AddDropdown("TracOrigin", { Text="Origin", Values={"Bottom","Center","Top"}, Default=cfg.Tracers.Position,
    Callback=function(v) cfg.Tracers.Position=v; save() end })
VR:AddSlider("TracThick", { Text="Tracer thickness", Default=cfg.Tracers.Thickness, Min=1, Max=10, Rounding=0,
    Callback=function(v) cfg.Tracers.Thickness=v; save() end })

VR:AddDivider()

-- Name tag
VR:AddToggle("NameOn", { Text="Name tag", Default=cfg.Name.Enabled,
    Callback=function(v) cfg.Name.Enabled=v; save() end,
}):AddColorPicker("NameCol", { Title="Name color", Default=Config.ToC3(cfg.Name.Color),
    Callback=function(v) cfg.Name.Color=Config.FromC3(v); save() end })
VR:AddSlider("NameSize", { Text="Name font size (px)", Default=cfg.Name.Size, Min=6, Max=48, Rounding=0,
    Callback=function(v) cfg.Name.Size=v; save() end })

-- Distance
VR:AddToggle("DistOn", { Text="Distance", Default=cfg.Distance.Enabled,
    Callback=function(v) cfg.Distance.Enabled=v; save() end,
}):AddColorPicker("DistCol", { Title="Distance color", Default=Config.ToC3(cfg.Distance.Color),
    Callback=function(v) cfg.Distance.Color=Config.FromC3(v); save() end })
VR:AddSlider("DistSize", { Text="Distance font size (px)", Default=cfg.Distance.Size or 11,
    Min=6, Max=40, Rounding=0,
    Callback=function(v) cfg.Distance.Size=v; save() end })

VR:AddDivider()

-- FOV circle (Line segments, very smooth)
VR:AddToggle("FovOn", { Text="FOV circle", Default=cfg.FOV.Enabled,
    Callback=function(v)
        cfg.FOV.Enabled=v; save()
        if FOV then if v then FOV.Show(cfg.FOV) else FOV.Hide() end end
    end,
}):AddColorPicker("FovCol", { Title="FOV color", Default=Config.ToC3(cfg.FOV.Color),
    Callback=function(v) cfg.FOV.Color=Config.FromC3(v); save() end })
VR:AddSlider("FovRadius", { Text="FOV radius", Default=cfg.FOV.Radius, Min=10, Max=800, Rounding=0,
    Callback=function(v) cfg.FOV.Radius=v; if FOV then FOV.UpdateRadius(v) end; save() end })

VR:AddDivider()

-- Radar
VR:AddToggle("RadarOn", { Text="Radar (mini-map)", Default=cfg.Radar.Enabled,
    Callback=function(v)
        cfg.Radar.Enabled=v; save()
        if Radar then if v then Radar.Show() else Radar.Hide() end end
    end })
VR:AddSlider("RadarRange", { Text="Radar range (studs)", Default=cfg.Radar.Range,
    Min=50, Max=1000, Rounding=0,
    Callback=function(v) cfg.Radar.Range=v; save() end })
VR:AddToggle("RadarNames", { Text="Names on radar", Default=cfg.Radar.ShowNames,
    Callback=function(v) cfg.Radar.ShowNames=v; save() end })

VR:AddDivider()

-- Preview
VR:AddButton({ Text="👁  Open preview window", Func=function()
    if Preview then Preview.Show() end
end})
VR:AddButton({ Text="✖  Close preview", Func=function()
    if Preview then Preview.Hide() end
end})

-- ╔══════════════════════════════════════════════════════╗
--   TAB 2 — PLAYER LIST
-- ╚══════════════════════════════════════════════════════╝
local PLT = Win:AddTab("Player List")
local PLL = PLT:AddLeftGroupbox("Player List")

PLL:AddToggle("PLOn", { Text="Show player list", Default=cfg.PlayerList.Enabled,
    Callback=function(v)
        cfg.PlayerList.Enabled=v; save()
        if PlayerList then if v then PlayerList.Show() else PlayerList.Hide() end end
    end })
PLL:AddDivider()
PLL:AddLabel("Drag  :  header")
PLL:AddLabel("Resize  :  bottom-right corner")
PLL:AddLabel("▼  :  expanded info per player")
PLL:AddLabel("👁 ON / 🚫 OFF  :  toggle ESP per player")
PLL:AddLabel("🎥 Spec  :  spectate (camera stays free)")
PLL:AddLabel("Spectate tab opens/closes automatically")

-- ╔══════════════════════════════════════════════════════╗
--   TAB 3 — SETTINGS
-- ╚══════════════════════════════════════════════════════╝
local ST = Win:AddTab("Settings")
local SL = ST:AddLeftGroupbox("Profiles")
local SR = ST:AddRightGroupbox("UI Colors")

if SaveManager then SaveManager:BuildSection(SL) end
SL:AddDivider()
SL:AddButton({ Text="Reset to defaults", Func=function()
    Config:Reset(); Library:Notify("Config reset", 3)
end})

-- UI colors — instant apply (only rebuilds PlayerList, does NOT open Radar)
SR:AddLabel("Applies instantly to Player List")
SR:AddDivider()

SR:AddToggle("UIAccentT", { Text="Accent color", Default=false, Callback=function()end }
):AddColorPicker("UIAccent", { Title="Accent",
    Default=Config.ToC3(cfg.UI and cfg.UI.Accent),
    Callback=function(v)
        cfg.UI = cfg.UI or {}; cfg.UI.Accent = Config.FromC3(v); save(); applyUI()
    end})

SR:AddToggle("UIBgT", { Text="Background color", Default=false, Callback=function()end }
):AddColorPicker("UIBg", { Title="Background",
    Default=Config.ToC3(cfg.UI and cfg.UI.Bg),
    Callback=function(v)
        cfg.UI = cfg.UI or {}; cfg.UI.Bg = Config.FromC3(v); save(); applyUI()
    end})

SR:AddToggle("UIRowT", { Text="Row color", Default=false, Callback=function()end }
):AddColorPicker("UIRow", { Title="Row",
    Default=Config.ToC3(cfg.UI and cfg.UI.Row),
    Callback=function(v)
        cfg.UI = cfg.UI or {}; cfg.UI.Row = Config.FromC3(v); save(); applyUI()
    end})

SR:AddToggle("UITextT", { Text="Text color", Default=false, Callback=function()end }
):AddColorPicker("UIText", { Title="Text",
    Default=Config.ToC3(cfg.UI and cfg.UI.Text),
    Callback=function(v)
        cfg.UI = cfg.UI or {}; cfg.UI.Text = Config.FromC3(v); save(); applyUI()
    end})

SR:AddDivider()

SR:AddButton({ Text="⛔  SHUTDOWN", Func=function()
    Library:Notify("Shutting down...", 2); task.wait(0.4)
    ESP.Cleanup()
    if PlayerList then PlayerList.Cleanup() end
    if FOV        then FOV.Hide()           end
    if Radar      then Radar.Hide()         end
    if Preview    then Preview.Hide()       end
    pcall(function()
        for _, s in ipairs(Library.Signals or {}) do pcall(function() s:Disconnect() end) end
        Library.ScreenGui:Destroy()
    end)
    print("[NexusESP] Stopped.")
end})

-- ── Auto-start ───────────────────────────────────────────────
if cfg.Enabled                       then task.wait(1); ESP.Enable()    end
if cfg.PlayerList.Enabled            then
    if PlayerList then PlayerList.Show() end
end
if cfg.FOV.Enabled    and FOV        then FOV.Show(cfg.FOV)  end
if cfg.Radar.Enabled  and Radar      then Radar.Show()       end

print("[NexusESP] v"..VERSION.." ready — RightCtrl = toggle menu")
