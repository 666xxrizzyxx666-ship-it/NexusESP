-- Aurora ESP v6.0 — AUTONOME, aucun fichier externe requis
-- Tout est dans ce fichier : Box, CornerBox, Skeleton, Tracers, Health, Name, Distance

local ESP = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ── Options ───────────────────────────────────────────
local opt = {
    Enabled    = false,
    Box        = false,
    BoxStyle   = "2D Normal", -- "2D Normal" | "Corner Box"
    BoxColor   = Color3.fromRGB(255,255,255),
    Skeleton   = false,
    SkeletonHP = true,
    Tracers    = false,
    TracerStyle= "Ligne",
    TracerColor= Color3.fromRGB(255,255,255),
    Name       = false,
    Weapon     = false,
    Distance   = false,
    Health     = false,
    HealthPos  = "Gauche",
    TeamCheck  = false,
    WallCheck  = false,
    FOVCircle  = false,
    FOVRadius  = 120,
    MaxDist    = 500,
    EnemyColor = Color3.fromRGB(255,80,80),
    TeamColor  = Color3.fromRGB(80,255,120),
}

-- ── State ─────────────────────────────────────────────
local playerData  = {}
local renderConn  = nil
local fovLines    = {}
local FOV_SEGS    = 64

-- ── Utils ─────────────────────────────────────────────
local function newLine(thickness, col)
    local l = Drawing.new("Line")
    l.Visible   = false
    l.Thickness = thickness or 1
    l.Color     = col or Color3.new(1,1,1)
    l.Transparency = 1
    l.ZIndex    = 2
    return l
end

local function newText(size, col, outline)
    local t = Drawing.new("Text")
    t.Visible  = false
    t.Size     = size or 13
    t.Color    = col or Color3.new(1,1,1)
    t.Outline  = outline ~= false
    t.Center   = true
    t.Font     = Drawing.Fonts.Plex
    t.ZIndex   = 3
    return t
end

local function isOnScreen(pos)
    local _, _, depth = Camera:WorldToViewportPoint(pos)
    return depth > 0
end

local function w2s(pos)
    local sp = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y)
end

local function getBB(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not root or not head then return nil end

    local headPos = head.Position + Vector3.new(0, head.Size.Y/2 + 0.1, 0)
    local feetPos = root.Position - Vector3.new(0, 3, 0)

    local hs = Camera:WorldToViewportPoint(headPos)
    local fs = Camera:WorldToViewportPoint(feetPos)
    if hs.Z <= 0 or fs.Z <= 0 then return nil end

    local h = math.abs(hs.Y - fs.Y)
    if h < 5 then return nil end
    local w  = h * 0.55
    local cx = (hs.X + fs.X) / 2

    return {
        x=cx-w/2, y=hs.Y,
        width=w, height=h,
        cx=cx, cy=hs.Y+h/2,
        topY=hs.Y, botY=fs.Y,
        headPos=headPos,
    }
end

local function getHP(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return 100, 100 end
    return hum.Health, hum.MaxHealth
end

local function hpColor(hp, maxHp)
    local pct = math.clamp(hp / math.max(maxHp, 1), 0, 1)
    if pct > 0.6 then
        return Color3.fromRGB(80, 255, 80)
    elseif pct > 0.3 then
        return Color3.fromRGB(255, 220, 0)
    else
        return Color3.fromRGB(255, 60, 60)
    end
end

local function getTeamColor(player)
    if LP.Team and player.Team and LP.Team == player.Team then
        return opt.TeamColor
    end
    return opt.EnemyColor
end

local function getThickness(dist)
    return math.clamp(math.floor(2 - dist/500), 1, 3)
end

-- ── FOV Circle ────────────────────────────────────────
local function buildFOV()
    for i = 1, FOV_SEGS do
        local l = newLine(1, Color3.new(1,1,1))
        fovLines[i] = l
    end
end

local function renderFOV()
    if not opt.FOVCircle then
        for i = 1, FOV_SEGS do fovLines[i].Visible = false end
        return
    end
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    local r  = opt.FOVRadius
    for i = 1, FOV_SEGS do
        local a1 = (i-1) / FOV_SEGS * math.pi * 2
        local a2 =  i    / FOV_SEGS * math.pi * 2
        local l  = fovLines[i]
        l.From    = Vector2.new(cx + math.cos(a1)*r, cy + math.sin(a1)*r)
        l.To      = Vector2.new(cx + math.cos(a2)*r, cy + math.sin(a2)*r)
        l.Color   = Color3.new(1,1,1)
        l.Visible = true
    end
end

-- ── Drawings par joueur ───────────────────────────────
local function createDrawings()
    -- Box 2D : 4 lignes
    local box = {}
    for i = 1, 4 do box[i] = newLine(1) end

    -- Corner Box : 8 groupes de 2 lignes (4 coins x 2 traits)
    local corner = {}
    for i = 1, 8 do corner[i] = newLine(1) end

    -- Skeleton R15 : 14 os
    local skel = {}
    for i = 1, 14 do skel[i] = newLine(1) end

    -- Tracers : 3 lignes (Ligne=1, Point=3)
    local tracer = {}
    for i = 1, 3 do tracer[i] = newLine(1) end

    -- Health bar : 2 lignes (fond + barre)
    local health = { bg=newLine(4), bar=newLine(4) }

    -- Texts
    local name    = newText(13, Color3.new(1,1,1))
    local weapon  = newText(11, Color3.fromRGB(255,220,80))
    local dist    = newText(11, Color3.fromRGB(180,180,180))
    local hpText  = newText(10, Color3.new(1,1,1))

    return {
        box=box, corner=corner, skel=skel,
        tracer=tracer, health=health,
        name=name, weapon=weapon, dist=dist, hpText=hpText,
    }
end

local function hideDrawings(d)
    if not d then return end
    local dr = d.drawings; if not dr then return end
    for _, l in ipairs(dr.box)     do l.Visible = false end
    for _, l in ipairs(dr.corner)  do l.Visible = false end
    for _, l in ipairs(dr.skel)    do l.Visible = false end
    for _, l in ipairs(dr.tracer)  do l.Visible = false end
    dr.health.bg.Visible  = false
    dr.health.bar.Visible = false
    dr.name.Visible   = false
    dr.weapon.Visible = false
    dr.dist.Visible   = false
    dr.hpText.Visible = false
end

local function removeDrawings(d)
    if not d or not d.drawings then return end
    local dr = d.drawings
    for _, l in ipairs(dr.box)    do pcall(function() l:Remove() end) end
    for _, l in ipairs(dr.corner) do pcall(function() l:Remove() end) end
    for _, l in ipairs(dr.skel)   do pcall(function() l:Remove() end) end
    for _, l in ipairs(dr.tracer) do pcall(function() l:Remove() end) end
    pcall(function() dr.health.bg:Remove()  end)
    pcall(function() dr.health.bar:Remove() end)
    pcall(function() dr.name:Remove()   end)
    pcall(function() dr.weapon:Remove() end)
    pcall(function() dr.dist:Remove()   end)
    pcall(function() dr.hpText:Remove() end)
end

-- ── Box 2D ────────────────────────────────────────────
local function drawBox(lines, bb, col, thickness)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    local t = thickness
    -- Top
    lines[1].From=Vector2.new(x,y)       lines[1].To=Vector2.new(x+w,y)
    -- Bottom
    lines[2].From=Vector2.new(x,y+h)     lines[2].To=Vector2.new(x+w,y+h)
    -- Left
    lines[3].From=Vector2.new(x,y)       lines[3].To=Vector2.new(x,y+h)
    -- Right
    lines[4].From=Vector2.new(x+w,y)     lines[4].To=Vector2.new(x+w,y+h)
    for i=1,4 do
        lines[i].Color     = col
        lines[i].Thickness = t
        lines[i].Visible   = true
    end
end

local function hideBox(lines)
    for i=1,4 do lines[i].Visible=false end
end

-- ── Corner Box ────────────────────────────────────────
local function drawCorner(lines, bb, col, thickness)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    local cw = w * 0.28
    local ch = h * 0.28
    local t  = thickness
    -- Top-Left H, V
    lines[1].From=Vector2.new(x,y)          lines[1].To=Vector2.new(x+cw,y)
    lines[2].From=Vector2.new(x,y)          lines[2].To=Vector2.new(x,y+ch)
    -- Top-Right H, V
    lines[3].From=Vector2.new(x+w-cw,y)    lines[3].To=Vector2.new(x+w,y)
    lines[4].From=Vector2.new(x+w,y)        lines[4].To=Vector2.new(x+w,y+ch)
    -- Bottom-Left H, V
    lines[5].From=Vector2.new(x,y+h-ch)    lines[5].To=Vector2.new(x,y+h)
    lines[6].From=Vector2.new(x,y+h)        lines[6].To=Vector2.new(x+cw,y+h)
    -- Bottom-Right H, V
    lines[7].From=Vector2.new(x+w,y+h-ch)  lines[7].To=Vector2.new(x+w,y+h)
    lines[8].From=Vector2.new(x+w-cw,y+h)  lines[8].To=Vector2.new(x+w,y+h)
    for i=1,8 do
        lines[i].Color     = col
        lines[i].Thickness = t
        lines[i].Visible   = true
    end
end

local function hideCorner(lines)
    for i=1,8 do lines[i].Visible=false end
end

-- ── Skeleton ──────────────────────────────────────────
local R15_BONES = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"},
}
local R6_BONES = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"},
    {"Left Arm","Left Leg"}, -- dummy, won't show
}

local function drawSkeleton(lines, char, hp, maxHp)
    local col = opt.SkeletonHP and hpColor(hp, maxHp) or Color3.new(1,1,1)
    local bones = char:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
    local drawn = 0
    for i, bone in ipairs(bones) do
        local a = char:FindFirstChild(bone[1])
        local b = char:FindFirstChild(bone[2])
        if a and b and i <= #lines then
            local sp1 = Camera:WorldToViewportPoint(a.Position)
            local sp2 = Camera:WorldToViewportPoint(b.Position)
            if sp1.Z > 0 and sp2.Z > 0 then
                lines[i].From      = Vector2.new(sp1.X, sp1.Y)
                lines[i].To        = Vector2.new(sp2.X, sp2.Y)
                lines[i].Color     = col
                lines[i].Thickness = 1
                lines[i].Visible   = true
                drawn = drawn + 1
            else
                lines[i].Visible = false
            end
        elseif i <= #lines then
            lines[i].Visible = false
        end
    end
    -- Hide unused lines
    for i = #bones+1, #lines do lines[i].Visible = false end
end

local function hideSkeleton(lines)
    for i=1,#lines do lines[i].Visible=false end
end

-- ── Tracers ───────────────────────────────────────────
local function drawTracer(lines, bb, col, style)
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y
    local tx = bb.cx
    local ty = bb.botY

    if style == "Ligne" then
        lines[1].From      = Vector2.new(cx, cy)
        lines[1].To        = Vector2.new(tx, ty)
        lines[1].Color     = col
        lines[1].Thickness = 1
        lines[1].Visible   = true
        lines[2].Visible   = false
        lines[3].Visible   = false

    elseif style == "Flèche" then
        -- Ligne principale
        lines[1].From=Vector2.new(cx,cy) lines[1].To=Vector2.new(tx,ty)
        lines[1].Color=col lines[1].Thickness=1 lines[1].Visible=true
        -- Flèche : 2 branches
        local angle = math.atan2(ty-cy, tx-cx)
        local arrowSize = 12
        local a1 = angle + math.rad(150)
        local a2 = angle - math.rad(150)
        lines[2].From=Vector2.new(tx,ty)
        lines[2].To=Vector2.new(tx+math.cos(a1)*arrowSize, ty+math.sin(a1)*arrowSize)
        lines[2].Color=col lines[2].Thickness=1 lines[2].Visible=true
        lines[3].From=Vector2.new(tx,ty)
        lines[3].To=Vector2.new(tx+math.cos(a2)*arrowSize, ty+math.sin(a2)*arrowSize)
        lines[3].Color=col lines[3].Thickness=1 lines[3].Visible=true

    elseif style == "Point" then
        -- 3 segments pointillés
        local dx = (tx-cx)/3
        local dy = (ty-cy)/3
        for i=1,3 do
            lines[i].From=Vector2.new(cx+dx*(i-1), cy+dy*(i-1))
            lines[i].To  =Vector2.new(cx+dx*(i-0.5), cy+dy*(i-0.5))
            lines[i].Color=col lines[i].Thickness=1 lines[i].Visible=true
        end
    end
end

local function hideTracer(lines)
    for i=1,3 do lines[i].Visible=false end
end

-- ── Health Bar ────────────────────────────────────────
local function drawHealth(dr, bb, hp, maxHp)
    local pct  = math.clamp(hp / math.max(maxHp,1), 0, 1)
    local col  = hpColor(hp, maxHp)
    local x, y, h = bb.x, bb.y, bb.height
    local barX

    if opt.HealthPos == "Gauche" then
        barX = x - 5
    else
        barX = x + bb.width + 5
    end

    -- Fond gris
    dr.health.bg.From      = Vector2.new(barX, y)
    dr.health.bg.To        = Vector2.new(barX, y + h)
    dr.health.bg.Color     = Color3.fromRGB(60,60,60)
    dr.health.bg.Thickness = 4
    dr.health.bg.Visible   = true

    -- Barre colorée
    dr.health.bar.From      = Vector2.new(barX, y + h * (1-pct))
    dr.health.bar.To        = Vector2.new(barX, y + h)
    dr.health.bar.Color     = col
    dr.health.bar.Thickness = 4
    dr.health.bar.Visible   = true
end

-- ── Name / Weapon / Distance ──────────────────────────
local function drawName(t, player, char, bb, showWeapon)
    local tool = char:FindFirstChildOfClass("Tool")
    t.name.Text     = player.DisplayName
    t.name.Position = Vector2.new(bb.cx, bb.y - 14)
    t.name.Visible  = true

    if showWeapon and tool then
        t.weapon.Text     = tool.Name
        t.weapon.Position = Vector2.new(bb.cx, bb.botY + 2)
        t.weapon.Visible  = true
    else
        t.weapon.Visible = false
    end
end

local function drawDist(t, bb, dist)
    local col
    if dist < 100 then col = Color3.fromRGB(255,60,60)
    elseif dist < 300 then col = Color3.fromRGB(255,220,0)
    else col = Color3.fromRGB(180,180,180) end
    t.dist.Text     = dist.."m"
    t.dist.Color    = col
    t.dist.Position = Vector2.new(bb.cx, bb.botY + 14)
    t.dist.Visible  = true
end

-- ── Render principal ──────────────────────────────────
local function renderPlayer(player, d)
    local char = player.Character
    if not char then hideDrawings(d) return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then hideDrawings(d) return end

    local rootPos  = root.Position
    local _, _, dz = Camera:WorldToViewportPoint(rootPos)
    if dz <= 0 then hideDrawings(d) return end

    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local dist   = myRoot and math.floor((rootPos - myRoot.Position).Magnitude) or 9999
    if dist > opt.MaxDist then hideDrawings(d) return end

    -- Team check
    if opt.TeamCheck and LP.Team and player.Team and LP.Team == player.Team then
        hideDrawings(d) return
    end

    -- Wall check
    if opt.WallCheck then
        local ok, result = pcall(function()
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {LP.Character, char}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local dir = rootPos - Camera.CFrame.Position
            return workspace:Raycast(Camera.CFrame.Position, dir, params)
        end)
        if ok and result ~= nil then hideDrawings(d) return end
    end

    local bb = getBB(char)
    if not bb then hideDrawings(d) return end

    local hp, maxHp = getHP(char)
    local col       = getTeamColor(player)
    local thickness = getThickness(dist)
    local dr        = d.drawings

    -- Box
    if opt.Box then
        if opt.BoxStyle == "Corner Box" then
            hideBox(dr.box)
            drawCorner(dr.corner, bb, opt.BoxColor, thickness)
        else
            hideCorner(dr.corner)
            drawBox(dr.box, bb, opt.BoxColor, thickness)
        end
    else
        hideBox(dr.box)
        hideCorner(dr.corner)
    end

    -- Skeleton
    if opt.Skeleton then
        drawSkeleton(dr.skel, char, hp, maxHp)
    else
        hideSkeleton(dr.skel)
    end

    -- Tracers
    if opt.Tracers then
        drawTracer(dr.tracer, bb, opt.TracerColor, opt.TracerStyle)
    else
        hideTracer(dr.tracer)
    end

    -- Health
    if opt.Health then
        drawHealth(dr, bb, hp, maxHp)
    else
        dr.health.bg.Visible  = false
        dr.health.bar.Visible = false
    end

    -- Name / Weapon
    if opt.Name then
        drawName(dr, player, char, bb, opt.Weapon)
    else
        dr.name.Visible   = false
        dr.weapon.Visible = false
    end

    -- Distance
    if opt.Distance then
        drawDist(dr, bb, dist)
    else
        dr.dist.Visible = false
    end
end

-- ── Render loop ───────────────────────────────────────
function ESP._render()
    renderFOV()
    if not opt.Enabled then return end
    for player, d in pairs(playerData) do
        if not player or not player.Parent then
            ESP._removePlayer(player)
        else
            pcall(renderPlayer, player, d)
        end
    end
end

-- ── Gestion joueurs ───────────────────────────────────
function ESP._addPlayer(player)
    if playerData[player] then return end
    playerData[player] = {
        drawings = createDrawings()
    }
    player.CharacterRemoving:Connect(function()
        if playerData[player] then
            hideDrawings(playerData[player])
        end
    end)
end

function ESP._removePlayer(player)
    if playerData[player] then
        removeDrawings(playerData[player])
        playerData[player] = nil
    end
end

-- ── Init ──────────────────────────────────────────────
function ESP.Init(deps)
    buildFOV()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then ESP._addPlayer(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LP then ESP._addPlayer(p) end
    end)
    Players.PlayerRemoving:Connect(function(p)
        ESP._removePlayer(p)
    end)
end

function ESP.Enable()
    opt.Enabled = true
    if not renderConn then
        renderConn = RunService.RenderStepped:Connect(ESP._render)
    end
end

function ESP.Disable()
    opt.Enabled = false
    for _, d in pairs(playerData) do hideDrawings(d) end
end

function ESP.SetOption(key, value)
    opt[key] = value
    -- Si on désactive l'ESP global
    if key == "Enabled" and not value then
        for _, d in pairs(playerData) do hideDrawings(d) end
    end
end

function ESP.GetOption(key) return opt[key] end

return ESP
