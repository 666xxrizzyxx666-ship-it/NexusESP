-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/Name.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Name tag ESP
-- ══════════════════════════════════════════════════════

local Name = {}

local function newText()
    local t = Drawing.new("Text")
    t.Visible  = false
    t.Outline  = false
    t.Center   = true
    t.Font     = Drawing.Fonts.Plex
    return t
end

function Name.Create()
    return {text = newText()}
end

function Name.Update(d, bb, name, cfg)
    if not d or not bb then return end

    local color   = cfg.Color and Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B) or Color3.new(1,1,1)
    local size    = cfg.Size    or 13
    local offsetY = cfg.OffsetY or 5

    d.text.Text     = name
    d.text.Size     = size
    d.text.Color    = color
    d.text.Position = Vector2.new(bb.cx, bb.y - offsetY - size)
    d.text.Visible  = true
end

function Name.Hide(d)
    if d and d.text then d.text.Visible = false end
end

function Name.Remove(d)
    if d and d.text then pcall(function() d.text:Remove() end) end
end

return Name
