-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/CornerBox.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Corner box ESP — coins uniquement
--          Pas de continue keyword
-- ══════════════════════════════════════════════════════

local CornerBox = {}

local function newLine()
    local l = Drawing.new("Line")
    l.Visible  = false
    l.ZIndex   = 2
    l.Outline  = false
    return l
end

function CornerBox.Create()
    -- 8 lignes : 2 par coin (H + V)
    local d = {}
    for i = 1, 8 do
        d[i] = newLine()
    end
    return d
end

function CornerBox.Update(d, bb, cfg)
    if not d or not bb then return end

    local x, y = bb.x, bb.y
    local w, h = bb.width, bb.height
    local color = cfg.Color and Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B) or Color3.new(1,1,1)
    local thick = cfg.Thickness or 1
    local cw    = math.max(4, math.floor(w * 0.25))
    local ch    = math.max(4, math.floor(h * 0.25))

    -- Coin haut gauche — horizontal
    d[1].From = Vector2.new(x,      y)
    d[1].To   = Vector2.new(x + cw, y)
    -- Coin haut gauche — vertical
    d[2].From = Vector2.new(x, y)
    d[2].To   = Vector2.new(x, y + ch)

    -- Coin haut droit — horizontal
    d[3].From = Vector2.new(x + w - cw, y)
    d[3].To   = Vector2.new(x + w,      y)
    -- Coin haut droit — vertical
    d[4].From = Vector2.new(x + w, y)
    d[4].To   = Vector2.new(x + w, y + ch)

    -- Coin bas gauche — horizontal
    d[5].From = Vector2.new(x,      y + h)
    d[5].To   = Vector2.new(x + cw, y + h)
    -- Coin bas gauche — vertical
    d[6].From = Vector2.new(x, y + h - ch)
    d[6].To   = Vector2.new(x, y + h)

    -- Coin bas droit — horizontal
    d[7].From = Vector2.new(x + w - cw, y + h)
    d[7].To   = Vector2.new(x + w,      y + h)
    -- Coin bas droit — vertical
    d[8].From = Vector2.new(x + w, y + h - ch)
    d[8].To   = Vector2.new(x + w, y + h)

    for i = 1, 8 do
        d[i].Color     = color
        d[i].Thickness = thick
        d[i].Visible   = true
    end
end

function CornerBox.Hide(d)
    if not d then return end
    for i = 1, 8 do
        if d[i] then d[i].Visible = false end
    end
end

function CornerBox.Remove(d)
    if not d then return end
    for i = 1, 8 do
        if d[i] then pcall(function() d[i]:Remove() end) end
    end
end

return CornerBox
