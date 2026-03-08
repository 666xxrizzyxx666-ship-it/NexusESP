-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/Distance.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Distance tag ESP
-- ══════════════════════════════════════════════════════

local Distance = {}

local function newText()
    local t = Drawing.new("Text")
    t.Visible  = false
    t.Outline  = false
    t.Center   = true
    t.Font     = Drawing.Fonts.Plex
    return t
end

function Distance.Create()
    return {text = newText()}
end

function Distance.Update(d, bb, dist, cfg)
    if not d or not bb then return end

    local color = cfg.Color and Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B) or Color3.fromRGB(180,180,180)
    local size  = cfg.Size  or 11

    d.text.Text     = dist .. "m"
    d.text.Size     = size
    d.text.Color    = color
    d.text.Position = Vector2.new(bb.cx, bb.y + bb.height + 4)
    d.text.Visible  = true
end

function Distance.Hide(d)
    if d and d.text then d.text.Visible = false end
end

function Distance.Remove(d)
    if d and d.text then pcall(function() d.text:Remove() end) end
end

return Distance
