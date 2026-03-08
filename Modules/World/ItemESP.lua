-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/World/ItemESP.lua
--   📁 Dossier : Modules/World/
--   Rôle : ESP des items / véhicules / NPCs
-- ══════════════════════════════════════════════════════

local ItemESP = {}

local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer

local Config  = nil
local enabled = false
local conn    = nil
local items   = {}

local function newText()
    local t = Drawing.new("Text")
    t.Visible = false
    t.Outline = false
    t.Center  = true
    t.Font    = Drawing.Fonts.Plex
    return t
end

local function newLine()
    local l = Drawing.new("Line")
    l.Visible   = false
    l.Thickness = 1
    l.Outline   = false
    return l
end

local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function ItemESP.Init(deps)
    Config = deps.Config or Config
    print("[ItemESP] Initialisé ✓")
end

function ItemESP.Enable()
    if enabled then return end
    enabled = true

    conn = RunService.RenderStepped:Connect(function()
        local cfg = Config and Config.Current and Config.Current.ItemESP
        if not cfg then return end

        local root   = getRoot()
        local maxDist = cfg.MaxDist or 500
        local color   = cfg.Color and Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B) or Color3.fromRGB(255,215,0)

        -- Cherche les tools dans workspace
        for _, item in ipairs(workspace:GetDescendants()) do
            if item:IsA("Tool") or item:IsA("Model") then
                local part = item:FindFirstChildOfClass("BasePart")
                if part then
                    local dist = root and (root.Position - part.Position).Magnitude or 9999

                    if dist <= maxDist then
                        local screen, onScreen = Camera:WorldToViewportPoint(part.Position)

                        if onScreen then
                            local key = tostring(item)
                            if not items[key] then
                                items[key] = {
                                    label  = newText(),
                                    tracer = newLine(),
                                    ref    = item,
                                }
                            end

                            local d = items[key]
                            local distStr = math.floor(dist).."m"

                            d.label.Text     = item.Name.." ["..distStr.."]"
                            d.label.Size     = 11
                            d.label.Color    = color
                            d.label.Position = Vector2.new(screen.X, screen.Y - 10)
                            d.label.Visible  = true

                            d.tracer.From    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            d.tracer.To      = Vector2.new(screen.X, screen.Y)
                            d.tracer.Color   = color
                            d.tracer.Visible = false -- optionnel
                        else
                            local key2 = tostring(item)
                            if items[key2] then
                                items[key2].label.Visible  = false
                                items[key2].tracer.Visible = false
                            end
                        end
                    end
                end
            end
        end

        -- Nettoie les items supprimés
        for key, d in pairs(items) do
            if not d.ref or not d.ref.Parent then
                pcall(function() d.label:Remove()  end)
                pcall(function() d.tracer:Remove() end)
                items[key] = nil
            end
        end
    end)

    print("[ItemESP] Activé ✓")
end

function ItemESP.Disable()
    if not enabled then return end
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    for _, d in pairs(items) do
        pcall(function() d.label:Remove()  end)
        pcall(function() d.tracer:Remove() end)
    end
    items = {}
    print("[ItemESP] Désactivé")
end

function ItemESP.Toggle()
    if enabled then ItemESP.Disable() else ItemESP.Enable() end
end

function ItemESP.IsEnabled() return enabled end

return ItemESP
