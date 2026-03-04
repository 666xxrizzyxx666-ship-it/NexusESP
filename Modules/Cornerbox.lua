local CornerBox = {}
CornerBox.__index = CornerBox
local Utils, Config
function CornerBox.SetDependencies(u,c) Utils=u; Config=c end

function CornerBox.Create(player)
    local self = setmetatable({}, CornerBox)
    self.Player = player
    self.Out = {}
    self.Col = {}
    for i = 1, 8 do
        self.Out[i] = Utils.NewDrawing("Line", {Thickness=3, Color=Color3.new(0,0,0), Visible=false}, 1)
        self.Col[i] = Utils.NewDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1), Visible=false}, 2)
    end
    return self
end

function CornerBox:Update(character, cfg)
    for i=1,8 do self.Out[i].Visible=false; self.Col[i].Visible=false end
    cfg = cfg or {}
    if not cfg.Enabled or not character then return end

    local tl, sz = Utils.GetBoundingBox2D(character)
    if not tl or not sz or sz.X < 4 or sz.Y < 4 then return end

    local c   = cfg.Color or {R=255,G=255,B=255}
    local col = Color3.fromRGB(c.R, c.G, c.B)
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
    for i, seg in ipairs(segs) do
        self.Out[i].From=seg[1]; self.Out[i].To=seg[2]; self.Out[i].Thickness=th+2; self.Out[i].Visible=true
        self.Col[i].From=seg[1]; self.Col[i].To=seg[2]; self.Col[i].Thickness=th; self.Col[i].Color=col; self.Col[i].Visible=true
    end
end

function CornerBox:Hide()
    for i=1,8 do self.Out[i].Visible=false; self.Col[i].Visible=false end
end

function CornerBox:Remove()
    for i=1,8 do Utils.RemoveDrawing(self.Out[i]); Utils.RemoveDrawing(self.Col[i]) end
    self.Out={}; self.Col={}
end

return CornerBox
