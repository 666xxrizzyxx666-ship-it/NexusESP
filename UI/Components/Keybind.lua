-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Components/Keybind.lua
--   📁 Dossier : UI/Components/
--   Rôle : Picker de keybind
-- ══════════════════════════════════════════════════════

local Keybind = {}
Keybind.__index = Keybind

local UIS = game:GetService("UserInputService")
local Theme, Animation

local function makeCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0,6)
    return c
end

local function makeStroke(p, color, thick)
    local s = Instance.new("UIStroke", p)
    s.Color     = color or Color3.fromRGB(30,30,50)
    s.Thickness = thick or 1
    return s
end

function Keybind.Init(theme, anim)
    Theme     = theme
    Animation = anim
end

function Keybind.new(parent, opts)
    opts = opts or {}
    local self     = setmetatable({}, Keybind)

    self.label     = opts.label    or "Keybind"
    self.value     = opts.default  or "None"
    self.callback  = opts.callback or function() end
    self.listening = false

    local row = Instance.new("Frame", parent)
    row.Name               = "Keybind_"..self.label
    row.BackgroundTransparency = 1
    row.BorderSizePixel    = 0
    row.Size               = UDim2.new(1,0,0,34)
    row.LayoutOrder        = opts.order or 0

    local lbl = Instance.new("TextLabel", row)
    lbl.Text               = self.label
    lbl.Font               = Theme.Fonts.Medium
    lbl.TextSize           = Theme.TextSize.Body
    lbl.TextColor3         = Theme.Colors.Text
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Size               = UDim2.new(1,-90,1,0)
    lbl.Position           = UDim2.fromOffset(10,0)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", row)
    btn.Name               = "KeyBtn"
    btn.BackgroundColor3   = Theme.Colors.SurfaceAlt
    btn.BorderSizePixel    = 0
    btn.Size               = UDim2.fromOffset(75,24)
    btn.Position           = UDim2.new(1,-85,0.5,-12)
    btn.Text               = self.value
    btn.Font               = Theme.Fonts.Bold
    btn.TextSize           = Theme.TextSize.Small
    btn.TextColor3         = Theme.Colors.Accent
    btn.AutoButtonColor    = false
    makeCorner(btn, UDim.new(0,6))
    makeStroke(btn, Theme.Colors.Border)

    self._row = row
    self._btn = btn

    btn.MouseButton1Click:Connect(function()
        if self.listening then
            self:StopListening()
        else
            self:StartListening()
        end
    end)

    -- Écoute les touches
    UIS.InputBegan:Connect(function(inp, gp)
        if not self.listening then return end
        if gp then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            local name = inp.KeyCode.Name
            self:Set(name)
            self:StopListening()
        elseif inp.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Set("None")
            self:StopListening()
        end
    end)

    return self
end

function Keybind:StartListening()
    self.listening    = true
    self._btn.Text    = "..."
    self._btn.TextColor3 = Theme.Colors.Warning
    Animation.Tween(self._btn,
        {BackgroundColor3 = Theme.Colors.WarningDark},
        TweenInfo.new(0.1)
    )
end

function Keybind:StopListening()
    self.listening    = false
    self._btn.Text    = self.value
    self._btn.TextColor3 = Theme.Colors.Accent
    Animation.Tween(self._btn,
        {BackgroundColor3 = Theme.Colors.SurfaceAlt},
        TweenInfo.new(0.1)
    )
end

function Keybind:Set(key)
    self.value        = key
    self._btn.Text    = key
    self._btn.TextColor3 = key == "None"
        and Theme.Colors.TextMuted
        or  Theme.Colors.Accent
    pcall(self.callback, key)
end

function Keybind:Get()
    return self.value
end

function Keybind:Destroy()
    if self._row then self._row:Destroy() end
end

return Keybind
