-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Game/Games/Fisch/Init.lua
--   📁 Dossier : Game/Games/Fisch/
--   Rôle : Exploits Fisch (fishing game)
--          Auto-fish / ESP poissons / Valeurs
-- ══════════════════════════════════════════════════════

local Fisch = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Notify     = nil

local autoFishConn = nil
local autoFishing  = false

-- ── Trouver le mini-jeu de pêche ─────────────────────
local function getFishingGui()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    -- Cherche le GUI de pêche
    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name:lower():find("fish") or gui.Name:lower():find("catch") then
            return gui
        end
    end
    return nil
end

local function getFishRemote()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n = v.Name:lower()
            if n:find("fish") or n:find("catch") or n:find("reel") then
                return v
            end
        end
    end
    return nil
end

-- ── Auto Fish ─────────────────────────────────────────
function Fisch.StartAutoFish()
    if autoFishing then return end
    autoFishing = true

    autoFishConn = RunService.Heartbeat:Connect(function()
        if not autoFishing then return end

        local remote = getFishRemote()
        if not remote then return end

        -- Cherche les événements de pêche dans le GUI
        local gui = getFishingGui()
        if gui then
            -- Clique les boutons automatiquement
            for _, btn in ipairs(gui:GetDescendants()) do
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    local n = btn.Name:lower()
                    if n:find("reel") or n:find("catch") or n:find("click") then
                        if btn.Visible then
                            pcall(function()
                                btn.MouseButton1Click:Fire()
                            end)
                        end
                    end
                end
            end
        end

        -- Fire le remote directement
        pcall(function() remote:FireServer("AutoCatch") end)
    end)

    if Notify then Notify.Success("Fisch", "Auto-fish activé ✓") end
end

function Fisch.StopAutoFish()
    autoFishing = false
    if autoFishConn then
        autoFishConn:Disconnect()
        autoFishConn = nil
    end
    if Notify then Notify.Info("Fisch", "Auto-fish désactivé") end
end

-- ── ESP Poissons ──────────────────────────────────────
local fishDrawings = {}

function Fisch.EnableFishESP()
    local Camera = workspace.CurrentCamera
    local conn   = RunService.RenderStepped:Connect(function()
        -- Nettoie les anciens drawings
        for _, d in pairs(fishDrawings) do
            pcall(function() d:Remove() end)
        end
        fishDrawings = {}

        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for _, v in ipairs(workspace:GetDescendants()) do
            local n = v.Name:lower()
            if v:IsA("BasePart") and (n:find("fish") or n:find("bobber") or n:find("lure")) then
                local screen, onScreen = Camera:WorldToViewportPoint(v.Position)
                if onScreen then
                    local dist = (root.Position - v.Position).Magnitude
                    local t = Drawing.new("Text")
                    t.Text     = "🐟 "..v.Name.." ["..math.floor(dist).."m]"
                    t.Size     = 12
                    t.Color    = Color3.fromRGB(0,200,255)
                    t.Position = Vector2.new(screen.X, screen.Y)
                    t.Center   = true
                    t.Outline  = false
                    t.Visible  = true
                    table.insert(fishDrawings, t)
                end
            end
        end
    end)
    return conn
end

-- ── Vitesse de pêche ─────────────────────────────────
function Fisch.SetFishSpeed(multiplier)
    multiplier = multiplier or 5
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("NumberValue") and v.Name:lower():find("speed") then
            if v:IsDescendantOf(LP) then
                v.Value = v.Value * multiplier
            end
        end
    end
    if Notify then Notify.Success("Fisch", "Speed ×"..multiplier) end
end

function Fisch.Init(deps)
    Notify = deps.Notify
    print("[Fisch] Module initialisé ✓")
end

return Fisch
