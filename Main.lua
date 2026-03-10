-- Aurora — Main.lua v1.0 — ESP Boxes uniquement
local VERSION = "1.0"
local REPO = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════
-- OPTIONS
-- ══════════════════════════════════════════════════════
local opt = {
    Enabled  = false,
    Box      = false,
    BoxStyle = "2D Normal", -- "2D Normal" ou "Corner Box"
    BoxColor = Color3.fromRGB(255, 255, 255),
    MaxDist  = 500,
    TeamCheck= false,
}

-- ══════════════════════════════════════════════════════
-- UTILS
-- ══════════════════════════════════════════════════════
local function getBB(char)
    if not char then return nil end
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

    return {
        x      = cx - w/2,
        y      = hs.Y,
        width  = w,
        height = h,
        cx     = cx,
        topY   = hs.Y,
        botY   = fs.Y,
    }
end

local function newLine(thickness, color)
    local l = Drawing.new("Line")
    l.Visible      = false
    l.Thickness    = thickness or 1
    l.Color        = color or Color3.new(1,1,1)
    l.Transparency = 1
    l.ZIndex       = 2
    return l
end

local function getThickness(dist)
    return math.clamp(math.floor(2 - dist/500), 1, 3)
end

-- ══════════════════════════════════════════════════════
-- DRAWINGS PAR JOUEUR
-- ══════════════════════════════════════════════════════
local playerData = {}

local function createDrawings()
    -- 4 lignes pour box 2D
    local box = {}
    for i = 1, 4 do box[i] = newLine(1) end

    -- 8 lignes pour corner box
    local cor = {}
    for i = 1, 8 do cor[i] = newLine(1) end

    return { box=box, cor=cor }
end

local function hideDrawings(d)
    if not d then return end
    for i = 1, 4 do d.box[i].Visible = false end
    for i = 1, 8 do d.cor[i].Visible = false end
end

local function removeDrawings(d)
    if not d then return end
    for i = 1, 4 do pcall(function() d.box[i]:Remove() end) end
    for i = 1, 8 do pcall(function() d.cor[i]:Remove() end) end
end

-- ══════════════════════════════════════════════════════
-- DRAW BOX 2D
-- ══════════════════════════════════════════════════════
local function drawBox(b, bb, col, thick)
    local x, y, w, h = bb.x, bb.y, bb.width, bb.height
    -- Top
    b[1].From = Vector2.new(x, y)     b[1].To = Vector2.new(x+w, y)
    -- Bottom
    b[2].From = Vector2.new(x, y+h)   b[2].To = Vector2.new(x+w, y+h)
    -- Left
    b[3].From = Vector2.new(x, y)     b[3].To = Vector2.new(x, y+h)
    -- Right
    b[4].From = Vector2.new(x+w, y)   b[4].To = Vector2.new(x+w, y+h)
    for i = 1, 4 do
        b[i].Color     = col
        b[i].Thickness = thick
        b[i].Visible   = true
    end
end

-- ══════════════════════════════════════════════════════
-- DRAW CORNER BOX
-- ══════════════════════════════════════════════════════
local function drawCorner(b, bb, col, thick)
    local x, y, w, h = bb.x, bb.y, bb.width, bb.height
    local cw = w * 0.28
    local ch = h * 0.28
    -- Top-Left
    b[1].From=Vector2.new(x,y)           b[1].To=Vector2.new(x+cw,y)
    b[2].From=Vector2.new(x,y)           b[2].To=Vector2.new(x,y+ch)
    -- Top-Right
    b[3].From=Vector2.new(x+w-cw,y)     b[3].To=Vector2.new(x+w,y)
    b[4].From=Vector2.new(x+w,y)         b[4].To=Vector2.new(x+w,y+ch)
    -- Bottom-Left
    b[5].From=Vector2.new(x,y+h-ch)     b[5].To=Vector2.new(x,y+h)
    b[6].From=Vector2.new(x,y+h)         b[6].To=Vector2.new(x+cw,y+h)
    -- Bottom-Right
    b[7].From=Vector2.new(x+w,y+h-ch)   b[7].To=Vector2.new(x+w,y+h)
    b[8].From=Vector2.new(x+w-cw,y+h)   b[8].To=Vector2.new(x+w,y+h)
    for i = 1, 8 do
        b[i].Color     = col
        b[i].Thickness = thick
        b[i].Visible   = true
    end
end

-- ══════════════════════════════════════════════════════
-- RENDER
-- ══════════════════════════════════════════════════════
local function renderPlayer(player, d)
    local char = player.Character
    if not char then hideDrawings(d) return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then hideDrawings(d) return end

    local _, _, dz = Camera:WorldToViewportPoint(root.Position)
    if dz <= 0 then hideDrawings(d) return end

    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local dist   = myRoot and math.floor((root.Position - myRoot.Position).Magnitude) or 9999
    if dist > opt.MaxDist then hideDrawings(d) return end

    if opt.TeamCheck and LP.Team and player.Team and LP.Team == player.Team then
        hideDrawings(d) return
    end

    local bb = getBB(char)
    if not bb then hideDrawings(d) return end

    local thick = getThickness(dist)

    -- Box
    if opt.Box then
        if opt.BoxStyle == "Corner Box" then
            for i=1,4 do d.box[i].Visible=false end
            drawCorner(d.cor, bb, opt.BoxColor, thick)
        else
            for i=1,8 do d.cor[i].Visible=false end
            drawBox(d.box, bb, opt.BoxColor, thick)
        end
    else
        hideDrawings(d)
    end
end

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

-- ══════════════════════════════════════════════════════
-- GESTION JOUEURS
-- ══════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════
-- UI FLUENT
-- ══════════════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title       = "Aurora  •  v"..VERSION,
    SubTitle    = "ESP — Boxes",
    TabWidth    = 160,
    Size        = Vector2.new(580, 400),
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.Insert,
})

local Tab = Window:AddTab({ Title="ESP", Icon="eye" })

Tab:AddSection("Boxes")

Tab:AddToggle("ESPGlobal", {
    Title    = "ESP Global",
    Default  = false,
    Callback = function(v) opt.Enabled = v end,
})

Tab:AddToggle("ESPBox", {
    Title    = "Box ESP",
    Default  = false,
    Callback = function(v) opt.Box = v end,
})

Tab:AddDropdown("ESPBoxStyle", {
    Title    = "Style Box",
    Default  = "2D Normal",
    Values   = {"2D Normal", "Corner Box"},
    Callback = function(v) opt.BoxStyle = v end,
})

Tab:AddSection("Filtres")

Tab:AddToggle("ESPTeam", {
    Title    = "Team Check",
    Default  = false,
    Callback = function(v) opt.TeamCheck = v end,
})

Tab:AddSlider("ESPMaxDist", {
    Title    = "Distance max",
    Default  = 500,
    Min      = 50,
    Max      = 2000,
    Rounding = 0,
    Callback = function(v) opt.MaxDist = v end,
})

Window:SelectTab(1)
print("[Aurora v"..VERSION.."] Box ESP chargé ✓")
print("[Aurora] Active 'ESP Global' puis 'Box ESP' pour tester")
