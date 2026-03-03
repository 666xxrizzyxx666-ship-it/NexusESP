local Name = {}
Name.__index = Name
local Utils, Config
function Name.SetDependencies(u,c) Utils=u; Config=c end

function Name.Create(player)
    local self = setmetatable({}, Name)
    self.Player = player
    self.Text = Utils.NewDrawing("Text", { Text=player.Name, Size=13, Color=Color3.new(1,1,1), Outline=true, Center=true, Visible=false })
    return self
end

function Name:Update(character, cfg)
    cfg = cfg or {}
    if not cfg.Enabled or not character then self:Hide(); return end
    local top = Utils.GetCharTop(character)
    if not top then self:Hide(); return end
    local sp, on = Utils.W2V(top)
    if not on then self:Hide(); return end
    local c = cfg.Color
    self.Text.Text     = self.Player.Name
    self.Text.Position = Vector2.new(sp.X, sp.Y - (cfg.OffsetY or 5) - (cfg.Size or 13))
    self.Text.Color    = Color3.fromRGB(c and c.R or 255, c and c.G or 255, c and c.B or 255)
    self.Text.Size     = cfg.Size or 13
    self.Text.Outline  = cfg.Outline ~= false
    self.Text.Visible  = true
end

function Name:Hide() self.Text.Visible = false end
function Name:Remove() Utils.RemoveDrawing(self.Text) end
return Name
