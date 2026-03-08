-- ══════════════════════════════════════════════════════
--   Aurora v3.1.3 — UI/Framework.lua
--   Style : Sidebar gauche + contenu droite
--           Inspiré design moderne dark avec sous-tabs
-- ══════════════════════════════════════════════════════

local Framework = {}

local TweenS     = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer

local Theme, Animation, Config
local gui, window, sidebar, content
local tabs       = {}
local activeTab  = nil
local visible    = true
local particles  = {}

-- ── Helpers ───────────────────────────────────────────
local function C(r,g,b) return Color3.fromRGB(r,g,b) end
local function T(i, p, t, style)
    return TweenS:Create(i,
        TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        p
    )
end
local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0,8)
    return c
end
local function padding(p, all, t, b, l, r)
    local pad = Instance.new("UIPadding", p)
    pad.PaddingTop    = UDim.new(0, t or all or 6)
    pad.PaddingBottom = UDim.new(0, b or all or 6)
    pad.PaddingLeft   = UDim.new(0, l or all or 6)
    pad.PaddingRight  = UDim.new(0, r or all or 6)
    return pad
end
local function listLayout(p, dir, space)
    local l = Instance.new("UIListLayout", p)
    l.SortOrder       = Enum.SortOrder.LayoutOrder
    l.FillDirection   = dir or Enum.FillDirection.Vertical
    l.Padding         = UDim.new(0, space or 0)
    return l
end

-- ── Draggable ─────────────────────────────────────────
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = i.Position
            startPos  = target.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ── Particle background ───────────────────────────────
local function animateParticles(parent)
    local count = 18
    for i = 1, count do
        local p = Instance.new("Frame", parent)
        p.BackgroundColor3       = C(91,107,248)
        p.BorderSizePixel        = 0
        p.BackgroundTransparency = 0.82
        local s = math.random(2,4)
        p.Size     = UDim2.fromOffset(s,s)
        p.Position = UDim2.fromScale(math.random()*0.95+0.02, math.random()*0.95+0.02)
        corner(p, UDim.new(1,0))
        table.insert(particles, p)

        task.spawn(function()
            while p and p.Parent do
                local ox = p.Position.X.Scale
                local oy = p.Position.Y.Scale
                local nx  = math.clamp(ox + (math.random()-0.5)*0.06, 0.02, 0.97)
                local ny  = math.clamp(oy + (math.random()-0.5)*0.04, 0.02, 0.97)
                local dur = 2 + math.random()*2
                T(p, {Position=UDim2.fromScale(nx,ny), BackgroundTransparency=0.6+math.random()*0.3}, dur):Play()
                task.wait(dur)
            end
        end)
    end
end

-- ── Tab activation ────────────────────────────────────
local function activateTab(name)
    if activeTab == name then return end

    if activeTab and tabs[activeTab] then
        local old = tabs[activeTab]
        old.active = false
        if old.content then
            T(old.content, {BackgroundTransparency=1}, 0.2):Play()
            task.delay(0.2, function()
                if old.content then old.content.Visible = false end
            end)
        end
        if old.sideBtn then
            T(old.sideBtn, {BackgroundTransparency=1}, 0.2):Play()
            T(old.sideIcon, {TextColor3=C(90,90,120)}, 0.2):Play()
            T(old.sideLabel, {TextColor3=C(90,90,120)}, 0.2):Play()
            if old.sideIndicator then
                T(old.sideIndicator, {BackgroundTransparency=1}, 0.2):Play()
            end
        end
    end

    activeTab = name
    local t = tabs[name]
    if not t then return end
    t.active = true

    if t.content then
        t.content.Visible = true
        t.content.BackgroundTransparency = 1
        T(t.content, {BackgroundTransparency=0}, 0.22):Play()
    end
    if t.sideBtn then
        T(t.sideBtn, {BackgroundTransparency=0.88}, 0.2):Play()
        T(t.sideIcon, {TextColor3=C(140,160,255)}, 0.2):Play()
        T(t.sideLabel, {TextColor3=Color3.new(1,1,1)}, 0.2):Play()
        if t.sideIndicator then
            T(t.sideIndicator, {BackgroundTransparency=0}, 0.2):Play()
        end
    end
end

-- ── Build GUI ─────────────────────────────────────────
function Framework._buildGui()
    gui = Instance.new("ScreenGui")
    gui.Name           = "Aurora_UI"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.DisplayOrder   = 100
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Fenêtre principale
    window = Instance.new("Frame", gui)
    window.Name              = "Window"
    window.BackgroundColor3  = C(8,8,14)
    window.BorderSizePixel   = 0
    window.Size              = UDim2.fromOffset(680, 460)
    window.Position          = UDim2.fromScale(0.5, 0.5)
    window.AnchorPoint       = Vector2.new(0.5, 0.5)
    window.ClipsDescendants  = true
    corner(window, UDim.new(0,14))

    -- Bordure accent
    local winBorder = Instance.new("UIStroke", window)
    winBorder.Color     = C(91,107,248)
    winBorder.Thickness = 1
    winBorder.Transparency = 0.5

    -- Particles bg
    animateParticles(window)

    -- ── HEADER ────────────────────────────────────────
    local header = Instance.new("Frame", window)
    header.Name             = "Header"
    header.BackgroundColor3 = C(10,10,18)
    header.BorderSizePixel  = 0
    header.Size             = UDim2.new(1,0,0,44)
    header.ZIndex           = 10

    -- Gradient header
    local hGrad = Instance.new("UIGradient", header)
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C(14,12,28)),
        ColorSequenceKeypoint.new(1, C(10,10,18)),
    })
    hGrad.Rotation = 90

    -- Ligne séparation header
    local hLine = Instance.new("Frame", header)
    hLine.BackgroundColor3 = C(91,107,248)
    hLine.BackgroundTransparency = 0.7
    hLine.BorderSizePixel  = 0
    hLine.Size             = UDim2.new(1,0,0,1)
    hLine.Position         = UDim2.new(0,0,1,-1)

    -- Logo
    local logoBox = Instance.new("Frame", header)
    logoBox.BackgroundColor3 = C(91,107,248)
    logoBox.BorderSizePixel  = 0
    logoBox.Size             = UDim2.fromOffset(28,28)
    logoBox.Position         = UDim2.new(0,10,0.5,-14)
    corner(logoBox, UDim.new(0,7))

    local logoTxt = Instance.new("TextLabel", logoBox)
    logoTxt.Text            = "A"
    logoTxt.Font            = Enum.Font.GothamBold
    logoTxt.TextSize        = 14
    logoTxt.TextColor3      = Color3.new(1,1,1)
    logoTxt.BackgroundTransparency = 1
    logoTxt.Size            = UDim2.fromScale(1,1)
    logoTxt.TextXAlignment  = Enum.TextXAlignment.Center

    local nameLabel = Instance.new("TextLabel", header)
    nameLabel.Text           = "Aurora"
    nameLabel.Font           = Enum.Font.GothamBold
    nameLabel.TextSize       = 16
    nameLabel.TextColor3     = Color3.new(1,1,1)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size           = UDim2.fromOffset(80,44)
    nameLabel.Position       = UDim2.fromOffset(44,0)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local verLabel = Instance.new("TextLabel", header)
    verLabel.Text           = "v3.1.3"
    verLabel.Font           = Enum.Font.Gotham
    verLabel.TextSize       = 11
    verLabel.TextColor3     = C(91,107,248)
    verLabel.BackgroundTransparency = 1
    verLabel.Size           = UDim2.fromOffset(50,44)
    verLabel.Position       = UDim2.fromOffset(122,0)
    verLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Watermark droite
    local wm = Instance.new("TextLabel", header)
    wm.Name             = "WM"
    wm.Text             = "-- | -- fps | --ms"
    wm.Font             = Enum.Font.Gotham
    wm.TextSize         = 12
    wm.TextColor3       = C(130,130,180)
    wm.BackgroundTransparency = 1
    wm.Size             = UDim2.fromOffset(260,44)
    wm.Position         = UDim2.new(1,-330,0,0)
    wm.TextXAlignment   = Enum.TextXAlignment.Right

    -- Boutons header
    local function mkHBtn(txt, xOffset, hoverColor)
        local b = Instance.new("TextButton", header)
        b.Text            = txt
        b.Font            = Enum.Font.GothamBold
        b.TextSize        = 13
        b.TextColor3      = C(150,150,180)
        b.BackgroundColor3 = C(20,20,32)
        b.BackgroundTransparency = 0.4
        b.BorderSizePixel = 0
        b.Size            = UDim2.fromOffset(28,28)
        b.Position        = UDim2.new(1,xOffset,0.5,-14)
        b.AutoButtonColor = false
        corner(b, UDim.new(0,6))
        b.MouseEnter:Connect(function()
            T(b, {BackgroundColor3=hoverColor or C(40,40,60)}, 0.12):Play()
            T(b, {TextColor3=Color3.new(1,1,1)}, 0.12):Play()
        end)
        b.MouseLeave:Connect(function()
            T(b, {BackgroundColor3=C(20,20,32)}, 0.15):Play()
            T(b, {TextColor3=C(150,150,180)}, 0.15):Play()
        end)
        return b
    end

    local closeBtn = mkHBtn("✕", -10, C(200,50,50))
    local minBtn   = mkHBtn("─", -44, C(40,40,70))

    closeBtn.MouseButton1Click:Connect(function() Framework.Hide() end)
    minBtn.MouseButton1Click:Connect(function() Framework.Toggle() end)

    makeDraggable(header, window)

    -- ── SIDEBAR ───────────────────────────────────────
    sidebar = Instance.new("Frame", window)
    sidebar.Name            = "Sidebar"
    sidebar.BackgroundColor3 = C(10,10,18)
    sidebar.BorderSizePixel = 0
    sidebar.Size            = UDim2.new(0,160,1,-44)
    sidebar.Position        = UDim2.fromOffset(0,44)
    sidebar.ClipsDescendants = true

    -- Gradient sidebar
    local sGrad = Instance.new("UIGradient", sidebar)
    sGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C(12,10,24)),
        ColorSequenceKeypoint.new(1, C(10,10,18)),
    })
    sGrad.Rotation = 180

    -- Séparateur droite
    local sSep = Instance.new("Frame", sidebar)
    sSep.BackgroundColor3 = C(91,107,248)
    sSep.BackgroundTransparency = 0.8
    sSep.BorderSizePixel  = 0
    sSep.Size             = UDim2.fromOffset(1, 9999)
    sSep.Position         = UDim2.new(1,-1,0,0)

    local sLayout = Instance.new("ScrollingFrame", sidebar)
    sLayout.BackgroundTransparency = 1
    sLayout.BorderSizePixel        = 0
    sLayout.Size                   = UDim2.fromScale(1,1)
    sLayout.ScrollBarThickness     = 0
    sLayout.CanvasSize             = UDim2.fromOffset(0,0)
    sLayout.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    listLayout(sLayout, nil, 2)
    padding(sLayout, 8, 10, 8, 8, 8)

    -- ── CONTENT ───────────────────────────────────────
    content = Instance.new("Frame", window)
    content.Name              = "Content"
    content.BackgroundColor3  = C(8,8,14)
    content.BackgroundTransparency = 0
    content.BorderSizePixel   = 0
    content.Size              = UDim2.new(1,-160,1,-44)
    content.Position          = UDim2.fromOffset(160,44)
    content.ClipsDescendants  = true

    -- Watermark update loop
    local fpsBuffer = {}
    local lastT     = os.clock()
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        table.insert(fpsBuffer, 1/(now-lastT))
        lastT = now
        if #fpsBuffer > 20 then table.remove(fpsBuffer,1) end
        if #fpsBuffer % 10 == 0 then
            local avg = 0
            for _, v in ipairs(fpsBuffer) do avg = avg + v end
            avg = math.floor(avg/#fpsBuffer)
            local ping = 0
            pcall(function() ping = math.floor(LP:GetNetworkPing()*1000) end)
            local name = ""
            pcall(function() name = LP.Name end)
            local pingC = ping <= 80 and "✦" or ping <= 150 and "△" or "✕"
            wm.Text = name.."  |  "..avg.." fps  |  "..pingC.." "..ping.."ms"
            wm.TextColor3 = avg > 50 and C(130,130,180) or C(248,180,80)
        end
    end)

    -- Keybind Insert pour toggle
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Insert then
            Framework.Toggle()
        end
    end)

    Framework._gui     = gui
    Framework._window  = window
    Framework._sidebar = sLayout
    Framework._content = content
end

-- ── AddTab ────────────────────────────────────────────
function Framework.AddTab(name, icon)
    if not Framework._sidebar then return end

    -- Bouton sidebar
    local btn = Instance.new("TextButton", Framework._sidebar)
    btn.Name                 = "Tab_"..name
    btn.BackgroundColor3     = C(91,107,248)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel      = 0
    btn.Size                 = UDim2.new(1,0,0,42)
    btn.Text                 = ""
    btn.AutoButtonColor      = false
    btn.LayoutOrder          = #tabs + 1
    corner(btn, UDim.new(0,8))

    -- Indicateur actif gauche
    local indicator = Instance.new("Frame", btn)
    indicator.BackgroundColor3       = C(91,107,248)
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel        = 0
    indicator.Size                   = UDim2.fromOffset(3,24)
    indicator.Position               = UDim2.new(0,0,0.5,-12)
    corner(indicator, UDim.new(1,0))

    -- Icône
    local ico = Instance.new("TextLabel", btn)
    ico.Text            = icon or "•"
    ico.Font            = Enum.Font.GothamBold
    ico.TextSize        = 11
    ico.TextColor3      = C(90,90,120)
    ico.BackgroundTransparency = 1
    ico.Size            = UDim2.fromOffset(32,42)
    ico.Position        = UDim2.fromOffset(10,0)
    ico.TextXAlignment  = Enum.TextXAlignment.Center

    -- Label
    local lbl = Instance.new("TextLabel", btn)
    lbl.Text            = name
    lbl.Font            = Enum.Font.GothamMedium
    lbl.TextSize        = 13
    lbl.TextColor3      = C(90,90,120)
    lbl.BackgroundTransparency = 1
    lbl.Size            = UDim2.new(1,-44,1,0)
    lbl.Position        = UDim2.fromOffset(40,0)
    lbl.TextXAlignment  = Enum.TextXAlignment.Left

    -- Hover
    btn.MouseEnter:Connect(function()
        if not (tabs[name] and tabs[name].active) then
            T(btn, {BackgroundTransparency=0.92}, 0.12):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not (tabs[name] and tabs[name].active) then
            T(btn, {BackgroundTransparency=1}, 0.15):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        activateTab(name)
    end)

    -- Zone de contenu
    local tabContent = Instance.new("Frame", Framework._content)
    tabContent.Name                  = "Tab_"..name
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel       = 0
    tabContent.Size                  = UDim2.fromScale(1,1)
    tabContent.Visible               = false

    local scroll = Instance.new("ScrollingFrame", tabContent)
    scroll.Name                  = "Scroll"
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel       = 0
    scroll.Size                  = UDim2.fromScale(1,1)
    scroll.ScrollBarThickness    = 3
    scroll.ScrollBarImageColor3  = C(91,107,248)
    scroll.CanvasSize            = UDim2.fromOffset(0,0)
    scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    listLayout(scroll, nil, 10)
    padding(scroll, 14)

    tabs[name] = {
        name         = name,
        content      = tabContent,
        scroll       = scroll,
        sideBtn      = btn,
        sideIcon     = ico,
        sideLabel    = lbl,
        sideIndicator = indicator,
        active       = false,
    }

    if not activeTab then
        activateTab(name)
    end

    return tabs[name]
end

-- ── AddSection ────────────────────────────────────────
function Framework.AddSection(tabName, title)
    local t = tabs[tabName]
    if not t then return nil end

    local section = Instance.new("Frame", t.scroll)
    section.Name             = "Sec_"..title
    section.BackgroundColor3 = C(13,13,22)
    section.BorderSizePixel  = 0
    section.Size             = UDim2.new(1,0,0,0)
    section.AutomaticSize    = Enum.AutomaticSize.Y
    corner(section, UDim.new(0,10))

    local stroke = Instance.new("UIStroke", section)
    stroke.Color       = C(30,30,55)
    stroke.Thickness   = 1

    -- Header section
    local secHeader = Instance.new("Frame", section)
    secHeader.BackgroundTransparency = 1
    secHeader.BorderSizePixel        = 0
    secHeader.Size                   = UDim2.new(1,0,0,36)

    local secLine = Instance.new("Frame", secHeader)
    secLine.BackgroundColor3 = C(91,107,248)
    secLine.BackgroundTransparency = 0.6
    secLine.BorderSizePixel  = 0
    secLine.Size             = UDim2.fromOffset(3,16)
    secLine.Position         = UDim2.new(0,12,0.5,-8)
    corner(secLine, UDim.new(1,0))

    local titleLbl = Instance.new("TextLabel", secHeader)
    titleLbl.Text           = title:upper()
    titleLbl.Font           = Enum.Font.GothamBold
    titleLbl.TextSize       = 10
    titleLbl.TextColor3     = C(91,107,248)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size           = UDim2.new(1,-20,1,0)
    titleLbl.Position       = UDim2.fromOffset(22,0)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTransparency = 0.1

    local divider = Instance.new("Frame", section)
    divider.BackgroundColor3 = C(20,20,38)
    divider.BorderSizePixel  = 0
    divider.Size             = UDim2.new(1,-24,0,1)
    divider.Position         = UDim2.fromOffset(12,36)

    local items = Instance.new("Frame", section)
    items.Name             = "Items"
    items.BackgroundTransparency = 1
    items.BorderSizePixel  = 0
    items.Size             = UDim2.new(1,0,0,0)
    items.AutomaticSize    = Enum.AutomaticSize.Y
    items.Position         = UDim2.fromOffset(0,40)
    listLayout(items, nil, 0)
    padding(items, 0, 2, 8, 8, 8)

    local itemLayout = Instance.new("UIListLayout", items)
    itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
    itemLayout.Padding   = UDim.new(0,2)

    return {frame=section, container=items, layout=itemLayout}
end

-- ── Init ──────────────────────────────────────────────
function Framework.Init(deps)
    Theme     = deps.Theme     or {}
    Animation = deps.Animation or {}
    Config    = deps.Config

    Framework._buildGui()

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
    for _, tab in ipairs(defaultTabs) do
        Framework.AddTab(tab[1], tab[2])
    end

    -- Animation d'entrée
    window.Size = UDim2.fromOffset(0, 0)
    window.BackgroundTransparency = 1
    local tween = TweenS:Create(window,
        TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size=UDim2.fromOffset(680,460), BackgroundTransparency=0}
    )
    tween:Play()
end

-- ── Visibility ────────────────────────────────────────
function Framework.Show()
    if not window then return end
    visible = true
    window.Visible = true
    T(window, {BackgroundTransparency=0, Size=UDim2.fromOffset(680,460)}, 0.3, Enum.EasingStyle.Back):Play()
end

function Framework.Hide()
    if not window then return end
    visible = false
    T(window, {BackgroundTransparency=1, Size=UDim2.fromOffset(660,440)}, 0.2):Play()
    task.delay(0.22, function()
        if window then window.Visible = false end
    end)
end

function Framework.Toggle()
    if visible then Framework.Hide() else Framework.Show() end
end

function Framework.IsVisible() return visible end

function Framework.HideAll()
    if gui then gui.Enabled = false end
end

function Framework.GetGui()   return gui    end
function Framework.GetWindow() return window end

return Framework
