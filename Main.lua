-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Main.lua
--   📁 Racine du projet
--   Rôle : Point d'entrée principal
--          Charge et connecte tous les modules
-- ══════════════════════════════════════════════════════

local VERSION = "3.1.3"
local REPO    = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

print("╔══════════════════════════════╗")
print("║  Aurora v"..VERSION.."           ║")
print("║  Loading...                  ║")
print("╚══════════════════════════════╝")

local function load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(REPO..path, true))()
    end)
    if not ok then
        warn("[Aurora] Erreur : "..path.." → "..tostring(result))
        return nil
    end
    return result
end

getgenv().NexusESP = {}
local N = getgenv().NexusESP

-- ── Phase 1 : Core ────────────────────────────────────
print("[Aurora] Core...")
N.Signal   = load("Core/Signal.lua")
N.EventBus = load("Core/EventBus.lua")
N.Thread   = load("Core/Thread.lua")
N.Memory   = load("Core/Memory.lua")
if N.EventBus then N.EventBus.Init() end

-- ── Phase 2 : Config ──────────────────────────────────
print("[Aurora] Config...")
N.Profiles = load("Config/Profiles.lua")
N.Config   = load("Config/Manager.lua")
if N.Profiles then N.Profiles.Init() end
if N.Config   then
    N.Config.Init()
    local profileConfig = N.Profiles and N.Profiles.Load("Default")
    if profileConfig then N.Config.SetAll(profileConfig) end
end

-- ── Phase 3 : Network / Key ───────────────────────────
print("[Aurora] Network/Key...")
-- Firebase chargé mais jamais bloquant
pcall(function() N.Firebase = load("Network/Firebase.lua") end)
pcall(function() N.Updater  = load("Network/Updater.lua")  end)
-- Key system — chargé mais jamais bloquant
pcall(function()
    N.KeySystem = load("Security/KeySystem.lua")
    if N.KeySystem and N.KeySystem.Validate then
        N.KeySystem.Validate()
    end
end)
-- Security détection — chargée mais jamais bloquante
pcall(function()
    N.Detector = load("Security/Detector.lua")
    if N.Detector then N.Detector.Init({Config=N.Config}) end
end)
pcall(function()
    N.GenericBypass = load("Security/GenericBypass.lua")
    if N.GenericBypass then N.GenericBypass.Init() end
end)

-- ── Phase 4 : Utils ───────────────────────────────────
N.Utils = load("Modules/Utils.lua")

-- ── Phase 5 : UI ──────────────────────────────────────
print("[Aurora] UI...")
N.Theme         = load("UI/Theme.lua")
N.Animation     = load("UI/Animation.lua")
N.Notifications = load("UI/Notifications.lua")
-- Watermark standalone désactivé — intégré dans le header du Framework
-- N.Watermark = load("UI/Watermark.lua")
N.Framework     = load("UI/Framework.lua")

if N.Animation     then N.Animation.Init(N.Theme) end
if N.Notifications then N.Notifications.Init(N.Theme, N.Animation) end
-- if N.Watermark     then N.Watermark.Init(N.Theme, N.Animation) end

local Toggle      = load("UI/Components/Toggle.lua")
local Slider      = load("UI/Components/Slider.lua")
local Dropdown    = load("UI/Components/Dropdown.lua")
local Button_c    = load("UI/Components/Button.lua")
local ColorPicker = load("UI/Components/ColorPicker.lua")
local Keybind     = load("UI/Components/Keybind.lua")
local Label_c     = load("UI/Components/Label.lua")

if Toggle      then Toggle.Init(N.Theme, N.Animation)      end
if Slider      then Slider.Init(N.Theme, N.Animation)      end
if Dropdown    then Dropdown.Init(N.Theme, N.Animation)    end
if Button_c    then Button_c.Init(N.Theme, N.Animation)    end
if ColorPicker then ColorPicker.Init(N.Theme, N.Animation) end
if Keybind     then Keybind.Init(N.Theme, N.Animation)     end
if Label_c     then Label_c.Init(N.Theme, N.Animation)     end

N.Components = {
    Toggle=Toggle, Slider=Slider, Dropdown=Dropdown,
    Button=Button_c, ColorPicker=ColorPicker,
    Keybind=Keybind, Label=Label_c,
}

if N.Framework then
    N.Framework.Init({
        Theme=N.Theme, Animation=N.Animation,
        Config=N.Config, Components=N.Components, Profiles=N.Profiles,
    })
end

-- ── Phase 6 : AI ──────────────────────────────────────
print("[Aurora] AI...")
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

-- ── Phase 7 : ESP ─────────────────────────────────────
print("[Aurora] ESP...")
N.ESP = load("Modules/ESP/ESP.lua")
if N.ESP then
    N.ESP.Init({Utils=N.Utils, Config=N.Config, EventBus=N.EventBus})
    -- ESP désactivé par défaut au lancement
    -- N.ESP.Enable()  ← activé par toggle dans l'UI
end

-- ── Phase 8 : Combat ──────────────────────────────────
print("[Aurora] Combat...")
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

-- ── Phase 9 : Movement ────────────────────────────────
print("[Aurora] Movement...")
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

-- ── Phase 10 : World / Utility ────────────────────────
print("[Aurora] World/Utility...")
N.FullBright    = load("Modules/World/FullBright.lua")
N.NoFog         = load("Modules/World/NoFog.lua")
N.ItemESP       = load("Modules/World/ItemESP.lua")
N.AntiAFK       = load("Modules/Utility/AntiAFK.lua")
N.ServerHop     = load("Modules/Utility/ServerHop.lua")
N.AdminDetector = load("Modules/Utility/AdminDetector.lua")
N.RemoteSpy     = load("Modules/Utility/RemoteSpy.lua")
N.ChatLogger    = load("Modules/Utility/ChatLogger.lua")
N.FPSUnlock     = load("Modules/Utility/FPSUnlock.lua")
local uDeps = {Config=N.Config, Notify=N.Notifications}
if N.FullBright    then N.FullBright.Init(uDeps)    end
if N.NoFog         then N.NoFog.Init(uDeps)         end
if N.ItemESP       then N.ItemESP.Init(uDeps)       end
if N.AntiAFK       then N.AntiAFK.Init(uDeps)       end
if N.ServerHop     then N.ServerHop.Init(uDeps)     end
if N.AdminDetector then N.AdminDetector.Init(uDeps) end
if N.RemoteSpy     then N.RemoteSpy.Init(uDeps)     end
if N.ChatLogger    then N.ChatLogger.Init(uDeps)    end
if N.FPSUnlock     then N.FPSUnlock.Init(uDeps)     end

-- Defaults
if N.AntiAFK and N.Config.Current.AntiAFK and N.Config.Current.AntiAFK.Enabled then
    N.AntiAFK.Enable()
end
if N.FPSUnlock and N.Config.Current.FPSUnlock and N.Config.Current.FPSUnlock.Enabled then
    N.FPSUnlock.Enable(N.Config.Current.FPSUnlock.Target)
end

-- ── Phase 11 : Security finale ────────────────────────
print("[Aurora] Security...")
N.PanicKey    = load("Security/PanicKey.lua")
N.StealthMode = load("Security/StealthMode.lua")
local sDeps   = {Config=N.Config, AdminDetector=N.AdminDetector, Notify=N.Notifications}
if N.PanicKey    then N.PanicKey.Init(sDeps)    end
if N.StealthMode then N.StealthMode.Init(sDeps) end

if N.PanicKey then
    N.PanicKey.OnPanic(function(isPanic)
        if isPanic then
            if N.ESP    then N.ESP.HideAll()    end
            if N.Aimbot then N.Aimbot.Disable() end
        end
    end)
end

if N.AdminDetector then
    N.AdminDetector.Enable()
    N.AdminDetector.OnDetected(function(player)
        if N.Notifications then
            N.Notifications.Warning("⚠ Admin", player.Name.." a rejoint !")
        end
        if N.StealthMode then N.StealthMode.Enable() end
    end)
end

-- ── Phase 12 : Game Specific ──────────────────────────
print("[Aurora] Game Specific...")
N.GameDetector = load("Game/Detector.lua")
if N.GameDetector then
    N.GameDetector.Init({Notify=N.Notifications, Utils=N.Utils})
    local gameId = N.GameDetector.Detect()
    print("[Aurora] Jeu : "..tostring(gameId))

    local gMod
    if     gameId == "DaHood"        then gMod = load("Game/Games/DaHood/Init.lua")
    elseif gameId == "PhantomForces" then gMod = load("Game/Games/PhantomForces/Init.lua")
    elseif gameId == "Arsenal"       then gMod = load("Game/Games/Arsenal/Init.lua")
    elseif gameId == "Fisch"         then gMod = load("Game/Games/Fisch/Init.lua")
    else                                  gMod = load("Game/Games/Generic/Init.lua") end

    if gMod then
        N.CurrentGame = gMod
        gMod.Init({Notify=N.Notifications, Utils=N.Utils, Config=N.Config})
    end
end

-- ── Prêt ──────────────────────────────────────────────
task.wait(0.5)
if N.Notifications then
    N.Notifications.Success("Aurora v"..VERSION, "Chargé ! Appuie sur Insert 🚀", 5)
end

-- ── Contenu des tabs ──────────────────────────────────
local F  = N.Framework
local C  = N.Components
local Cfg = N.Config

if F and C then
    -- ── ESP ───────────────────────────────────────────
    local espSec = F.AddSection("ESP", "Joueurs")
    if espSec and C.Toggle then
        C.Toggle.new(espSec.container, {
            label   = "ESP (Global)",
            default = false,
            onChange = function(v)
                if N.ESP then
                    if v then N.ESP.Enable() else N.ESP.Disable() end
                end
            end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Box ESP",
            default = false,
            onChange = function(v)
                if N.ESP then N.ESP.SetOption("Box", v) end
            end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Skeleton",
            default = false,
            onChange = function(v) if N.ESP then N.ESP.SetOption("Skeleton", v) end end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Tracers",
            default = false,
            onChange = function(v) if N.ESP then N.ESP.SetOption("Tracers", v) end end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Noms",
            default = false,
            onChange = function(v) if N.ESP then N.ESP.SetOption("Name", v) end end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Distance",
            default = false,
            onChange = function(v) if N.ESP then N.ESP.SetOption("Distance", v) end end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Santé",
            default = false,
            onChange = function(v) if N.ESP then N.ESP.SetOption("Health", v) end end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Chams",
            default = false,
            onChange = function(v) if N.ESP then N.ESP.SetOption("Chams", v) end end,
        })
        C.Toggle.new(espSec.container, {
            label   = "Team Check",
            default = false,
            onChange = function(v) if N.ESP then N.ESP.SetOption("TeamCheck", v) end end,
        })
    end

    local espSec2 = F.AddSection("ESP", "Visibilité")
    if espSec2 and C.Slider then
        C.Slider.new(espSec2.container, {
            label   = "Distance max",
            min=100, max=2000, default=800, step=50,
            format  = "%dm",
            onChange = function(v) if N.ESP then N.ESP.SetOption("MaxDist", v) end end,
        })
    end

    -- ── Combat ────────────────────────────────────────
    local aimSec = F.AddSection("Combat", "Aimbot")
    if aimSec and C.Toggle then
        C.Toggle.new(aimSec.container, {
            label   = "Aimbot",
            default = false,
            onChange = function(v) if N.Aimbot then N.Aimbot.Toggle() end end,
        })
        C.Toggle.new(aimSec.container, {
            label   = "Silent Aim",
            default = false,
            onChange = function(v) if N.SilentAim then N.SilentAim.Toggle() end end,
        })
        C.Toggle.new(aimSec.container, {
            label   = "Triggerbot",
            default = false,
            onChange = function(v) if N.Triggerbot then N.Triggerbot.Toggle() end end,
        })
        C.Toggle.new(aimSec.container, {
            label   = "Recoil Control",
            default = false,
            onChange = function(v) if N.RecoilCtrl then N.RecoilCtrl.Toggle() end end,
        })
    end
    if aimSec and C.Dropdown then
        C.Dropdown.new(aimSec.container, {
            label   = "Bone",
            options = {"Head","HumanoidRootPart","UpperTorso"},
            default = "Head",
            onChange = function(v) if Cfg then Cfg:Set("Aimbot", {Bone=v}) end end,
        })
    end
    if aimSec and C.Slider then
        C.Slider.new(aimSec.container, {
            label="FOV", min=10, max=360, default=100, step=5, format="%d°",
            onChange = function(v) if Cfg then Cfg:Set("Aimbot", {FOV=v}) end end,
        })
        C.Slider.new(aimSec.container, {
            label="Smoothness", min=1, max=50, default=10, step=1,
            onChange = function(v) if Cfg then Cfg:Set("Aimbot", {Smoothness=v}) end end,
        })
    end

    -- ── Movement ──────────────────────────────────────
    local movSec = F.AddSection("Movement", "Déplacement")
    if movSec and C.Toggle then
        C.Toggle.new(movSec.container, {
            label="Speed", default=false,
            onChange = function(v) if N.Speed then N.Speed.Toggle() end end,
        })
        C.Toggle.new(movSec.container, {
            label="Fly", default=false,
            onChange = function(v) if N.Fly then N.Fly.Toggle() end end,
        })
        C.Toggle.new(movSec.container, {
            label="Noclip", default=false,
            onChange = function(v) if N.Noclip then N.Noclip.Toggle() end end,
        })
        C.Toggle.new(movSec.container, {
            label="Bunny Hop", default=false,
            onChange = function(v) if N.BunnyHop then N.BunnyHop.Toggle() end end,
        })
        C.Toggle.new(movSec.container, {
            label="Infinite Jump", default=false,
            onChange = function(v) if N.InfJump then N.InfJump.Toggle() end end,
        })
    end
    if movSec and C.Slider then
        C.Slider.new(movSec.container, {
            label="Speed Value", min=16, max=200, default=50, step=2,
            onChange = function(v) if N.Speed then N.Speed.SetSpeed(v) end end,
        })
        C.Slider.new(movSec.container, {
            label="Fly Speed", min=10, max=300, default=80, step=5,
            onChange = function(v) if N.Fly then N.Fly.SetSpeed(v) end end,
        })
    end

    -- ── World ─────────────────────────────────────────
    local worldSec = F.AddSection("World", "Environnement")
    if worldSec and C.Toggle then
        C.Toggle.new(worldSec.container, {
            label="Full Bright", default=false,
            onChange = function(v) if N.FullBright then N.FullBright.Toggle() end end,
        })
        C.Toggle.new(worldSec.container, {
            label="No Fog", default=false,
            onChange = function(v) if N.NoFog then N.NoFog.Toggle() end end,
        })
        C.Toggle.new(worldSec.container, {
            label="Item ESP", default=false,
            onChange = function(v) if N.ItemESP then N.ItemESP.Toggle() end end,
        })
    end

    -- ── AI ────────────────────────────────────────────
    local aiSec = F.AddSection("AI", "Intelligence Artificielle")
    if aiSec and C.Toggle then
        C.Toggle.new(aiSec.container, {
            label="AI Aim", default=false,
            onChange = function(v) if N.AimAI then N.AimAI.Toggle() end end,
        })
        C.Toggle.new(aiSec.container, {
            label="Stealth Mode", default=false,
            onChange = function(v) if N.StealthMode then N.StealthMode.Toggle() end end,
        })
    end
    if aiSec and C.Slider then
        C.Slider.new(aiSec.container, {
            label="AI Blend", min=0, max=100, default=50, step=5, format="%d%%",
            onChange = function(v)
                if Cfg then Cfg:Set("Aimbot", {AIBlend=v/100}) end
            end,
        })
    end
    if aiSec and C.Label then
        local prof = N.LearningEngine and N.LearningEngine.GetProfile()
        local hitRate = prof and math.floor((prof.aim.hitRate or 0)*100) or 0
        C.Label.new(aiSec.container, {text="Session #"..(prof and prof.sessions or 1).." — Hit rate : "..hitRate.."%"})
    end

    -- ── Bot ───────────────────────────────────────────
    local botSec = F.AddSection("Bot", "Bot Autonome")
    if botSec and C.Toggle then
        C.Toggle.new(botSec.container, {
            label="Bot Activé", default=false,
            onChange = function(v) if N.BotCore then N.BotCore.Toggle() end end,
        })
    end
    if botSec and C.Label then
        C.Label.new(botSec.container, {text="⚠ Le bot joue de façon entièrement automatique"})
    end

    -- ── Utility ───────────────────────────────────────
    local utilSec = F.AddSection("Utility", "Outils")
    if utilSec and C.Toggle then
        C.Toggle.new(utilSec.container, {
            label="Anti AFK", default=true,
            onChange = function(v)
                if N.AntiAFK then
                    if v then N.AntiAFK.Enable() else N.AntiAFK.Disable() end
                end
            end,
        })
        C.Toggle.new(utilSec.container, {
            label="FPS Unlock", default=false,
            onChange = function(v)
                if N.FPSUnlock then
                    if v then N.FPSUnlock.Enable(144) else N.FPSUnlock.Disable() end
                end
            end,
        })
        C.Toggle.new(utilSec.container, {
            label="Remote Spy", default=false,
            onChange = function(v)
                if N.RemoteSpy then
                    if v then N.RemoteSpy.Enable() else N.RemoteSpy.Disable() end
                end
            end,
        })
        C.Toggle.new(utilSec.container, {
            label="Admin Detector", default=true,
            onChange = function(v)
                if N.AdminDetector then
                    if v then N.AdminDetector.Enable() else N.AdminDetector.Disable() end
                end
            end,
        })
    end
    if utilSec and C.Button then
        C.Button.new(utilSec.container, {
            label="Server Hop",
            onClick = function() if N.ServerHop then N.ServerHop.Hop() end end,
        })
    end

    -- ── Config ────────────────────────────────────────
    local cfgSec = F.AddSection("Config", "Profils")
    if cfgSec and C.Button then
        C.Button.new(cfgSec.container, {
            label="Sauvegarder le profil",
            onClick = function()
                if N.Profiles and Cfg then
                    N.Profiles.Save("Default", Cfg.Current)
                    if N.Notifications then N.Notifications.Success("Config", "Profil sauvegardé ✓") end
                end
            end,
        })
        C.Button.new(cfgSec.container, {
            label="Reset profil",
            onClick = function()
                if N.Profiles then
                    N.Profiles.Reset("Default")
                    if N.Notifications then N.Notifications.Info("Config", "Profil réinitialisé") end
                end
            end,
        })
    end
    if cfgSec and C.Toggle then
        C.Toggle.new(cfgSec.container, {
            label="Watermark", default=true,
            onChange = function(v) if N.Watermark then N.Watermark.Toggle() end end,
        })
    end
    if cfgSec and C.Label then
        C.Label.new(cfgSec.container, {text="Touche panique : DELETE"})
        C.Label.new(cfgSec.container, {text="Ouvrir/Fermer : INSERT"})
    end
end

print("╔══════════════════════════════╗")
print("║  Aurora v"..VERSION.." — PRÊT  ║")
print("╚══════════════════════════════╝")
