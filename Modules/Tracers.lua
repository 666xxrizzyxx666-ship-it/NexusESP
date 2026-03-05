local Tracers = {}
Tracers.__index = Tracers
local Utils, Config
function Tracers.SetDependencies(u, c) Utils = u; Config = c end

function Tracers.Create()
    local s = setmetatable({}, Tracers)
    s.Line = Utils.NewDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1)})
    return s
end

local function origin(pos)
    local vp = Utils.GetViewport()
    if pos == "Center" then return Vector2.new(vp.X/2, vp.Y/2)
    elseif pos == "Top" then return Vector2.new(vp.X/2, 0)
    else return Vector2.new(vp.X/2, vp.Y) end
end

function Tracers:Update(char, cfg)
    self.Line.Visible = false
    if not cfg or not cfg.Enabled or not char then return end
    local root = Utils.GetRoot(char)
    if not root then return end
    local tp, on = Utils.W2V(root.Position)
    if not on then return end
    self.Line.From      = origin(cfg.Position or "Bottom")
    self.Line.To        = tp
    self.Line.Color     = Utils.C3(cfg.Color)
    self.Line.Thickness = math.max(1, cfg.Thickness or 1)
    self.Line.Visible   = true
end

function Tracers:Hide()   self.Line.Visible = false end
function Tracers:Remove() Utils.Kill(self.Line) end
return Tracers
