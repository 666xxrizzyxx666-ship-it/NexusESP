local Tracers = {}
local Camera = workspace.CurrentCamera
local function L() local l=Drawing.new("Line") l.Visible=false l.ZIndex=1 l.Outline=false return l end
function Tracers.Create() return {line=L()} end
function Tracers.Update(d, bb, col)
    if not d or not bb then return end
    local vp = Camera.ViewportSize
    d.line.From      = Vector2.new(vp.X/2, vp.Y)
    d.line.To        = Vector2.new(bb.cx, bb.y + bb.height)
    d.line.Color     = col or Color3.new(1,1,1)
    d.line.Thickness = 1
    d.line.Visible   = true
end
function Tracers.Hide(d) if d and d.line then d.line.Visible=false end end
function Tracers.Remove(d) if d and d.line then pcall(function() d.line:Remove() end) end end
return Tracers
