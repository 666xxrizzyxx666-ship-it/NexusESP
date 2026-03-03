-- ============================================================
--  Health.lua — Barre de sante dynamique (vert→rouge)
-- ============================================================
local Health = {}
Health.__index = Health

local Utils, Config

function Health.SetDependencies(u, c) Utils = u; Config = c end

function Health.Create(player)
    local self = setmetatable({}, Health)
    self.Player = player
    self.Border = Utils.NewDrawing("Square", { Filled=true, Color=Color3.new(0,0,0), Visible=false })
    self.Bg     = Utils.NewDrawing("Square", { Filled=true, Color=Color3.fromRGB(20,20,20), Visible=false })
    self.Bar    = Utils.NewDrawing("Square", { Filled=true, Color=Color3.fromRGB(0,255,0), Visible=false })
    self.Text   = Utils.NewDrawing("Text",   { Size=10, Color=Color3.new(1,1,1), Outline=true, Center=true, Visible=false })
    return self
end

function Health:Update(character, cfg)
    cfg = cfg or {}
    if not cfg.Enabled or not character then self:Hide(); return end

    local tl, sz = Utils.GetBoundingBox2D(character)
    if not tl or not sz then self:Hide(); return end

    local hp  = Utils.GetHealthPercent(character)
    local pos = cfg.Position or "Left"
    local bw  = cfg.Width or 3
    local pad = 3

    local bx, by, bh, bw2, fillW, fillH, fillX, fillY

    if pos == "Left" then
        bx = tl.X - bw - pad - 1
        by = tl.Y - 1
        bh = sz.Y + 2
        bw2 = bw
        fillH = math.max(1, math.floor(bh * hp))
        fillX = bx
        fillY = by + bh - fillH

        self.Border.Position = Vector2.new(bx-1, by-1);    self.Border.Size = Vector2.new(bw2+2, bh+2)
        self.Bg.Position     = Vector2.new(bx,   by);      self.Bg.Size     = Vector2.new(bw2,   bh)
        self.Bar.Position    = Vector2.new(fillX, fillY);  self.Bar.Size    = Vector2.new(bw2,   fillH)

    elseif pos == "Right" then
        bx = tl.X + sz.X + pad
        by = tl.Y - 1
        bh = sz.Y + 2
        bw2 = bw
        fillH = math.max(1, math.floor(bh * hp))
        fillX = bx
        fillY = by + bh - fillH

        self.Border.Position = Vector2.new(bx-1, by-1);    self.Border.Size = Vector2.new(bw2+2, bh+2)
        self.Bg.Position     = Vector2.new(bx,   by);      self.Bg.Size     = Vector2.new(bw2,   bh)
        self.Bar.Position    = Vector2.new(fillX, fillY);  self.Bar.Size    = Vector2.new(bw2,   fillH)

    elseif pos == "Top" then
        bx = tl.X - 1
        by = tl.Y - bw - pad - 1
        bw2 = sz.X + 2
        bh = bw
        fillW = math.max(1, math.floor(bw2 * hp))

        self.Border.Position = Vector2.new(bx-1,  by-1);  self.Border.Size = Vector2.new(bw2+2, bh+2)
        self.Bg.Position     = Vector2.new(bx,    by);    self.Bg.Size     = Vector2.new(bw2,   bh)
        self.Bar.Position    = Vector2.new(bx,    by);    self.Bar.Size    = Vector2.new(fillW, bh)

    else -- Bottom
        bx = tl.X - 1
        by = tl.Y + sz.Y + pad
        bw2 = sz.X + 2
        bh = bw
        fillW = math.max(1, math.floor(bw2 * hp))

        self.Border.Position = Vector2.new(bx-1,  by-1);  self.Border.Size = Vector2.new(bw2+2, bh+2)
        self.Bg.Position     = Vector2.new(bx,    by);    self.Bg.Size     = Vector2.new(bw2,   bh)
        self.Bar.Position    = Vector2.new(bx,    by);    self.Bar.Size    = Vector2.new(fillW or bw2, bh)
    end

    self.Bar.Color    = Utils.HealthColor(hp)
    self.Border.Visible = true
    self.Bg.Visible     = true
    self.Bar.Visible    = (hp > 0)

    if cfg.ShowText then
        local hum = Utils.GetHumanoid(character)
        self.Text.Text     = hum and math.floor(hum.Health) or "?"
        self.Text.Position = self.Bg.Position + self.Bg.Size / 2
        self.Text.Visible  = true
    else
        self.Text.Visible = false
    end
end

function Health:Hide()
    self.Border.Visible = false
    self.Bg.Visible     = false
    self.Bar.Visible    = false
    self.Text.Visible   = false
end

function Health:Remove()
    Utils.RemoveDrawing(self.Border)
    Utils.RemoveDrawing(self.Bg)
    Utils.RemoveDrawing(self.Bar)
    Utils.RemoveDrawing(self.Text)
end

return Health
