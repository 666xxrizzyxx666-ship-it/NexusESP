local Health = {}
Health.__index = Health
local Utils, Config
function Health.SetDependencies(u,c) Utils=u; Config=c end

function Health.Create(player)
    local self = setmetatable({}, Health)
    self.Player = player
    self.Border = Utils.NewDrawing("Square", {Filled=true, Color=Color3.new(0,0,0), Visible=false}, 1)
    self.Bg     = Utils.NewDrawing("Square", {Filled=true, Color=Color3.fromRGB(20,20,20), Visible=false}, 1)
    self.Bar    = Utils.NewDrawing("Square", {Filled=true, Color=Color3.fromRGB(0,255,0), Visible=false}, 2)
    -- Pas de Drawing Text pour ShowText car il freeze — on utilise un Text normal
    self.HpText = Utils.NewDrawing("Text",   {Size=10, Color=Color3.new(1,1,1), Outline=true, Center=true, Visible=false}, 3)
    return self
end

function Health:Update(character, cfg)
    self.Border.Visible = false
    self.Bg.Visible     = false
    self.Bar.Visible    = false
    self.HpText.Visible = false

    cfg = cfg or {}
    if not cfg.Enabled or not character then return end

    local tl, sz = Utils.GetBoundingBox2D(character)
    if not tl or not sz or sz.X < 2 or sz.Y < 2 then return end

    local hp  = Utils.GetHealthPercent(character)
    local pos = cfg.Position or "Left"
    local bw  = math.max(2, cfg.Width or 3)
    local pad = 3

    local bx, by, bh, bww, fillH, fillW

    if pos == "Left" then
        bx=tl.X-bw-pad-1; by=tl.Y-1; bh=sz.Y+2; bww=bw
        fillH = math.max(1, math.floor(bh * hp))
        self.Border.Position=Vector2.new(bx-1,by-1); self.Border.Size=Vector2.new(bww+2,bh+2)
        self.Bg.Position    =Vector2.new(bx,  by);   self.Bg.Size    =Vector2.new(bww,  bh)
        self.Bar.Position   =Vector2.new(bx,  by+bh-fillH); self.Bar.Size=Vector2.new(bww, fillH)
        if cfg.ShowText then
            self.HpText.Position = Vector2.new(bx+bww/2, by+bh/2-5)
        end
    elseif pos == "Right" then
        bx=tl.X+sz.X+pad; by=tl.Y-1; bh=sz.Y+2; bww=bw
        fillH = math.max(1, math.floor(bh * hp))
        self.Border.Position=Vector2.new(bx-1,by-1); self.Border.Size=Vector2.new(bww+2,bh+2)
        self.Bg.Position    =Vector2.new(bx,  by);   self.Bg.Size    =Vector2.new(bww,  bh)
        self.Bar.Position   =Vector2.new(bx,  by+bh-fillH); self.Bar.Size=Vector2.new(bww, fillH)
        if cfg.ShowText then
            self.HpText.Position = Vector2.new(bx+bww/2, by+bh/2-5)
        end
    elseif pos == "Top" then
        bx=tl.X-1; by=tl.Y-bw-pad-1; bww=sz.X+2; bh=bw
        fillW = math.max(1, math.floor(bww * hp))
        self.Border.Position=Vector2.new(bx-1, by-1); self.Border.Size=Vector2.new(bww+2,bh+2)
        self.Bg.Position    =Vector2.new(bx,   by);   self.Bg.Size    =Vector2.new(bww,  bh)
        self.Bar.Position   =Vector2.new(bx,   by);   self.Bar.Size   =Vector2.new(fillW,bh)
        if cfg.ShowText then
            self.HpText.Position = Vector2.new(bx+bww/2, by-12)
        end
    else -- Bottom
        bx=tl.X-1; by=tl.Y+sz.Y+pad; bww=sz.X+2; bh=bw
        fillW = math.max(1, math.floor(bww * hp))
        self.Border.Position=Vector2.new(bx-1, by-1); self.Border.Size=Vector2.new(bww+2,bh+2)
        self.Bg.Position    =Vector2.new(bx,   by);   self.Bg.Size    =Vector2.new(bww,  bh)
        self.Bar.Position   =Vector2.new(bx,   by);   self.Bar.Size   =Vector2.new(fillW or bww, bh)
        if cfg.ShowText then
            self.HpText.Position = Vector2.new(bx+bww/2, by+bh+2)
        end
    end

    self.Bar.Color      = Utils.HealthColor(hp)
    self.Border.Visible = true
    self.Bg.Visible     = true
    self.Bar.Visible    = hp > 0

    if cfg.ShowText then
        local hum = Utils.GetHumanoid(character)
        if hum and hum.MaxHealth > 0 then
            self.HpText.Text    = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
            self.HpText.Size    = 9
            self.HpText.Visible = true
        end
    end
end

function Health:Hide()
    self.Border.Visible = false
    self.Bg.Visible     = false
    self.Bar.Visible    = false
    self.HpText.Visible = false
end

function Health:Remove()
    Utils.RemoveDrawing(self.Border)
    Utils.RemoveDrawing(self.Bg)
    Utils.RemoveDrawing(self.Bar)
    Utils.RemoveDrawing(self.HpText)
end

return Health
