-- ══════════════════════════════════════════════════════════════════
--   Aurora v5.5.0 — Main.lua
-- ══════════════════════════════════════════════════════════════════
local VERSION = "6.0.2"

-- Détection jeu
local PLACE_ID     = game.PlaceId
local IS_ARSENAL   = PLACE_ID == 286090429
local IS_DAHOOD    = PLACE_ID == 2788229376

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════════════
-- OPTIONS
-- ══════════════════════════════════════════════════════════════════
local opt = {
    Box         = false,
    BoxStyle    = "Box",
    Skeleton    = false,
    Tracers     = false,
    Name        = false,
    TracerOrigin = "Bottom",
    Health      = false,
    EnemyColor  = Color3.fromRGB(255, 60, 60),
    TeamColor   = Color3.fromRGB(60, 255, 120),
    MaxDist     = 500,
    Distance    = false,
    Weapon      = false,
    Chams       = false,
    ChamsStyle  = "Outline",
    TeamCheck   = false,
}

local function anyEnabled()
    return opt.Box or opt.Skeleton or opt.Tracers or opt.Name or opt.Health or opt.Distance or opt.Weapon or opt.Chams
end

local function getColor(player)
    if opt.TeamCheck and LP.Team and player.Team and LP.Team == player.Team then
        return nil -- skip teammates
    end
    if LP.Team and player.Team and LP.Team == player.Team then
        return opt.TeamColor
    end
    return opt.EnemyColor
end

-- ══════════════════════════════════════════════════════════════════
-- DRAWING HELPERS
-- ══════════════════════════════════════════════════════════════════
local function newLine()
    local l = Drawing.new("Line")
    l.Visible = false l.Thickness = 1
    l.Color = Color3.new(1,1,1) l.Transparency = 1 l.ZIndex = 2
    return l
end

local function newText()
    local t = Drawing.new("Text")
    t.Visible = false t.Center = true t.Outline = true
    t.Size = 13 t.Font = Drawing.Fonts.Plex
    return t
end

-- ══════════════════════════════════════════════════════════════════
-- BONES
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
    return { box=box, cor=cor, sk=sk, tr=newLine(), name=newText(), hbar=newLine(), dist=newText(), weap=newText(), highlight=nil }
end

local function hideDrawings(d)
    if not d then return end
    for i=1,4 do d.box[i].Visible=false end
    for i=1,8 do d.cor[i].Visible=false end
    for i=1,MAX_BONES do d.sk[i].Visible=false end
    d.tr.Visible=false d.name.Visible=false
    d.hbar.Visible=false
    if d.dist then d.dist.Visible=false end
    if d.weap then d.weap.Visible=false end
    if d.highlight then d.highlight.Enabled=false end
end

local function removeDrawings(d)
    if not d then return end
    for i=1,4 do pcall(function() d.box[i]:Remove() end) end
    for i=1,8 do pcall(function() d.cor[i]:Remove() end) end
    for i=1,MAX_BONES do pcall(function() d.sk[i]:Remove() end) end
    pcall(function() d.tr:Remove() end)
    pcall(function() d.name:Remove() end)
    pcall(function() d.hbar:Remove() end)
    pcall(function() d.dist:Remove() end)
    pcall(function() d.weap:Remove() end)
    if d.highlight then d.highlight.Enabled=false end
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
    local w = h * 0.55
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
                    line.From=Vector2.new(sA.X,sA.Y) line.To=Vector2.new(sB.X,sB.Y)
                    line.Color=col line.Visible=true
                else line.Visible=false end
            else line.Visible=false end
        else line.Visible=false end
    end
end

local function drawTracer(tr, bb, col)
    local vp = Camera.ViewportSize
    local fromY = opt.TracerOrigin == "Top" and 0 or vp.Y
    local toY   = opt.TracerOrigin == "Top" and bb.y or bb.botY
    tr.From=Vector2.new(vp.X/2, fromY) tr.To=Vector2.new(bb.cx, toY)
    tr.Color=col tr.Thickness=1 tr.Visible=true
end

local function getHPColor(pct)
    if pct > 0.6 then return Color3.fromRGB(74, 222, 128)
    elseif pct > 0.3 then return Color3.fromRGB(251, 191, 36)
    else return Color3.fromRGB(248, 113, 113) end
end

local function drawHealth(d, bb, hum)
    local maxHp = hum.MaxHealth
    local hp    = hum.Health
    if maxHp <= 0 then maxHp = 100 end
    if hp    <= 0 then hp    = 0   end
    local pct  = hp / maxHp
    local col  = getHPColor(pct)
    local x    = bb.x - 4
    local yBot = bb.y + bb.height
    local yTop = bb.y + bb.height * (1 - pct)
    d.hbar.From      = Vector2.new(x, yBot)
    d.hbar.To        = Vector2.new(x, yTop)
    d.hbar.Color     = col
    d.hbar.Thickness = 3
    d.hbar.Visible   = true
end

local function updateChams(d, player, col)
    local char = player.Character
    if not char then
        if d.highlight then d.highlight.Enabled=false end
        return
    end
    -- Crée le Highlight si pas encore fait
    if not d.highlight then
        local h = Instance.new("Highlight")
        h.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.Parent           = char
        d.highlight        = h
    else
        -- Reparent si le character a changé
        if d.highlight.Parent ~= char then
            d.highlight.Parent = char
        end
    end
    if opt.ChamsStyle == "Filled" then
        d.highlight.FillTransparency    = 0.5
        d.highlight.OutlineTransparency = 0
    else -- Outline only
        d.highlight.FillTransparency    = 1
        d.highlight.OutlineTransparency = 0
    end
    d.highlight.FillColor    = col
    d.highlight.OutlineColor = col
    d.highlight.Enabled      = true
end

local function drawWeapon(weapD, player, char, bb, col)
    local weapName = nil
    -- Arsenal : StringValue "EquippedWep" dans le character
    local equippedWep = char:FindFirstChild("EquippedWep")
    if equippedWep and equippedWep.Value ~= "" then
        weapName = equippedWep.Value
    end
    -- Fallback générique : Tool classique
    if not weapName then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then weapName = tool.Name end
    end
    if not weapName or weapName == "" then weapD.Visible=false return end
    local yOffset = opt.Distance and 18 or 0
    weapD.Text     = "[" .. weapName .. "]"
    weapD.Size     = 11
    weapD.Color    = col
    weapD.Position = Vector2.new(bb.cx, bb.y + bb.height + 3 + yOffset)
    weapD.Visible  = true
end

local function drawDistance(distD, bb, dist, col)
    distD.Text     = dist .. "m"
    distD.Size     = 15
    distD.Color    = col
    distD.Position = Vector2.new(bb.cx, bb.y + bb.height + 3)
    distD.Visible  = true
end

local function drawName(nameD, player, bb, col)
    nameD.Text     = player.Name
    nameD.Color    = col
    nameD.Position = Vector2.new(bb.cx, bb.y - 16)
    nameD.Visible  = true
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

    local col = getColor(player)
    if not col then hideDrawings(d) return end
    local bb  = getBB(char)

    if opt.Box and bb then
        if opt.BoxStyle == "CornerBox" then drawCorner(d, bb, col)
        else drawBox(d, bb, col) end
    else
        for i=1,4 do d.box[i].Visible=false end
        for i=1,8 do d.cor[i].Visible=false end
    end

    if opt.Skeleton then drawSkeleton(d.sk, char, col)
    else for i=1,MAX_BONES do d.sk[i].Visible=false end end

    if opt.Tracers and bb then drawTracer(d.tr, bb, col)
    else d.tr.Visible=false end

    if opt.Name and bb then drawName(d.name, player, bb, col)
    else d.name.Visible=false end

    if opt.Health and bb then drawHealth(d, bb, hum)
    else d.hbar.Visible=false end

    if opt.Distance and bb then drawDistance(d.dist, bb, dist, col)
    else d.dist.Visible=false end

    if opt.Weapon and bb then drawWeapon(d.weap, player, char, bb, col)
    else d.weap.Visible=false end

    if opt.Chams then
        updateChams(d, player, col)
    else
        if d.highlight then d.highlight.Enabled=false end
    end
end

RunService:BindToRenderStep("AuroraESP", Enum.RenderPriority.Camera.Value + 1, function()
    if not anyEnabled() then return end
    for player, d in pairs(playerData) do
        if not player or not player.Parent then
            removeDrawings(d) playerData[player]=nil
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
Players.PlayerAdded:Connect(function(p) if p ~= LP then addPlayer(p) end end)
Players.PlayerRemoving:Connect(function(p)
    if playerData[p] then removeDrawings(playerData[p]) playerData[p]=nil end
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

Tab:AddToggle("ESPBox", {
    Title="Box", Default=false,
    Callback=function(v) opt.Box=v end,
})
Tab:AddDropdown("ESPBoxStyle", {
    Title="Style", Default="Box", Values={"Box","CornerBox"},
    Callback=function(v) opt.BoxStyle=v end,
})
Tab:AddToggle("ESPSkeleton", {
    Title="Skeleton", Default=false,
    Callback=function(v) opt.Skeleton=v end,
})
Tab:AddToggle("ESPTracers", {
    Title="Tracers", Default=false,
    Callback=function(v) opt.Tracers=v end,
})
Tab:AddDropdown("ESPTracerOrigin", {
    Title="Origine Tracers", Default="Bottom", Values={"Bottom","Top"},
    Callback=function(v) opt.TracerOrigin=v end,
})
Tab:AddToggle("ESPName", {
    Title="Name", Default=false,
    Callback=function(v) opt.Name=v end,
})
Tab:AddToggle("ESPHealth", {
    Title="Health Bar", Default=false,
    Callback=function(v) opt.Health=v end,
})
if IS_ARSENAL then
    Tab:AddParagraph({
        Title   = "⚠ Health Bar indisponible",
        Content = "Arsenal ne réplique pas les HP des joueurs côté client. Cette option n'aura aucun effet sur ce jeu.",
    })
end
Tab:AddToggle("ESPDistance", {
    Title="Distance", Default=false,
    Callback=function(v) opt.Distance=v end,
})
Tab:AddToggle("ESPWeapon", {
    Title="Weapon", Default=false,
    Callback=function(v) opt.Weapon=v end,
})
if IS_ARSENAL then
    Tab:AddParagraph({
        Title   = "⚠ Weapon indisponible",
        Content = "Arsenal ne réplique pas les armes des joueurs côté client. Cette option n'aura aucun effet sur ce jeu.",
    })
end
Tab:AddToggle("ESPChams", {
    Title="Chams", Default=false,
    Callback=function(v) opt.Chams=v end,
})
Tab:AddDropdown("ESPChamsStyle", {
    Title="Style Chams", Default="Outline", Values={"Outline","Filled"},
    Callback=function(v) opt.ChamsStyle=v end,
})
Tab:AddToggle("ESPTeamCheck", {
    Title="Team Check (cache les coéquipiers)",
    Default=false,
    Callback=function(v) opt.TeamCheck=v end,
})
Tab:AddColorpicker("ESPEnemyColor", {
    Title="Enemy Color", Default=Color3.fromRGB(255,60,60),
    Callback=function(v) opt.EnemyColor=v end,
})
Tab:AddColorpicker("ESPTeamColor", {
    Title="Team Color", Default=Color3.fromRGB(60,255,120),
    Callback=function(v) opt.TeamColor=v end,
})
Tab:AddSlider("ESPDist", {
    Title="Distance max", Default=500, Min=50, Max=2000, Rounding=0,
    Callback=function(v) opt.MaxDist=v end,
})

-- ══════════════════════════════════════════════════════════════════
-- AIMBOT ENGINE
-- ══════════════════════════════════════════════════════════════════
local aimbotOpt = {
    Enabled    = false,
    FOV        = 120,
    Smoothness = 10,
    Bone       = "Head",
    TeamCheck  = true,
    HoldKey    = true,
}

-- FOV Circle (64 segments)
local FOV_SEG  = 64
local fovLines = {}
for i = 1, FOV_SEG do
    local l = Drawing.new("Line")
    l.Visible   = false
    l.Thickness = 1
    l.Color     = Color3.fromRGB(255, 255, 255)
    l.ZIndex    = 6
    fovLines[i] = l
end

local function renderFOV()
    local show = aimbotOpt.Enabled
    local cx   = Camera.ViewportSize.X / 2
    local cy   = Camera.ViewportSize.Y / 2
    local r    = aimbotOpt.FOV
    for i = 1, FOV_SEG do
        local l  = fovLines[i]
        if show then
            local a1 = (i-1)/FOV_SEG * math.pi*2
            local a2 = i    /FOV_SEG * math.pi*2
            l.From    = Vector2.new(cx + math.cos(a1)*r, cy + math.sin(a1)*r)
            l.To      = Vector2.new(cx + math.cos(a2)*r, cy + math.sin(a2)*r)
            l.Visible = true
        else
            l.Visible = false
        end
    end
end

local UIS = game:GetService("UserInputService")

local function getBestTarget()
    local center   = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best     = nil
    local bestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local char = player.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                -- Team check
                if aimbotOpt.TeamCheck and LP.Team and player.Team and LP.Team == player.Team then
                    -- skip teammate
                else
                    local bone = char:FindFirstChild(aimbotOpt.Bone)
                        or char:FindFirstChild("HumanoidRootPart")
                    if bone then
                        local sp = Camera:WorldToViewportPoint(bone.Position)
                        if sp.Z > 0 then
                            local screenPos = Vector2.new(sp.X, sp.Y)
                            local dist      = (screenPos - center).Magnitude
                            if dist <= aimbotOpt.FOV and dist < bestDist then
                                bestDist = dist
                                best     = bone
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

RunService:BindToRenderStep("AuroraAimbot", Enum.RenderPriority.Camera.Value + 2, function()
    renderFOV()
    if not aimbotOpt.Enabled then return end

    local holding = aimbotOpt.HoldKey
        and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        or not aimbotOpt.HoldKey

    if not holding then return end

    local bone = getBestTarget()
    if not bone then return end

    local camCF    = Camera.CFrame
    local targetCF = CFrame.new(camCF.Position, bone.Position)
    local smooth   = math.max(1, aimbotOpt.Smoothness)
    Camera.CFrame  = camCF:Lerp(targetCF, 1 / smooth)
end)

-- ── Aimbot UI ─────────────────────────────────────────────────────
local TabAim = Window:AddTab({ Title="Aim", Icon="crosshair" })

TabAim:AddToggle("AimEnabled", {
    Title="Aimbot", Default=false,
    Callback=function(v) aimbotOpt.Enabled=v end,
})
TabAim:AddParagraph({
    Title   = "ℹ Touche de visée",
    Content = "Touche par défaut : Hold Clic Droit. Le choix de touche sera disponible dans l'UI finale.",
})
TabAim:AddSlider("AimFOV", {
    Title="FOV", Default=120, Min=10, Max=500, Rounding=0,
    Callback=function(v) aimbotOpt.FOV=v end,
})
TabAim:AddSlider("AimSmooth", {
    Title="Smoothness", Default=10, Min=1, Max=50, Rounding=0,
    Callback=function(v) aimbotOpt.Smoothness=v end,
})
TabAim:AddDropdown("AimBone", {
    Title="Bone", Default="Head", Values={"Head","HumanoidRootPart","UpperTorso"},
    Callback=function(v) aimbotOpt.Bone=v end,
})
TabAim:AddToggle("AimTeamCheck", {
    Title="Team Check", Default=true,
    Callback=function(v) aimbotOpt.TeamCheck=v end,
})


-- ══════════════════════════════════════════════════════════════════
-- MOVEMENT ENGINE
-- ══════════════════════════════════════════════════════════════════
local movOpt = {
    Speed      = false,
    SpeedVal   = 24,
    Fly        = false,
    FlySpeed   = 50,
    Noclip     = false,
    BunnyHop   = false,
    InfJump    = false,
}

local UIS2     = game:GetService("UserInputService")
local movConns = {}

local function movClean(key)
    if movConns[key] then
        movConns[key]:Disconnect()
        movConns[key] = nil
    end
end

-- ── Speed ─────────────────────────────────────────────────────────
local function applySpeed()
    movClean("speed")
    if not movOpt.Speed then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
        return
    end
    movConns["speed"] = RunService.Heartbeat:Connect(function()
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = movOpt.SpeedVal end
    end)
end

-- ── Fly ───────────────────────────────────────────────────────────
local flyBody = nil
local function applyFly()
    movClean("fly")
    -- cleanup
    if flyBody then flyBody:Destroy() flyBody = nil end
    if not movOpt.Fly then return end

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    bg.P = 1e4 bg.Parent = root

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    flyBody = bv

    movConns["fly"] = RunService.Heartbeat:Connect(function()
        if not movOpt.Fly then return end
        local cf  = Camera.CFrame
        local vel = Vector3.zero
        if UIS2:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
        if UIS2:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
        if UIS2:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
        if UIS2:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
        if UIS2:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
        if UIS2:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,1,0) end
        bv.Velocity = vel * movOpt.FlySpeed
        bg.CFrame   = cf
    end)
end

-- ── Noclip ────────────────────────────────────────────────────────
local function applyNoclip()
    movClean("noclip")
    if not movOpt.Noclip then return end
    movConns["noclip"] = RunService.Stepped:Connect(function()
        if not movOpt.Noclip then return end
        local char = LP.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end)
end

-- ── BunnyHop ──────────────────────────────────────────────────────
local function applyBhop()
    movClean("bhop")
    if not movOpt.BunnyHop then return end
    movConns["bhop"] = UIS2.JumpRequest:Connect(function()
        if not movOpt.BunnyHop then return end
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ── InfJump ───────────────────────────────────────────────────────
local function applyInfJump()
    movClean("infjump")
    if not movOpt.InfJump then return end
    movConns["infjump"] = UIS2.JumpRequest:Connect(function()
        if not movOpt.InfJump then return end
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

-- cleanup on respawn
LP.CharacterAdded:Connect(function()
    flyBody = nil
    if movOpt.Fly   then task.wait(0.1) applyFly()   end
    if movOpt.Speed then applySpeed() end
    if movOpt.Noclip then applyNoclip() end
    if movOpt.BunnyHop then applyBhop() end
    if movOpt.InfJump then applyInfJump() end
end)

-- ── Movement UI ───────────────────────────────────────────────────
local TabMov = Window:AddTab({ Title="Movement", Icon="zap" })

TabMov:AddToggle("MovSpeed", {
    Title="Speed", Default=false,
    Callback=function(v) movOpt.Speed=v applySpeed() end,
})
TabMov:AddSlider("MovSpeedVal", {
    Title="Walk Speed", Default=24, Min=16, Max=150, Rounding=0,
    Callback=function(v) movOpt.SpeedVal=v end,
})
TabMov:AddToggle("MovFly", {
    Title="Fly  (WASD + Space/Ctrl)", Default=false,
    Callback=function(v) movOpt.Fly=v applyFly() end,
})
TabMov:AddSlider("MovFlySpeed", {
    Title="Fly Speed", Default=50, Min=10, Max=300, Rounding=0,
    Callback=function(v) movOpt.FlySpeed=v end,
})
TabMov:AddToggle("MovNoclip", {
    Title="Noclip", Default=false,
    Callback=function(v) movOpt.Noclip=v applyNoclip() end,
})
TabMov:AddToggle("MovBhop", {
    Title="BunnyHop", Default=false,
    Callback=function(v) movOpt.BunnyHop=v applyBhop() end,
})
TabMov:AddToggle("MovInfJump", {
    Title="Infinite Jump", Default=false,
    Callback=function(v) movOpt.InfJump=v applyInfJump() end,
})

Window:SelectTab(1)
print("[Aurora v"..VERSION.."] Chargé")
