-- ══════════════════════════════════════════════════════════════════
--   Aurora v4.0.0 — Main.lua
--   UI : Fluent UI Library
--   GitHub : 666xxrizzyxx666-ship-it/NexusESP
-- ══════════════════════════════════════════════════════════════════

local VERSION = "4.0.9"
local REPO    = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

-- ── Console silencieuse ────────────────────────────────────────────
local _logs = {}
local function _p(m) table.insert(_logs, {t=os.clock(), m=tostring(m)}) end
local function _w(m) table.insert(_logs, {t=os.clock(), m="[!]"..tostring(m)}) end

-- ── Loader universel ──────────────────────────────────────────────
local function load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(REPO..path, true))()
    end)
    if not ok then _w("load err: "..path.." | "..tostring(result)) end
    return ok and result or nil
end

-- ══════════════════════════════════════════════════════════════════
-- ÉTAPE 1 — KEY SYSTEM
-- ══════════════════════════════════════════════════════════════════
getgenv().AuroraESP = {}
local N = getgenv().AuroraESP
N._version = VERSION

local KeySystem = load("Security/KeySystem.lua")
if KeySystem then
    local valid = KeySystem.Validate()
    if not valid then return end
    N.KeySystem = KeySystem
end

-- ══════════════════════════════════════════════════════════════════
-- ÉTAPE 2 — LOADING SCREEN
-- ══════════════════════════════════════════════════════════════════
local LS = load("UI/LoadingScreen.lua")
if LS then LS.Show(VERSION) end

local function progress(pct, txt)
    if LS then pcall(LS.SetProgress, pct, txt) end
end

-- ── Chargement modules ────────────────────────────────────────────
progress(0.05, "Core...")
pcall(function()
    N.Signal   = load("Core/Signal.lua")
    N.EventBus = load("Core/EventBus.lua")
    N.Thread   = load("Core/Thread.lua")
    N.Memory   = load("Core/Memory.lua")
    if N.EventBus then N.EventBus.Init({Signal=N.Signal}) end
end)

progress(0.12, "Configuration...")
pcall(function()
    N.Config   = load("Config/Manager.lua")
    N.Profiles = load("Config/Profiles.lua")
    if N.Config   then N.Config.Init() end
    if N.Profiles then
        N.Profiles.Init()
        local p = N.Profiles.Load("Default")
        if p and N.Config then N.Config.SetAll(p) end
    end
end)

progress(0.20, "Sécurité...")
pcall(function()
    N.Firebase      = load("Network/Firebase.lua")
    N.Detector      = load("Security/Detector.lua")
    N.GenericBypass = load("Security/GenericBypass.lua")
    N.PanicKey      = load("Security/PanicKey.lua")
    N.StealthMode   = load("Security/StealthMode.lua")
    if N.Detector      then N.Detector.Init({Config=N.Config}) end
    if N.GenericBypass then N.GenericBypass.Init() end
end)

progress(0.28, "Utilitaires...")
pcall(function()
    N.Utils = load("Modules/Utils.lua")
end)

progress(0.36, "ESP...")
pcall(function()
    N.ESP   = load("Modules/ESP/ESP.lua")
    N.Chams = load("Modules/ESP/Chams.lua")
    if N.ESP   then N.ESP.Init({Utils=N.Utils, Config=N.Config}) end
    if N.Chams then N.Chams.Init({}) end
end)

progress(0.44, "Combat...")
pcall(function()
    N.Aimbot     = load("Modules/Combat/Aimbot.lua")
    N.SilentAim  = load("Modules/Combat/SilentAim.lua")
    N.Triggerbot = load("Modules/Combat/Triggerbot.lua")
    N.RecoilCtrl = load("Modules/Combat/RecoilControl.lua")
    N.Humanizer  = load("Modules/Combat/Humanizer.lua")
    local d = {Utils=N.Utils, Config=N.Config}
    if N.Aimbot     then N.Aimbot.Init(d)     end
    if N.SilentAim  then N.SilentAim.Init(d)  end
    if N.Triggerbot then N.Triggerbot.Init(d)  end
    if N.RecoilCtrl then N.RecoilCtrl.Init(d)  end
    if N.Humanizer  then N.Humanizer.Init(d)   end
end)

progress(0.52, "Mouvement...")
pcall(function()
    N.Speed       = load("Modules/Movement/Speed.lua")
    N.Fly         = load("Modules/Movement/Fly.lua")
    N.Noclip      = load("Modules/Movement/Noclip.lua")
    N.BunnyHop    = load("Modules/Movement/BunnyHop.lua")
    N.InfJump     = load("Modules/Movement/InfiniteJump.lua")
    N.Teleport    = load("Modules/Movement/Teleport.lua")
    N.AntiRagdoll = load("Modules/Movement/AntiRagdoll.lua")
    local d = {Config=N.Config}
    if N.Speed       then N.Speed.Init(d)       end
    if N.Fly         then N.Fly.Init(d)         end
    if N.Noclip      then N.Noclip.Init(d)      end
    if N.BunnyHop    then N.BunnyHop.Init(d)    end
    if N.InfJump     then N.InfJump.Init(d)     end
    if N.Teleport    then N.Teleport.Init(d)    end
    if N.AntiRagdoll then N.AntiRagdoll.Init(d) end
end)

progress(0.60, "Monde...")
pcall(function()
    N.FullBright = load("Modules/World/FullBright.lua")
    N.NoFog      = load("Modules/World/NoFog.lua")
    N.ItemESP    = load("Modules/World/ItemESP.lua")
    if N.FullBright then N.FullBright.Init({}) end
    if N.NoFog      then N.NoFog.Init({})      end
    if N.ItemESP    then N.ItemESP.Init({Config=N.Config}) end
end)

progress(0.68, "Utilitaires avancés...")
pcall(function()
    N.AntiAFK       = load("Modules/Utility/AntiAFK.lua")
    N.ServerHop     = load("Modules/Utility/ServerHop.lua")
    N.AdminDetector = load("Modules/Utility/AdminDetector.lua")
    N.RemoteSpy     = load("Modules/Utility/RemoteSpy.lua")
    N.ChatLogger    = load("Modules/Utility/ChatLogger.lua")
    N.FPSUnlock     = load("Modules/Utility/FPSUnlock.lua")
    local d = {Config=N.Config}
    if N.AntiAFK       then N.AntiAFK.Init(d);       N.AntiAFK.Enable() end
    if N.ServerHop     then N.ServerHop.Init(d)     end
    if N.AdminDetector then N.AdminDetector.Init(d) end
    if N.RemoteSpy     then N.RemoteSpy.Init(d)     end
    if N.ChatLogger    then N.ChatLogger.Init(d)    end
    if N.FPSUnlock     then N.FPSUnlock.Init(d)     end
end)

progress(0.76, "Intelligence Artificielle...")
pcall(function()
    N.LearningEngine = load("AI/Core/LearningEngine.lua")
    N.PatternEngine  = load("AI/Core/PatternEngine.lua")
    N.DecisionTree   = load("AI/Core/DecisionTree.lua")
    N.AimAI          = load("AI/Combat/AimAI.lua")
    N.PredictionAI   = load("AI/Combat/PredictionAI.lua")
    N.ThreatLevel    = load("AI/Combat/ThreatLevel.lua")
    N.PerfectHuman   = load("AI/Combat/PerfectHumanizer.lua")
    N.BotCore        = load("AI/Bot/BotCore.lua")
    local d = {
        Utils=N.Utils, Config=N.Config,
        LearningEngine=N.LearningEngine, PatternEngine=N.PatternEngine,
        DecisionTree=N.DecisionTree, ThreatLevel=N.ThreatLevel,
        PredictionAI=N.PredictionAI, PerfectHuman=N.PerfectHuman,
    }
    if N.LearningEngine then N.LearningEngine.Init(d) end
    if N.PatternEngine  then N.PatternEngine.Init(d)  end
    if N.DecisionTree   then N.DecisionTree.Init(d)   end
    if N.AimAI          then N.AimAI.Init(d)          end
    if N.PredictionAI   then N.PredictionAI.Init(d)   end
    if N.ThreatLevel    then N.ThreatLevel.Init(d)    end
    if N.PerfectHuman   then N.PerfectHuman.Init(d)   end
    if N.BotCore        then N.BotCore.Init(d)        end
end)

progress(0.84, "Sécurité finale...")
pcall(function()
    local d = {Config=N.Config, AdminDetector=N.AdminDetector}
    if N.PanicKey    then N.PanicKey.Init(d)    end
    if N.StealthMode then N.StealthMode.Init(d) end
    if N.AdminDetector then
        N.AdminDetector.Enable()
        N.AdminDetector.OnDetected(function(p)
            if N.StealthMode then N.StealthMode.Enable() end
        end)
    end
    if N.PanicKey then
        N.PanicKey.OnPanic(function(isPanic)
            if isPanic then
                if N.ESP    then N.ESP.HideAll()    end
                if N.Aimbot then N.Aimbot.Disable() end
            end
        end)
    end
end)

progress(0.90, "Détection du jeu...")
local detectedGame = "Generic"
pcall(function()
    N.GameDetector = load("Game/Detector.lua")
    if N.GameDetector then
        N.GameDetector.Init({Utils=N.Utils})
        detectedGame = N.GameDetector.Detect() or "Generic"
    end
    local gMod
    if     detectedGame == "DaHood"        then gMod = load("Game/Games/DaHood/Init.lua")
    elseif detectedGame == "PhantomForces" then gMod = load("Game/Games/PhantomForces/Init.lua")
    elseif detectedGame == "Arsenal"       then gMod = load("Game/Games/Arsenal/Init.lua")
    elseif detectedGame == "Fisch"         then gMod = load("Game/Games/Fisch/Init.lua")
    else                                        gMod = load("Game/Games/Generic/Init.lua") end
    if gMod then
        N.CurrentGame = gMod
        gMod.Init({Utils=N.Utils, Config=N.Config})
    end
end)

progress(0.96, "Interface (téléchargement)...")

-- ══════════════════════════════════════════════════════════════════
-- ÉTAPE 3 — FLUENT UI
-- ══════════════════════════════════════════════════════════════════
local Fluent, SaveManager, InterfaceManager

local okFluent, errFluent = pcall(function()
    Fluent = loadstring(game:HttpGet(
        "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
    ))()
end)

if not okFluent or not Fluent then
    if LS then pcall(LS.Hide) end
    warn("[Aurora] Fluent impossible à charger: "..tostring(errFluent))
    return
end

pcall(function()
    SaveManager = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
    ))()
end)

pcall(function()
    InterfaceManager = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
    ))()
end)

progress(1.0, "Bienvenue dans Aurora !")
task.wait(0.6)
if LS then pcall(LS.Hide) end

-- ── Fenêtre principale ────────────────────────────────────────────
local gameLabel = detectedGame ~= "Generic" and ("⚡ "..detectedGame) or "Mode Générique"

local Window = Fluent:CreateWindow({
    Title       = "Aurora  v"..VERSION,
    SubTitle    = gameLabel,
    TabWidth    = 160,
    Size        = UDim2.fromOffset(800, 520),
    Acrylic     = true,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.Insert,
})

-- ── Tabs ──────────────────────────────────────────────────────────
local Tabs = {
    ESP      = Window:AddTab({ Title = "ESP",      Icon = "eye"        }),
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "crosshair"  }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "wind"       }),
    World    = Window:AddTab({ Title = "World",    Icon = "globe"      }),
    AI       = Window:AddTab({ Title = "AI",       Icon = "cpu"        }),
    Utility  = Window:AddTab({ Title = "Utility",  Icon = "shield"     }),
    Exploit  = Window:AddTab({ Title = "Exploit",  Icon = "activity"   }),
    Config   = Window:AddTab({ Title = "Config",   Icon = "settings"   }),
}
if detectedGame ~= "Generic" then
    Tabs.Game = Window:AddTab({ Title = detectedGame, Icon = "star" })
end

-- ════════════════════════════════════════════════════
-- TAB : ESP
-- ════════════════════════════════════════════════════

-- ── Section : Joueurs ─────────────────────────────
Tabs.ESP:AddSection("Joueurs")

Tabs.ESP:AddToggle("ESPEnable", {
    Title = "ESP Global", Default = false,
    Callback = function(v)
        if N.ESP then
            if v then N.ESP.Enable() else N.ESP.Disable() end
        end
    end
})
Tabs.ESP:AddToggle("ESPBox", {
    Title = "Box ESP", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Box", v) end
    end
})
Tabs.ESP:AddDropdown("ESPBoxStyle", {
    Title = "Style Box",
    Values = {"2D Normal", "Corner Box"},
    Default = 1,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("BoxStyle", v) end
    end
})
Tabs.ESP:AddColorpicker("ESPColorBox", {
    Title = "Couleur Box", Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("BoxColor", v) end
    end
})
Tabs.ESP:AddToggle("ESPSkeleton", {
    Title = "Skeleton", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Skeleton", v) end
    end
})
Tabs.ESP:AddToggle("ESPTracers", {
    Title = "Tracers", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Tracers", v) end
    end
})
Tabs.ESP:AddColorpicker("ESPColorTracer", {
    Title = "Couleur Tracers", Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("TracerColor", v) end
    end
})
Tabs.ESP:AddToggle("ESPName", {
    Title = "Noms", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Name", v) end
    end
})
Tabs.ESP:AddToggle("ESPDistance", {
    Title = "Distance", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Distance", v) end
    end
})
Tabs.ESP:AddToggle("ESPHealth", {
    Title = "Barre de vie", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Health", v) end
    end
})
Tabs.ESP:AddDropdown("ESPHealthPos", {
    Title = "Position HP Bar",
    Values = {"Gauche", "Droite", "Dessus", "Dessous"},
    Default = 1,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("HealthPos", v) end
    end
})
Tabs.ESP:AddToggle("ESPTeamCheck", {
    Title = "Team Check", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("TeamCheck", v) end
    end
})
Tabs.ESP:AddToggle("ESPWallCheck", {
    Title = "Visibles seulement", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("WallCheck", v) end
    end
})
Tabs.ESP:AddToggle("FOVCircle", {
    Title = "FOV Circle", Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("FOVCircle", v) end
    end
})
Tabs.ESP:AddSlider("ESPMaxDist", {
    Title = "Distance Max", Default = 500, Min = 50, Max = 2000, Rounding = 0,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("MaxDist", v) end
    end
})

-- ── Section : Couleurs joueurs ────────────────────
Tabs.ESP:AddSection("Couleurs joueurs")

Tabs.ESP:AddColorpicker("ESPColorEnemy", {
    Title = "Ennemis", Default = Color3.fromRGB(255, 80, 80),
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("EnemyColor", v) end
    end
})
Tabs.ESP:AddColorpicker("ESPColorTeam", {
    Title = "Équipe", Default = Color3.fromRGB(80, 255, 120),
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("TeamColor", v) end
    end
})

-- ── Section : Chams ───────────────────────────────
Tabs.ESP:AddSection("Chams")

Tabs.ESP:AddToggle("Chams", {
    Title = "Chams", Default = false,
    Callback = function(v)
        if N.Chams then
            if v then N.Chams.Enable() else N.Chams.Disable() end
        end
    end
})
Tabs.ESP:AddDropdown("ChamsStyle", {
    Title = "Style Chams",
    Values = {"Neon", "Flat", "Wireframe", "Glass"},
    Default = 1,
    Callback = function(v)
        if N.Chams then N.Chams.SetStyle(v) end
    end
})
Tabs.ESP:AddColorpicker("ChamsColorEnemy", {
    Title = "Couleur Ennemis", Default = Color3.fromRGB(255, 80, 80),
    Callback = function(v)
        if N.Chams then N.Chams.SetEnemyColor(v) end
    end
})
Tabs.ESP:AddColorpicker("ChamsColorTeam", {
    Title = "Couleur Équipe", Default = Color3.fromRGB(80, 255, 120),
    Callback = function(v)
        if N.Chams then N.Chams.SetTeamColor(v) end
    end
})

-- ── Section : Monde ───────────────────────────────
Tabs.ESP:AddSection("Monde")

Tabs.ESP:AddToggle("ItemESP", {
    Title = "Item ESP", Default = false,
    Callback = function(v)
        if N.ItemESP then
            if v then N.ItemESP.Enable() else N.ItemESP.Disable() end
        end
    end
})
Tabs.ESP:AddSlider("ItemESPDistESP", {
    Title = "Distance items", Default = 300, Min = 50, Max = 1000, Rounding = 0,
    Callback = function(v)
        if N.ItemESP then N.ItemESP.SetMaxDist(v) end
    end
})

-- ════════════════════════════════════════════════════
-- TAB : COMBAT
-- ════════════════════════════════════════════════════

-- ── Section : Aimbot ──────────────────────────────
Tabs.Combat:AddSection("Aimbot")

Tabs.Combat:AddToggle("AimbotEnable", {
    Title = "Aimbot", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("AimbotSmooth", {
    Title = "Smoothness", Default = 10, Min = 1, Max = 100, Rounding = 0,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("AimbotFOV", {
    Title = "FOV", Default = 120, Min = 10, Max = 360, Rounding = 0,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("AimbotPrediction", {
    Title = "Prédiction mouvement", Default = 50, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddDropdown("AimbotBone", {
    Title = "Bone cible",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Neck"},
    Default = 1,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddToggle("AimbotTeamCheck", {
    Title = "Team Check", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddToggle("AimbotWallCheck", {
    Title = "Wall Check", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddToggle("AimbotTargetLock", {
    Title = "Target Lock", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddKeybind("AimbotKey", {
    Title = "Touche Aimbot", Default = "RightMouseButton",
    Callback = function() end -- TODO
})

-- ── Section : Silent Aim ──────────────────────────
Tabs.Combat:AddSection("Silent Aim")

Tabs.Combat:AddToggle("SilentAimEnable", {
    Title = "Silent Aim", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddDropdown("SilentAimBone", {
    Title = "Bone",
    Values = {"Head", "HumanoidRootPart", "UpperTorso"},
    Default = 1,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("SilentAimFOV", {
    Title = "FOV Silent", Default = 180, Min = 10, Max = 360, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ── Section : Triggerbot ──────────────────────────
Tabs.Combat:AddSection("Triggerbot")

Tabs.Combat:AddToggle("TriggerbotEnable", {
    Title = "Triggerbot", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("TriggerbotDelay", {
    Title = "Délai (ms)", Default = 50, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("TriggerbotHoldTime", {
    Title = "Durée clic (ms)", Default = 80, Min = 10, Max = 300, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ── Section : Recul & Tir ─────────────────────────
Tabs.Combat:AddSection("Recul & Tir")

Tabs.Combat:AddToggle("RecoilControl", {
    Title = "Recoil Control", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("RecoilStrength", {
    Title = "Force anti-recul", Default = 50, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddToggle("RapidFire", {
    Title = "Rapid Fire", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddToggle("AutoReload", {
    Title = "Auto Reload", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddToggle("HitboxExpander", {
    Title = "Hitbox Expander", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("HitboxSize", {
    Title = "Taille hitbox", Default = 1, Min = 1, Max = 20, Rounding = 1,
    Callback = function(v) end -- TODO
})

-- ── Section : Humanizer ───────────────────────────
Tabs.Combat:AddSection("Humanizer")

Tabs.Combat:AddToggle("HumanizerEnable", {
    Title = "Humanizer", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Combat:AddSlider("HumanizerVariance", {
    Title = "Variance (ms)", Default = 30, Min = 0, Max = 200, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ════════════════════════════════════════════════════
-- TAB : MOVEMENT
-- ════════════════════════════════════════════════════

-- ── Section : Vitesse ─────────────────────────────
Tabs.Movement:AddSection("Vitesse")

Tabs.Movement:AddToggle("SpeedEnable", {
    Title = "Speed Hack", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddSlider("SpeedValue", {
    Title = "Valeur vitesse", Default = 32, Min = 16, Max = 500, Rounding = 0,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddToggle("AutoStrafe", {
    Title = "Auto Strafe", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddToggle("AirStrafe", {
    Title = "Air Strafe", Default = false,
    Callback = function(v) end -- TODO
})

-- ── Section : Vol ─────────────────────────────────
Tabs.Movement:AddSection("Vol")

Tabs.Movement:AddToggle("FlyEnable", {
    Title = "Fly", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddSlider("FlySpeed", {
    Title = "Vitesse vol", Default = 50, Min = 5, Max = 500, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ── Section : Saut ────────────────────────────────
Tabs.Movement:AddSection("Saut")

Tabs.Movement:AddToggle("InfiniteJump", {
    Title = "Infinite Jump", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddToggle("BunnyHop", {
    Title = "Bunny Hop", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddSlider("JumpPower", {
    Title = "Jump Power", Default = 50, Min = 10, Max = 500, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ── Section : Divers ──────────────────────────────
Tabs.Movement:AddSection("Divers")

Tabs.Movement:AddToggle("Noclip", {
    Title = "Noclip", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddToggle("AntiRagdoll", {
    Title = "Anti Ragdoll", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddToggle("SlideHack", {
    Title = "Slide Hack", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddToggle("SwimSpeed", {
    Title = "Swim Speed", Default = false,
    Callback = function(v) end -- TODO
})

-- ── Section : Téléportation ───────────────────────
Tabs.Movement:AddSection("Téléportation")

Tabs.Movement:AddDropdown("TeleportPlayer", {
    Title = "Téléporter vers joueur",
    Values = {"Sélectionner..."},
    Default = 1,
    Callback = function(v) end -- TODO
})
Tabs.Movement:AddButton({
    Title = "Go !",
    Callback = function() end -- TODO
})
Tabs.Movement:AddButton({
    Title = "Ajouter Waypoint ici",
    Callback = function() end -- TODO
})
Tabs.Movement:AddButton({
    Title = "Teleport Waypoint",
    Callback = function() end -- TODO
})

-- ════════════════════════════════════════════════════
-- TAB : WORLD
-- ════════════════════════════════════════════════════

-- ── Section : Éclairage ───────────────────────────
Tabs.World:AddSection("Éclairage")

Tabs.World:AddToggle("FullBright", {
    Title = "Full Bright", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.World:AddToggle("NoFog", {
    Title = "No Fog", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.World:AddSlider("TimeOfDay", {
    Title = "Heure du jour", Default = 14, Min = 0, Max = 24, Rounding = 1,
    Callback = function(v) end -- TODO
})
Tabs.World:AddSlider("Brightness", {
    Title = "Luminosité", Default = 1, Min = 0, Max = 10, Rounding = 1,
    Callback = function(v) end -- TODO
})
Tabs.World:AddColorpicker("AmbientColor", {
    Title = "Couleur Ambiance", Default = Color3.fromRGB(178, 178, 178),
    Callback = function(v) end -- TODO
})

-- ── Section : Météo ───────────────────────────────
Tabs.World:AddSection("Météo")

Tabs.World:AddDropdown("WeatherControl", {
    Title = "Météo",
    Values = {"Normal", "Pluie OFF", "Neige OFF", "Brouillard OFF", "Tout désactiver"},
    Default = 1,
    Callback = function(v) end -- TODO
})
Tabs.World:AddToggle("SkyChanger", {
    Title = "Sky Changer", Default = false,
    Callback = function(v) end -- TODO
})

-- ── Section : Items ───────────────────────────────
Tabs.World:AddSection("Items")

Tabs.World:AddToggle("ItemESPWorld", {
    Title = "Item ESP", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.World:AddSlider("ItemESPDist", {
    Title = "Distance items", Default = 300, Min = 50, Max = 1000, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ════════════════════════════════════════════════════
-- TAB : AI
-- ════════════════════════════════════════════════════

-- ── Section : IA Combat ───────────────────────────
Tabs.AI:AddSection("IA Combat")

Tabs.AI:AddToggle("AimAI", {
    Title = "Aim IA (adaptatif)", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.AI:AddToggle("PredictionAI", {
    Title = "Prediction IA", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.AI:AddSlider("AIBlend", {
    Title = "Blend IA / Manuel", Default = 50, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) end -- TODO
})
Tabs.AI:AddToggle("ThreatDetector", {
    Title = "Threat Detector", Default = false,
    Callback = function(v) end -- TODO
})

-- ── Section : Bot Autonome ────────────────────────
Tabs.AI:AddSection("Bot Autonome")

Tabs.AI:AddToggle("BotEnable", {
    Title = "Bot Autonome", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.AI:AddDropdown("BotMode", {
    Title = "Mode bot",
    Values = {"Combat", "Loot", "Survie", "Mixte"},
    Default = 4,
    Callback = function(v) end -- TODO
})
Tabs.AI:AddToggle("LearningEngine", {
    Title = "Learning Engine", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.AI:AddButton({
    Title = "Reset données IA",
    Callback = function() end -- TODO
})

-- ════════════════════════════════════════════════════
-- TAB : UTILITY
-- ════════════════════════════════════════════════════

-- ── Section : Anti-Détection ──────────────────────
Tabs.Utility:AddSection("Anti-Détection")

Tabs.Utility:AddToggle("AntiAFK", {
    Title = "Anti AFK", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddToggle("StealthMode", {
    Title = "Stealth Mode", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddToggle("AdminDetector", {
    Title = "Admin Detector", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddToggle("AntiScreenshot", {
    Title = "Anti Screenshot", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddKeybind("PanicKey", {
    Title = "Panic Key", Default = "Delete",
    Callback = function() end -- TODO
})

-- ── Section : Performance ─────────────────────────
Tabs.Utility:AddSection("Performance")

Tabs.Utility:AddToggle("FPSUnlock", {
    Title = "FPS Unlock", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddSlider("FPSTarget", {
    Title = "FPS Cible", Default = 144, Min = 60, Max = 360, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ── Section : Serveur ─────────────────────────────
Tabs.Utility:AddSection("Serveur")

Tabs.Utility:AddButton({
    Title = "Server Hop",
    Callback = function() end -- TODO
})
Tabs.Utility:AddToggle("AutoRejoin", {
    Title = "Auto Rejoin si kick", Default = false,
    Callback = function(v) end -- TODO
})

-- ── Section : Outils ──────────────────────────────
Tabs.Utility:AddSection("Outils")

Tabs.Utility:AddToggle("ChatLogger", {
    Title = "Chat Logger", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddToggle("NameSpoofer", {
    Title = "Name Spoofer", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddToggle("FakeLag", {
    Title = "Fake Lag", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Utility:AddSlider("FakeLagAmount", {
    Title = "Lag artificiel (ms)", Default = 0, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v) end -- TODO
})

-- ── Section : Watermark HUD ───────────────────────
Tabs.Utility:AddSection("HUD")

Tabs.Utility:AddToggle("Watermark", {
    Title = "Watermark", Default = false,
    Callback = function(v) end -- TODO
})

-- ════════════════════════════════════════════════════
-- TAB : EXPLOIT (Serveur)
-- ════════════════════════════════════════════════════

-- ── Section : Remote ──────────────────────────────
Tabs.Exploit:AddSection("Analyse Réseau")

Tabs.Exploit:AddToggle("RemoteSpy", {
    Title = "Remote Spy", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Exploit:AddToggle("RemoteScanner", {
    Title = "Remote Scanner (auto)", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Exploit:AddButton({
    Title = "Scanner les remotes",
    Callback = function() end -- TODO
})

-- ── Section : Exploitation ────────────────────────
Tabs.Exploit:AddSection("Exploitation Serveur")

Tabs.Exploit:AddToggle("RemoteFuzzer", {
    Title = "Remote Fuzzer", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Exploit:AddToggle("HookSystem", {
    Title = "Hook Système", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Exploit:AddToggle("MemoryScanner", {
    Title = "Memory Scanner", Default = false,
    Callback = function(v) end -- TODO
})
Tabs.Exploit:AddButton({
    Title = "Dump remotes dans console",
    Callback = function() end -- TODO
})

-- ════════════════════════════════════════════════════
-- TAB : CONFIG
-- ════════════════════════════════════════════════════

-- ── Section : Info ────────────────────────────────
Tabs.Config:AddSection("Informations")

Tabs.Config:AddParagraph({
    Title   = "Aurora v"..VERSION,
    Content = "Jeu : "..detectedGame.."\nINSERT = Cacher/Afficher\nDELETE = Panic Key",
})

-- ── Section : Profils ─────────────────────────────
Tabs.Config:AddSection("Profils")

Tabs.Config:AddButton({
    Title = "Sauvegarder profil",
    Callback = function() end -- TODO
})
Tabs.Config:AddButton({
    Title = "Charger profil",
    Callback = function() end -- TODO
})
Tabs.Config:AddButton({
    Title = "Reset config",
    Callback = function() end -- TODO
})

-- ── Section : Thème ───────────────────────────────
Tabs.Config:AddSection("Thème")

Tabs.Config:AddDropdown("UITheme", {
    Title = "Thème UI",
    Values = {"Dark", "Light", "Midnight", "Vynixu"},
    Default = 1,
    Callback = function(v)
        pcall(function() Fluent:SetTheme(v) end)
    end
})

-- ── SaveManager & InterfaceManager ────────────────
pcall(function()
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetFolder("Aurora")
    InterfaceManager:SetFolder("Aurora")
    InterfaceManager:BuildInterfaceSection(Tabs.Config)
    SaveManager:BuildConfigSection(Tabs.Config)
    SaveManager:LoadAutoloadConfig()
end)

-- ── Tab jeu spécifique ────────────────────────────
if Tabs.Game then
    Tabs.Game:AddSection("Options "..detectedGame)
    Tabs.Game:AddParagraph({
        Title   = detectedGame.." détecté !",
        Content = "Les options spécifiques à ce jeu\nseront disponibles ici.",
    })
end

-- ── Tab par défaut ────────────────────────────────
Window:SelectTab(1)
N.UI = Window
N.Tabs = Tabs

_p("Aurora v"..VERSION.." — PRÊT — "..detectedGame)
