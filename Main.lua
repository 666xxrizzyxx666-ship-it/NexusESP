-- ══════════════════════════════════════════════════════════════════
--   Aurora v5.1.1 — Main.lua
--   TEST : Box ESP uniquement — tout le reste désactivé
--   GitHub : 666xxrizzyxx666-ship-it/NexusESP
-- ══════════════════════════════════════════════════════════════════
local VERSION = "5.1.1"
local REPO    = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

-- ── Services ──────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ── Logs silencieux ───────────────────────────────────────────────
local function _p(...) end
local function _w(...) end

-- ── Loader GitHub ─────────────────────────────────────────────────
local function load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(REPO..path, true))()
    end)
    if not ok then _w("load err: "..path.." | "..tostring(result)) end
    return ok and result or nil
end

-- ── Global state ──────────────────────────────────────────────────
getgenv().AuroraESP = {}
local N = getgenv().AuroraESP
N._version = VERSION

-- ══════════════════════════════════════════════════════════════════
-- CHARGEMENT ESP
-- ══════════════════════════════════════════════════════════════════
N.ESP = load("Modules/ESP/ESP.lua")
if N.ESP then
    N.ESP.Init({})
    print("[Aurora] ESP chargé ✓")
else
    warn("[Aurora] ESP FAILED à charger")
end

-- ══════════════════════════════════════════════════════════════════
-- UI FLUENT
-- ══════════════════════════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title       = "Aurora  •  v"..VERSION,
    SubTitle    = "TEST — Box ESP",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(600, 440),
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.Insert,
})

local Tabs = {
    ESP      = Window:AddTab({ Title = "ESP",      Icon = "eye"      }),
    -- Les autres tabs sont désactivés pour le test
    -- Aimbot   = Window:AddTab({ Title = "Aimbot",   Icon = "crosshair" }),
    -- Movement = Window:AddTab({ Title = "Movement", Icon = "zap"       }),
    -- Misc     = Window:AddTab({ Title = "Misc",     Icon = "settings"  }),
}

-- ══════════════════════════════════════════════════════════════════
-- TAB ESP — BOXES UNIQUEMENT
-- ══════════════════════════════════════════════════════════════════
Tabs.ESP:AddSection("Boxes")

Tabs.ESP:AddToggle("ESPEnabled", {
    Title    = "👁 ESP Global",
    Default  = false,
    Callback = function(v)
        if N.ESP then
            if v then N.ESP.Enable() else N.ESP.Disable() end
        end
    end,
})

Tabs.ESP:AddToggle("ESPBox", {
    Title    = "🟩 Box ESP",
    Default  = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Box", v) end
    end,
})

Tabs.ESP:AddDropdown("ESPBoxStyle", {
    Title    = "Style Box",
    Default  = "2D Normal",
    Values   = {"2D Normal", "Corner Box"},
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("BoxStyle", v) end
    end,
})

Tabs.ESP:AddSection("Filtres")

Tabs.ESP:AddToggle("ESPTeamCheck", {
    Title    = "👥 Team Check",
    Default  = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("TeamCheck", v) end
    end,
})

Tabs.ESP:AddSlider("ESPMaxDist", {
    Title    = "Distance max",
    Default  = 500,
    Min      = 50,
    Max      = 2000,
    Rounding = 0,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("MaxDist", v) end
    end,
})

Tabs.ESP:AddSection("Info")
Tabs.ESP:AddParagraph({
    Title   = "Test v"..VERSION,
    Content = "Seules les boxes sont actives.\nActive 'ESP Global' puis 'Box ESP'.\nDis si ça marche → on ajoute la suite.",
})

-- ══════════════════════════════════════════════════════════════════
-- LES OPTIONS SUIVANTES SONT DÉSACTIVÉES — SERONT RÉACTIVÉES UNE PAR UNE
-- ══════════════════════════════════════════════════════════════════
-- DÉSACTIVÉ : Skeleton, Tracers, Name, Distance, Health, FOV Circle
-- DÉSACTIVÉ : Aimbot, SilentAim, Triggerbot
-- DÉSACTIVÉ : Speed, Fly, Noclip, BunnyHop, InfJump
-- DÉSACTIVÉ : Fullbright, NoFog, AntiAFK, FPSUnlock
-- DÉSACTIVÉ : Da Hood module, Arsenal module

Window:SelectTab(1)

print("[Aurora v"..VERSION.."] Chargé ✓")
print("[Aurora] Active 'ESP Global' puis 'Box ESP' pour tester")
