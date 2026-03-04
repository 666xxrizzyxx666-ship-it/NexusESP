-- CornerBox: 8 L-shaped segments, NO black outline
local CornerBox = {}; CornerBox.__index = CornerBox
local Utils, Config
function CornerBox.SetDependencies(u,c) Utils=u; Config=c end

function CornerBox.Create()
    local s = setmetatable({}, CornerBox)
    s.Lines = {}
    for i=1,8 do
        s.Lines[i] = Utils.NewDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1)})
    end
    return s
end

function CornerBox:Update(char, cfg)
    for i=1,8 do self.Lines[i].Visible=false end
    if not cfg or not cfg.Enabled or not char then return end
    local tl, sz = Utils.GetBoundingBox2D(char)
    if not tl or not sz or sz.X<4 or sz.Y<4 then return end
    local col = Utils.C3(cfg.Color)
    local th  = math.max(1, cfg.Thickness or 1)
    local x1,y1 = tl.X, tl.Y
    local x2,y2 = tl.X+sz.X, tl.Y+sz.Y
    local lx = math.max(4, math.floor(sz.X*0.22))
    local ly = math.max(4, math.floor(sz.Y*0.22))
    local segs = {
        {Vector2.new(x1,y1), Vector2.new(x1+lx,y1)},
        {Vector2.new(x1,y1), Vector2.new(x1,y1+ly)},
        {Vector2.new(x2,y1), Vector2.new(x2-lx,y1)},
        {Vector2.new(x2,y1), Vector2.new(x2,y1+ly)},
        {Vector2.new(x1,y2), Vector2.new(x1+lx,y2)},
        {Vector2.new(x1,y2), Vector2.new(x1,y2-ly)},
        {Vector2.new(x2,y2), Vector2.new(x2-lx,y2)},
        {Vector2.new(x2,y2), Vector2.new(x2,y2-ly)},
    }
    for i,seg in ipairs(segs) do
        self.Lines[i].From=seg[1]; self.Lines[i].To=seg[2]
        self.Lines[i].Color=col;   self.Lines[i].Thickness=th
        self.Lines[i].Visible=true
    end
end

function CornerBox:Hide() for i=1,8 do self.Lines[i].Visible=false end end
function CornerBox:Remove() for i=1,8 do Utils.Kill(self.Lines[i]) end end
return CornerBox
