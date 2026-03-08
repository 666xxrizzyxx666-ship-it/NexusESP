-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Security/PanicKey.lua
--   📁 Dossier : Security/
--   Rôle : Touche panique — cache tout instantanément
--          Supprime l'UI + ESP + tous les drawings
-- ══════════════════════════════════════════════════════

local PanicKey = {}

local UIS     = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local panicked    = false
local panicKey    = Enum.KeyCode.Delete
local callbacks   = {}

local function hideAllDrawings()
    -- Méthode brute : parcourt tous les Drawing actifs
    pcall(function()
        for _, v in ipairs(Drawing.GetDrawings and Drawing:GetDrawings() or {}) do
            pcall(function() v.Visible = false end)
        end
    end)
end

local function hideAllGuis()
    -- Cache les GUIs NexusESP
    local screenGuis = {
        "NexusESP_Main",
        "NexusESP_Notifs",
        "NexusESP_Watermark",
        "NexusESP_Radar",
        "NexusESP_HUD",
    }
    local cg = game:GetService("CoreGui")
    for _, name in ipairs(screenGuis) do
        local gui = cg:FindFirstChild(name)
        if gui then gui.Enabled = false end
    end

    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, name in ipairs(screenGuis) do
            local gui = pg:FindFirstChild(name)
            if gui then gui.Enabled = false end
        end
    end
end

local function restoreAll()
    panicked = false
    local cg = game:GetService("CoreGui")
    local pg = LP:FindFirstChild("PlayerGui")

    local screenGuis = {
        "NexusESP_Main",
        "NexusESP_Notifs",
        "NexusESP_Watermark",
        "NexusESP_Radar",
        "NexusESP_HUD",
    }

    for _, name in ipairs(screenGuis) do
        local gui = cg:FindFirstChild(name)
        if gui then gui.Enabled = true end
        if pg then
            local pgui = pg:FindFirstChild(name)
            if pgui then pgui.Enabled = true end
        end
    end
end

function PanicKey.Init(deps)
    local cfg = deps.Config and deps.Config.Current and deps.Config.Current.PanicKey
    if cfg and cfg.Key then
        pcall(function()
            panicKey = Enum.KeyCode[cfg.Key]
        end)
    end

    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == panicKey then
            if panicked then
                PanicKey.Restore()
            else
                PanicKey.Panic()
            end
        end
    end)

    print("[PanicKey] Initialisé — touche : "..panicKey.Name.." ✓")
end

function PanicKey.Panic()
    if panicked then return end
    panicked = true

    -- 1. Cache tous les drawings
    hideAllDrawings()

    -- 2. Cache tous les GUIs
    hideAllGuis()

    -- 3. Notifie les callbacks (pour désactiver ESP/aimbot loop)
    for _, cb in ipairs(callbacks) do
        pcall(cb, true)
    end

    print("[PanicKey] 🚨 PANIC — tout caché")
end

function PanicKey.Restore()
    restoreAll()

    for _, cb in ipairs(callbacks) do
        pcall(cb, false)
    end

    print("[PanicKey] ✓ Restauré")
end

function PanicKey.OnPanic(callback)
    table.insert(callbacks, callback)
end

function PanicKey.SetKey(keyCode)
    panicKey = keyCode
end

function PanicKey.IsPanicked()
    return panicked
end

return PanicKey
