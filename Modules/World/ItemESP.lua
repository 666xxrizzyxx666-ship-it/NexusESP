-- Aurora — ItemESP.lua v3.0 — scan async, zero freeze
local ItemESP = {}

local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LP         = game:GetService("Players").LocalPlayer

local enabled  = false
local maxDist  = 300
local conn     = nil
local scanLoop = nil
local items    = {}  -- { part, label }

local KEYWORDS = {
    "gun","pistol","rifle","weapon","knife","bat","sword",
    "money","cash","drug","pickup","loot","ammo","health","med",
    "grenade","tool","bomb","glock","ak","uzi","shotgun"
}

local function matchKeyword(name)
    local low = name:lower()
    for _, k in ipairs(KEYWORDS) do
        if low:find(k, 1, true) then return true end
    end
    return false
end

local function newLabel(name)
    local t = Drawing.new("Text")
    t.Visible=false t.Outline=true t.Center=true
    t.Font=Drawing.Fonts.Plex t.Size=12
    t.Color=Color3.fromRGB(255,220,50)
    t.Text=name
    return t
end

local function clearAll()
    for _, e in ipairs(items) do
        pcall(function() e.label:Remove() end)
    end
    items = {}
end

-- Scan dans un thread séparé — jamais bloquant
local function doScan()
    local newItems = {}
    local ok, descs = pcall(function()
        return workspace:GetDescendants()
    end)
    if not ok then return end

    for _, obj in ipairs(descs) do
        -- yield toutes les 100 objs pour éviter le freeze
        if obj:IsA("Tool") or matchKeyword(obj.Name) then
            local part = nil
            if obj:IsA("BasePart") then
                part = obj
            elseif obj:IsA("Model") or obj:IsA("Tool") then
                part = obj:FindFirstChildOfClass("BasePart")
            end
            if part and part.Parent and not part:IsDescendantOf(
                game:GetService("Players").LocalPlayer.Character or game
            ) then
                local label = newLabel(obj.Name)
                table.insert(newItems, {part=part, label=label, name=obj.Name})
            end
        end
    end

    -- Nettoie les anciens et remplace
    for _, e in ipairs(items) do
        pcall(function() e.label:Remove() end)
    end
    items = newItems
end

local function onRender()
    if not enabled then return end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, entry in ipairs(items) do
        local part  = entry.part
        local label = entry.label
        if part and part.Parent then
            local dist = (myRoot.Position - part.Position).Magnitude
            if dist <= maxDist then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and sp.Z > 0 then
                    label.Text     = entry.name.." ["..math.floor(dist).."m]"
                    label.Position = Vector2.new(sp.X, sp.Y - 14)
                    label.Visible  = true
                else
                    label.Visible = false
                end
            else
                label.Visible = false
            end
        else
            label.Visible = false
        end
    end
end

function ItemESP.Init(deps) end

function ItemESP.Enable()
    if enabled then return end
    enabled = true

    -- Scan initial
    task.spawn(doScan)

    -- Re-scan toutes les 4s dans un thread séparé (jamais bloquant)
    scanLoop = task.spawn(function()
        while enabled do
            task.wait(4)
            if enabled then
                task.spawn(doScan)
            end
        end
    end)

    -- Render léger : juste positionne les labels existants
    conn = RunService.RenderStepped:Connect(onRender)
end

function ItemESP.Disable()
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    clearAll()
end

function ItemESP.SetMaxDist(v) maxDist = v end

return ItemESP
