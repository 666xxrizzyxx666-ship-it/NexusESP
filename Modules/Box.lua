-- ============================================================
--  Box.lua — CORRIGE : outline rendu EN PREMIER (derriere)
--  frame colore rendu EN SECOND (devant) → couleur visible
-- ============================================================
local Box = {}
Box.__index = Box

local Utils, Config

function Box.SetDependencies(u, c) Utils = u; Config = c end

function Box.Create(player)
    local self = setmetatable({}, Box)
    self.Player = player
    -- ORDRE CRITIQUE : outline d'abord, frame ensuite
    self.Outline = Utils.NewDrawing("Square", { Filled=false, Color=Color3.new(0,0,0), Visible=false })
    self.Frame   = Utils.NewDrawing("Square", { Filled=false, Color=Color3.new(1,1,1), Visible=false })
    self.Fill    = Utils.NewDrawing("Square", { Filled=true,  Color=Color3.new(1,1,1), Visible=false, Transparency=0.6 })
    return self
end

function Box:Update(character, cfg)
    cfg = cfg or {}
    if not cfg.Enabled or not character then self:Hide(); return end

    local tl, sz = Utils.GetBoundingBox2D(character)
    if not tl or not sz or sz.X < 4 or sz.Y < 4 then self:Hide(); return end

    local c  = cfg.Color
    local col = Color3.fromRGB(c and c.R or 255, c and c.G or 255, c and c.B or 255)
    local th  = math.max(1, cfg.Thickness or 1)

    self.Outline.Position  = tl - Vector2.new(1,1)
    self.Outline.Size      = sz + Vector2.new(2,2)
    self.Outline.Thickness = th + 1
    self.Outline.Visible   = true

    self.Frame.Position  = tl
    self.Frame.Size      = sz
    self.Frame.Thickness = th
    self.Frame.Color     = col
    self.Frame.Visible   = true

    if cfg.Filled then
        local fc = cfg.FillColor
        self.Fill.Position     = tl
        self.Fill.Size         = sz
        self.Fill.Color        = Color3.fromRGB(fc and fc.R or 255, fc and fc.G or 255, fc and fc.B or 255)
        self.Fill.Transparency = cfg.FillTrans or 0.6
        self.Fill.Visible      = true
    else
        self.Fill.Visible = false
    end
end

function Box:Hide()
    self.Outline.Visible = false
    self.Frame.Visible   = false
    self.Fill.Visible    = false
end

function Box:Remove()
    Utils.RemoveDrawing(self.Outline)
    Utils.RemoveDrawing(self.Frame)
    Utils.RemoveDrawing(self.Fill)
end

return Box
