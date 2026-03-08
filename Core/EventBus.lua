-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Core/EventBus.lua
--   Rôle : Bus d'événements central
--          Tous les modules communiquent via EventBus
--          Pas de dépendances directes entre modules
-- ══════════════════════════════════════════════════════

local EventBus = {}

local Signal = nil
local events = {}
local history = {}
local MAX_HISTORY = 100

function EventBus.Init()
    Signal = getgenv().NexusESP and getgenv().NexusESP.Signal
    if not Signal then
        -- Fallback si Signal pas encore chargé
        Signal = require and require("Core/Signal") or {}
    end
    events  = {}
    history = {}
end

-- Récupère ou crée un signal pour un événement
local function getEvent(name)
    if not events[name] then
        events[name] = Signal.new()
    end
    return events[name]
end

-- S'abonne à un événement
function EventBus.Subscribe(name, fn)
    return getEvent(name):Connect(fn)
end

-- Publie un événement
function EventBus.Publish(name, ...)
    -- Historique
    table.insert(history, {name=name, time=os.clock(), args={...}})
    if #history > MAX_HISTORY then
        table.remove(history, 1)
    end
    -- Fire
    getEvent(name):Fire(...)
end

-- Alias
EventBus.On   = EventBus.Subscribe
EventBus.Emit = EventBus.Publish

-- Publie une seule fois
function EventBus.Once(name, fn)
    local conn
    conn = getEvent(name):Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

-- Attend un événement (bloquant)
function EventBus.Wait(name)
    return getEvent(name):Wait()
end

-- Désinscrit tout pour un événement
function EventBus.Clear(name)
    if events[name] then
        events[name]:DisconnectAll()
    end
end

-- Liste des événements actifs
function EventBus.GetEvents()
    local list = {}
    for name in pairs(events) do
        table.insert(list, name)
    end
    return list
end

function EventBus.GetHistory()
    return history
end

-- ── Événements standards NexusESP ─────────────────────
-- Ces événements sont publiés automatiquement par le Core
--
-- "ESP:PlayerAdded"     → nouveau joueur
-- "ESP:PlayerRemoving"  → joueur part
-- "ESP:Render"          → chaque frame
-- "ESP:Enabled"         → ESP activé
-- "ESP:Disabled"        → ESP désactivé
-- "UI:Ready"            → UI chargée
-- "UI:Toggle"           → UI toggle
-- "Key:Validated"       → clé validée
-- "Key:Invalid"         → clé invalide
-- "AC:Detected"         → anti-cheat détecté
-- "AC:Bypassed"         → bypass appliqué
-- "Game:Detected"       → jeu détecté
-- "Panic"               → panic key pressée
-- "Shutdown"            → shutdown demandé

return EventBus
