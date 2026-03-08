-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Main.lua
--   📁 Racine du projet
--   Rôle : Point d'entrée principal
--          Charge et connecte tous les modules
-- ══════════════════════════════════════════════════════

local VERSION = "3.0.4"
local REPO    = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

print("╔══════════════════════════════╗")
print("║  NexusESP v"..VERSION.."           ║")
print("║  Loading...                  ║")
print("╚══════════════════════════════╝")

local function load(path)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(REPO..path, true))()
    end)
    if not ok then
        warn("[NexusESP] Erreur : "..path.." → "..tostring(result))
        return nil
    end
    return result
end

getgenv().NexusESP = {}
local N = getgenv().NexusESP

-- ── Phase 1 : Core ────────────────────────────────────
print("[NexusESP] Core...")
N.Signal   = load("Core/Signal.lua")
N.EventBus = load("Core/EventBus.lua")
N.Thread   = load("Core/Thread.lua")
N.Memory   = load("Core/Memory.lua")
if N.EventBus then N.EventBus.Init() end

-- ── Phase 2 : Config ──────────────────────────────────
print("[NexusESP] Config...")
N.Profiles = load("Config/Profiles.lua")
N.Config   = load("Config/Manager.lua")
if N.Profiles then N.Profiles.Init() end
if N.Config   then
    N.Config.Init()
    local profileConfig = N.Profiles and N.Profiles.Load("Default")
    if profileConfig then N.Config.SetAll(profileConfig) end
end

-- ── Phase 3 : Network / Key ───────────────────────────
print("[NexusESP] Network/Key...")
N.Firebase  = load("Network/Firebase.lua")
N.Updater   = load("Network/Updater.lua")
N.KeySystem = load("Security/KeySystem.lua")
if N.KeySystem then
    local valid = N.KeySystem.Validate()
    if not valid then warn("[NexusESP] Clé invalide — arrêt"); return end
end
N.Detector     = load("Security/Detector.lua")
N.GenericBypass = load("Security/GenericBypass.lua")
if N.Detector      then N.Detector.Init({Config=N.Config}) end
if N.GenericBypass then N.GenericBypass.Init() end

-- ── Phase 4 : Utils ───────────────────────────────────
N.Utils = load("Modules/Utils.lua")

-- ── Phase 5 : UI ──────────────────────────────────────
print("[NexusESP] UI...")
N.Theme         = load("UI/Theme.lua")
N.Animation     = load("UI/Animation.lua")
N.Notifications = load("UI/Notifications.lua")
N.Watermark     = load("UI/Watermark.lua")
N.Framework     = load("UI/Framework.lua")

if N.Animation     then N.Animation.Init(N.Theme) end
if N.Notifications then N.Notifications.Init(N.Theme, N.Animation) end
if N.Watermark     then N.Watermark.Init(N.Theme, N.Animation) end

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
print("[NexusESP] AI...")
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
print("[NexusESP] ESP...")
N.ESP = load("Modules/ESP/ESP.lua")
if N.ESP then
    N.ESP.Init({Utils=N.Utils, Config=N.Config, EventBus=N.EventBus})
    N.ESP.Enable()
end

-- ── Phase 8 : Combat ──────────────────────────────────
print("[NexusESP] Combat...")
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
print("[NexusESP] Movement...")
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
print("[NexusESP] World/Utility...")
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
print("[NexusESP] Security...")
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
print("[NexusESP] Game Specific...")
N.GameDetector = load("Game/Detector.lua")
if N.GameDetector then
    N.GameDetector.Init({Notify=N.Notifications, Utils=N.Utils})
    local gameId = N.GameDetector.Detect()
    print("[NexusESP] Jeu : "..tostring(gameId))

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
    N.Notifications.Success("NexusESP v"..VERSION, "Chargé ! Appuie sur Insert", 5)
end

print("╔══════════════════════════════╗")
print("║  NexusESP v"..VERSION.." — PRÊT  ║")
print("╚══════════════════════════════╝")
