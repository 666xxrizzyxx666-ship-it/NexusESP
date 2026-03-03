-- ============================================================
--  Distance.lua — Affichage de la distance en studs
--  Se place sous le NameTag, format configurable
-- ============================================================

local Distance = {}
Distance.__index = Distance

local Utils
local Config

function Distance.SetDependencies(utils, config)
    Utils  = utils
    Config = config
end

-- ── Constructeur ─────────────────────────────────────────────
function Distance.Create(player)
    local self = setmetatable({}, Distance)
    self.Player = player

    self.Text = Utils.NewDrawing("Text", {
        Text    = "0m",
        Size    = 11,
        Color   = Color3.fromRGB(200, 200, 200),
        Outline = true,
        Center  = true,
        Visible = false,
    })

    return self
end

-- ── Mise à jour chaque frame ──────────────────────────────────
function Distance:Update(character, cfg, nameOffsetY)
    cfg = cfg or (Config and Config.Current and Config.Current.Distance) or {}
    nameOffsetY = nameOffsetY or 0

    if cfg.Enabled == false or not character then
        self:Hide()
        return
    end

    local root = Utils.GetRoot(character)
    if not root then
        self:Hide()
        return
    end

    local dist = Utils.GetDistance(root.Position)

    -- Respect de la distance max
    local maxDist = cfg.MaxDist or 1000
    if dist > maxDist then
        self:Hide()
        return
    end

    local topPos = Utils.GetCharTop(character)
    if not topPos then
        self:Hide()
        return
    end

    local screenPos, onScreen = Utils.W2V(topPos)
    if not onScreen then
        self:Hide()
        return
    end

    local color  = cfg.Color and
                   Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B)
                   or Color3.fromRGB(200, 200, 200)
    local size   = cfg.Size or 11
    local fmt    = cfg.Format or "{dist}m"

    local displayText = Utils.FormatDistance(dist, fmt)

    -- Positionner juste sous le name tag
    local nameSize = (Config and Config.Current and Config.Current.Name and Config.Current.Name.Size) or 13
    local nameOff  = (Config and Config.Current and Config.Current.Name and Config.Current.Name.OffsetY) or 5
    local totalOffset = nameOff + nameSize + size + 2 + nameOffsetY

    self.Text.Text     = displayText
    self.Text.Position = Vector2.new(screenPos.X, screenPos.Y - totalOffset + nameSize + size + 4)
    self.Text.Color    = color
    self.Text.Size     = size
    self.Text.Visible  = true
end

-- ── Cacher ───────────────────────────────────────────────────
function Distance:Hide()
    self.Text.Visible = false
end

-- ── Destruction ──────────────────────────────────────────────
function Distance:Remove()
    Utils.RemoveDrawing(self.Text)
end

return Distance
