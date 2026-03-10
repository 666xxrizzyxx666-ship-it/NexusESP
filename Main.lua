-- ══════════════════════════════════════════════════════════════════
--   Aurora v5.4.0 — Main.lua — TOUT EN UN FICHIER
-- ══════════════════════════════════════════════════════════════════
local VERSION = "5.4.0"

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════════════
-- OPTIONS
-- ══════════════════════════════════════════════════════════════════
local opt = {
    Box       = false,
    BoxStyle  = "Box",
    BoxColor  = Color3.fromRGB(255, 255, 255),
    Skeleton  = false,
    SkelColor = Color3.fromRGB(255, 255, 255),
    Tracers   = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    MaxDist   = 500,
}

local function anyEnabled()
    return opt.Box or opt.Skeleton or opt.Tracers
end

-- ══════════════════════════════════════════════════════════════════
-- DRAWING HELPERS
-- ══════════════════════════════════════════════════════════════════
local function newLine()
    local l = Drawing.new("Line")
    l.Visible      = false
    l.Thickness    = 1
    l.Color        = Color3.new(1,1,1)
    l.Transparency = 1
    l.ZIndex       = 2
    return l
end

-- ══════════════════════════════════════════════════════════════════
-- SKELETON BONES
-- ══════════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════════
-- PLAYER DRAWINGS
-- ══════════════════════════════════════════════════════════════════
local playerData = {}

local function createDrawings()
    local box = {}; for i=1,4 do box[i] = newLine() end
    local cor = {}; for i=1,8 do cor[i] = newLine() end
    local sk  = {}; for i=1,MAX_BONES do sk[i] = newLine() end
    local tr  = newLine()
    return { box=box, cor=cor, sk=sk, tr=tr }
end

local function hideDrawings(d)
    if not d then return end
    for i=1,4 do d.box[i].Visible = false end
    for i=1,8 do d.cor[i].Visible = false end
    for i=1,MAX_BONES do d.sk[i].Visible = false end
    d.tr.Visible = false
end

local function removeDrawings(d)
    if not d then return end
    for i=1,4 do pcall(function() d.box[i]:Remove() end) end
    for i=1,8 do pcall(function() d.cor[i]:Remove() end) end
    for i=1,MAX_BONES do pcall(function() d.sk[i]:Remove() end) end
    pcall(function() d.tr:Remove() end)
end

-- ══════════════════════════════════════════════════════════════════
-- BOUNDING BOX
-- ══════════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════════
-- DRAW FUNCTIONS
-- ══════════════════════════════════════════════════════════════════
local function drawBox(d, bb, col)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    d.box[1].From=Vector2.new(x,y)   d.box[1].To=Vector2.new(x+w,y)
    d.box[2].From=Vector2.new(x,y+h) d.box[2].To=Vector2.new(x+w,y+h)
    d.box[3].From=Vector2.new(x,y)   d.box[3].To=Vector2.new(x,y+h)
    d.box[4].From=Vector2.new(x+w,y) d.box[4].To=Vector2.new(x+w,y+h)
    for i=1,4 do d.box[i].Color=col d.box[i].Visible=true end
    for i=1,8 do d.cor[i].Visible=false end
end

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
    for i=1,8 do d.cor[i].Color=col d.cor[i].Visible=true end
    for i=1,4 do d.box[i].Visible=false end
end

local function drawSkeleton(sk, char, col)
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
                    line.From    = Vector2.new(sA.X, sA.Y)
                    line.To      = Vector2.new(sB.X, sB.Y)
                    line.Color   = col
                    line.Visible = true
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

local function drawTracer(d, bb, col)
    local vp = Camera.ViewportSize
    d.tr.From      = Vector2.new(vp.X/2, vp.Y)
    d.tr.To        = Vector2.new(bb.cx, bb.botY)
    d.tr.Color     = col
    d.tr.Thickness = 1
    d.tr.Visible   = true
end

-- ══════════════════════════════════════════════════════════════════
-- RENDER
-- ══════════════════════════════════════════════════════════════════
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

    local bb = getBB(char)

    -- Box
    if opt.Box and bb then
        if opt.BoxStyle == "CornerBox" then
            drawCorner(d, bb, opt.BoxColor)
        else
            drawBox(d, bb, opt.BoxColor)
        end
    else
        for i=1,4 do d.box[i].Visible=false end
        for i=1,8 do d.cor[i].Visible=false end
    end

    -- Skeleton
    if opt.Skeleton then
        drawSkeleton(d.sk, char, opt.SkelColor)
    else
        for i=1,MAX_BONES do d.sk[i].Visible=false end
    end

    -- Tracers
    if opt.Tracers and bb then
        drawTracer(d, bb, opt.TracerColor)
    else
        d.tr.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if not anyEnabled() then return end
    for player, d in pairs(playerData) do
        if not player or not player.Parent then
            removeDrawings(d)
            playerData[player] = nil
        else
            pcall(renderPlayer, player, d)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- GESTION JOUEURS
-- ══════════════════════════════════════════════════════════════════
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
-- UI FLUENT
-- ══════════════════════════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title       = "Aurora  •  v"..VERSION,
    SubTitle    = "",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 400),
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.Insert,
})

local Tab = Window:AddTab({ Title="ESP", Icon="eye" })

-- Box
Tab:AddToggle("ESPBox", {
    Title    = "Box",
    Default  = false,
    Callback = function(v) opt.Box = v end,
})

Tab:AddDropdown("ESPBoxStyle", {
    Title    = "Style",
    Default  = "Box",
    Values   = {"Box", "CornerBox"},
    Callback = function(v) opt.BoxStyle = v end,
})

Tab:AddColorpicker("ESPBoxColor", {
    Title   = "Couleur Box",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) opt.BoxColor = v end,
})

-- Skeleton
Tab:AddToggle("ESPSkeleton", {
    Title    = "Skeleton",
    Default  = false,
    Callback = function(v) opt.Skeleton = v end,
})

Tab:AddColorpicker("ESPSkelColor", {
    Title   = "Couleur Skeleton",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) opt.SkelColor = v end,
})

-- Tracers
Tab:AddToggle("ESPTracers", {
    Title    = "Tracers",
    Default  = false,
    Callback = function(v) opt.Tracers = v end,
})

Tab:AddColorpicker("ESPTracerColor", {
    Title   = "Couleur Tracers",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(v) opt.TracerColor = v end,
})

-- Distance
Tab:AddSlider("ESPDist", {
    Title    = "Distance max",
    Default  = 500,
    Min      = 50,
    Max      = 2000,
    Rounding = 0,
    Callback = function(v) opt.MaxDist = v end,
})

Window:SelectTab(1)
print("[Aurora v"..VERSION.."] Chargé")
