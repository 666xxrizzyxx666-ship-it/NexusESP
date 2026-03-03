-- ============================================================
--  Box.lua — Bounding Box 2D autour d'un character Roblox
--  Supporte : coin-to-corner box, filled box, outline box
--  Utilise Drawing.new("Square")
-- ============================================================

local Box = {}
Box.__index = Box

-- ── Dépendances (injectées par ESP.lua) ─────────────────────
local Utils  -- will be injected
local Config -- will be injected

function Box.SetDependencies(utils, config)
    Utils  = utils
    Config = config
end

-- ── Constructeur ─────────────────────────────────────────────
-- player : Player instance
-- Retourne une instance Box avec ses Drawing objects
function Box.Create(player)
    local self = setmetatable({}, Box)

    self.Player  = player
    self.Enabled = false

    -- Drawing de l'outline
    self.Outline = Utils.NewDrawing("Square", {
        Thickness    = 3,
        Color        = Color3.new(0, 0, 0),
        Filled       = false,
        Visible      = false,
    })

    -- Drawing du cadre principal
    self.Frame = Utils.NewDrawing("Square", {
        Thickness    = 1,
        Color        = Color3.new(1, 1, 1),
        Filled       = false,
        Visible      = false,
    })

    -- Drawing du fill (semi-transparent)
    self.Fill = Utils.NewDrawing("Square", {
        Thickness    = 1,
        Color        = Color3.new(1, 1, 1),
        Filled       = true,
        Transparency = 0.5,
        Visible      = false,
    })

    return self
end

-- ── Mise à jour chaque frame ──────────────────────────────────
function Box:Update(character, cfg)
    cfg = cfg or (Config and Config.Current and Config.Current.Box) or {}

    local enabled = cfg.Enabled ~= false

    if not enabled or not character then
        self:Hide()
        return
    end

    local topLeft, size2D, _ = Utils.GetBoundingBox2D(character)
    if not topLeft or not size2D then
        self:Hide()
        return
    end

    -- Limite min size pour éviter les minuscules boîtes
    if size2D.X < 4 or size2D.Y < 4 then
        self:Hide()
        return
    end

    local color     = cfg.Color and Utils.NewDrawing and
                      Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B)
                      or Color3.new(1, 1, 1)
    local thickness = cfg.Thickness or 1
    local filled    = cfg.Filled or false

    -- Outline (légèrement agrandi, noir)
    local pad = 1
    self.Outline.Position    = topLeft - Vector2.new(pad, pad)
    self.Outline.Size        = size2D  + Vector2.new(pad * 2, pad * 2)
    self.Outline.Thickness   = thickness + 2
    self.Outline.Color       = Color3.new(0, 0, 0)
    self.Outline.Visible     = true

    -- Frame principal
    self.Frame.Position  = topLeft
    self.Frame.Size      = size2D
    self.Frame.Thickness = thickness
    self.Frame.Color     = color
    self.Frame.Visible   = true

    -- Fill optionnel
    if filled then
        local fc = cfg.FillColor and
                   Color3.fromRGB(cfg.FillColor.R, cfg.FillColor.G, cfg.FillColor.B)
                   or color
        self.Fill.Position     = topLeft
        self.Fill.Size         = size2D
        self.Fill.Color        = fc
        self.Fill.Transparency = cfg.FillTrans or 0.5
        self.Fill.Visible      = true
    else
        self.Fill.Visible = false
    end
end

-- ── Cacher tous les drawings ─────────────────────────────────
function Box:Hide()
    self.Outline.Visible = false
    self.Frame.Visible   = false
    self.Fill.Visible    = false
end

-- ── Destruction ──────────────────────────────────────────────
function Box:Remove()
    Utils.RemoveDrawing(self.Outline)
    Utils.RemoveDrawing(self.Frame)
    Utils.RemoveDrawing(self.Fill)
end

return Box
