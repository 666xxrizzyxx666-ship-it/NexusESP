local Tracers = {}
Tracers.__index = Tracers
local Utils, Config
function Tracers.SetDependencies(u,c) Utils=u; Config=c end

function Tracers.Create(player)
    local self = setmetatable({}, Tracers)
    self.Player  = player
    self.Outline = Utils.NewDrawing("Line", {Thickness=3, Color=Color3.new(0,0,0), Visible=false}, 1)
    self.Line    = Utils.NewDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1), Visible=false}, 2)
    return self
end

local function srcPoint(pos)
    local vp = Utils.GetViewport()
    if pos == "Center" then return Vector2.new(vp.X/2, vp.Y/2)
    elseif pos == "Top" then return Vector2.new(vp.X/2, 0)
    else return Vector2.new(vp.X/2, vp.Y) end
end

function Tracers:Update(character, cfg)
    self.Outline.Visible = false
    self.Line.Visible    = false

    cfg = cfg or {}
    if not cfg.Enabled or not character then return end

    local root = Utils.GetRoot(character)
    if not root then return end

    local tp, on = Utils.W2V(root.Position)
    if not on or not tp then return end

    local c   = cfg.Color or {R=255,G=255,B=255}
    local col = Color3.fromRGB(c.R, c.G, c.B)
    local th  = math.max(1, cfg.Thickness or 1)
    local src = srcPoint(cfg.Position or "Bottom")

    self.Outline.From=src; self.Outline.To=tp; self.Outline.Thickness=th+2; self.Outline.Visible=true
    self.Line.From=src;    self.Line.To=tp;    self.Line.Thickness=th; self.Line.Color=col; self.Line.Visible=true
end

function Tracers:Hide()
    self.Outline.Visible = false
    self.Line.Visible    = false
end

function Tracers:Remove()
    Utils.RemoveDrawing(self.Outline)
    Utils.RemoveDrawing(self.Line)
end

return Tracers
