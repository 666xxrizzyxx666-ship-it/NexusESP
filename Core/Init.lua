-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Core/Init.lua
--   Rôle    : Bootstrap principal, détection executor,
--             chargement des modules dans l'ordre
--   Auteur  : Privé
-- ══════════════════════════════════════════════════════

local Init = {}

-- ── Constantes ────────────────────────────────────────
local VERSION  = "3.0.0"
local REPO     = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"
local MIN_EXECUTOR_LEVEL = 7

-- ── Services ──────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ── Détection executor ────────────────────────────────
local function detectExecutor()
    if syn         then return "Synapse"  end
    if KRNL_ENV    then return "KRNL"     end
    if fluxus      then return "Fluxus"   end
    if Wave        then return "Wave"     end
    if getexecutorname then
        return getexecutorname()
    end
    return "Unknown"
end

-- ── Protect GUI selon executor ────────────────────────
local function protectGui(gui)
    if syn and syn.protect_gui then
        pcall(function() syn.protect_gui(gui) end)
    elseif fluxus and fluxus.protect_gui then
        pcall(function() fluxus.protect_gui(gui) end)
    elseif protectgui then
        pcall(function() protectgui(gui) end)
    end
end

-- ── Loader de modules ─────────────────────────────────
local loaded  = {}
local failed  = {}

local function load(path)
    if loaded[path] then return loaded[path] end
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(REPO .. path, true))()
    end)
    if ok and result then
        loaded[path] = result
        return result
    else
        table.insert(failed, {path=path, err=tostring(result)})
        warn("[NexusESP] FAILED: " .. path .. "\n" .. tostring(result))
        return nil
    end
end

-- ── Vérification niveau executor ──────────────────────
local function checkExecutorLevel()
    if not getgenv then
        warn("[NexusESP] Executor trop limité")
        return false
    end
    return true
end

-- ── Init principal ────────────────────────────────────
function Init.Start()
    print("╔══════════════════════════════════╗")
    print("║   NexusESP v" .. VERSION .. "              ║")
    print("║   Chargement en cours...         ║")
    print("╚══════════════════════════════════╝")

    -- Vérification executor
    if not checkExecutorLevel() then return end

    -- Détection executor
    local executor = detectExecutor()
    print("[NexusESP] Executor : " .. executor)

    -- Expose globals
    getgenv().NexusESP = {
        Version      = VERSION,
        Executor     = executor,
        ProtectGui   = protectGui,
        Load         = load,
        Loaded       = loaded,
        Failed       = failed,
        StartTime    = os.clock(),
    }

    -- Charge les modules Core en premier
    print("[NexusESP] Chargement Core...")
    local Signal   = load("Core/Signal.lua")
    local EventBus = load("Core/EventBus.lua")
    local Thread   = load("Core/Thread.lua")
    local Memory   = load("Core/Memory.lua")

    if not Signal or not EventBus or not Thread or not Memory then
        warn("[NexusESP] Core modules manquants — arrêt")
        return
    end

    -- Init Core
    Signal.Init()
    EventBus.Init()
    Thread.Init()
    Memory.Init()

    getgenv().NexusESP.Signal   = Signal
    getgenv().NexusESP.EventBus = EventBus
    getgenv().NexusESP.Thread   = Thread
    getgenv().NexusESP.Memory   = Memory

    print("[NexusESP] Core OK")

    -- Charge Config
    print("[NexusESP] Chargement Config...")
    local Config = load("Config/Manager.lua")
    if not Config then
        warn("[NexusESP] Config manquant — arrêt")
        return
    end
    Config:Init()
    getgenv().NexusESP.Config = Config
    print("[NexusESP] Config OK")

    -- Charge Network
    print("[NexusESP] Chargement Network...")
    local Firebase  = load("Network/Firebase.lua")
    local Updater   = load("Network/Updater.lua")
    if Firebase then
        Firebase.Init()
        getgenv().NexusESP.Firebase = Firebase
    end
    if Updater then
        Updater.Check(VERSION)
        getgenv().NexusESP.Updater = Updater
    end
    print("[NexusESP] Network OK")

    -- Charge Security
    print("[NexusESP] Chargement Security...")
    local KeySystem = load("Security/KeySystem.lua")
    local Detector  = load("Security/Detector.lua")
    if not KeySystem then
        warn("[NexusESP] KeySystem manquant — arrêt")
        return
    end
    getgenv().NexusESP.KeySystem = KeySystem
    getgenv().NexusESP.Detector  = Detector
    print("[NexusESP] Security OK")

    -- Lance le Key System (bloque jusqu'à validation)
    print("[NexusESP] Validation clé...")
    KeySystem.Show(function(valid)
        if not valid then
            warn("[NexusESP] Clé invalide — arrêt")
            return
        end
        print("[NexusESP] Clé validée ✓")
        Init._loadMain()
    end)
end

-- ── Chargement principal après clé validée ────────────
function Init._loadMain()
    print("[NexusESP] Chargement modules principaux...")

    local NexusESP = getgenv().NexusESP

    -- Utils
    local Utils = load("Modules/Utils.lua")
    if not Utils then warn("[NexusESP] Utils manquant"); return end
    NexusESP.Utils = Utils

    -- Détection Anti-Cheat
    if NexusESP.Detector then
        print("[NexusESP] Scan anti-cheat...")
        local acInfo = NexusESP.Detector.Scan()
        if acInfo.hasAC then
            print("[NexusESP] AC détecté : " .. acInfo.acName)
            local bypass = load("Security/Bypasses/" .. acInfo.acName .. ".lua")
            if bypass then
                bypass.Apply()
                print("[NexusESP] Bypass appliqué : " .. acInfo.acName)
            else
                local genericBypass = load("Security/GenericBypass.lua")
                if genericBypass then
                    genericBypass.Apply(acInfo.checks)
                    print("[NexusESP] Bypass générique appliqué")
                end
            end
        else
            print("[NexusESP] Aucun AC détecté")
        end
    end

    -- Game Detection
    print("[NexusESP] Détection du jeu...")
    local GameDetector = load("Game/Detector.lua")
    if GameDetector then
        local gameName = GameDetector.Detect()
        print("[NexusESP] Jeu : " .. gameName)
        NexusESP.Game = gameName
        local gameModule = load("Game/Games/" .. gameName .. "/Init.lua")
        if gameModule then
            gameModule.Init()
            NexusESP.GameModule = gameModule
        end
    end

    -- ESP Modules
    print("[NexusESP] Chargement ESP...")
    local ESP = load("Modules/ESP/ESP.lua")
    if ESP then
        ESP.Init({
            Utils   = Utils,
            Config  = NexusESP.Config,
            EventBus = NexusESP.EventBus,
        })
        NexusESP.ESP = ESP
    end

    -- UI
    print("[NexusESP] Chargement UI...")
    local UI = load("UI/Framework.lua")
    if UI then
        UI.Init({
            Config   = NexusESP.Config,
            Version  = NexusESP.Version,
            Executor = NexusESP.Executor,
            Game     = NexusESP.Game,
        })
        NexusESP.UI = UI
    end

    -- Panic key
    local UIS = game:GetService("UserInputService")
    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            if NexusESP.ESP  then NexusESP.ESP.HideAll()  end
            if NexusESP.UI   then NexusESP.UI.Hide()      end
            print("[NexusESP] PANIC — tout caché")
        end
        if i.KeyCode == Enum.KeyCode.RightControl then
            if NexusESP.UI then NexusESP.UI.Toggle() end
        end
    end)

    local elapsed = math.floor((os.clock() - NexusESP.StartTime) * 1000)
    print("╔══════════════════════════════════╗")
    print("║   NexusESP v" .. NexusESP.Version .. " PRÊT         ║")
    print("║   Chargé en " .. elapsed .. "ms                ║")
    print("║   RightCtrl  = toggle menu       ║")
    print("║   RightShift = panic key         ║")
    print("╚══════════════════════════════════╝")
end

return Init
