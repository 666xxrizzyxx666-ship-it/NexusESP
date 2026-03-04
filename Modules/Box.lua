local Box = {}
Box.__index = Box
local Utils, Config
function Box.SetDependencies(u,c) Utils=u; Config=c end

function Box.Create(player)
    local self = setmetatable({}, Box)
    self.Player  = player
    -- ZIndex 1 = derrière, ZIndex 2 = devant → couleur toujours visible
    self.Outline = Utils.NewDrawing("Square", {Filled=false, Color=Color3.new(0,0,0), Thickness=1, Visible=false}, 1)
    self.Frame   = Utils.NewDrawing("Square", {Filled=false, Color=Color3.new(1,1,1), Thickness=1, Visible=false}, 2)
    self.Fill    = Utils.NewDrawing("Square", {Filled=true,  Color=Color3.new(1,1,1), Transparency=0.6, Visible=false}, 2)
    return self
end

function Box:Update(character, cfg)
    -- Reset systématique
    self.Outline.Visible = false
    self.Frame.Visible   = false
    self.Fill.Visible    = false

    cfg = cfg or {}
    if not cfg.Enabled or not character then return end

    local tl, sz = Utils.GetBoundingBox2D(character)
    if not tl or not sz or sz.X < 4 or sz.Y < 4 then return end

    local c   = cfg.Color or {R=255,G=255,B=255}
    local col = Color3.fromRGB(c.R, c.G, c.B)
    local th  = math.max(1, cfg.Thickness or 1)

    self.Outline.Position  = tl - Vector2.new(1,1)
    self.Outline.Size      = sz + Vector2.new(2,2)
    self.Outline.Thickness = th + 2
    self.Outline.Color     = Color3.new(0,0,0)
    self.Outline.Visible   = true

    self.Frame.Position  = tl
    self.Frame.Size      = sz
    self.Frame.Thickness = th
    self.Frame.Color     = col
    self.Frame.Visible   = true

    if cfg.Filled then
        local fc = cfg.FillColor or c
        self.Fill.Position     = tl
        self.Fill.Size         = sz
        self.Fill.Color        = Color3.fromRGB(fc.R, fc.G, fc.B)
        self.Fill.Transparency = cfg.FillTrans or 0.6
        self.Fill.Visible      = true
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
