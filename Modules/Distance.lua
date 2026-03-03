local Distance = {}
Distance.__index = Distance
local Utils, Config
function Distance.SetDependencies(u,c) Utils=u; Config=c end

function Distance.Create(player)
    local self = setmetatable({}, Distance)
    self.Player = player
    self.Text = Utils.NewDrawing("Text", { Text="0m", Size=11, Color=Color3.fromRGB(200,200,200), Outline=true, Center=true, Visible=false })
    return self
end

function Distance:Update(character, cfg)
    cfg = cfg or {}
    if not cfg.Enabled or not character then self:Hide(); return end
    local root = Utils.GetRoot(character)
    if not root then self:Hide(); return end
    local dist = Utils.GetDistance(root.Position)
    if dist > (cfg.MaxDist or 1000) then self:Hide(); return end
    local top = Utils.GetCharTop(character)
    if not top then self:Hide(); return end
    local sp, on = Utils.W2V(top)
    if not on then self:Hide(); return end
    local c = cfg.Color
    local nameCfg = Config and Config.Current and Config.Current.Name
    local nameOff = (nameCfg and nameCfg.OffsetY or 5) + (nameCfg and nameCfg.Size or 13) + 2
    self.Text.Text     = Utils.FormatDistance(dist, cfg.Format or "{dist}m")
    self.Text.Position = Vector2.new(sp.X, sp.Y - (cfg.Size or 11) - nameOff)
    self.Text.Color    = Color3.fromRGB(c and c.R or 200, c and c.G or 200, c and c.B or 200)
    self.Text.Size     = cfg.Size or 11
    self.Text.Visible  = true
end

function Distance:Hide() self.Text.Visible = false end
function Distance:Remove() Utils.RemoveDrawing(self.Text) end
return Distance
