-- ══════════════════════════════════════════════════════
--   Aurora v4.0.0 — Main.lua
--   UI : Fluent Renewed Library
-- ══════════════════════════════════════════════════════

local VERSION = "4.0.0"
local REPO    = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

-- Console silencieux
local _log = {}
local function _p(m) table.insert(_log,{t=os.clock(),m=tostring(m)}) end
local function _w(m) table.insert(_log,{t=os.clock(),m="[!]"..tostring(m)}) end

-- ── Loader ────────────────────────────────────────────
local function load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(REPO..path, true))()
    end)
    if not ok then _w("err:"..path); return nil end
    return result
end

-- ══════════════════════════════════════════════════════
-- ÉTAPE 1 — KEY SYSTEM
-- ══════════════════════════════════════════════════════
getgenv().AuroraESP = {}
local N = getgenv().AuroraESP

-- Charge Firebase d'abord pour que KeySystem puisse valider
pcall(function() N.Firebase = load("Network/Firebase.lua") end)

N.KeySystem = load("Security/KeySystem.lua")
if N.KeySystem then
    local valid = N.KeySystem.Validate()
    if not valid then return end
end

-- ══════════════════════════════════════════════════════
-- ÉTAPE 2 — LOADING SCREEN
-- ══════════════════════════════════════════════════════
local LS = load("UI/LoadingScreen.lua")
if LS then LS.Show(VERSION) end
local function progress(pct, txt)
    if LS then pcall(LS.SetProgress, pct, txt) end
end

-- ── Core ──────────────────────────────────────────────
progress(0.05, "Core...")
N.Signal   = load("Core/Signal.lua")
N.EventBus = load("Core/EventBus.lua")
N.Thread   = load("Core/Thread.lua")
N.Memory   = load("Core/Memory.lua")
if N.EventBus then N.EventBus.Init() end

-- ── Config ────────────────────────────────────────────
progress(0.10, "Configuration...")
N.Config   = load("Config/Manager.lua")
N.Profiles = load("Config/Profiles.lua")
if N.Config   then N.Config.Init() end
if N.Profiles then
    local p = N.Profiles.Load("Default")
    if p then N.Config.SetAll(p) end
end

-- ── Network ───────────────────────────────────────────
progress(0.15, "Réseau...")
pcall(function() N.Updater = load("Network/Updater.lua") end)

-- ── Security ──────────────────────────────────────────
progress(0.20, "Sécurité...")
pcall(function()
    N.Detector      = load("Security/Detector.lua")
    N.GenericBypass = load("Security/GenericBypass.lua")
    N.PanicKey      = load("Security/PanicKey.lua")
    N.StealthMode   = load("Security/StealthMode.lua")
    N.AdminDetector = load("Modules/Utility/AdminDetector.lua")
    if N.Detector      then N.Detector.Init({Config=N.Config}) end
    if N.GenericBypass then N.GenericBypass.Init() end
end)

-- ── Utils ─────────────────────────────────────────────
progress(0.25, "Utilitaires...")
N.Utils = load("Modules/Utils.lua")

-- ── ESP ───────────────────────────────────────────────
progress(0.35, "ESP...")
N.ESP    = load("Modules/ESP/ESP.lua")
N.Chams  = load("Modules/ESP/Chams.lua")
if N.ESP then N.ESP.Init({Utils=N.Utils, Config=N.Config}) end
if N.Chams then N.Chams.Init({}) end

-- ── Combat ────────────────────────────────────────────
progress(0.45, "Combat...")
N.Aimbot     = load("Modules/Combat/Aimbot.lua")
N.SilentAim  = load("Modules/Combat/SilentAim.lua")
N.Triggerbot = load("Modules/Combat/Triggerbot.lua")
N.RecoilCtrl = load("Modules/Combat/RecoilControl.lua")
N.Humanizer  = load("Modules/Combat/Humanizer.lua")
local cDeps  = {Utils=N.Utils, Config=N.Config}
if N.Aimbot     then N.Aimbot.Init(cDeps)     end
if N.SilentAim  then N.SilentAim.Init(cDeps)  end
if N.Triggerbot then N.Triggerbot.Init(cDeps)  end
if N.RecoilCtrl then N.RecoilCtrl.Init(cDeps)  end
if N.Humanizer  then N.Humanizer.Init(cDeps)   end

-- ── Movement ──────────────────────────────────────────
progress(0.55, "Mouvement...")
N.Speed       = load("Modules/Movement/Speed.lua")
N.Fly         = load("Modules/Movement/Fly.lua")
N.Noclip      = load("Modules/Movement/Noclip.lua")
N.BunnyHop    = load("Modules/Movement/BunnyHop.lua")
N.InfJump     = load("Modules/Movement/InfiniteJump.lua")
N.Teleport    = load("Modules/Movement/Teleport.lua")
N.AntiRagdoll = load("Modules/Movement/AntiRagdoll.lua")
local mDeps   = {Config=N.Config}
if N.Speed       then N.Speed.Init(mDeps)       end
if N.Fly         then N.Fly.Init(mDeps)         end
if N.Noclip      then N.Noclip.Init(mDeps)      end
if N.BunnyHop    then N.BunnyHop.Init(mDeps)    end
if N.InfJump     then N.InfJump.Init(mDeps)     end
if N.Teleport    then N.Teleport.Init(mDeps)    end
if N.AntiRagdoll then N.AntiRagdoll.Init(mDeps) end

-- ── World ─────────────────────────────────────────────
progress(0.62, "Monde...")
N.FullBright = load("Modules/World/FullBright.lua")
N.NoFog      = load("Modules/World/NoFog.lua")
N.ItemESP    = load("Modules/World/ItemESP.lua")
if N.FullBright then N.FullBright.Init({}) end
if N.NoFog      then N.NoFog.Init({})      end
if N.ItemESP    then N.ItemESP.Init({Config=N.Config}) end

-- ── Utility ───────────────────────────────────────────
progress(0.70, "Utilitaires...")
N.AntiAFK    = load("Modules/Utility/AntiAFK.lua")
N.ServerHop  = load("Modules/Utility/ServerHop.lua")
N.RemoteSpy  = load("Modules/Utility/RemoteSpy.lua")
N.ChatLogger = load("Modules/Utility/ChatLogger.lua")
N.FPSUnlock  = load("Modules/Utility/FPSUnlock.lua")
local uDeps  = {Config=N.Config}
if N.AntiAFK       then N.AntiAFK.Init(uDeps)       end
if N.AdminDetector then N.AdminDetector.Init(uDeps)  end
if N.ServerHop     then N.ServerHop.Init(uDeps)      end
if N.RemoteSpy     then N.RemoteSpy.Init(uDeps)      end
if N.ChatLogger    then N.ChatLogger.Init(uDeps)     end
if N.FPSUnlock     then N.FPSUnlock.Init(uDeps)      end
if N.AntiAFK       then N.AntiAFK.Enable()           end

-- ── AI ────────────────────────────────────────────────
progress(0.78, "Intelligence Artificielle...")
pcall(function()
    N.LearningEngine = load("AI/Core/LearningEngine.lua")
    N.PatternEngine  = load("AI/Core/PatternEngine.lua")
    N.DecisionTree   = load("AI/Core/DecisionTree.lua")
    N.AimAI          = load("AI/Combat/AimAI.lua")
    N.PredictionAI   = load("AI/Combat/PredictionAI.lua")
    N.ThreatLevel    = load("AI/Combat/ThreatLevel.lua")
    N.PerfectHuman   = load("AI/Combat/PerfectHumanizer.lua")
    N.BotCore        = load("AI/Bot/BotCore.lua")
    local aiDeps = {
        Utils=N.Utils, Config=N.Config,
        LearningEngine=N.LearningEngine, PatternEngine=N.PatternEngine,
        DecisionTree=N.DecisionTree, ThreatLevel=N.ThreatLevel,
        PredictionAI=N.PredictionAI, PerfectHuman=N.PerfectHuman,
    }
    if N.LearningEngine then N.LearningEngine.Init(aiDeps) end
    if N.PatternEngine  then N.PatternEngine.Init(aiDeps)  end
    if N.DecisionTree   then N.DecisionTree.Init(aiDeps)   end
    if N.AimAI          then N.AimAI.Init(aiDeps)          end
    if N.PredictionAI   then N.PredictionAI.Init(aiDeps)   end
    if N.ThreatLevel    then N.ThreatLevel.Init(aiDeps)    end
    if N.PerfectHuman   then N.PerfectHuman.Init(aiDeps)   end
    if N.BotCore        then N.BotCore.Init(aiDeps)        end
end)

-- ── Security finale ───────────────────────────────────
progress(0.85, "Sécurité finale...")
pcall(function()
    local sDeps = {Config=N.Config, AdminDetector=N.AdminDetector}
    if N.PanicKey    then N.PanicKey.Init(sDeps)    end
    if N.StealthMode then N.StealthMode.Init(sDeps) end
    if N.AdminDetector then
        N.AdminDetector.Enable()
        N.AdminDetector.OnDetected(function(player)
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

-- ── Game Detection ────────────────────────────────────
progress(0.90, "Détection du jeu...")
N.GameDetector = load("Game/Detector.lua")
local detectedGame = "Generic"
if N.GameDetector then
    N.GameDetector.Init({Utils=N.Utils})
    detectedGame = N.GameDetector.Detect() or "Generic"
end

local gameMod
pcall(function()
    if     detectedGame == "DaHood"        then gameMod = load("Game/Games/DaHood/Init.lua")
    elseif detectedGame == "PhantomForces" then gameMod = load("Game/Games/PhantomForces/Init.lua")
    elseif detectedGame == "Arsenal"       then gameMod = load("Game/Games/Arsenal/Init.lua")
    elseif detectedGame == "Fisch"         then gameMod = load("Game/Games/Fisch/Init.lua")
    else                                        gameMod = load("Game/Games/Generic/Init.lua") end
    if gameMod then
        N.CurrentGame = gameMod
        gameMod.Init({Utils=N.Utils, Config=N.Config})
    end
end)

-- ══════════════════════════════════════════════════════
-- ÉTAPE 3 — FLUENT UI
-- ══════════════════════════════════════════════════════
progress(0.95, "Interface...")

local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

progress(1.0, "Prêt !")
task.wait(0.6)
if LS then LS.Hide() end

-- ── Fenêtre principale ────────────────────────────────
local Window = Fluent:CreateWindow({
    Title          = "Aurora  •  v"..VERSION,
    SubTitle       = detectedGame ~= "Generic" and "⚡ "..detectedGame.." détecté" or "Mode Générique",
    TabWidth       = 160,
    Size           = UDim2.fromOffset(780, 510),
    Acrylic        = true,
    Theme          = "Dark",
    MinimizeKey    = Enum.KeyCode.Insert,
})

-- ── Tabs ──────────────────────────────────────────────
local Tabs = {
    ESP      = Window:AddTab({ Title = "ESP",      Icon = "eye" }),
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "crosshair" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "wind" }),
    World    = Window:AddTab({ Title = "World",    Icon = "globe" }),
    AI       = Window:AddTab({ Title = "AI",       Icon = "cpu" }),
    Utility  = Window:AddTab({ Title = "Utility",  Icon = "tool" }),
    Config   = Window:AddTab({ Title = "Config",   Icon = "settings" }),
}

-- Si jeu détecté, ajoute un tab dédié
if detectedGame ~= "Generic" then
    Tabs.Game = Window:AddTab({ Title = detectedGame, Icon = "star" })
end

-- ══════════════════════════════════════════════════════
-- TAB ESP
-- ══════════════════════════════════════════════════════
local espJoueurs = Tabs.ESP:AddSection("Joueurs")
local espVisuel  = Tabs.ESP:AddSection("Visuel")
local espMonde   = Tabs.ESP:AddSection("Monde")

-- Joueurs
Tabs.ESP:AddToggle("ESPGlobal", {
    Title   = "ESP Global",
    Default = false,
    Callback = function(v)
        if N.ESP then
            if v then N.ESP.Enable() else N.ESP.Disable() end
        end
    end
})

Tabs.ESP:AddToggle("BoxESP", {
    Title   = "Box ESP",
    Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Box", v) end
    end
})

Tabs.ESP:AddToggle("CornerBox", {
    Title   = "Corner Box",
    Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("CornerBox", v) end
    end
})

Tabs.ESP:AddToggle("Skeleton", {
    Title   = "Skeleton",
    Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Skeleton", v) end
    end
})

Tabs.ESP:AddToggle("Tracers", {
    Title   = "Tracers",
    Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Tracers", v) end
    end
})

Tabs.ESP:AddToggle("NomESP", {
    Title   = "Noms",
    Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Name", v) end
    end
})

Tabs.ESP:AddToggle("Distance", {
    Title   = "Distance",
    Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Distance", v) end
    end
})

Tabs.ESP:AddToggle("HealthBar", {
    Title   = "Barre de vie",
    Default = false,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("Health", v) end
    end
})

Tabs.ESP:AddToggle("Chams", {
    Title   = "Chams",
    Default = false,
    Callback = function(v)
        if N.Chams then
            if v then N.Chams.Enable() else N.Chams.Disable() end
        end
    end
})

Tabs.ESP:AddToggle("TeamCheck", {
    Title   = "Team Check",
    Default = true,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("TeamCheck", v) end
    end
})

-- Visuel
Tabs.ESP:AddSlider("DistanceMax", {
    Title   = "Distance Max",
    Default = 500,
    Min     = 50,
    Max     = 2000,
    Rounding = 0,
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("MaxDist", v) end
    end
})

Tabs.ESP:AddColorpicker("ESPColor", {
    Title   = "Couleur Ennemis",
    Default = Color3.fromRGB(248, 113, 113),
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("EnemyColor", v) end
    end
})

Tabs.ESP:AddColorpicker("ESPTeamColor", {
    Title   = "Couleur Équipe",
    Default = Color3.fromRGB(74, 222, 128),
    Callback = function(v)
        if N.ESP then N.ESP.SetOption("TeamColor", v) end
    end
})

-- Monde
Tabs.ESP:AddToggle("ItemESP", {
    Title   = "Item ESP",
    Default = false,
    Callback = function(v)
        if N.ItemESP then N.ItemESP.Toggle() end
    end
})

Tabs.ESP:AddToggle("FullBright", {
    Title   = "Full Bright",
    Default = false,
    Callback = function(v)
        if N.FullBright then
            if v then N.FullBright.Enable() else N.FullBright.Disable() end
        end
    end
})

Tabs.ESP:AddToggle("NoFog", {
    Title   = "No Fog",
    Default = false,
    Callback = function(v)
        if N.NoFog then
            if v then N.NoFog.Enable() else N.NoFog.Disable() end
        end
    end
})

-- ══════════════════════════════════════════════════════
-- TAB COMBAT
-- ══════════════════════════════════════════════════════
local aimSec     = Tabs.Combat:AddSection("Aimbot")
local silentSec  = Tabs.Combat:AddSection("Silent Aim")
local triggerSec = Tabs.Combat:AddSection("Triggerbot")
local recoilSec  = Tabs.Combat:AddSection("Recul")

-- Aimbot
Tabs.Combat:AddToggle("Aimbot", {
    Title   = "Aimbot",
    Default = false,
    Callback = function(v)
        if N.Aimbot then
            if v then N.Aimbot.Enable() else N.Aimbot.Disable() end
        end
    end
})

Tabs.Combat:AddSlider("Smoothness", {
    Title    = "Smoothness",
    Default  = 10,
    Min      = 1,
    Max      = 50,
    Rounding = 0,
    Callback = function(v)
        if N.Aimbot then N.Aimbot.SetSmooth(v) end
    end
})

Tabs.Combat:AddSlider("FOV", {
    Title    = "FOV",
    Default  = 100,
    Min      = 10,
    Max      = 360,
    Rounding = 0,
    Callback = function(v)
        if N.Aimbot then N.Aimbot.SetFOV(v) end
    end
})

Tabs.Combat:AddDropdown("AimbotBone", {
    Title   = "Bone cible",
    Values  = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Default = 1,
    Callback = function(v)
        if N.Aimbot then N.Aimbot.SetBone(v) end
    end
})

Tabs.Combat:AddToggle("TeamCheckAim", {
    Title   = "Team Check",
    Default = true,
    Callback = function(v)
        if N.Aimbot then N.Aimbot.SetTeamCheck(v) end
    end
})

Tabs.Combat:AddToggle("WallCheck", {
    Title   = "Wall Check",
    Default = false,
    Callback = function(v)
        if N.Aimbot then N.Aimbot.SetWallCheck(v) end
    end
})

-- Silent Aim
Tabs.Combat:AddToggle("SilentAim", {
    Title   = "Silent Aim",
    Default = false,
    Callback = function(v)
        if N.SilentAim then
            if v then N.SilentAim.Enable() else N.SilentAim.Disable() end
        end
    end
})

Tabs.Combat:AddDropdown("SilentBone", {
    Title   = "Bone Silent Aim",
    Values  = {"Head", "HumanoidRootPart", "UpperTorso"},
    Default = 1,
    Callback = function(v)
        if N.SilentAim then N.SilentAim.SetBone(v) end
    end
})

-- Triggerbot
Tabs.Combat:AddToggle("Triggerbot", {
    Title   = "Triggerbot",
    Default = false,
    Callback = function(v)
        if N.Triggerbot then
            if v then N.Triggerbot.Enable() else N.Triggerbot.Disable() end
        end
    end
})

Tabs.Combat:AddSlider("TriggerDelay", {
    Title    = "Délai trigger (ms)",
    Default  = 50,
    Min      = 0,
    Max      = 300,
    Rounding = 0,
    Callback = function(v)
        if N.Triggerbot then N.Triggerbot.SetDelay(v/1000) end
    end
})

-- Recul
Tabs.Combat:AddToggle("RecoilControl", {
    Title   = "Recoil Control",
    Default = false,
    Callback = function(v)
        if N.RecoilCtrl then
            if v then N.RecoilCtrl.Enable() else N.RecoilCtrl.Disable() end
        end
    end
})

Tabs.Combat:AddSlider("RecoilStrength", {
    Title    = "Force anti-recul",
    Default  = 50,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
    Callback = function(v)
        if N.RecoilCtrl then N.RecoilCtrl.SetStrength(v/100) end
    end
})

Tabs.Combat:AddToggle("Humanizer", {
    Title   = "Humanizer",
    Default = false,
    Callback = function(v)
        if N.Humanizer then
            if v then N.Humanizer.Enable() else N.Humanizer.Disable() end
        end
    end
})

-- ══════════════════════════════════════════════════════
-- TAB MOVEMENT
-- ══════════════════════════════════════════════════════
local speedSec = Tabs.Movement:AddSection("Vitesse")
local flySec   = Tabs.Movement:AddSection("Vol")
local miscMov  = Tabs.Movement:AddSection("Divers")
local tpSec    = Tabs.Movement:AddSection("Téléportation")

-- Speed
Tabs.Movement:AddToggle("Speed", {
    Title   = "Speed",
    Default = false,
    Callback = function(v)
        if N.Speed then
            if v then N.Speed.Enable() else N.Speed.Disable() end
        end
    end
})

Tabs.Movement:AddSlider("SpeedValue", {
    Title    = "Valeur vitesse",
    Default  = 32,
    Min      = 16,
    Max      = 500,
    Rounding = 0,
    Callback = function(v)
        if N.Speed then N.Speed.SetSpeed(v) end
    end
})

-- Fly
Tabs.Movement:AddToggle("Fly", {
    Title   = "Fly",
    Default = false,
    Callback = function(v)
        if N.Fly then
            if v then N.Fly.Enable() else N.Fly.Disable() end
        end
    end
})

Tabs.Movement:AddSlider("FlySpeed", {
    Title    = "Vitesse vol",
    Default  = 50,
    Min      = 5,
    Max      = 500,
    Rounding = 0,
    Callback = function(v)
        if N.Fly then N.Fly.SetSpeed(v) end
    end
})

-- Divers
Tabs.Movement:AddToggle("Noclip", {
    Title   = "Noclip",
    Default = false,
    Callback = function(v)
        if N.Noclip then
            if v then N.Noclip.Enable() else N.Noclip.Disable() end
        end
    end
})

Tabs.Movement:AddToggle("BunnyHop", {
    Title   = "Bunny Hop",
    Default = false,
    Callback = function(v)
        if N.BunnyHop then
            if v then N.BunnyHop.Enable() else N.BunnyHop.Disable() end
        end
    end
})

Tabs.Movement:AddToggle("InfiniteJump", {
    Title   = "Infinite Jump",
    Default = false,
    Callback = function(v)
        if N.InfJump then
            if v then N.InfJump.Enable() else N.InfJump.Disable() end
        end
    end
})

Tabs.Movement:AddToggle("AntiRagdoll", {
    Title   = "Anti Ragdoll",
    Default = false,
    Callback = function(v)
        if N.AntiRagdoll then
            if v then N.AntiRagdoll.Enable() else N.AntiRagdoll.Disable() end
        end
    end
})

-- ══════════════════════════════════════════════════════
-- TAB WORLD
-- ══════════════════════════════════════════════════════
local lightSec  = Tabs.World:AddSection("Éclairage")
local weatherSec = Tabs.World:AddSection("Météo")

Tabs.World:AddToggle("FullBrightW", {
    Title   = "Full Bright",
    Default = false,
    Callback = function(v)
        if N.FullBright then
            if v then N.FullBright.Enable() else N.FullBright.Disable() end
        end
    end
})

Tabs.World:AddToggle("NoFogW", {
    Title   = "No Fog",
    Default = false,
    Callback = function(v)
        if N.NoFog then
            if v then N.NoFog.Enable() else N.NoFog.Disable() end
        end
    end
})

Tabs.World:AddSlider("TimeOfDay", {
    Title    = "Heure du jour",
    Default  = 14,
    Min      = 0,
    Max      = 24,
    Rounding = 1,
    Callback = function(v)
        pcall(function()
            game:GetService("Lighting").ClockTime = v
        end)
    end
})

-- ══════════════════════════════════════════════════════
-- TAB AI
-- ══════════════════════════════════════════════════════
local aiAimSec = Tabs.AI:AddSection("IA Combat")
local botSec   = Tabs.AI:AddSection("Bot Autonome")

Tabs.AI:AddToggle("AimAI", {
    Title   = "Aim IA",
    Default = false,
    Callback = function(v)
        if N.AimAI then
            if v then N.AimAI.Enable() else N.AimAI.Disable() end
        end
    end
})

Tabs.AI:AddToggle("PredictionAI", {
    Title   = "Prediction IA",
    Default = false,
    Callback = function(v)
        if N.PredictionAI then
            if v then N.PredictionAI.Enable() else N.PredictionAI.Disable() end
        end
    end
})

Tabs.AI:AddToggle("BotCore", {
    Title   = "Bot Autonome",
    Default = false,
    Callback = function(v)
        if N.BotCore then
            if v then N.BotCore.Enable() else N.BotCore.Disable() end
        end
    end
})

Tabs.AI:AddToggle("ThreatLevel", {
    Title   = "Threat Detector",
    Default = false,
    Callback = function(v)
        if N.ThreatLevel then
            if v then N.ThreatLevel.Enable() else N.ThreatLevel.Disable() end
        end
    end
})

-- ══════════════════════════════════════════════════════
-- TAB UTILITY
-- ══════════════════════════════════════════════════════
local antiSec   = Tabs.Utility:AddSection("Anti-Détection")
local utilSec   = Tabs.Utility:AddSection("Utilitaires")
local spySec    = Tabs.Utility:AddSection("Analyse")

-- Anti
Tabs.Utility:AddToggle("AntiAFK", {
    Title   = "Anti AFK",
    Default = true,
    Callback = function(v)
        if N.AntiAFK then
            if v then N.AntiAFK.Enable() else N.AntiAFK.Disable() end
        end
    end
})

Tabs.Utility:AddToggle("StealthMode", {
    Title   = "Stealth Mode",
    Default = false,
    Callback = function(v)
        if N.StealthMode then
            if v then N.StealthMode.Enable() else N.StealthMode.Disable() end
        end
    end
})

Tabs.Utility:AddToggle("AdminDetector", {
    Title   = "Admin Detector",
    Default = false,
    Callback = function(v)
        if N.AdminDetector then
            if v then N.AdminDetector.Enable() else N.AdminDetector.Disable() end
        end
    end
})

Tabs.Utility:AddKeybind("PanicKey", {
    Title   = "Panic Key",
    Default = "Delete",
    Callback = function()
        if N.PanicKey then N.PanicKey.Panic() end
    end
})

-- Util
Tabs.Utility:AddToggle("FPSUnlock", {
    Title   = "FPS Unlock",
    Default = false,
    Callback = function(v)
        if N.FPSUnlock then
            if v then N.FPSUnlock.Enable(144) else N.FPSUnlock.Disable() end
        end
    end
})

Tabs.Utility:AddButton({
    Title = "Server Hop",
    Callback = function()
        if N.ServerHop then N.ServerHop.Hop() end
    end
})

Tabs.Utility:AddToggle("ChatLogger", {
    Title   = "Chat Logger",
    Default = false,
    Callback = function(v)
        if N.ChatLogger then
            if v then N.ChatLogger.Enable() else N.ChatLogger.Disable() end
        end
    end
})

-- Spy
Tabs.Utility:AddToggle("RemoteSpy", {
    Title   = "Remote Spy",
    Default = false,
    Callback = function(v)
        if N.RemoteSpy then
            if v then N.RemoteSpy.Enable() else N.RemoteSpy.Disable() end
        end
    end
})

-- ══════════════════════════════════════════════════════
-- TAB CONFIG
-- ══════════════════════════════════════════════════════
local configSec = Tabs.Config:AddSection("Interface")
local profileSec = Tabs.Config:AddSection("Profils")

Tabs.Config:AddParagraph({
    Title = "Aurora v"..VERSION,
    Content = "Jeu détecté : "..detectedGame.."\nAppuie sur INSERT pour cacher/afficher",
})

Tabs.Config:AddButton({
    Title = "Reset Config",
    Callback = function()
        if N.Config then N.Config.Init() end
    end
})

Tabs.Config:AddButton({
    Title = "Sauvegarder Profil",
    Callback = function()
        if N.Profiles and N.Config then
            N.Profiles.Save("Default", N.Config.Current)
        end
    end
})

-- ── SaveManager ───────────────────────────────────────
pcall(function()
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder("Aurora")
    InterfaceManager:SetFolder("Aurora")
    InterfaceManager:BuildInterfaceSection(Tabs.Config)
    SaveManager:BuildConfigSection(Tabs.Config)
    SaveManager:LoadAutoloadConfig()
end)

-- ── Tab actif par défaut ──────────────────────────────
Window:SelectTab(1)

_p("Aurora v"..VERSION.." — PRÊT")
