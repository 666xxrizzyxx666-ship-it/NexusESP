-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Framework.lua
--   📁 Dossier : UI/
--   Rôle : Moteur principal de l'UI
--          Crée la fenêtre, sidebar, tabs, background animé
-- ══════════════════════════════════════════════════════

local Framework = {}

local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Players        = game:GetService("Players")
local LP             = Players.LocalPlayer

local REPO = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"

local Theme     = nil
local Animation = nil
local Config    = nil

local gui       = nil
local window    = nil
local sidebar   = nil
local content   = nil
local tabs      = {}
local activeTab = nil
local visible   = true

local particles = {}
local PARTICLE_COUNT = 40

-- ── Helpers ───────────────────────────────────────────
local function C(r,g,b) return Color3.fromRGB(r,g,b) end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = radius or UDim.new(0,8)
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color     = color or C(30,30,50)
    s.Thickness = thickness or 1
    return s
end

local function makePadding(parent, all, top, bottom, left, right)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, top    or all or 8)
    p.PaddingBottom = UDim.new(0, bottom or all or 8)
    p.PaddingLeft   = UDim.new(0, left   or all or 8)
    p.PaddingRight  = UDim.new(0, right  or all or 8)
    return p
end

-- ── Protect GUI ───────────────────────────────────────
local function protectGui(g)
    local n = getgenv().NexusESP
    if n and n.ProtectGui then n.ProtectGui(g) end
end

-- ── Background animé (particules) ────────────────────
local function createParticle(parent)
    local p = Instance.new("Frame", parent)
    p.BackgroundColor3    = Theme.Colors.Accent
    p.BackgroundTransparency = 0.85
    p.BorderSizePixel     = 0
    local size = math.random(2, 5)
    p.Size     = UDim2.fromOffset(size, size)
    p.Position = UDim2.fromScale(math.random(), math.random())
    makeCorner(p, UDim.new(1,0))
    return {
        frame   = p,
        speedX  = (math.random() - 0.5) * 0.0003,
        speedY  = (math.random() - 0.5) * 0.0003,
        alpha   = math.random(75, 92) / 100,
        pulse   = math.random() * math.pi * 2,
    }
end

local function animateBackground(bgFrame)
    for i = 1, PARTICLE_COUNT do
        particles[i] = createParticle(bgFrame)
    end

    RunService.Heartbeat:Connect(function(dt)
        if not bgFrame or not bgFrame.Parent then return end
        local t = os.clock()
        for _, p in ipairs(particles) do
            if p.frame and p.frame.Parent then
                local cx = p.frame.Position.X.Scale + p.speedX
                local cy = p.frame.Position.Y.Scale + p.speedY
                if cx < 0 then cx = 1 end
                if cx > 1 then cx = 0 end
                if cy < 0 then cy = 1 end
                if cy > 1 then cy = 0 end
                p.frame.Position = UDim2.fromScale(cx, cy)
                p.pulse = p.pulse + dt * 0.8
                local alpha = p.alpha + math.sin(p.pulse) * 0.06
                p.frame.BackgroundTransparency = math.clamp(alpha, 0.7, 0.95)
            end
        end
    end)
end

-- ── Drag ──────────────────────────────────────────────
local function makeDraggable(dragHandle, dragTarget)
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = i.Position
            startPos  = dragTarget.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local delta = i.Position - dragStart
            dragTarget.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ── Sidebar item ──────────────────────────────────────
local function createSidebarItem(parent, icon, tabName, index)
    local btn = Instance.new("TextButton", parent)
    btn.Size                = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3    = Theme.Colors.Surface
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel     = 0
    btn.Text                = ""
    btn.LayoutOrder         = index

    -- Indicateur actif (barre gauche)
    local indicator = Instance.new("Frame", btn)
    indicator.BackgroundColor3    = Theme.Colors.Accent
    indicator.BorderSizePixel     = 0
    indicator.Size                = UDim2.fromOffset(3, 24)
    indicator.Position            = UDim2.new(0, 0, 0.5, -12)
    indicator.BackgroundTransparency = 1
    makeCorner(indicator, UDim.new(0,2))

    -- Icône
    local ico = Instance.new("TextLabel", btn)
    ico.Text                = icon
    ico.Font                = Enum.Font.GothamBold
    ico.TextSize            = 11
    ico.TextColor3          = Theme.Colors.TextSub
    ico.BackgroundTransparency = 1
    ico.BorderSizePixel     = 0
    ico.Size                = UDim2.fromOffset(46, 46)
    ico.TextXAlignment      = Enum.TextXAlignment.Center
    ico.TextYAlignment      = Enum.TextYAlignment.Center

    -- Tooltip (nom du tab au hover)
    local tooltip = Instance.new("Frame", btn)
    tooltip.BackgroundColor3    = Theme.Colors.SurfaceAlt
    tooltip.BorderSizePixel     = 0
    tooltip.Size                = UDim2.fromOffset(90, 28)
    tooltip.Position            = UDim2.new(1, 6, 0.5, -14)
    tooltip.BackgroundTransparency = 1
    tooltip.ZIndex              = 100
    makeCorner(tooltip, UDim.new(0,6))
    makeStroke(tooltip, Theme.Colors.Border)

    local ttLabel = Instance.new("TextLabel", tooltip)
    ttLabel.Text                = tabName
    ttLabel.Font                = Enum.Font.GothamMedium
    ttLabel.TextSize            = 11
    ttLabel.TextColor3          = Theme.Colors.Text
    ttLabel.BackgroundTransparency = 1
    ttLabel.Size                = UDim2.fromScale(1,1)
    ttLabel.ZIndex              = 101

    -- Hover effects
    btn.MouseEnter:Connect(function()
        Animation.Tween(ico,     {TextColor3 = Theme.Colors.Text},   TweenInfo.new(0.12))
        Animation.Tween(tooltip, {BackgroundTransparency = 0},        TweenInfo.new(0.12))
    end)
    btn.MouseLeave:Connect(function()
        if tabs[tabName] and tabs[tabName].active then return end
        Animation.Tween(ico,     {TextColor3 = Theme.Colors.TextSub}, TweenInfo.new(0.12))
        Animation.Tween(tooltip, {BackgroundTransparency = 1},         TweenInfo.new(0.12))
    end)

    return {
        btn       = btn,
        icon      = ico,
        indicator = indicator,
        tooltip   = tooltip,
    }
end

-- ── Activation d'un tab ───────────────────────────────
local function activateTab(name)
    if activeTab == name then return end

    -- Désactive l'ancien
    if activeTab and tabs[activeTab] then
        local old = tabs[activeTab]
        old.active = false
        if old.content then old.content.Visible = false end
        Animation.Tween(old.sidebar.icon,      {TextColor3 = Theme.Colors.TextSub}, TweenInfo.new(0.15))
        Animation.Tween(old.sidebar.indicator, {BackgroundTransparency = 1},         TweenInfo.new(0.15))
    end

    activeTab = name
    local t = tabs[name]
    if not t then return end

    t.active = true
    if t.content then
        t.content.Visible = true
        Animation.SlideIn(t.content, "Right", 0.2)
    end
    Animation.Tween(t.sidebar.icon,      {TextColor3 = Theme.Colors.Accent}, TweenInfo.new(0.15))
    Animation.Tween(t.sidebar.indicator, {BackgroundTransparency = 0},        TweenInfo.new(0.15))
end

-- ── Init principal ────────────────────────────────────
function Framework.Init(deps)
    Theme     = deps.Theme     or loadstring(game:HttpGet(REPO.."UI/Theme.lua",     true))()
    Animation = deps.Animation or loadstring(game:HttpGet(REPO.."UI/Animation.lua", true))()
    Config    = deps.Config

    Animation.Init(Theme)

    -- Applique accent color depuis config
    if Config then
        local uiCfg = Config:Get("UI")
        if uiCfg and uiCfg.Accent then
            Theme.Apply({Accent = uiCfg.Accent})
        end
    end

    Framework._buildGui()

    -- ── Tabs par défaut ───────────────────────────────
    local defaultTabs = {
        {"ESP",      "ESP"},
        {"Combat",   "CMB"},
        {"Movement", "MOV"},
        {"World",    "WLD"},
        {"AI",       "AI"},
        {"Bot",      "BOT"},
        {"Utility",  "UTL"},
        {"Config",   "CFG"},
    }
    for _, t in ipairs(defaultTabs) do
        Framework.AddTab(t[1], t[2])
    end
end

function Framework._buildGui()
    -- ScreenGui
    gui = Instance.new("ScreenGui")
    gui.Name              = "NexusESP_UI"
    gui.ResetOnSpawn      = false
    gui.IgnoreGuiInset    = true
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Global
    gui.DisplayOrder      = 999
    protectGui(gui)
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Background overlay animé
    local bgFrame = Instance.new("Frame", gui)
    bgFrame.Name                  = "Background"
    bgFrame.BackgroundColor3      = Theme.Colors.Background
    bgFrame.BorderSizePixel       = 0
    bgFrame.Size                  = UDim2.fromOffset(
        Theme.Size.WindowWidth,
        Theme.Size.WindowHeight
    )
    bgFrame.Position              = UDim2.fromScale(0.5, 0.5)
    bgFrame.AnchorPoint           = Vector2.new(0.5, 0.5)
    bgFrame.ClipsDescendants      = true
    makeCorner(bgFrame, Theme.Radius.Window)
    makeStroke(bgFrame, Theme.Colors.Border, 1)
    animateBackground(bgFrame)

    window = bgFrame

    -- ── Header ────────────────────────────────────────
    local header = Instance.new("Frame", window)
    header.Name                = "Header"
    header.BackgroundColor3    = Theme.Colors.Surface
    header.BorderSizePixel     = 0
    header.Size                = UDim2.new(1, 0, 0, Theme.Size.HeaderHeight)
    makeCorner(header, UDim.new(0,12))

    -- Fix coins bas du header
    local headerFix = Instance.new("Frame", header)
    headerFix.BackgroundColor3    = Theme.Colors.Surface
    headerFix.BorderSizePixel     = 0
    headerFix.Size                = UDim2.new(1,0,0,12)
    headerFix.Position            = UDim2.new(0,0,1,-12)

    -- Barre accent gauche
    local acBar = Instance.new("Frame", header)
    acBar.BackgroundColor3 = Theme.Colors.Accent
    acBar.BorderSizePixel  = 0
    acBar.Size             = UDim2.fromOffset(3, 30)
    acBar.Position         = UDim2.new(0, 0, 0.5, -15)
    makeCorner(acBar, UDim.new(0,2))

    -- Logo
    local logo = Instance.new("TextLabel", header)
    logo.Text               = "✦  Aurora"
    logo.Font               = Theme.Fonts.Bold
    logo.TextSize           = Theme.TextSize.Logo
    logo.TextColor3         = Theme.Colors.Accent
    logo.BackgroundTransparency = 1
    logo.Size               = UDim2.new(0, 160, 1, 0)
    logo.Position           = UDim2.fromOffset(16, 0)
    logo.TextXAlignment     = Enum.TextXAlignment.Left

    -- Version
    local ver = Instance.new("TextLabel", header)
    ver.Text = "v3.1.1"
    ver.Font                = Theme.Fonts.Regular
    ver.TextSize            = Theme.TextSize.Tiny
    ver.TextColor3          = Theme.Colors.TextMuted
    ver.BackgroundTransparency = 1
    ver.Size                = UDim2.new(0, 60, 1, 0)
    ver.Position            = UDim2.fromOffset(145, 0)
    ver.TextXAlignment      = Enum.TextXAlignment.Left

    -- Watermark droite (FPS/Ping)
    local wm = Instance.new("TextLabel", header)
    wm.Name                 = "Watermark"
    wm.Text                 = "FPS: -- | Ping: --ms"
    wm.Font                 = Theme.Fonts.Regular
    wm.TextSize             = Theme.TextSize.Small
    wm.TextColor3           = Theme.Colors.TextSub
    wm.BackgroundTransparency = 1
    wm.Size                 = UDim2.new(0, 200, 1, 0)
    wm.Position             = UDim2.new(1, -280, 0, 0)
    wm.TextXAlignment       = Enum.TextXAlignment.Right

    -- Bouton minimiser
    local minBtn = Instance.new("TextButton", header)
    minBtn.Text                = "─"
    minBtn.Font                = Theme.Fonts.Bold
    minBtn.TextSize            = 14
    minBtn.TextColor3          = Theme.Colors.TextSub
    minBtn.BackgroundColor3    = Theme.Colors.SurfaceAlt
    minBtn.BorderSizePixel     = 0
    minBtn.Size                = UDim2.fromOffset(28, 28)
    minBtn.Position            = UDim2.new(1, -64, 0.5, -14)
    makeCorner(minBtn, UDim.new(0,6))

    -- Bouton fermer
    local closeBtn = Instance.new("TextButton", closeBtn or header)
    closeBtn = Instance.new("TextButton", header)
    closeBtn.Text               = "✕"
    closeBtn.Font               = Theme.Fonts.Bold
    closeBtn.TextSize           = 12
    closeBtn.TextColor3         = Theme.Colors.TextSub
    closeBtn.BackgroundColor3   = Theme.Colors.SurfaceAlt
    closeBtn.BorderSizePixel    = 0
    closeBtn.Size               = UDim2.fromOffset(28, 28)
    closeBtn.Position           = UDim2.new(1, -32, 0.5, -14)
    makeCorner(closeBtn, UDim.new(0,6))

    closeBtn.MouseButton1Click:Connect(function()
        Framework.Hide()
    end)
    minBtn.MouseButton1Click:Connect(function()
        Framework.Toggle()
    end)

    -- Hover sur boutons header
    for _, b in ipairs({minBtn, closeBtn}) do
        b.MouseEnter:Connect(function()
            Animation.Tween(b, {BackgroundColor3 = Theme.Colors.BorderHover}, TweenInfo.new(0.1))
        end)
        b.MouseLeave:Connect(function()
            Animation.Tween(b, {BackgroundColor3 = Theme.Colors.SurfaceAlt},  TweenInfo.new(0.1))
        end)
    end

    makeDraggable(header, window)

    -- ── Sidebar ───────────────────────────────────────
    sidebar = Instance.new("Frame", window)
    sidebar.Name               = "Sidebar"
    sidebar.BackgroundColor3   = Theme.Colors.Surface
    sidebar.BorderSizePixel    = 0
    sidebar.Size               = UDim2.new(0, Theme.Size.SidebarWidth, 1, -Theme.Size.HeaderHeight)
    sidebar.Position           = UDim2.new(0, 0, 0, Theme.Size.HeaderHeight)

    -- Séparateur droite sidebar
    local sep = Instance.new("Frame", sidebar)
    sep.BackgroundColor3 = Theme.Colors.Border
    sep.BorderSizePixel  = 0
    sep.Size             = UDim2.fromOffset(1, 9999)
    sep.Position         = UDim2.new(1, -1, 0, 0)

    local sideLayout = Instance.new("UIListLayout", sidebar)
    sideLayout.SortOrder        = Enum.SortOrder.LayoutOrder
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sideLayout.Padding          = UDim.new(0, 2)
    makePadding(sidebar, 6)

    -- ── Content area ──────────────────────────────────
    content = Instance.new("Frame", window)
    content.Name               = "Content"
    content.BackgroundTransparency = 1
    content.BorderSizePixel    = 0
    content.Size               = UDim2.new(1, -Theme.Size.SidebarWidth, 1, -Theme.Size.HeaderHeight)
    content.Position           = UDim2.new(0, Theme.Size.SidebarWidth, 0, Theme.Size.HeaderHeight)
    content.ClipsDescendants   = true

    -- Watermark update
    Framework._startWatermark(wm)

    -- Animation d'entrée
    window.Size = UDim2.fromOffset(0, 0)
    window.BackgroundTransparency = 1
    TweenService:Create(window, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(Theme.Size.WindowWidth, Theme.Size.WindowHeight),
        BackgroundTransparency = 0,
    }):Play()

    Framework._gui       = gui
    Framework._window    = window
    Framework._sidebar   = sidebar
    Framework._content   = content
    Framework._header    = header
end

-- ── Watermark ─────────────────────────────────────────
function Framework._startWatermark(label)
    local fpsBuffer = {}
    local lastTime  = os.clock()

    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        local dt  = now - lastTime
        lastTime  = now
        table.insert(fpsBuffer, 1/dt)
        if #fpsBuffer > 30 then table.remove(fpsBuffer, 1) end
        local avgFps = 0
        for _, v in ipairs(fpsBuffer) do avgFps = avgFps + v end
        avgFps = math.floor(avgFps / #fpsBuffer)

        local ping = 0
        pcall(function()
            ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
        end)

        label.Text = "FPS: "..avgFps.." | Ping: "..ping.."ms"
        label.TextColor3 = avgFps > 50
            and Theme.Colors.TextSub
            or  Theme.Colors.Warning
    end)
end

-- ── Ajouter un tab ────────────────────────────────────
function Framework.AddTab(name, icon)
    local sidebarItem = createSidebarItem(sidebar, icon, name, #tabs + 1)

    local tabContent = Instance.new("Frame", content)
    tabContent.Name                  = "Tab_"..name
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel       = 0
    tabContent.Size                  = UDim2.fromScale(1,1)
    tabContent.Visible               = false
    tabContent.ClipsDescendants      = true

    -- Scroll
    local scroll = Instance.new("ScrollingFrame", tabContent)
    scroll.Name                     = "Scroll"
    scroll.BackgroundTransparency   = 1
    scroll.BorderSizePixel          = 0
    scroll.Size                     = UDim2.fromScale(1,1)
    scroll.ScrollBarThickness       = 3
    scroll.ScrollBarImageColor3     = Theme.Colors.Accent
    scroll.CanvasSize               = UDim2.fromOffset(0,0)
    scroll.AutomaticCanvasSize      = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout", scroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 8)
    makePadding(scroll, 10)

    tabs[name] = {
        name    = name,
        icon    = icon,
        content = tabContent,
        scroll  = scroll,
        layout  = layout,
        sidebar = sidebarItem,
        active  = false,
    }

    sidebarItem.btn.MouseButton1Click:Connect(function()
        activateTab(name)
    end)

    -- Active le premier tab automatiquement
    if not activeTab then
        activateTab(name)
    end

    return tabs[name]
end

-- ── Ajouter une section dans un tab ───────────────────
function Framework.AddSection(tabName, title)
    local t = tabs[tabName]
    if not t then return end

    local section = Instance.new("Frame", t.scroll)
    section.Name               = "Section_"..title
    section.BackgroundColor3   = Theme.Colors.Surface
    section.BorderSizePixel    = 0
    section.Size               = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize      = Enum.AutomaticSize.Y
    makeCorner(section, Theme.Radius.Card)
    makeStroke(section, Theme.Colors.Border)

    -- Titre section
    local titleBar = Instance.new("Frame", section)
    titleBar.BackgroundTransparency = 1
    titleBar.BorderSizePixel        = 0
    titleBar.Size                   = UDim2.new(1,0,0,32)

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Text              = title:upper()
    titleLabel.Font              = Theme.Fonts.Bold
    titleLabel.TextSize          = Theme.TextSize.Small
    titleLabel.TextColor3        = Theme.Colors.Accent
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size              = UDim2.fromScale(1,1)
    titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    makePadding(titleLabel, 0, 0, 0, 12, 0)

    -- Séparateur
    local sep = Instance.new("Frame", section)
    sep.BackgroundColor3 = Theme.Colors.Border
    sep.BorderSizePixel  = 0
    sep.Size             = UDim2.new(1,-24,0,1)
    sep.Position         = UDim2.fromOffset(12, 30)

    -- Container des items
    local itemContainer = Instance.new("Frame", section)
    itemContainer.Name             = "Items"
    itemContainer.BackgroundTransparency = 1
    itemContainer.BorderSizePixel  = 0
    itemContainer.Size             = UDim2.new(1,0,0,0)
    itemContainer.Position         = UDim2.fromOffset(0, 34)
    itemContainer.AutomaticSize   = Enum.AutomaticSize.Y

    local itemLayout = Instance.new("UIListLayout", itemContainer)
    itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemLayout.Padding   = UDim.new(0, 2)
    makePadding(itemContainer, 0, 4, 8, 8, 8)

    return {
        frame     = section,
        container = itemContainer,
        layout    = itemLayout,
    }
end

-- ── Visibilité ────────────────────────────────────────
function Framework.Show()
    if not window then return end
    visible = true
    window.Visible = true
    Animation.Tween(window,
        {BackgroundTransparency = 0},
        TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    )
end

function Framework.Hide()
    if not window then return end
    visible = false
    Animation.Tween(window,
        {BackgroundTransparency = 1},
        TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    )
    task.delay(0.15, function()
        if window then window.Visible = false end
    end)
end

function Framework.Toggle()
    if visible then Framework.Hide() else Framework.Show() end
end

function Framework.IsVisible()
    return visible
end

function Framework.Destroy()
    if gui then gui:Destroy(); gui = nil end
    tabs      = {}
    activeTab = nil
    particles = {}
end

return Framework
