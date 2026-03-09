-- Aurora — Modules/World/ItemESP.lua v2.0
-- Scan lent (pas chaque frame) pour eviter le lag
local ItemESP = {}

local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LP         = game:GetService("Players").LocalPlayer

local enabled  = false
local maxDist  = 300
local conn     = nil
local items    = {}   -- { {part, label} }
local lastScan = 0

local KEYWORDS = {
    "gun","pistol","rifle","weapon","knife","bat","sword",
    "money","cash","drug","item","pickup","loot","ammo","health",
    "med","grenade","bomb","tool"
}

local function matchesKeyword(name)
    local low = name:lower()
    for _, k in ipairs(KEYWORDS) do
        if low:find(k) then return true end
    end
    return false
end

local function newLabel(name)
    local t = Drawing.new("Text")
    t.Visible   = false
    t.Outline   = true
    t.Center    = true
    t.Font      = Drawing.Fonts.Plex
    t.Size      = 12
    t.Color     = Color3.fromRGB(255, 220, 50)
    t.Text      = name
    return t
end

local function clearItems()
    for _, entry in ipairs(items) do
        pcall(function() entry.label:Remove() end)
    end
    items = {}
end

local function scanWorld()
    clearItems()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") or matchesKeyword(obj.Name) then
            local part = obj:IsA("BasePart") and obj
                or (obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart"))
                or (obj:IsA("Tool") and obj:FindFirstChildOfClass("BasePart"))
            if part and part:IsDescendantOf(workspace) and not part:IsDescendantOf(game:GetService("Players").LocalPlayer.Character or workspace) then
                table.insert(items, { part = part, label = newLabel(obj.Name) })
            end
        end
    end
end

local function onRender()
    if not enabled then return end

    local now = tick()
    if now - lastScan > 3 then
        lastScan = now
        pcall(scanWorld)
    end

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
                    label.Position = Vector2.new(sp.X, sp.Y - 14)
                    label.Text     = entry.part.Parent and entry.part.Parent.Name or part.Name
                    label.Text     = label.Text .. " [" .. math.floor(dist) .. "m]"
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
    if conn then return end
    enabled  = true
    lastScan = 0
    conn = RunService.RenderStepped:Connect(onRender)
end

function ItemESP.Disable()
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    clearItems()
end

function ItemESP.SetMaxDist(v)
    maxDist = v
end

return ItemESP
