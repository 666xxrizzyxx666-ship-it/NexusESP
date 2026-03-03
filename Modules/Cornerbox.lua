-- ============================================================
--  CornerBox.lua — Box style "coins en L" (Corner Box)
--  Plus discret et plus stylé que la box pleine
-- ============================================================
local CornerBox = {}
CornerBox.__index = CornerBox

local Utils, Config

function CornerBox.SetDependencies(u, c) Utils = u; Config = c end

-- 4 coins × 2 lignes (H+V) × 2 (outline + couleur) = 16 drawings
function CornerBox.Create(player)
    local self = setmetatable({}, CornerBox)
    self.Player = player
    self.Lines  = {}

    -- outline d'abord, couleur ensuite pour chaque segment
    for i = 1, 8 do
        self.Lines["out"..i] = Utils.NewDrawing("Line", { Thickness=3, Color=Color3.new(0,0,0), Visible=false })
        self.Lines["col"..i] = Utils.NewDrawing("Line", { Thickness=1, Color=Color3.new(1,1,1), Visible=false })
    end
    return self
end

local function setLine(d, a, b, col, th)
    d.From      = a
    d.To        = b
    d.Color     = col
    d.Thickness = th
    d.Visible   = true
end

function CornerBox:Update(character, cfg)
    cfg = cfg or {}
    if not cfg.Enabled or not character then self:Hide(); return end

    local tl, sz = Utils.GetBoundingBox2D(character)
    if not tl or not sz or sz.X < 4 or sz.Y < 4 then self:Hide(); return end

    local c   = cfg.Color
    local col = Color3.fromRGB(c and c.R or 255, c and c.G or 255, c and c.B or 255)
    local th  = math.max(1, cfg.Thickness or 1)
    local blk = Color3.new(0,0,0)

    local x1, y1 = tl.X,        tl.Y
    local x2, y2 = tl.X+sz.X,   tl.Y+sz.Y
    local lx = math.floor(sz.X * 0.22)   -- longueur coin H
    local ly = math.floor(sz.Y * 0.22)   -- longueur coin V

    -- 8 segments : TL-H, TL-V, TR-H, TR-V, BL-H, BL-V, BR-H, BR-V
    local segs = {
        { Vector2.new(x1,y1),      Vector2.new(x1+lx,y1)   }, -- TL H
        { Vector2.new(x1,y1),      Vector2.new(x1,y1+ly)   }, -- TL V
        { Vector2.new(x2,y1),      Vector2.new(x2-lx,y1)   }, -- TR H
        { Vector2.new(x2,y1),      Vector2.new(x2,y1+ly)   }, -- TR V
        { Vector2.new(x1,y2),      Vector2.new(x1+lx,y2)   }, -- BL H
        { Vector2.new(x1,y2),      Vector2.new(x1,y2-ly)   }, -- BL V
        { Vector2.new(x2,y2),      Vector2.new(x2-lx,y2)   }, -- BR H
        { Vector2.new(x2,y2),      Vector2.new(x2,y2-ly)   }, -- BR V
    }

    for i, seg in ipairs(segs) do
        setLine(self.Lines["out"..i], seg[1], seg[2], blk, th+2)
        setLine(self.Lines["col"..i], seg[1], seg[2], col, th)
    end
end

function CornerBox:Hide()
    for _, d in pairs(self.Lines) do d.Visible = false end
end

function CornerBox:Remove()
    for _, d in pairs(self.Lines) do Utils.RemoveDrawing(d) end
    self.Lines = {}
end

return CornerBox
