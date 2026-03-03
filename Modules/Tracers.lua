-- ============================================================
--  Tracers.lua — Ligne depuis un point d'ancrage vers l'entité
--  Positions source : "Bottom" | "Center" | "Top"
-- ============================================================

local Tracers = {}
Tracers.__index = Tracers

local Utils
local Config

function Tracers.SetDependencies(utils, config)
    Utils  = utils
    Config = config
end

-- ── Constructeur ─────────────────────────────────────────────
function Tracers.Create(player)
    local self = setmetatable({}, Tracers)
    self.Player = player

    self.Outline = Utils.NewDrawing("Line", {
        Thickness = 3,
        Color     = Color3.new(0, 0, 0),
        Visible   = false,
    })

    self.Line = Utils.NewDrawing("Line", {
        Thickness = 1,
        Color     = Color3.new(1, 1, 1),
        Visible   = false,
    })

    return self
end

-- ── Point source selon la position configurée ────────────────
local function getSourcePoint(position)
    local vp     = Utils.GetViewport()
    local center = Vector2.new(vp.X / 2, vp.Y / 2)

    if position == "Center" then
        return center
    elseif position == "Top" then
        return Vector2.new(vp.X / 2, 0)
    else -- "Bottom" (défaut)
        return Vector2.new(vp.X / 2, vp.Y)
    end
end

-- ── Mise à jour chaque frame ──────────────────────────────────
function Tracers:Update(character, cfg)
    cfg = cfg or (Config and Config.Current and Config.Current.Tracers) or {}

    if cfg.Enabled == false or not character then
        self:Hide()
        return
    end

    local root = Utils.GetRoot(character)
    if not root then
        self:Hide()
        return
    end

    local targetPos, onScreen = Utils.W2V(root.Position)
    if not onScreen then
        self:Hide()
        return
    end

    local color     = cfg.Color and
                      Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B)
                      or Color3.new(1, 1, 1)
    local thickness = cfg.Thickness or 1
    local srcPos    = getSourcePoint(cfg.Position or "Bottom")

    -- Outline
    self.Outline.From      = srcPos
    self.Outline.To        = targetPos
    self.Outline.Thickness = thickness + 2
    self.Outline.Color     = Color3.new(0, 0, 0)
    self.Outline.Visible   = true

    -- Ligne principale
    self.Line.From      = srcPos
    self.Line.To        = targetPos
    self.Line.Thickness = thickness
    self.Line.Color     = color
    self.Line.Visible   = true
end

-- ── Cacher ───────────────────────────────────────────────────
function Tracers:Hide()
    self.Outline.Visible = false
    self.Line.Visible    = false
end

-- ── Destruction ──────────────────────────────────────────────
function Tracers:Remove()
    Utils.RemoveDrawing(self.Outline)
    Utils.RemoveDrawing(self.Line)
end

return Tracers
