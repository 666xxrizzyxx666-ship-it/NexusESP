-- Aurora — ItemESP.lua v3.0 — exclut TOUS les persos joueurs
local ItemESP = {}

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

local enabled  = false
local maxDist  = 300
local conn     = nil
local items    = {}
local lastScan = 0

local KEYWORDS = {
    "gun","pistol","rifle","weapon","knife","bat","sword",
    "money","cash","drug","pickup","loot","ammo","grenade","bomb"
}

local function matchKeyword(name)
    local low = name:lower()
    for _, k in ipairs(KEYWORDS) do
        if low:find(k, 1, true) then return true end
    end
    return false
end

local function isPlayerPart(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if char and obj:IsDescendantOf(char) then return true end
    end
    return false
end

local function newLabel(name)
    local t = Drawing.new("Text")
    t.Visible=false t.Outline=true t.Center=true
    t.Font=Drawing.Fonts.Plex t.Size=12
    t.Color=Color3.fromRGB(255, 220, 50)
    t.Text=name
    return t
end

local function clearItems()
    for _, e in ipairs(items) do
        pcall(function() e.label:Remove() end)
    end
    items = {}
end

local function scanWorld()
    local newItems = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") or matchKeyword(obj.Name) then
            -- Ignore si c'est un Tool dans un perso joueur
            if not isPlayerPart(obj) then
                local part = obj:IsA("BasePart") and obj
                    or (obj:FindFirstChildOfClass("BasePart"))
                if part then
                    table.insert(newItems, {
                        part  = part,
                        label = newLabel(obj.Name),
                        name  = obj.Name
                    })
                end
            end
        end
    end
    clearItems()
    items = newItems
end

local function onRender()
    if not enabled then return end
    local now = tick()
    if now - lastScan > 3 then
        lastScan = now
        task.spawn(scanWorld)
    end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, e in ipairs(items) do
        if e.part and e.part.Parent and not isPlayerPart(e.part) then
            local dist = (myRoot.Position - e.part.Position).Magnitude
            if dist <= maxDist then
                local sp, onScreen = Camera:WorldToViewportPoint(e.part.Position)
                if onScreen and sp.Z > 0 then
                    e.label.Position = Vector2.new(sp.X, sp.Y - 14)
                    e.label.Text     = e.name.." ["..math.floor(dist).."m]"
                    e.label.Visible  = true
                else
                    e.label.Visible = false
                end
            else
                e.label.Visible = false
            end
        else
            e.label.Visible = false
        end
    end
end

function ItemESP.Init(deps) end

function ItemESP.Enable()
    if conn then return end
    enabled = true; lastScan = 0
    conn = RunService.RenderStepped:Connect(onRender)
end

function ItemESP.Disable()
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    clearItems()
end

function ItemESP.SetMaxDist(v) maxDist = v end

return ItemESP
