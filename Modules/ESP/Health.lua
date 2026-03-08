-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/Health.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Health bar + HP text
-- ══════════════════════════════════════════════════════

local Health = {}

local function newLine()
    local l = Drawing.new("Line")
    l.Visible  = false
    l.ZIndex   = 2
    l.Outline  = false
    return l
end

local function newText()
    local t = Drawing.new("Text")
    t.Visible  = false
    t.Outline  = false
    t.Center   = true
    t.Font     = Drawing.Fonts.Plex
    return t
end

local function getHealthColor(pct)
    if pct > 0.6 then return Color3.fromRGB(74,222,128)
    elseif pct > 0.3 then return Color3.fromRGB(251,191,36)
    else return Color3.fromRGB(248,113,113) end
end

function Health.Create()
    return {
        bg   = newLine(),
        bar  = newLine(),
        text = newText(),
    }
end

function Health.Update(d, bb, hp, maxHp, cfg)
    if not d or not bb then return end

    local pct    = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0
    local color  = getHealthColor(pct)
    local pos    = cfg.Position or "Left"
    local width  = cfg.Width    or 3
    local offset = 4 + width

    local x, y, w, h = bb.x, bb.y, bb.width, bb.height

    local bx, by, bTo

    if pos == "Left" then
        bx  = x - offset
        by  = y
        bTo = y + h
    elseif pos == "Right" then
        bx  = x + w + offset
        by  = y
        bTo = y + h
    else
        -- Bottom
        bx  = x
        by  = y + h + offset
        bTo = x + w
    end

    -- Background
    d.bg.From      = pos == "Bottom" and Vector2.new(bx, by)    or Vector2.new(bx, by)
    d.bg.To        = pos == "Bottom" and Vector2.new(bTo, by)   or Vector2.new(bx, bTo)
    d.bg.Color     = Color3.fromRGB(20,20,20)
    d.bg.Thickness = width
    d.bg.Visible   = true

    -- Bar
    local fillLen = (pos == "Bottom" and w or h) * pct
    d.bar.From     = d.bg.From
    d.bar.To       = pos == "Bottom"
        and Vector2.new(bx + fillLen, by)
        or  Vector2.new(bx, by + (h - fillLen))
    d.bar.Color     = color
    d.bar.Thickness = width
    d.bar.Visible   = true

    -- HP text
    if cfg.ShowText then
        local hpInt = math.floor(hp)
        d.text.Text     = tostring(hpInt)
        d.text.Size     = 10
        d.text.Color    = color
        d.text.Position = pos == "Left"
            and Vector2.new(bx - 2, by + h/2 - 5)
            or  Vector2.new(bx + 2, by + h/2 - 5)
        d.text.Visible  = true
    else
        d.text.Visible  = false
    end
end

function Health.Hide(d)
    if not d then return end
    d.bg.Visible   = false
    d.bar.Visible  = false
    d.text.Visible = false
end

function Health.Remove(d)
    if not d then return end
    pcall(function() d.bg:Remove()   end)
    pcall(function() d.bar:Remove()  end)
    pcall(function() d.text:Remove() end)
end

return Health
