local CornerBox = {}
local function L() local l=Drawing.new("Line") l.Visible=false l.ZIndex=2 l.Outline=false return l end
function CornerBox.Create()
    local d = {}
    for i=1,8 do d[i]=L() end
    return d
end
function CornerBox.Update(d, bb, col, boxCol)
    local c = boxCol or col or Color3.new(1,1,1)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    local cw, ch = w*0.25, h*0.25
    local corners = {
        {Vector2.new(x,y),      Vector2.new(x+cw,y)},
        {Vector2.new(x,y),      Vector2.new(x,y+ch)},
        {Vector2.new(x+w,y),    Vector2.new(x+w-cw,y)},
        {Vector2.new(x+w,y),    Vector2.new(x+w,y+ch)},
        {Vector2.new(x,y+h),    Vector2.new(x+cw,y+h)},
        {Vector2.new(x,y+h),    Vector2.new(x,y+h-ch)},
        {Vector2.new(x+w,y+h),  Vector2.new(x+w-cw,y+h)},
        {Vector2.new(x+w,y+h),  Vector2.new(x+w,y+h-ch)},
    }
    for i=1,8 do
        d[i].From=corners[i][1] d[i].To=corners[i][2]
        d[i].Color=c d[i].Thickness=2 d[i].Visible=true
    end
end
function CornerBox.Hide(d) if not d then return end for i=1,#d do d[i].Visible=false end end
function CornerBox.Remove(d) if not d then return end for i=1,#d do pcall(function() d[i]:Remove() end) end end
return CornerBox
