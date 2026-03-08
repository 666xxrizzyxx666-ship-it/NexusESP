-- ══════════════════════════════════════════════════════
--   Aurora v3.1.3 — UI/Components/Toggle.lua
-- ══════════════════════════════════════════════════════

local Toggle = {}
Toggle.__index = Toggle

local TweenS = game:GetService("TweenService")
local function T(i, p, t, style)
    if not i or not p then return end
    local ok, tw = pcall(function()
        return TweenS:Create(i,
            TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            p
        )
    end)
    if ok and tw then tw:Play() return tw end
end
local function C(r,g,b) return Color3.fromRGB(r,g,b) end
local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(1,0)
end

local COLOR_ON  = C(91,107,248)
local COLOR_OFF = C(30,30,48)
local COLOR_TEXT     = C(220,220,230)
local COLOR_TEXT_OFF = C(110,110,140)
local COLOR_HOVER    = C(18,18,28)

function Toggle.Init(theme, anim) end -- compatibility stub

function Toggle.new(parent, opts)
    opts = opts or {}
    local self   = setmetatable({}, Toggle)
    self.value    = opts.default ~= nil and opts.default or false
    self.callback = opts.onChange or opts.callback or function() end
    self.label    = opts.label or "Toggle"
    self.disabled = opts.disabled or false

    -- Row
    local row = Instance.new("TextButton", parent)
    row.Name                  = "Toggle_"..self.label
    row.BackgroundColor3      = C(13,13,22)
    row.BackgroundTransparency = 1
    row.BorderSizePixel       = 0
    row.Size                  = UDim2.new(1, 0, 0, 36)
    row.Text                  = ""
    row.AutoButtonColor       = false
    row.LayoutOrder           = opts.order or 0
    corner(row, UDim.new(0,6))

    row.MouseEnter:Connect(function()
        if self.disabled then return end
        T(row, {BackgroundColor3=COLOR_HOVER, BackgroundTransparency=0}, 0.1)
    end)
    row.MouseLeave:Connect(function()
        T(row, {BackgroundTransparency=1}, 0.12)
    end)

    -- Label texte
    local lbl = Instance.new("TextLabel", row)
    lbl.Text               = self.label
    lbl.Font               = Enum.Font.GothamMedium
    lbl.TextSize           = 13
    lbl.TextColor3         = self.disabled and COLOR_TEXT_OFF or COLOR_TEXT
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Size               = UDim2.new(1,-60,1,0)
    lbl.Position           = UDim2.fromOffset(12,0)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    -- Toggle BG
    local bg = Instance.new("Frame", row)
    bg.BackgroundColor3 = self.value and COLOR_ON or COLOR_OFF
    bg.BorderSizePixel  = 0
    bg.Size             = UDim2.fromOffset(38,20)
    bg.Position         = UDim2.new(1,-50,0.5,-10)
    corner(bg, UDim.new(1,0))

    -- Knob
    local knob = Instance.new("Frame", bg)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    knob.Size             = UDim2.fromOffset(16,16)
    knob.Position         = self.value
        and UDim2.new(1,-18,0.5,-8)
        or  UDim2.new(0,2,0.5,-8)
    knob.ZIndex           = 2
    corner(knob, UDim.new(1,0))

    -- Ombre knob
    local ks = Instance.new("UIStroke", knob)
    ks.Color = Color3.new(0,0,0)
    ks.Thickness = 1
    ks.Transparency = 0.8

    self._row   = row
    self._bg    = bg
    self._knob  = knob
    self._label = lbl

    -- Click
    row.MouseButton1Click:Connect(function()
        if self.disabled then return end
        self:Set(not self.value)
    end)

    return self
end

function Toggle:Set(val)
    self.value = val
    -- Animation smooth
    T(self._bg, {
        BackgroundColor3 = val and COLOR_ON or COLOR_OFF
    }, 0.15)
    T(self._knob, {
        Position = val
            and UDim2.new(1,-18,0.5,-8)
            or  UDim2.new(0,2,0.5,-8)
    }, 0.18, Enum.EasingStyle.Back)
    -- Callback avec protection
    local ok, err = pcall(self.callback, val)
    if not ok then
        warn("[Toggle/"..tostring(self.label).."] "..tostring(err))
    end
end

function Toggle:Get()    return self.value end
function Toggle:SetDisabled(v)
    self.disabled = v
    self._label.TextColor3 = v and COLOR_TEXT_OFF or COLOR_TEXT
end
function Toggle:Destroy()
    if self._row then self._row:Destroy() end
end

return Toggle
