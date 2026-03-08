-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/Box.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Box ESP — 4 Lines (pas Square)
--          Thickness fiable + fill optionnel
-- ══════════════════════════════════════════════════════

local Box = {}

local function newLine()
    local l = Drawing.new("Line")
    l.Visible   = false
    l.ZIndex    = 2
    l.Outline   = false
    return l
end

local function newQuad()
    local q = Drawing.new("Quad")
    q.Visible   = false
    q.ZIndex    = 1
    q.Outline   = false
    return q
end

function Box.Create()
    return {
        top    = newLine(),
        bottom = newLine(),
        left   = newLine(),
        right  = newLine(),
        fill   = newQuad(),
    }
end

function Box.Update(d, bb, cfg)
    if not d or not bb then return end

    local x, y   = bb.x, bb.y
    local w, h   = bb.width, bb.height
    local color  = cfg.Color and Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B) or Color3.new(1,1,1)
    local thick  = cfg.Thickness or 1

    -- Top
    d.top.From    = Vector2.new(x,     y)
    d.top.To      = Vector2.new(x + w, y)
    d.top.Color   = color
    d.top.Thickness = thick
    d.top.Visible = true

    -- Bottom
    d.bottom.From    = Vector2.new(x,     y + h)
    d.bottom.To      = Vector2.new(x + w, y + h)
    d.bottom.Color   = color
    d.bottom.Thickness = thick
    d.bottom.Visible = true

    -- Left
    d.left.From    = Vector2.new(x, y)
    d.left.To      = Vector2.new(x, y + h)
    d.left.Color   = color
    d.left.Thickness = thick
    d.left.Visible = true

    -- Right
    d.right.From    = Vector2.new(x + w, y)
    d.right.To      = Vector2.new(x + w, y + h)
    d.right.Color   = color
    d.right.Thickness = thick
    d.right.Visible = true

    -- Fill
    if cfg.Filled then
        local fc    = cfg.FillColor and Color3.fromRGB(cfg.FillColor.R, cfg.FillColor.G, cfg.FillColor.B) or Color3.fromRGB(255,60,60)
        local ft    = cfg.FillTrans or 0.7
        d.fill.PointA = Vector2.new(x,     y)
        d.fill.PointB = Vector2.new(x + w, y)
        d.fill.PointC = Vector2.new(x + w, y + h)
        d.fill.PointD = Vector2.new(x,     y + h)
        d.fill.Color  = fc
        d.fill.Transparency = ft
        d.fill.Visible = true
    else
        d.fill.Visible = false
    end
end

function Box.Hide(d)
    if not d then return end
    d.top.Visible    = false
    d.bottom.Visible = false
    d.left.Visible   = false
    d.right.Visible  = false
    d.fill.Visible   = false
end

function Box.Remove(d)
    if not d then return end
    for _, v in pairs(d) do
        pcall(function() v:Remove() end)
    end
end

return Box
