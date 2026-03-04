local Distance = {}
Distance.__index = Distance
local Utils, Config
function Distance.SetDependencies(u,c) Utils=u; Config=c end

function Distance.Create(player)
    local self = setmetatable({}, Distance)
    self.Player = player
    self.Text   = Utils.NewDrawing("Text", {Text="0m", Size=11, Color=Color3.fromRGB(180,180,180), Outline=true, Center=true, Visible=false}, 2)
    return self
end

function Distance:Update(character, cfg)
    -- TOUJOURS reset en premier → corrige le "reste à l'écran"
    self.Text.Visible = false

    cfg = cfg or {}
    if not cfg.Enabled or not character then return end

    local root = Utils.GetRoot(character)
    if not root then return end

    local dist = Utils.GetDistance(root.Position)
    if dist > (cfg.MaxDist or 800) then return end

    local top = Utils.GetCharTop(character)
    if not top then return end

    local sp, on = Utils.W2V(top)
    if not on or not sp then return end

    local nameCfg = Config and Config.Current and Config.Current.Name
    local nameSize = nameCfg and nameCfg.Size or 13
    local nameOff  = nameCfg and nameCfg.OffsetY or 5
    local sz = cfg.Size or 11

    local c   = cfg.Color or {R=180,G=180,B=180}
    local col = Color3.fromRGB(c.R, c.G, c.B)

    -- Position : juste en dessous du name tag
    local posY = sp.Y - nameOff - nameSize - sz - 2

    self.Text.Text     = Utils.FormatDistance(dist, cfg.Format or "{dist}m")
    self.Text.Position = Vector2.new(sp.X, posY)
    self.Text.Color    = col
    self.Text.Size     = math.clamp(sz, 6, 24)
    self.Text.Visible  = true
end

function Distance:Hide()
    self.Text.Visible = false
end

function Distance:Remove()
    Utils.RemoveDrawing(self.Text)
end

return Distance
