-- ============================================================
--  Radar.lua — Mini-radar 2D en coin d'ecran
--  Affiche la position relative de tous les joueurs
-- ============================================================
local Radar = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local Utils, Config
local LP = Players.LocalPlayer

function Radar.SetDependencies(u, c) Utils = u; Config = c end

-- ── Constantes visuelles ──────────────────────────────────────
local SIZE    = 160    -- taille du radar en px
local PADDING = 10     -- marge depuis le coin
local RANGE   = 200    -- studs affichés = rayon du radar

-- ── Drawings permanents ───────────────────────────────────────
local drawings     = {}
local dotPool      = {}  -- pool de Drawing pour les blips
local labelPool    = {}
local conn         = nil
local visible      = false

local function makeDrawings()
    -- Fond
    drawings.bg = Utils.NewDrawing("Square", {
        Filled = true, Color = Color3.fromRGB(10,10,10),
        Transparency = 0.35, Visible = false,
    })
    -- Bordure
    drawings.border = Utils.NewDrawing("Square", {
        Filled = false, Color = Color3.fromRGB(60,60,60),
        Thickness = 1, Visible = false,
    })
    -- Croix centrale (joueur local)
    drawings.crossH = Utils.NewDrawing("Line", { Color=Color3.fromRGB(0,200,255), Thickness=1, Visible=false })
    drawings.crossV = Utils.NewDrawing("Line", { Color=Color3.fromRGB(0,200,255), Thickness=1, Visible=false })
    -- Cercle de range
    drawings.rangeCircle = Utils.NewDrawing("Circle", {
        Radius=SIZE/2-2, NumSides=48, Filled=false,
        Color=Color3.fromRGB(50,50,50), Thickness=1, Visible=false
    })
    -- Titre
    drawings.title = Utils.NewDrawing("Text", {
        Text="RADAR", Size=10, Color=Color3.fromRGB(0,200,255),
        Outline=true, Center=false, Visible=false
    })
end

local function getOrCreateDot(i)
    if not dotPool[i] then
        -- outline
        dotPool[i] = {
            out = Utils.NewDrawing("Circle", { Radius=4, Filled=true, Color=Color3.new(0,0,0), NumSides=8, Visible=false }),
            dot = Utils.NewDrawing("Circle", { Radius=3, Filled=true, Color=Color3.new(1,0,0), NumSides=8, Visible=false }),
            lbl = Utils.NewDrawing("Text",   { Size=9,  Color=Color3.new(1,1,1), Outline=true, Center=true, Visible=false }),
        }
    end
    return dotPool[i]
end

local function worldToRadar(radarCenter, lpPos, targetPos, radarSize, range)
    local camCF  = Workspace.CurrentCamera.CFrame
    local rel    = targetPos - lpPos
    -- Rotation relative à la caméra (Y ignoré)
    local right  = camCF.RightVector
    local fwd    = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
    local dx =  rel:Dot(right)
    local dz = -rel:Dot(fwd)
    local scale  = (radarSize / 2 - 4) / range
    local px = radarCenter.X + dx * scale
    local py = radarCenter.Y + dz * scale
    -- Clamp au bord
    local fromCenter = Vector2.new(px - radarCenter.X, py - radarCenter.Y)
    if fromCenter.Magnitude > radarSize / 2 - 4 then
        fromCenter = fromCenter.Unit * (radarSize / 2 - 4)
        px = radarCenter.X + fromCenter.X
        py = radarCenter.Y + fromCenter.Y
    end
    return Vector2.new(px, py)
end

local function updateRadar()
    if not visible then return end
    local cfg = Config and Config.Current and Config.Current.Radar or {}
    if not cfg.Enabled then
        Radar.Hide(); return
    end

    local vp = Utils.GetViewport()
    local sz = cfg.Size or SIZE
    -- Position : coin en bas à gauche
    local rx = PADDING
    local ry = vp.Y - sz - PADDING
    local center = Vector2.new(rx + sz/2, ry + sz/2)
    local range  = cfg.Range or RANGE

    drawings.bg.Position    = Vector2.new(rx, ry)
    drawings.bg.Size        = Vector2.new(sz, sz)
    drawings.bg.Visible     = true

    drawings.border.Position = Vector2.new(rx, ry)
    drawings.border.Size     = Vector2.new(sz, sz)
    drawings.border.Visible  = true

    drawings.rangeCircle.Position = center
    drawings.rangeCircle.Radius   = sz/2 - 2
    drawings.rangeCircle.Visible  = true

    -- Croix centrale
    drawings.crossH.From = Vector2.new(center.X-6, center.Y); drawings.crossH.To = Vector2.new(center.X+6, center.Y); drawings.crossH.Visible = true
    drawings.crossV.From = Vector2.new(center.X, center.Y-6); drawings.crossV.To = Vector2.new(center.X, center.Y+6); drawings.crossV.Visible = true

    drawings.title.Position = Vector2.new(rx+4, ry+2); drawings.title.Visible = true

    local char = LP.Character
    local lpRoot = char and Utils.GetRoot(char)
    local lpPos  = lpRoot and lpRoot.Position or Vector3.new(0,0,0)

    local playerList = Players:GetPlayers()
    local idx = 0

    for _, player in ipairs(playerList) do
        if player == LP then continue end
        local pc   = player.Character
        local root = pc and Utils.GetRoot(pc)
        if not root then continue end

        idx = idx + 1
        local blip = getOrCreateDot(idx)
        local bpos = worldToRadar(center, lpPos, root.Position, sz, range)
        local col  = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(255,60,60)
        local hp   = Utils.GetHealthPercent(pc)

        blip.out.Position = bpos; blip.out.Radius = 4; blip.out.Visible = true
        blip.dot.Position = bpos; blip.dot.Radius = 3; blip.dot.Color   = col; blip.dot.Visible = true
        blip.lbl.Text     = player.Name:sub(1,6)
        blip.lbl.Position = bpos + Vector2.new(0, -10)
        blip.lbl.Visible  = (cfg.ShowNames ~= false)
    end

    -- Cacher les blips inutilisés
    for i = idx+1, #dotPool do
        if dotPool[i] then
            dotPool[i].out.Visible = false
            dotPool[i].dot.Visible = false
            dotPool[i].lbl.Visible = false
        end
    end
end

function Radar.Show()
    if visible then return end
    visible = true
    makeDrawings()
    conn = RunService.RenderStepped:Connect(updateRadar)
end

function Radar.Hide()
    visible = false
    if conn then conn:Disconnect(); conn = nil end
    for _, d in pairs(drawings) do Utils.RemoveDrawing(d) end
    drawings = {}
    for i, b in pairs(dotPool) do
        Utils.RemoveDrawing(b.out); Utils.RemoveDrawing(b.dot); Utils.RemoveDrawing(b.lbl)
        dotPool[i] = nil
    end
end

function Radar.Toggle()
    if visible then Radar.Hide() else Radar.Show() end
end

return Radar
