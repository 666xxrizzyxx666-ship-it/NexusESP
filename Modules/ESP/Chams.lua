-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/Chams.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Chams (highlight through walls)
-- ══════════════════════════════════════════════════════

local Chams = {}

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local activeChams = {}

local function applyChams(char, cfg)
    if not char then return end
    local color     = cfg.Color     and Color3.fromRGB(cfg.Color.R,     cfg.Color.G,     cfg.Color.B)     or Color3.fromRGB(255,0,0)
    local fillColor = cfg.FillColor and Color3.fromRGB(cfg.FillColor.R, cfg.FillColor.G, cfg.FillColor.B) or Color3.fromRGB(0,0,255)
    local trans     = cfg.Transparent or 0.5

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local box = Instance.new("SelectionBox")
            box.Adornee           = part
            box.Color3            = color
            box.SurfaceColor3     = fillColor
            box.SurfaceTransparency = trans
            box.LineThickness     = 0.02
            box.Parent            = workspace
            table.insert(activeChams, box)
        end
    end
end

local function clearChams(player)
    local data = activeChams[player]
    if not data then return end
    for _, box in ipairs(data) do
        pcall(function() box:Destroy() end)
    end
    activeChams[player] = nil
end

function Chams.Create()
    return {active = false, boxes = {}}
end

function Chams.Update(d, char, cfg)
    if not d or not char then return end

    if d.active then return end
    d.active = true

    -- Nettoie les anciens
    for _, box in ipairs(d.boxes) do
        pcall(function() box:Destroy() end)
    end
    d.boxes = {}

    local color     = cfg.Color     and Color3.fromRGB(cfg.Color.R,     cfg.Color.G,     cfg.Color.B)     or Color3.fromRGB(255,60,60)
    local fillColor = cfg.FillColor and Color3.fromRGB(cfg.FillColor.R, cfg.FillColor.G, cfg.FillColor.B) or Color3.fromRGB(60,60,255)
    local trans     = cfg.Transparent or 0.5

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local ok, box = pcall(function()
                local b = Instance.new("SelectionBox")
                b.Adornee             = part
                b.Color3              = color
                b.SurfaceColor3       = fillColor
                b.SurfaceTransparency = trans
                b.LineThickness       = 0.02
                b.Parent              = workspace
                return b
            end)
            if ok then
                table.insert(d.boxes, box)
            end
        end
    end
end

function Chams.Hide(d)
    if not d then return end
    for _, box in ipairs(d.boxes) do
        pcall(function() box.Visible = false end)
    end
    d.active = false
end

function Chams.Remove(d)
    if not d then return end
    for _, box in ipairs(d.boxes) do
        pcall(function() box:Destroy() end)
    end
    d.boxes  = {}
    d.active = false
end

return Chams
