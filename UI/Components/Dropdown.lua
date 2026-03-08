-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Components/Dropdown.lua
--   📁 Dossier : UI/Components/
--   Rôle : Dropdown avec animation smooth
-- ══════════════════════════════════════════════════════

local Dropdown = {}
Dropdown.__index = Dropdown

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

function Dropdown.Init(theme, anim)
    Theme     = theme
    Animation = anim
end

function Dropdown.new(parent, opts)
    opts = opts or {}
    local self     = setmetatable({}, Dropdown)

    self.options   = opts.options  or {}
    self.value     = opts.default  or (self.options[1] or "")
    self.label     = opts.label    or "Dropdown"
    self.callback  = opts.callback or function() end
    self.open      = false

    -- Container
    local container = Instance.new("Frame", parent)
    container.Name               = "Dropdown_"..self.label
    container.BackgroundTransparency = 1
    container.BorderSizePixel    = 0
    container.Size               = UDim2.new(1, 0, 0, 54)
    container.LayoutOrder        = opts.order or 0
    container.ClipsDescendants   = false
    container.ZIndex             = 2

    -- Label
    local lbl = Instance.new("TextLabel", container)
    lbl.Text               = self.label
    lbl.Font               = Theme.Fonts.Medium
    lbl.TextSize           = Theme.TextSize.Body
    lbl.TextColor3         = Theme.Colors.Text
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Size               = UDim2.new(1,0,0,18)
    lbl.Position           = UDim2.fromOffset(10, 4)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    -- Bouton
    local btn = Instance.new("TextButton", container)
    btn.Name               = "Btn"
    btn.BackgroundColor3   = Theme.Colors.SurfaceAlt
    btn.BorderSizePixel    = 0
    btn.Size               = UDim2.new(1,-20,0,30)
    btn.Position           = UDim2.fromOffset(10, 22)
    btn.Text               = ""
    btn.AutoButtonColor    = false
    makeCorner(btn, UDim.new(0,6))
    makeStroke(btn, Theme.Colors.Border)

    local btnLabel = Instance.new("TextLabel", btn)
    btnLabel.Text          = self.value
    btnLabel.Font          = Theme.Fonts.Medium
    btnLabel.TextSize      = Theme.TextSize.Body
    btnLabel.TextColor3    = Theme.Colors.Text
    btnLabel.BackgroundTransparency = 1
    btnLabel.BorderSizePixel = 0
    btnLabel.Size          = UDim2.new(1,-30,1,0)
    btnLabel.Position      = UDim2.fromOffset(10,0)
    btnLabel.TextXAlignment = Enum.TextXAlignment.Left

    local arrow = Instance.new("TextLabel", btn)
    arrow.Text             = "▾"
    arrow.Font             = Theme.Fonts.Bold
    arrow.TextSize         = 14
    arrow.TextColor3       = Theme.Colors.TextSub
    arrow.BackgroundTransparency = 1
    arrow.BorderSizePixel  = 0
    arrow.Size             = UDim2.fromOffset(20,30)
    arrow.Position         = UDim2.new(1,-24,0,0)

    -- Dropdown list
    local list = Instance.new("Frame", container)
    list.Name              = "List"
    list.BackgroundColor3  = Theme.Colors.Surface
    list.BorderSizePixel   = 0
    list.Size              = UDim2.new(1,-20, 0, 0)
    list.Position          = UDim2.fromOffset(10, 54)
    list.ClipsDescendants  = true
    list.ZIndex            = 50
    list.Visible           = false
    makeCorner(list, UDim.new(0,6))
    makeStroke(list, Theme.Colors.BorderActive)

    local listLayout = Instance.new("UIListLayout", list)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0,2)

    local listPad = Instance.new("UIPadding", list)
    listPad.PaddingTop    = UDim.new(0,4)
    listPad.PaddingBottom = UDim.new(0,4)
    listPad.PaddingLeft   = UDim.new(0,4)
    listPad.PaddingRight  = UDim.new(0,4)

    self._container = container
    self._btn       = btn
    self._btnLabel  = btnLabel
    self._arrow     = arrow
    self._list      = list
    self._items     = {}

    -- Crée les options
    for i, opt in ipairs(self.options) do
        self:_addOption(opt, i)
    end

    -- Toggle
    btn.MouseButton1Click:Connect(function()
        if self.open then self:Close() else self:Open() end
    end)

    btn.MouseEnter:Connect(function()
        Animation.Tween(btn, {BackgroundColor3 = Theme.Colors.BorderHover}, TweenInfo.new(0.1))
    end)
    btn.MouseLeave:Connect(function()
        Animation.Tween(btn, {BackgroundColor3 = Theme.Colors.SurfaceAlt}, TweenInfo.new(0.1))
    end)

    return self
end

function Dropdown:_addOption(opt, order)
    local item = Instance.new("TextButton", self._list)
    item.Name              = "Opt_"..opt
    item.BackgroundColor3  = Theme.Colors.Surface
    item.BackgroundTransparency = 1
    item.BorderSizePixel   = 0
    item.Text              = opt
    item.Font              = Theme.Fonts.Medium
    item.TextSize          = Theme.TextSize.Body
    item.TextColor3        = opt == self.value
        and Theme.Colors.Accent
        or  Theme.Colors.Text
    item.Size              = UDim2.new(1,0,0,28)
    item.AutoButtonColor   = false
    item.LayoutOrder       = order
    makeCorner(item, UDim.new(0,4))

    item.MouseEnter:Connect(function()
        Animation.Tween(item, {BackgroundTransparency = 0.7}, TweenInfo.new(0.1))
    end)
    item.MouseLeave:Connect(function()
        Animation.Tween(item, {BackgroundTransparency = 1}, TweenInfo.new(0.1))
    end)

    item.MouseButton1Click:Connect(function()
        self:Select(opt)
        self:Close()
    end)

    self._items[opt] = item
end

function Dropdown:Open()
    self.open = true
    local count   = math.min(#self.options, 6)
    local height  = count * 30 + 8
    self._list.Visible = true
    self._list.Size    = UDim2.new(1,-20,0,0)
    Animation.Tween(self._list, {Size = UDim2.new(1,-20,0,height)}, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    Animation.Tween(self._arrow, {TextColor3 = Theme.Colors.Accent}, TweenInfo.new(0.1))
    self._container.Size = UDim2.new(1,0,0,54+height+4)
end

function Dropdown:Close()
    self.open = false
    Animation.Tween(self._list, {Size = UDim2.new(1,-20,0,0)}, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In))
    Animation.Tween(self._arrow, {TextColor3 = Theme.Colors.TextSub}, TweenInfo.new(0.1))
    task.delay(0.15, function()
        if not self.open and self._list then
            self._list.Visible = false
        end
    end)
    self._container.Size = UDim2.new(1,0,0,54)
end

function Dropdown:Select(opt)
    self.value          = opt
    self._btnLabel.Text = opt
    for name, item in pairs(self._items) do
        item.TextColor3 = name == opt
            and Theme.Colors.Accent
            or  Theme.Colors.Text
    end
    pcall(self.callback, opt)
end

function Dropdown:Get()
    return self.value
end

function Dropdown:SetOptions(opts)
    self.options = opts
    for _, item in pairs(self._items) do item:Destroy() end
    self._items = {}
    for i, opt in ipairs(opts) do
        self:_addOption(opt, i)
    end
end

function Dropdown:Destroy()
    if self._container then self._container:Destroy() end
end

return Dropdown
