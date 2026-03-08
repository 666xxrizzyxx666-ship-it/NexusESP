-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Utility/ChatLogger.lua
--   📁 Dossier : Modules/Utility/
--   Rôle : Log tous les messages du chat
-- ══════════════════════════════════════════════════════

local ChatLogger = {}

local Players = game:GetService("Players")

local log      = {}
local MAX_LOG  = 500
local enabled  = false
local callbacks = {}

local function addEntry(player, message)
    local entry = {
        player  = player.Name,
        userId  = player.UserId,
        message = message,
        time    = os.time(),
        clock   = os.clock(),
    }
    table.insert(log, entry)
    if #log > MAX_LOG then table.remove(log, 1) end
    for _, cb in ipairs(callbacks) do
        pcall(cb, entry)
    end
    print("[Chat] "..player.Name..": "..message)
end

local function hookPlayer(player)
    pcall(function()
        player.Chatted:Connect(function(msg)
            if not enabled then return end
            addEntry(player, msg)
        end)
    end)
end

function ChatLogger.Init(deps)
    print("[ChatLogger] Initialisé ✓")
end

function ChatLogger.Enable()
    if enabled then return end
    enabled = true

    for _, p in ipairs(Players:GetPlayers()) do
        hookPlayer(p)
    end
    Players.PlayerAdded:Connect(hookPlayer)

    print("[ChatLogger] Activé ✓")
end

function ChatLogger.Disable()
    enabled = false
    print("[ChatLogger] Désactivé")
end

function ChatLogger.GetLog()     return log  end
function ChatLogger.ClearLog()   log = {}    end
function ChatLogger.OnMessage(cb) table.insert(callbacks, cb) end
function ChatLogger.IsEnabled()  return enabled end

return ChatLogger
