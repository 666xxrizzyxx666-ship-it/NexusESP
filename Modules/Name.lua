local Name = {}; Name.__index = Name
local Utils, Config
function Name.SetDependencies(u,c) Utils=u; Config=c end

function Name.Create(player)
    local s = setmetatable({}, Name)
    s.Player = player
    -- Outline=true uses Roblox built-in text outline (not a second drawing)
    s.Text = Utils.NewDrawing("Text", {Text=player.Name, Size=13, Color=Color3.new(1,1,1), Outline=false, Center=true})
    return s
end

function Name:Update(char, cfg)
    self.Text.Visible = false
    if not cfg or not cfg.Enabled or not char then return end
    local top = Utils.GetCharTop(char)
    if not top then return end
    local sp, on = Utils.W2V(top)
    if not on then return end
    local sz = math.clamp(cfg.Size or 13, 6, 40)
    self.Text.Text     = self.Player.Name
    self.Text.Color    = Utils.C3(cfg.Color)
    self.Text.Size     = sz
    self.Text.Outline  = false    -- no outline = no black border
    self.Text.Position = Vector2.new(sp.X, sp.Y - (cfg.OffsetY or 5) - sz)
    self.Text.Visible  = true
end

function Name:Hide()   self.Text.Visible=false end
function Name:Remove() Utils.Kill(self.Text)   end
return Name
