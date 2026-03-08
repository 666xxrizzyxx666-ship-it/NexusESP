-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Components/Slider.lua
--   📁 Dossier : UI/Components/
--   Rôle : Slider avec preview valeur en temps réel
-- ══════════════════════════════════════════════════════

local Slider = {}
Slider.__index = Slider

local UIS = game:GetService("UserInputService")
local Theme, Animation

local function makeCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(1,0)
    return c
end

function Slider.Init(theme, anim)
    Theme     = theme
    Animation = anim
end

function Slider.new(parent, opts)
    opts = opts or {}
    local self    = setmetatable({}, Slider)

    self.min      = opts.min      or 0
    self.max      = opts.max      or 100
    self.value    = opts.default  or opts.min or 0
    self.step     = opts.step     or 1
    self.suffix   = opts.suffix   or ""
    self.label    = opts.label    or "Slider"
    self.callback = opts.onChange or opts.onClick or opts.callback or function() end
    self.dragging = false

    -- Container
    local row = Instance.new("Frame", parent)
    row.Name               = "Slider_"..self.label
    row.BackgroundTransparency = 1
    row.BorderSizePixel    = 0
    row.Size               = UDim2.new(1, 0, 0, 48)
    row.LayoutOrder        = opts.order or 0

    -- Label + valeur
    local lbl = Instance.new("TextLabel", row)
    lbl.Text               = self.label
    lbl.Font               = Theme.Fonts.Medium
    lbl.TextSize           = Theme.TextSize.Body
    lbl.TextColor3         = Theme.Colors.Text
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Size               = UDim2.new(1,-60,0,18)
    lbl.Position           = UDim2.fromOffset(10, 6)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local valLabel = Instance.new("TextLabel", row)
    valLabel.Text          = tostring(self.value)..self.suffix
    valLabel.Font          = Theme.Fonts.Bold
    valLabel.TextSize      = Theme.TextSize.Body
    valLabel.TextColor3    = Theme.Colors.Accent
    valLabel.BackgroundTransparency = 1
    valLabel.BorderSizePixel = 0
    valLabel.Size          = UDim2.new(0, 55, 0, 18)
    valLabel.Position      = UDim2.new(1,-65,0,6)
    valLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- Track background
    local trackBg = Instance.new("Frame", row)
    trackBg.BackgroundColor3 = Theme.Colors.SurfaceAlt
    trackBg.BorderSizePixel  = 0
    trackBg.Size             = UDim2.new(1,-20,0, Theme.Size.SliderHeight)
    trackBg.Position         = UDim2.new(0,10,0,30)
    makeCorner(trackBg, UDim.new(1,0))

    -- Track fill
    local trackFill = Instance.new("Frame", trackBg)
    trackFill.BackgroundColor3 = Theme.Colors.Accent
    trackFill.BorderSizePixel  = 0
    trackFill.Size             = UDim2.new(0,0,1,0)
    makeCorner(trackFill, UDim.new(1,0))

    -- Knob
    local knobSize = Theme.Size.SliderKnob
    local knob = Instance.new("Frame", trackBg)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    knob.Size             = UDim2.fromOffset(knobSize, knobSize)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new(0,0,0.5,0)
    knob.ZIndex           = 2
    makeCorner(knob, UDim.new(1,0))
    Instance.new("UIStroke", knob).Color = Theme.Colors.Border

    self._row        = row
    self._trackBg    = trackBg
    self._trackFill  = trackFill
    self._knob       = knob
    self._valLabel   = valLabel

    -- Met à jour visuellement
    local function updateVisual(v)
        local pct = (v - self.min) / (self.max - self.min)
        pct = math.clamp(pct, 0, 1)
        trackFill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position  = UDim2.new(pct, 0, 0.5, 0)
        valLabel.Text  = tostring(v)..self.suffix
    end

    -- Calcule la valeur depuis position souris
    local function calcValue(inputX)
        local abs = trackBg.AbsolutePosition.X
        local wid = trackBg.AbsoluteSize.X
        local pct = math.clamp((inputX - abs) / wid, 0, 1)
        local raw = self.min + pct * (self.max - self.min)
        local stepped = math.round(raw / self.step) * self.step
        return math.clamp(stepped, self.min, self.max)
    end

    -- Input
    trackBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            self.dragging = true
            local v = calcValue(i.Position.X)
            self:Set(v)
            Animation.Tween(knob, {Size = UDim2.fromOffset(knobSize+4, knobSize+4)}, TweenInfo.new(0.1))
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if not self.dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local v = calcValue(i.Position.X)
            self:Set(v)
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            self.dragging = false
            Animation.Tween(knob, {Size = UDim2.fromOffset(knobSize, knobSize)}, TweenInfo.new(0.1))
        end
    end)

    updateVisual(self.value)
    return self
end

function Slider:Set(v)
    v = math.clamp(v, self.min, self.max)
    v = math.round(v / self.step) * self.step
    self.value = v
    local pct  = (v - self.min) / (self.max - self.min)
    pct = math.clamp(pct, 0, 1)
    self._trackFill.Size = UDim2.new(pct, 0, 1, 0)
    self._knob.Position  = UDim2.new(pct, 0, 0.5, 0)
    self._valLabel.Text  = tostring(v)..self.suffix
    pcall(self.callback, v)
end

function Slider:Get()
    return self.value
end

function Slider:Destroy()
    if self._row then self._row:Destroy() end
end

return Slider
