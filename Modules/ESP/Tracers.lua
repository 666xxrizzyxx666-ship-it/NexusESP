-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/Tracers.lua
--   📁 Dossier : Modules/ESP/
-- ══════════════════════════════════════════════════════

local Tracers = {}
local Camera  = workspace.CurrentCamera

local function newLine()
    local l = Drawing.new("Line")
    l.Visible  = false
    l.ZIndex   = 1
    l.Outline  = false
    return l
end

function Tracers.Create()
    return {line = newLine()}
end

function Tracers.Update(d, bb, cfg)
    if not d or not bb then return end
    local vp     = Camera.ViewportSize
    local color  = cfg.Color and Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B) or Color3.new(1,1,1)
    local thick  = cfg.Thickness or 1
    local pos    = cfg.Position or "Bottom"

    local fromX  = vp.X / 2
    local fromY  = pos == "Top" and 0 or vp.Y

    local toX    = bb.cx
    local toY    = pos == "Top" and bb.y or (bb.y + bb.height)

    d.line.From      = Vector2.new(fromX, fromY)
    d.line.To        = Vector2.new(toX,   toY)
    d.line.Color     = color
    d.line.Thickness = thick
    d.line.Visible   = true
end

function Tracers.Hide(d)
    if d and d.line then d.line.Visible = false end
end

function Tracers.Remove(d)
    if d and d.line then pcall(function() d.line:Remove() end) end
end

return Tracers
