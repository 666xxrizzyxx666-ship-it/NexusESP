-- ══════════════════════════════════════════════════════════════════
--   Aurora v5.2.0 — Main.lua — TOUT EN UN FICHIER
--   Push UNIQUEMENT ce fichier sur GitHub, rien d'autre
-- ══════════════════════════════════════════════════════════════════
local VERSION = "5.3.0"

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════════════
-- ESP ENGINE
-- ══════════════════════════════════════════════════════════════════
local opt = {
    Enabled   = false,
    Box       = false,
    BoxStyle  = "2D Normal",
    BoxColor  = Color3.fromRGB(255, 255, 255),
    TeamCheck = false,
    WallCheck = false,
    MaxDist   = 500,
    Skeleton  = false,
}

local playerData = {}

-- Drawing helpers
local function newLine()
    local l = Drawing.new("Line")
    l.Visible      = false
    l.Thickness    = 1
    l.Color        = Color3.new(1,1,1)
    l.Transparency = 1
    l.ZIndex       = 2
    return l
end

-- Bones R15 + R6
local BONES_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"RightUpperLeg","RightLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},{"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},{"RightUpperArm","RightLowerArm"},
    {"LeftLowerArm","LeftHand"},{"RightLowerArm","RightHand"},
}
local BONES_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local MAX_BONES = #BONES_R15

-- Bounding box
local function getBB(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not root or not head then return nil end
    local hs = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y/2, 0))
    local fs = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    if hs.Z <= 0 or fs.Z <= 0 then return nil end
    local h = math.abs(hs.Y - fs.Y)
    if h < 5 then return nil end
    local w  = h * 0.55
    local cx = (hs.X + fs.X) / 2
    return { x=cx-w/2, y=hs.Y, width=w, height=h, cx=cx, botY=fs.Y }
end

-- Créer drawings pour un joueur
local function createDrawings()
    local box = {}; for i=1,4 do box[i] = newLine() end
    local cor = {}; for i=1,8 do cor[i] = newLine() end
    local sk  = {}; for i=1,MAX_BONES do sk[i] = newLine() end
    return { box=box, cor=cor, sk=sk }
end

-- Supprimer drawings
local function removeDrawings(d)
    if not d then return end
    for i=1,4 do pcall(function() d.box[i]:Remove() end) end
    for i=1,8 do pcall(function() d.cor[i]:Remove() end) end
    if d.sk then for i=1,MAX_BONES do pcall(function() d.sk[i]:Remove() end) end end
end

-- Cacher drawings
local function hideDrawings(d)
    if not d then return end
    for i=1,4 do d.box[i].Visible = false end
    for i=1,8 do d.cor[i].Visible = false end
    if d.sk then for i=1,MAX_BONES do d.sk[i].Visible = false end end
end

-- Box 2D normale
local function drawBox(d, bb, col)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    d.box[1].From=Vector2.new(x,y)     d.box[1].To=Vector2.new(x+w,y)
    d.box[2].From=Vector2.new(x,y+h)   d.box[2].To=Vector2.new(x+w,y+h)
    d.box[3].From=Vector2.new(x,y)     d.box[3].To=Vector2.new(x,y+h)
    d.box[4].From=Vector2.new(x+w,y)   d.box[4].To=Vector2.new(x+w,y+h)
    for i=1,4 do
        d.box[i].Color     = col
        d.box[i].Thickness = 1
        d.box[i].Visible   = true
    end
    for i=1,8 do d.cor[i].Visible = false end
end

-- Corner Box
local function drawCorner(d, bb, col)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    local cw, ch = w*0.28, h*0.28
    d.cor[1].From=Vector2.new(x,y)         d.cor[1].To=Vector2.new(x+cw,y)
    d.cor[2].From=Vector2.new(x,y)         d.cor[2].To=Vector2.new(x,y+ch)
    d.cor[3].From=Vector2.new(x+w-cw,y)   d.cor[3].To=Vector2.new(x+w,y)
    d.cor[4].From=Vector2.new(x+w,y)       d.cor[4].To=Vector2.new(x+w,y+ch)
    d.cor[5].From=Vector2.new(x,y+h-ch)   d.cor[5].To=Vector2.new(x,y+h)
    d.cor[6].From=Vector2.new(x,y+h)       d.cor[6].To=Vector2.new(x+cw,y+h)
    d.cor[7].From=Vector2.new(x+w,y+h-ch) d.cor[7].To=Vector2.new(x+w,y+h)
    d.cor[8].From=Vector2.new(x+w-cw,y+h) d.cor[8].To=Vector2.new(x+w,y+h)
    for i=1,8 do
        d.cor[i].Color     = col
        d.cor[i].Thickness = 1
        d.cor[i].Visible   = true
    end
    for i=1,4 do d.box[i].Visible = false end
end

-- Draw skeleton
local function drawSkeleton(sk, char)
    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and BONES_R15 or BONES_R6
    for i = 1, MAX_BONES do
        local line = sk[i]
        local bone = bones[i]
        if bone then
            local pA = char:FindFirstChild(bone[1])
            local pB = char:FindFirstChild(bone[2])
            if pA and pB then
                local sA = Camera:WorldToViewportPoint(pA.Position)
                local sB = Camera:WorldToViewportPoint(pB.Position)
                if sA.Z > 0 and sB.Z > 0 then
                    line.From      = Vector2.new(sA.X, sA.Y)
                    line.To        = Vector2.new(sB.X, sB.Y)
                    line.Color     = Color3.new(1,1,1)
                    line.Thickness = 1
                    line.Visible   = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

-- Render un joueur
local function renderPlayer(player, d)
    local char = player.Character
    if not char then hideDrawings(d) return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then hideDrawings(d) return end
    local sp = Camera:WorldToViewportPoint(root.Position)
    if sp.Z <= 0 then hideDrawings(d) return end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local dist   = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 9999
    if dist > opt.MaxDist then hideDrawings(d) return end
    if opt.TeamCheck and LP.Team and player.Team and LP.Team == player.Team then
        hideDrawings(d) return
    end
    local bb = getBB(char)
    if not bb then hideDrawings(d) return end

    if opt.Box then
        if opt.BoxStyle == "Corner Box" then
            drawCorner(d, bb, opt.BoxColor)
        else
            drawBox(d, bb, opt.BoxColor)
        end
    else
        for i=1,4 do d.box[i].Visible = false end
        for i=1,8 do d.cor[i].Visible = false end
    end

    -- Skeleton
    if opt.Skeleton and d.sk then
        drawSkeleton(d.sk, char)
    else
        if d.sk then for i=1,MAX_BONES do d.sk[i].Visible = false end end
    end
end

-- Render loop
RunService.RenderStepped:Connect(function()
    if not opt.Enabled then return end
    for player, d in pairs(playerData) do
        if not player or not player.Parent then
            removeDrawings(d)
            playerData[player] = nil
        else
            pcall(renderPlayer, player, d)
        end
    end
end)

-- Gestion joueurs
local function addPlayer(p)
    if playerData[p] then return end
    playerData[p] = createDrawings()
    p.CharacterRemoving:Connect(function()
        if playerData[p] then hideDrawings(playerData[p]) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then addPlayer(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LP then addPlayer(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    if playerData[p] then
        removeDrawings(playerData[p])
        playerData[p] = nil
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════════════
-- UI FLUENT
-- ══════════════════════════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title       = "Aurora  •  v"..VERSION,
    SubTitle    = "Box ESP Test",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 400),
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.Insert,
})

local Tab = Window:AddTab({ Title="ESP", Icon="eye" })

Tab:AddToggle("ESPEnabled", {
    Title    = "ESP",
    Default  = false,
    Callback = function(v)
        opt.Enabled = v
        if not v then
            for _, d in pairs(playerData) do hideDrawings(d) end
        end
    end,
})

Tab:AddToggle("ESPBox", {
    Title    = "Box",
    Default  = false,
    Callback = function(v) opt.Box = v end,
})

Tab:AddDropdown("ESPBoxStyle", {
    Title    = "Style Box",
    Default  = "2D Normal",
    Values   = {"2D Normal", "Corner Box"},
    Callback = function(v) opt.BoxStyle = v end,
})

Tab:AddToggle("ESPSkeleton", {
    Title    = "Skeleton",
    Default  = false,
    Callback = function(v) opt.Skeleton = v end,
})

Window:SelectTab(1)
print("[Aurora v"..VERSION.."] Chargé")
