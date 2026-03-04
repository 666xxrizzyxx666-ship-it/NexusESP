-- Health: bar and HP text are fully independent
local Health = {}; Health.__index = Health
local Utils, Config
function Health.SetDependencies(u,c) Utils=u; Config=c end

function Health.Create()
    local s = setmetatable({}, Health)
    s.Bg   = Utils.NewDrawing("Square", {Filled=true, Color=Color3.fromRGB(20,20,20)})
    s.Bar  = Utils.NewDrawing("Square", {Filled=true, Color=Color3.fromRGB(40,220,80)})
    s.Text = Utils.NewDrawing("Text",   {Size=10, Color=Color3.new(1,1,1), Outline=true, Center=true})
    return s
end

function Health:Update(char, cfg)
    self.Bg.Visible=false; self.Bar.Visible=false; self.Text.Visible=false
    if not cfg or not char then return end

    local tl, sz = Utils.GetBoundingBox2D(char)
    if not tl or not sz then return end

    local hp  = Utils.GetHealthPercent(char)
    local pos = cfg.Position or "Left"
    local bw  = math.max(2, cfg.Width or 3)
    local pad = 3

    -- Bar
    if cfg.Enabled then
        local bx, by, bh, bww, fillH, fillW
        if pos=="Left" then
            bx=tl.X-bw-pad; by=tl.Y; bh=sz.Y; bww=bw
            fillH=math.max(1,math.floor(bh*hp))
            self.Bg.Position =Vector2.new(bx,by);          self.Bg.Size =Vector2.new(bww,bh)
            self.Bar.Position=Vector2.new(bx,by+bh-fillH); self.Bar.Size=Vector2.new(bww,fillH)
        elseif pos=="Right" then
            bx=tl.X+sz.X+pad; by=tl.Y; bh=sz.Y; bww=bw
            fillH=math.max(1,math.floor(bh*hp))
            self.Bg.Position =Vector2.new(bx,by);          self.Bg.Size =Vector2.new(bww,bh)
            self.Bar.Position=Vector2.new(bx,by+bh-fillH); self.Bar.Size=Vector2.new(bww,fillH)
        elseif pos=="Top" then
            bx=tl.X; by=tl.Y-bw-pad; bww=sz.X; bh=bw
            fillW=math.max(1,math.floor(bww*hp))
            self.Bg.Position =Vector2.new(bx,by);  self.Bg.Size =Vector2.new(bww,bh)
            self.Bar.Position=Vector2.new(bx,by);  self.Bar.Size=Vector2.new(fillW,bh)
        else -- Bottom
            bx=tl.X; by=tl.Y+sz.Y+pad; bww=sz.X; bh=bw
            fillW=math.max(1,math.floor(bww*hp))
            self.Bg.Position =Vector2.new(bx,by); self.Bg.Size =Vector2.new(bww,bh)
            self.Bar.Position=Vector2.new(bx,by); self.Bar.Size=Vector2.new(fillW or bww,bh)
        end
        self.Bar.Color    = Utils.HealthColor(hp)
        self.Bg.Visible   = true
        self.Bar.Visible  = hp > 0
    end

    -- HP text: independent, always above head
    if cfg.ShowText then
        local top = Utils.GetCharTop(char)
        if top then
            local sp, on = Utils.W2V(top)
            if on then
                local hum = Utils.GetHumanoid(char)
                self.Text.Text     = hum and math.floor(hum.Health).."/"..math.floor(hum.MaxHealth) or "?"
                self.Text.Position = Vector2.new(sp.X, sp.Y - 28)
                self.Text.Size     = 10
                self.Text.Visible  = true
            end
        end
    end
end

function Health:Hide()
    self.Bg.Visible=false; self.Bar.Visible=false; self.Text.Visible=false
end
function Health:Remove()
    Utils.Kill(self.Bg); Utils.Kill(self.Bar); Utils.Kill(self.Text)
end
return Health
