-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Components/Toggle.lua
--   📁 Dossier : UI/Components/
--   Rôle : Toggle animé smooth
-- ══════════════════════════════════════════════════════

local Toggle = {}
Toggle.__index = Toggle

local TweenService = game:GetService("TweenService")
local Theme, Animation

local function C(r,g,b) return Color3.fromRGB(r,g,b) end

local function makeCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(1,0)
    return c
end

function Toggle.Init(theme, anim)
    Theme     = theme
    Animation = anim
end

function Toggle.new(parent, opts)
    opts = opts or {}
    local self = setmetatable({}, Toggle)

    self.value    = opts.default or false
    self.callback = opts.onChange or opts.callback or function() end
    self.label    = opts.label   or "Toggle"
    self.desc     = opts.desc    or nil
    self.disabled = opts.disabled or false

    -- Container
    local row = Instance.new("TextButton", parent)
    row.Name                 = "Toggle_"..self.label
    row.BackgroundColor3     = Theme.Colors.Surface
    row.BackgroundTransparency = 1
    row.BorderSizePixel      = 0
    row.Size                 = UDim2.new(1, 0, 0, self.desc and 44 or 34)
    row.Text                 = ""
    row.AutoButtonColor      = false
    row.LayoutOrder          = opts.order or 0

    -- Hover
    row.MouseEnter:Connect(function()
        if self.disabled then return end
        Animation.Tween(row, {BackgroundTransparency = 0.7}, TweenInfo.new(0.1))
    end)
    row.MouseLeave:Connect(function()
        Animation.Tween(row, {BackgroundTransparency = 1}, TweenInfo.new(0.12))
    end)
    makeCorner(row, UDim.new(0,6))

    -- Label
    local lbl = Instance.new("TextLabel", row)
    lbl.Text               = self.label
    lbl.Font               = Theme.Fonts.Medium
    lbl.TextSize           = Theme.TextSize.Body
    lbl.TextColor3         = Theme.Colors.Text
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Size               = UDim2.new(1,-52,0,20)
    lbl.Position           = UDim2.fromOffset(10, self.desc and 6 or 7)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    -- Description optionnelle
    if self.desc then
        local desc = Instance.new("TextLabel", row)
        desc.Text              = self.desc
        desc.Font              = Theme.Fonts.Regular
        desc.TextSize          = Theme.TextSize.Tiny
        desc.TextColor3        = Theme.Colors.TextSub
        desc.BackgroundTransparency = 1
        desc.BorderSizePixel   = 0
        desc.Size              = UDim2.new(1,-52,0,14)
        desc.Position          = UDim2.fromOffset(10, 24)
        desc.TextXAlignment    = Enum.TextXAlignment.Left
    end

    -- Toggle background
    local toggleBg = Instance.new("Frame", row)
    toggleBg.BackgroundColor3 = self.value
        and Theme.Colors.Accent
        or  Theme.Colors.SurfaceAlt
    toggleBg.BorderSizePixel  = 0
    toggleBg.Size             = UDim2.fromOffset(36, 20)
    toggleBg.Position         = UDim2.new(1, -46, 0.5, -10)
    makeCorner(toggleBg, UDim.new(1,0))

    -- Knob
    local knob = Instance.new("Frame", toggleBg)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    knob.Size             = UDim2.fromOffset(16, 16)
    knob.Position         = self.value
        and UDim2.new(1,-18,0.5,0)
        or  UDim2.new(0, 2, 0.5, 0)
    knob.AnchorPoint      = Vector2.new(0, 0.5)
    makeCorner(knob, UDim.new(1,0))

    -- Shadow knob
    local shadow = Instance.new("UIStroke", knob)
    shadow.Color     = Color3.new(0,0,0)
    shadow.Thickness = 0
    shadow.Transparency = 0.7

    self._row      = row
    self._toggleBg = toggleBg
    self._knob     = knob
    self._label    = lbl

    -- Click
    row.MouseButton1Click:Connect(function()
        if self.disabled then return end
        self:Set(not self.value)
    end)

    return self
end

function Toggle:Set(val)
    self.value = val
    Animation.Toggle(
        self._toggleBg,
        self._knob,
        val,
        Theme.Colors.Accent,
        Theme.Colors.SurfaceAlt
    )
    pcall(self.callback, val)
end

function Toggle:Get()
    return self.value
end

function Toggle:SetDisabled(v)
    self.disabled = v
    self._label.TextColor3 = v
        and Theme.Colors.TextMuted
        or  Theme.Colors.Text
end

function Toggle:Destroy()
    if self._row then self._row:Destroy() end
end

return Toggle
