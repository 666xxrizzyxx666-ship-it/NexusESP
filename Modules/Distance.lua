local Distance = {}; Distance.__index = Distance
local Utils, Config
function Distance.SetDependencies(u,c) Utils=u; Config=c end

function Distance.Create()
    local s = setmetatable({}, Distance)
    s.Text = Utils.NewDrawing("Text", {Text="0m", Size=11, Color=Color3.fromRGB(180,180,180), Outline=false, Center=true})
    return s
end

function Distance:Update(char, cfg)
    self.Text.Visible = false  -- always reset first
    if not cfg or not cfg.Enabled or not char then return end
    local root = Utils.GetRoot(char)
    if not root then return end
    local dist = Utils.GetDistance(root.Position)
    if dist > (cfg.MaxDist or 800) then return end
    local top = Utils.GetCharTop(char)
    if not top then return end
    local sp, on = Utils.W2V(top)
    if not on then return end
    local nameSz = Config and Config.Current and Config.Current.Name and Config.Current.Name.Size or 13
    local nameOff = Config and Config.Current and Config.Current.Name and Config.Current.Name.OffsetY or 5
    local sz = math.clamp(cfg.Size or 11, 6, 30)
    self.Text.Text     = Utils.FormatDist(dist)
    self.Text.Color    = Utils.C3(cfg.Color)
    self.Text.Size     = sz
    self.Text.Outline  = false
    self.Text.Position = Vector2.new(sp.X, sp.Y - nameOff - nameSz - sz - 4)
    self.Text.Visible  = true
end

function Distance:Hide()   self.Text.Visible=false end
function Distance:Remove() Utils.Kill(self.Text)   end
return Distance
