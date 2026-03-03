-- ============================================================
--  Health.lua — Barre de santé dynamique (vert → rouge)
--  Position : "Left" | "Right" | "Top" | "Bottom"
--  Utilise Drawing.new("Square") pour le bg et le fill
-- ============================================================

local Health = {}
Health.__index = Health

local Utils
local Config

function Health.SetDependencies(utils, config)
    Utils  = utils
    Config = config
end

-- ── Constantes ───────────────────────────────────────────────
local BAR_THICKNESS = 3   -- largeur de la barre (px)
local BAR_PADDING   = 3   -- écart par rapport à la box
local BAR_BORDER    = 1   -- bordure autour

-- ── Constructeur ─────────────────────────────────────────────
function Health.Create(player)
    local self = setmetatable({}, Health)
    self.Player = player

    -- Bordure noire
    self.Border = Utils.NewDrawing("Square", {
        Filled    = true,
        Color     = Color3.new(0, 0, 0),
        Visible   = false,
    })

    -- Fond gris foncé
    self.Background = Utils.NewDrawing("Square", {
        Filled    = true,
        Color     = Color3.fromRGB(30, 30, 30),
        Visible   = false,
    })

    -- Fill de santé (couleur dynamique)
    self.Bar = Utils.NewDrawing("Square", {
        Filled    = true,
        Color     = Color3.fromRGB(0, 255, 0),
        Visible   = false,
    })

    -- Texte optionnel de pourcentage
    self.Text = Utils.NewDrawing("Text", {
        Size     = 11,
        Color    = Color3.new(1, 1, 1),
        Outline  = true,
        Center   = true,
        Visible  = false,
    })

    return self
end

-- ── Calcul des positions selon la config ─────────────────────
local function computeBarBounds(position, boxTopLeft, boxSize, barWidth, healthPct)
    local pad    = BAR_PADDING
    local border = BAR_BORDER
    local bw     = barWidth or BAR_THICKNESS

    if position == "Left" then
        local bx  = boxTopLeft.X - bw - pad - border
        local by  = boxTopLeft.Y - border
        local bh  = boxSize.Y + border * 2

        local borderRect = { pos = Vector2.new(bx, by),              size = Vector2.new(bw + border * 2, bh) }
        local bgRect     = { pos = Vector2.new(bx + border, by + border), size = Vector2.new(bw, bh - border * 2) }

        local fillH = math.floor((bh - border * 2) * healthPct)
        local fillY = by + border + (bh - border * 2) - fillH
        local fillRect = { pos = Vector2.new(bx + border, fillY), size = Vector2.new(bw, fillH) }

        return borderRect, bgRect, fillRect

    elseif position == "Right" then
        local bx  = boxTopLeft.X + boxSize.X + pad
        local by  = boxTopLeft.Y - border
        local bh  = boxSize.Y + border * 2

        local borderRect = { pos = Vector2.new(bx - border, by),         size = Vector2.new(bw + border * 2, bh) }
        local bgRect     = { pos = Vector2.new(bx, by + border),          size = Vector2.new(bw, bh - border * 2) }

        local fillH = math.floor((bh - border * 2) * healthPct)
        local fillY = by + border + (bh - border * 2) - fillH
        local fillRect = { pos = Vector2.new(bx, fillY), size = Vector2.new(bw, fillH) }

        return borderRect, bgRect, fillRect

    elseif position == "Top" then
        local bx  = boxTopLeft.X - border
        local by  = boxTopLeft.Y - bw - pad - border
        local bw2 = boxSize.X + border * 2

        local borderRect = { pos = Vector2.new(bx, by),                   size = Vector2.new(bw2, bw + border * 2) }
        local bgRect     = { pos = Vector2.new(bx + border, by + border), size = Vector2.new(bw2 - border * 2, bw) }

        local fillW = math.floor((bw2 - border * 2) * healthPct)
        local fillRect = { pos = Vector2.new(bx + border, by + border), size = Vector2.new(fillW, bw) }

        return borderRect, bgRect, fillRect

    else -- "Bottom"
        local bx  = boxTopLeft.X - border
        local by  = boxTopLeft.Y + boxSize.Y + pad
        local bw2 = boxSize.X + border * 2

        local borderRect = { pos = Vector2.new(bx, by),                   size = Vector2.new(bw2, bw + border * 2) }
        local bgRect     = { pos = Vector2.new(bx + border, by + border), size = Vector2.new(bw2 - border * 2, bw) }

        local fillW = math.floor((bw2 - border * 2) * healthPct)
        local fillRect = { pos = Vector2.new(bx + border, by + border), size = Vector2.new(fillW, bw) }

        return borderRect, bgRect, fillRect
    end
end

-- ── Mise à jour chaque frame ──────────────────────────────────
function Health:Update(character, cfg)
    cfg = cfg or (Config and Config.Current and Config.Current.Health) or {}

    if cfg.Enabled == false or not character then
        self:Hide()
        return
    end

    local topLeft, size2D = Utils.GetBoundingBox2D(character)
    if not topLeft or not size2D then
        self:Hide()
        return
    end

    local healthPct = Utils.GetHealthPercent(character)
    local barColor  = Utils.HealthColor(healthPct)
    local position  = cfg.Position or "Left"
    local barWidth  = cfg.Width or BAR_THICKNESS

    local borderRect, bgRect, fillRect = computeBarBounds(
        position, topLeft, size2D, barWidth, healthPct
    )

    -- Bordure
    self.Border.Position = borderRect.pos
    self.Border.Size     = borderRect.size
    self.Border.Visible  = true

    -- Fond
    self.Background.Position = bgRect.pos
    self.Background.Size     = bgRect.size
    self.Background.Visible  = true

    -- Fill
    if fillRect.size.X > 0 and fillRect.size.Y > 0 then
        self.Bar.Position = fillRect.pos
        self.Bar.Size     = fillRect.size
        self.Bar.Color    = barColor
        self.Bar.Visible  = true
    else
        self.Bar.Visible  = false
    end

    -- Texte %
    if cfg.ShowText then
        local hum = Utils.GetHumanoid(character)
        local hp  = hum and math.floor(hum.Health) or 0
        self.Text.Text     = tostring(hp)
        self.Text.Position = bgRect.pos + bgRect.size / 2
        self.Text.Visible  = true
    else
        self.Text.Visible = false
    end
end

-- ── Cacher ───────────────────────────────────────────────────
function Health:Hide()
    self.Border.Visible     = false
    self.Background.Visible = false
    self.Bar.Visible        = false
    self.Text.Visible       = false
end

-- ── Destruction ──────────────────────────────────────────────
function Health:Remove()
    Utils.RemoveDrawing(self.Border)
    Utils.RemoveDrawing(self.Background)
    Utils.RemoveDrawing(self.Bar)
    Utils.RemoveDrawing(self.Text)
end

return Health
