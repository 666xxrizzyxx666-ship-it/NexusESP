-- Box: single square, NO black outline
local Box = {}; Box.__index = Box
local Utils, Config
function Box.SetDependencies(u,c) Utils=u; Config=c end

function Box.Create()
    local s = setmetatable({}, Box)
    s.Frame = Utils.NewDrawing("Square", {Filled=false, Color=Color3.new(1,1,1), Thickness=1})
    s.Fill  = Utils.NewDrawing("Square", {Filled=true,  Color=Color3.new(1,1,1), Transparency=0.7})
    return s
end

function Box:Update(char, cfg)
    self.Frame.Visible = false; self.Fill.Visible = false
    if not cfg or not cfg.Enabled or not char then return end
    local tl, sz = Utils.GetBoundingBox2D(char)
    if not tl or not sz or sz.X < 4 or sz.Y < 4 then return end
    local col = Utils.C3(cfg.Color)
    self.Frame.Position = tl; self.Frame.Size = sz
    self.Frame.Color    = col; self.Frame.Thickness = math.max(1, cfg.Thickness or 1)
    self.Frame.Visible  = true
    if cfg.Filled then
        self.Fill.Position     = tl; self.Fill.Size = sz
        self.Fill.Color        = Utils.C3(cfg.FillColor)
        self.Fill.Transparency = cfg.FillTrans or 0.7
        self.Fill.Visible      = true
    end
end

function Box:Hide() self.Frame.Visible=false; self.Fill.Visible=false end
function Box:Remove() Utils.Kill(self.Frame); Utils.Kill(self.Fill) end
return Box
