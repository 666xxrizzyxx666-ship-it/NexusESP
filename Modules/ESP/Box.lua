local Box = {}
local function L() local l=Drawing.new("Line") l.Visible=false l.ZIndex=2 l.Outline=false return l end
function Box.Create() return {top=L(),bottom=L(),left=L(),right=L()} end
function Box.Update(d, bb, col, boxCol)
    local c = boxCol or col or Color3.new(1,1,1)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    d.top.From=Vector2.new(x,y)         d.top.To=Vector2.new(x+w,y)       d.top.Color=c    d.top.Thickness=1    d.top.Visible=true
    d.bottom.From=Vector2.new(x,y+h)    d.bottom.To=Vector2.new(x+w,y+h)  d.bottom.Color=c d.bottom.Thickness=1 d.bottom.Visible=true
    d.left.From=Vector2.new(x,y)        d.left.To=Vector2.new(x,y+h)      d.left.Color=c   d.left.Thickness=1   d.left.Visible=true
    d.right.From=Vector2.new(x+w,y)     d.right.To=Vector2.new(x+w,y+h)   d.right.Color=c  d.right.Thickness=1  d.right.Visible=true
end
function Box.Hide(d) if not d then return end d.top.Visible=false d.bottom.Visible=false d.left.Visible=false d.right.Visible=false end
function Box.Remove(d) if not d then return end for _,v in pairs(d) do pcall(function() v:Remove() end) end end
return Box
