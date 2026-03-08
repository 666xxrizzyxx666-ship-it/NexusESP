-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Sidebar.lua
--   📁 Dossier : UI/
--   Rôle : Sidebar principale — navigation entre tabs
--          Style Wave/Hidden avec icônes + animations
-- ══════════════════════════════════════════════════════

local Sidebar = {}

local TweenService = game:GetService("TweenService")

local Theme, Animation
local frame   = nil
local tabs    = {}
local active  = nil
local onTabCb = nil

local ICONS = {
    ESP      = "👁",
    Combat   = "🎯",
    Movement = "🏃",
    World    = "🌍",
    AI       = "🧠",
    Bot      = "🤖",
    Utility  = "🔧",
    Security = "🛡",
    Config   = "⚙",
}

local TAB_ORDER = {
    "ESP", "Combat", "Movement", "World",
    "AI", "Bot", "Utility", "Security", "Config"
}

function Sidebar.Init(theme, anim, parent)
    Theme     = theme
    Animation = anim

    -- Frame sidebar
    frame = Instance.new("Frame", parent)
    frame.Name               = "Sidebar"
    frame.BackgroundColor3   = Theme.Colors.SurfaceDark
    frame.BorderSizePixel    = 0
    frame.Size               = UDim2.fromOffset(Theme.Size.SidebarWidth, 0)
    frame.Size               = UDim2.new(0, Theme.Size.SidebarWidth, 1, 0)
    frame.Position           = UDim2.fromOffset(0, 0)

    -- Séparateur droit
    local sep = Instance.new("Frame", frame)
    sep.BackgroundColor3 = Theme.Colors.Border
    sep.BorderSizePixel  = 0
    sep.Size             = UDim2.new(0,1,1,0)
    sep.Position         = UDim2.new(1,-1,0,0)

    -- Logo NexusESP
    local logoFrame = Instance.new("Frame", frame)
    logoFrame.BackgroundTransparency = 1
    logoFrame.Size     = UDim2.new(1,0,0,56)
    logoFrame.Position = UDim2.fromOffset(0,0)

    local logo = Instance.new("TextLabel", logoFrame)
    logo.Text              = "N"
    logo.Font              = Theme.Fonts.Bold
    logo.TextSize          = 22
    logo.TextColor3        = Theme.Colors.Accent
    logo.BackgroundTransparency = 1
    logo.Size              = UDim2.new(1,0,1,0)
    logo.TextXAlignment    = Enum.TextXAlignment.Center

    local logoSub = Instance.new("TextLabel", logoFrame)
    logoSub.Text           = "EXUS"
    logoSub.Font           = Theme.Fonts.Medium
    logoSub.TextSize       = 11
    logoSub.TextColor3     = Theme.Colors.TextSub
    logoSub.BackgroundTransparency = 1
    logoSub.Size           = UDim2.new(1,0,0,14)
    logoSub.Position       = UDim2.new(0,0,1,-14)
    logoSub.TextXAlignment = Enum.TextXAlignment.Center

    -- Séparateur logo
    local logoDivider = Instance.new("Frame", frame)
    logoDivider.BackgroundColor3 = Theme.Colors.Border
    logoDivider.BorderSizePixel  = 0
    logoDivider.Size             = UDim2.new(0.7, 0, 0, 1)
    logoDivider.Position         = UDim2.new(0.15, 0, 0, 56)

    -- Liste des tabs
    local tabList = Instance.new("Frame", frame)
    tabList.BackgroundTransparency = 1
    tabList.BorderSizePixel        = 0
    tabList.Size                   = UDim2.new(1, 0, 1, -66)
    tabList.Position               = UDim2.fromOffset(0, 64)

    local layout = Instance.new("UIListLayout", tabList)
    layout.SortOrder  = Enum.SortOrder.LayoutOrder
    layout.Padding    = UDim.new(0, 2)

    local pad = Instance.new("UIPadding", tabList)
    pad.PaddingLeft   = UDim.new(0, 6)
    pad.PaddingRight  = UDim.new(0, 6)
    pad.PaddingTop    = UDim.new(0, 4)

    -- Crée les boutons de tab
    for i, name in ipairs(TAB_ORDER) do
        Sidebar._createTab(tabList, name, i)
    end

    -- Sélectionne le premier tab
    if #TAB_ORDER > 0 then
        task.defer(function()
            Sidebar.SelectTab(TAB_ORDER[1])
        end)
    end

    return frame
end

function Sidebar._createTab(parent, name, order)
    local btn = Instance.new("TextButton", parent)
    btn.Name               = "Tab_"..name
    btn.BackgroundColor3   = Theme.Colors.Surface
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel    = 0
    btn.Size               = UDim2.new(1, 0, 0, 38)
    btn.Text               = ""
    btn.AutoButtonColor    = false
    btn.LayoutOrder        = order

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 8)

    -- Accent indicator (barre gauche)
    local indicator = Instance.new("Frame", btn)
    indicator.BackgroundColor3 = Theme.Colors.Accent
    indicator.BorderSizePixel  = 0
    indicator.Size             = UDim2.fromOffset(3, 20)
    indicator.Position         = UDim2.new(0, 0, 0.5, -10)
    indicator.Visible          = false
    local iCorner = Instance.new("UICorner", indicator)
    iCorner.CornerRadius = UDim.new(1, 0)

    -- Icône
    local icon = Instance.new("TextLabel", btn)
    icon.Text              = ICONS[name] or "•"
    icon.Font              = Theme.Fonts.Regular
    icon.TextSize          = 16
    icon.TextColor3        = Theme.Colors.TextSub
    icon.BackgroundTransparency = 1
    icon.Size              = UDim2.fromOffset(28, 38)
    icon.Position          = UDim2.fromOffset(8, 0)
    icon.TextXAlignment    = Enum.TextXAlignment.Center

    -- Label
    local lbl = Instance.new("TextLabel", btn)
    lbl.Text               = name
    lbl.Font               = Theme.Fonts.Medium
    lbl.TextSize           = Theme.TextSize.Small
    lbl.TextColor3         = Theme.Colors.TextSub
    lbl.BackgroundTransparency = 1
    lbl.Size               = UDim2.new(1, -40, 1, 0)
    lbl.Position           = UDim2.fromOffset(38, 0)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    tabs[name] = {
        btn       = btn,
        indicator = indicator,
        icon      = icon,
        lbl       = lbl,
        active    = false,
    }

    -- Hover
    btn.MouseEnter:Connect(function()
        if tabs[name] and not tabs[name].active then
            Animation.Tween(btn, {BackgroundTransparency = 0.7}, TweenInfo.new(0.12))
            Animation.Tween(lbl, {TextColor3 = Theme.Colors.Text}, TweenInfo.new(0.12))
        end
    end)
    btn.MouseLeave:Connect(function()
        if tabs[name] and not tabs[name].active then
            Animation.Tween(btn, {BackgroundTransparency = 1}, TweenInfo.new(0.15))
            Animation.Tween(lbl, {TextColor3 = Theme.Colors.TextSub}, TweenInfo.new(0.15))
        end
    end)

    -- Click
    btn.MouseButton1Click:Connect(function()
        Sidebar.SelectTab(name)
    end)
end

function Sidebar.SelectTab(name)
    if not tabs[name] then return end

    -- Désactive l'ancien tab
    if active and tabs[active] then
        local old = tabs[active]
        old.active          = false
        old.indicator.Visible = false
        Animation.Tween(old.btn, {BackgroundTransparency = 1}, TweenInfo.new(0.15))
        Animation.Tween(old.lbl, {TextColor3 = Theme.Colors.TextSub}, TweenInfo.new(0.15))
        Animation.Tween(old.icon, {TextColor3 = Theme.Colors.TextSub}, TweenInfo.new(0.15))
    end

    -- Active le nouveau tab
    active = name
    local t = tabs[name]
    t.active            = true
    t.indicator.Visible = true
    Animation.Tween(t.btn,  {BackgroundTransparency = 0.85}, TweenInfo.new(0.15))
    Animation.Tween(t.lbl,  {TextColor3 = Theme.Colors.Text}, TweenInfo.new(0.15))
    Animation.Tween(t.icon, {TextColor3 = Theme.Colors.Accent}, TweenInfo.new(0.15))

    -- Callback
    if onTabCb then pcall(onTabCb, name) end
end

function Sidebar.OnTabSelected(callback)
    onTabCb = callback
end

function Sidebar.GetActive()
    return active
end

function Sidebar.GetFrame()
    return frame
end

return Sidebar
