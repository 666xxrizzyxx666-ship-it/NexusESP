-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Components/Button.lua
--   📁 Dossier : UI/Components/
--   Rôle : Bouton avec états hover/press/disabled
-- ══════════════════════════════════════════════════════

local Button = {}
Button.__index = Button

local Theme, Animation

local function makeCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0,8)
    return c
end

function Button.Init(theme, anim)
    Theme     = theme
    Animation = anim
end

function Button.new(parent, opts)
    opts = opts or {}
    local self     = setmetatable({}, Button)

    self.label     = opts.label    or "Button"
    self.callback  = opts.callback or function() end
    self.style     = opts.style    or "primary"  -- primary / secondary / danger
    self.disabled  = opts.disabled or false
    self.icon      = opts.icon     or nil

    local normalColor, hoverColor, pressColor, textColor

    if self.style == "primary" then
        normalColor = Theme.Colors.Accent
        hoverColor  = Theme.Colors.AccentHover
        pressColor  = Theme.Colors.AccentPress
        textColor   = Theme.Colors.TextOnAccent
    elseif self.style == "danger" then
        normalColor = Theme.Colors.DangerDark
        hoverColor  = Theme.Colors.Danger
        pressColor  = Color3.fromRGB(180,40,40)
        textColor   = Color3.new(1,1,1)
    else
        normalColor = Theme.Colors.SurfaceAlt
        hoverColor  = Theme.Colors.BorderHover
        pressColor  = Theme.Colors.Border
        textColor   = Theme.Colors.Text
    end

    local btn = Instance.new("TextButton", parent)
    btn.Name               = "Btn_"..self.label
    btn.BackgroundColor3   = normalColor
    btn.BorderSizePixel    = 0
    btn.Size               = opts.size or UDim2.new(1,-20,0,32)
    btn.Position           = opts.position or UDim2.fromOffset(10,0)
    btn.Text               = (self.icon and self.icon.." " or "")..self.label
    btn.Font               = Theme.Fonts.Bold
    btn.TextSize           = Theme.TextSize.Body
    btn.TextColor3         = textColor
    btn.AutoButtonColor    = false
    btn.LayoutOrder        = opts.order or 0
    makeCorner(btn, Theme.Radius.Button)

    if self.style == "secondary" then
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color     = Theme.Colors.Border
        stroke.Thickness = 1
        self._stroke = stroke
    end

    -- Hover / Press
    btn.MouseEnter:Connect(function()
        if self.disabled then return end
        Animation.Tween(btn, {BackgroundColor3 = hoverColor}, TweenInfo.new(0.1))
    end)
    btn.MouseLeave:Connect(function()
        if self.disabled then return end
        Animation.Tween(btn, {BackgroundColor3 = normalColor}, TweenInfo.new(0.12))
    end)
    btn.MouseButton1Down:Connect(function()
        if self.disabled then return end
        Animation.Tween(btn, {BackgroundColor3 = pressColor}, TweenInfo.new(0.08))
    end)
    btn.MouseButton1Up:Connect(function()
        if self.disabled then return end
        Animation.Tween(btn, {BackgroundColor3 = hoverColor}, TweenInfo.new(0.1))
    end)
    btn.MouseButton1Click:Connect(function()
        if self.disabled then return end
        pcall(self.callback)
    end)

    self._btn         = btn
    self._normalColor = normalColor

    return self
end

function Button:SetDisabled(v)
    self.disabled              = v
    self._btn.BackgroundTransparency = v and 0.5 or 0
    self._btn.TextTransparency       = v and 0.5 or 0
end

function Button:SetLabel(text)
    self.label      = text
    self._btn.Text  = (self.icon and self.icon.." " or "")..text
end

function Button:Destroy()
    if self._btn then self._btn:Destroy() end
end

return Button
