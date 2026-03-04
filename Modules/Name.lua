local Name = {}
Name.__index = Name
local Utils, Config
function Name.SetDependencies(u,c) Utils=u; Config=c end

function Name.Create(player)
    local self = setmetatable({}, Name)
    self.Player   = player
    self.Outline  = Utils.NewDrawing("Text", {Text=player.Name, Size=13, Color=Color3.new(0,0,0), Outline=false, Center=true, Visible=false}, 1)
    self.Text     = Utils.NewDrawing("Text", {Text=player.Name, Size=13, Color=Color3.new(1,1,1), Outline=true,  Center=true, Visible=false}, 2)
    return self
end

function Name:Update(character, cfg)
    self.Text.Visible    = false
    self.Outline.Visible = false

    cfg = cfg or {}
    if not cfg.Enabled or not character then return end

    local top = Utils.GetCharTop(character)
    if not top then return end

    local sp, on = Utils.W2V(top)
    if not on or not sp then return end

    local c    = cfg.Color or {R=255,G=255,B=255}
    local col  = Color3.fromRGB(c.R, c.G, c.B)
    local sz   = math.clamp(cfg.Size or 13, 6, 30)
    local offY = cfg.OffsetY or 5
    local pos  = Vector2.new(sp.X, sp.Y - offY - sz)

    self.Text.Text     = self.Player.Name
    self.Text.Position = pos
    self.Text.Color    = col
    self.Text.Size     = sz
    self.Text.Outline  = true
    self.Text.Visible  = true
end

function Name:Hide()
    self.Text.Visible    = false
    self.Outline.Visible = false
end

function Name:Remove()
    Utils.RemoveDrawing(self.Text)
    Utils.RemoveDrawing(self.Outline)
end

return Name
