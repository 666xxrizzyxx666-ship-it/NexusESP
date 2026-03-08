-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Components/ColorPicker.lua
--   📁 Dossier : UI/Components/
--   Rôle : Color picker HSV complet
-- ══════════════════════════════════════════════════════

local ColorPicker = {}
ColorPicker.__index = ColorPicker

local UIS = game:GetService("UserInputService")
local Theme, Animation

local function makeCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0,8)
    return c
end

local function makeStroke(p, color, thick)
    local s = Instance.new("UIStroke", p)
    s.Color     = color or Color3.fromRGB(30,30,50)
    s.Thickness = thick or 1
    return s
end

function ColorPicker.Init(theme, anim)
    Theme     = theme
    Animation = anim
end

function ColorPicker.new(parent, opts)
    opts = opts or {}
    local self     = setmetatable({}, ColorPicker)

    self.label     = opts.label    or "Couleur"
    self.value     = opts.default  or Color3.fromRGB(255,255,255)
    self.callback  = opts.callback or function() end
    self.open      = false

    local h, s, v = Color3.toHSV(self.value)
    self._h = h; self._s = s; self._v = v

    -- Row
    local row = Instance.new("Frame", parent)
    row.Name               = "ColorPicker_"..self.label
    row.BackgroundTransparency = 1
    row.BorderSizePixel    = 0
    row.Size               = UDim2.new(1,0,0,34)
    row.LayoutOrder        = opts.order or 0
    row.ClipsDescendants   = false

    -- Label
    local lbl = Instance.new("TextLabel", row)
    lbl.Text               = self.label
    lbl.Font               = Theme.Fonts.Medium
    lbl.TextSize           = Theme.TextSize.Body
    lbl.TextColor3         = Theme.Colors.Text
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Size               = UDim2.new(1,-50,1,0)
    lbl.Position           = UDim2.fromOffset(10,0)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    -- Preview swatch
    local swatch = Instance.new("TextButton", row)
    swatch.BackgroundColor3 = self.value
    swatch.BorderSizePixel  = 0
    swatch.Size             = UDim2.fromOffset(28,20)
    swatch.Position         = UDim2.new(1,-38,0.5,-10)
    swatch.Text             = ""
    swatch.AutoButtonColor  = false
    makeCorner(swatch, UDim.new(0,4))
    makeStroke(swatch, Theme.Colors.Border)

    self._row    = row
    self._swatch = swatch

    -- Popup
    self._popup = self:_buildPopup(row)

    swatch.MouseButton1Click:Connect(function()
        if self.open then self:ClosePopup() else self:OpenPopup() end
    end)

    return self
end

function ColorPicker:_buildPopup(parent)
    local popup = Instance.new("Frame", parent)
    popup.Name             = "Popup"
    popup.BackgroundColor3 = Theme.Colors.Surface
    popup.BorderSizePixel  = 0
    popup.Size             = UDim2.fromOffset(200,160)
    popup.Position         = UDim2.new(1,-210,1,4)
    popup.Visible          = false
    popup.ZIndex           = 100
    makeCorner(popup, UDim.new(0,8))
    makeStroke(popup, Theme.Colors.BorderActive)

    -- Titre
    local title = Instance.new("TextLabel", popup)
    title.Text             = self.label
    title.Font             = Theme.Fonts.Bold
    title.TextSize         = Theme.TextSize.Small
    title.TextColor3       = Theme.Colors.TextSub
    title.BackgroundTransparency = 1
    title.Size             = UDim2.new(1,0,0,22)
    title.Position         = UDim2.fromOffset(10,4)
    title.TextXAlignment   = Enum.TextXAlignment.Left

    -- Sliders H S V
    local sliders = {"H", "S", "V"}
    local labels  = {"Hue", "Sat", "Val"}
    local yPos    = {30, 66, 102}
    local fields  = {}

    for i, name in ipairs(sliders) do
        local sliderLbl = Instance.new("TextLabel", popup)
        sliderLbl.Text             = labels[i]
        sliderLbl.Font             = Theme.Fonts.Regular
        sliderLbl.TextSize         = Theme.TextSize.Tiny
        sliderLbl.TextColor3       = Theme.Colors.TextSub
        sliderLbl.BackgroundTransparency = 1
        sliderLbl.Size             = UDim2.fromOffset(28,16)
        sliderLbl.Position         = UDim2.fromOffset(10, yPos[i])

        local trackBg = Instance.new("TextButton", popup)
        trackBg.BackgroundColor3   = Theme.Colors.SurfaceAlt
        trackBg.BorderSizePixel    = 0
        trackBg.Text               = ""
        trackBg.Size               = UDim2.fromOffset(130,6)
        trackBg.Position           = UDim2.fromOffset(42, yPos[i]+5)
        makeCorner(trackBg, UDim.new(1,0))

        local fill = Instance.new("Frame", trackBg)
        fill.BackgroundColor3 = Theme.Colors.Accent
        fill.BorderSizePixel  = 0
        fill.Size             = UDim2.new(0,0,1,0)
        makeCorner(fill, UDim.new(1,0))

        local knob = Instance.new("Frame", trackBg)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.BorderSizePixel  = 0
        knob.Size             = UDim2.fromOffset(12,12)
        knob.AnchorPoint      = Vector2.new(0.5,0.5)
        knob.Position         = UDim2.new(0,0,0.5,0)
        knob.ZIndex           = 2
        makeCorner(knob, UDim.new(1,0))

        local valLbl = Instance.new("TextLabel", popup)
        valLbl.Font            = Theme.Fonts.Bold
        valLbl.TextSize        = Theme.TextSize.Tiny
        valLbl.TextColor3      = Theme.Colors.Text
        valLbl.BackgroundTransparency = 1
        valLbl.Size            = UDim2.fromOffset(28,16)
        valLbl.Position        = UDim2.fromOffset(176, yPos[i])
        valLbl.TextXAlignment  = Enum.TextXAlignment.Left

        fields[name] = {trackBg=trackBg, fill=fill, knob=knob, valLbl=valLbl}

        -- Drag
        local dragging = false
        trackBg.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if not dragging then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement then
                local abs = trackBg.AbsolutePosition.X
                local wid = trackBg.AbsoluteSize.X
                local pct = math.clamp((inp.Position.X - abs)/wid, 0, 1)
                if     name == "H" then self._h = pct
                elseif name == "S" then self._s = pct
                elseif name == "V" then self._v = pct
                end
                self:_updateAll(fields)
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- Hex preview
    local hexBg = Instance.new("Frame", popup)
    hexBg.BackgroundColor3 = Theme.Colors.SurfaceAlt
    hexBg.BorderSizePixel  = 0
    hexBg.Size             = UDim2.fromOffset(180,24)
    hexBg.Position         = UDim2.fromOffset(10,132)
    makeCorner(hexBg, UDim.new(0,4))

    local hexLabel = Instance.new("TextLabel", hexBg)
    hexLabel.Font          = Theme.Fonts.Mono
    hexLabel.TextSize      = Theme.TextSize.Small
    hexLabel.TextColor3    = Theme.Colors.Text
    hexLabel.BackgroundTransparency = 1
    hexLabel.Size          = UDim2.fromScale(1,1)
    hexLabel.TextXAlignment = Enum.TextXAlignment.Center

    self._fields   = fields
    self._hexLabel = hexLabel
    self._updateAll(self, fields)

    return popup
end

function ColorPicker:_updateAll(fields)
    local color = Color3.fromHSV(self._h, self._s, self._v)
    self.value   = color

    local vals = {H=self._h, S=self._s, V=self._v}
    for name, f in pairs(fields) do
        local pct = vals[name]
        f.fill.Size    = UDim2.new(pct,0,1,0)
        f.knob.Position = UDim2.new(pct,0,0.5,0)
        f.valLbl.Text  = tostring(math.floor(pct*255))
    end

    self._swatch.BackgroundColor3 = color

    local r = math.floor(color.R*255)
    local g = math.floor(color.G*255)
    local b = math.floor(color.B*255)
    if self._hexLabel then
        self._hexLabel.Text = string.format("#%02X%02X%02X", r,g,b)
    end

    pcall(self.callback, color)
end

function ColorPicker:OpenPopup()
    self.open = true
    self._popup.Visible = true
    Animation.SlideIn(self._popup, "Bottom", 0.2)
end

function ColorPicker:ClosePopup()
    self.open = false
    Animation.Tween(self._popup,
        {BackgroundTransparency = 1},
        TweenInfo.new(0.15)
    )
    task.delay(0.15, function()
        if self._popup then
            self._popup.Visible = false
            self._popup.BackgroundTransparency = 0
        end
    end)
end

function ColorPicker:Set(color)
    local h,s,v = Color3.toHSV(color)
    self._h = h; self._s = s; self._v = v
    self:_updateAll(self._fields)
end

function ColorPicker:Get()
    return self.value
end

function ColorPicker:Destroy()
    if self._row then self._row:Destroy() end
end

return ColorPicker
