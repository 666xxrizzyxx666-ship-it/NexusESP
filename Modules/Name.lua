-- ============================================================
--  Name.lua — Affichage du nom du joueur au-dessus du modèle
--  Utilise Drawing.new("Text") avec outline et offset Y
-- ============================================================

local Name = {}
Name.__index = Name

local Utils
local Config

function Name.SetDependencies(utils, config)
    Utils  = utils
    Config = config
end

-- ── Constructeur ─────────────────────────────────────────────
function Name.Create(player)
    local self = setmetatable({}, Name)
    self.Player = player

    self.Text = Utils.NewDrawing("Text", {
        Text    = player.Name,
        Size    = 13,
        Color   = Color3.new(1, 1, 1),
        Outline = true,
        Center  = true,
        Visible = false,
    })

    return self
end

-- ── Mise à jour chaque frame ──────────────────────────────────
function Name:Update(character, cfg)
    cfg = cfg or (Config and Config.Current and Config.Current.Name) or {}

    if cfg.Enabled == false or not character then
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

    local color   = cfg.Color and
                    Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B)
                    or Color3.new(1, 1, 1)
    local size    = cfg.Size    or 13
    local offsetY = cfg.OffsetY or 5

    self.Text.Text     = self.Player.Name
    self.Text.Position = Vector2.new(screenPos.X, screenPos.Y - offsetY - size)
    self.Text.Color    = color
    self.Text.Size     = size
    self.Text.Outline  = cfg.Outline ~= false
    self.Text.Visible  = true
end

-- ── Cacher ───────────────────────────────────────────────────
function Name:Hide()
    self.Text.Visible = false
end

-- ── Destruction ──────────────────────────────────────────────
function Name:Remove()
    Utils.RemoveDrawing(self.Text)
end

return Name
