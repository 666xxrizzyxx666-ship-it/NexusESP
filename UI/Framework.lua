-- Aurora v3.2.0 — UI/Framework.lua
-- Architecture: tailles fixes, ZIndex explicite, pas d'AutomaticSize problématique
local Framework = {}

local TweenS     = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer

-- Palette
local BG       = Color3.fromRGB(8,8,14)
local SURF     = Color3.fromRGB(12,12,20)
local SURF2    = Color3.fromRGB(17,17,28)
local BORDER   = Color3.fromRGB(30,30,52)
local ACCENT   = Color3.fromRGB(91,107,248)
local ACCENT2  = Color3.fromRGB(130,148,255)
local TEXT     = Color3.fromRGB(228,228,238)
local TEXTMID  = Color3.fromRGB(148,148,172)
local TEXTLOW  = Color3.fromRGB(72,72,100)
local WARN     = Color3.fromRGB(251,191,36)

-- Dimensions fixes
local W_WIDTH   = 760
local W_HEIGHT  = 500
local HEADER_H  = 46
local SIDEBAR_W = 170
local CONTENT_X = SIDEBAR_W
local CONTENT_W = W_WIDTH - SIDEBAR_W
local CONTENT_H = W_HEIGHT - HEADER_H

local gui, win
local tabs       = {}
local activeTab  = nil
local visible    = true
local sideList   -- ScrollingFrame de la sidebar

-- ── Utilitaires ───────────────────────────────────────
local function tween(inst, props, t, style)
    if not inst or not inst.Parent then return end
    local ok, tw = pcall(TweenS.Create, TweenS, inst,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props)
    if ok and tw then tw:Play() return tw end
end

local function frame(parent, props)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    for k,v in pairs(props) do pcall(function() f[k]=v end) end
    f.Parent = parent
    return f
end

local function label(parent, props)
    local l = Instance.new("TextLabel")
    l.BorderSizePixel = 0
    l.BackgroundTransparency = 1
    for k,v in pairs(props) do pcall(function() l[k]=v end) end
    l.Parent = parent
    return l
end

local function btn(parent, props)
    local b = Instance.new("TextButton")
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    for k,v in pairs(props) do pcall(function() b[k]=v end) end
    b.Parent = parent
    return b
end

local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = type(r)=="number" and UDim.new(0,r) or (r or UDim.new(0,8))
    return c
end

local function uiStroke(p, col, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color = col or BORDER
    s.Thickness = thick or 1
    s.Transparency = trans or 0
    return s
end

local function scrollFrame(parent, props)
    local s = Instance.new("ScrollingFrame")
    s.BorderSizePixel = 0
    s.BackgroundTransparency = 1
    s.ScrollBarThickness = 3
    s.ScrollBarImageColor3 = ACCENT
    s.CanvasSize = UDim2.fromOffset(0,0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    for k,v in pairs(props) do pcall(function() s[k]=v end) end
    s.Parent = parent
    return s
end

local function listLayout(parent, spacing)
    local l = Instance.new("UIListLayout", parent)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, spacing or 0)
    return l
end

local function padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    return p
end

local function draggable(handle, target)
    local drag, ds, dp = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; dp = target.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            target.Position = UDim2.new(dp.X.Scale, dp.X.Offset+d.X, dp.Y.Scale, dp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

-- ── Particules fond ───────────────────────────────────
local function spawnParticles(parent)
    for i = 1, 18 do
        task.delay(math.random() * 2, function()
            if not parent or not parent.Parent then return end
            local p = frame(parent, {
                BackgroundColor3 = ACCENT,
                BackgroundTransparency = 0.82,
                Size = UDim2.fromOffset(math.random(2,3), math.random(2,3)),
                Position = UDim2.fromScale(math.random()*0.85+0.07, math.random()*0.85+0.07),
                ZIndex = 2,
            })
            corner(p, UDim.new(1,0))
            while p and p.Parent do
                local nx = math.clamp(p.Position.X.Scale + (math.random()-0.5)*0.06, 0.05, 0.94)
                local ny = math.clamp(p.Position.Y.Scale + (math.random()-0.5)*0.05, 0.05, 0.94)
                local dur = 2 + math.random()*2.5
                tween(p, {Position=UDim2.fromScale(nx,ny), BackgroundTransparency=0.7+math.random()*0.22}, dur)
                task.wait(dur)
            end
        end)
    end
end

-- ── Tab switch ────────────────────────────────────────
local function switchTab(name)
    if activeTab == name then return end

    -- Cache immédiatement l'ancien
    if activeTab and tabs[activeTab] then
        local old = tabs[activeTab]
        old.active = false
        if old.content then old.content.Visible = false end
        tween(old.sBtn, {BackgroundTransparency=1}, 0.15)
        tween(old.sTxt, {TextColor3=TEXTLOW}, 0.15)
        if old.sBar then tween(old.sBar, {BackgroundTransparency=1}, 0.15) end
    end

    activeTab = name
    local t = tabs[name]
    if not t then return end
    t.active = true

    -- Fade in nouveau tab
    if t.content then
        t.content.BackgroundTransparency = 1
        t.content.Visible = true
        tween(t.content, {BackgroundTransparency=0}, 0.2)
    end
    tween(t.sBtn, {BackgroundTransparency=0.88}, 0.18)
    tween(t.sTxt, {TextColor3=TEXT}, 0.18)
    if t.sBar then tween(t.sBar, {BackgroundTransparency=0}, 0.18) end
end

-- ── Build ─────────────────────────────────────────────
function Framework._buildGui()
    gui = Instance.new("ScreenGui")
    gui.Name = "Aurora_UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.DisplayOrder = 500
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Fenêtre principale
    win = frame(gui, {
        BackgroundColor3 = BG,
        Size = UDim2.fromOffset(W_WIDTH, W_HEIGHT),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        ZIndex = 10,
    })
    corner(win, 14)
    uiStroke(win, ACCENT, 1, 0.55)
    spawnParticles(win)

    -- ── HEADER ────────────────────────────────────────
    local hdr = frame(win, {
        BackgroundColor3 = SURF,
        Size = UDim2.fromOffset(W_WIDTH, HEADER_H),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 30,
    })

    -- Ligne bas header
    frame(hdr, {
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 0.7,
        Size = UDim2.fromOffset(W_WIDTH, 1),
        Position = UDim2.fromOffset(0, HEADER_H-1),
        ZIndex = 31,
    })

    -- Logo "A" badge
    local logoBg = frame(hdr, {
        BackgroundColor3 = ACCENT,
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.fromOffset(12, 8),
        ZIndex = 32,
    })
    corner(logoBg, 8)
    label(logoBg, {
        Text = "A", Font = Enum.Font.GothamBold, TextSize = 15,
        TextColor3 = Color3.new(1,1,1),
        Size = UDim2.fromScale(1,1), ZIndex = 33,
    })

    -- Titre
    label(hdr, {
        Text = "Aurora", Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = Color3.new(1,1,1),
        Size = UDim2.fromOffset(75, HEADER_H),
        Position = UDim2.fromOffset(48, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 32,
    })

    -- Version
    label(hdr, {
        Text = "v3.2.0", Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = ACCENT2,
        Size = UDim2.fromOffset(55, HEADER_H),
        Position = UDim2.fromOffset(124, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 32,
    })

    -- Watermark (nom | fps | ping)
    local wm = label(hdr, {
        Text = "", Font = Enum.Font.Code, TextSize = 12,
        TextColor3 = TEXTMID,
        Size = UDim2.fromOffset(320, HEADER_H),
        Position = UDim2.fromOffset(W_WIDTH-390, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 32,
    })

    -- Boutons header
    local function mkHBtn(txt, xOff, hoverCol)
        local b = btn(hdr, {
            Text = txt, Font = Enum.Font.GothamBold, TextSize = 12,
            TextColor3 = TEXTMID, BackgroundColor3 = SURF2,
            BackgroundTransparency = 0.2,
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.fromOffset(W_WIDTH + xOff, 9),
            ZIndex = 32,
        })
        corner(b, 6)
        b.MouseEnter:Connect(function()
            tween(b, {BackgroundColor3=hoverCol, TextColor3=Color3.new(1,1,1)}, 0.1)
        end)
        b.MouseLeave:Connect(function()
            tween(b, {BackgroundColor3=SURF2, TextColor3=TEXTMID}, 0.12)
        end)
        return b
    end

    local closeB = mkHBtn("✕", -10, Color3.fromRGB(200,60,60))
    local minB   = mkHBtn("─", -44, Color3.fromRGB(40,40,70))
    closeB.MouseButton1Click:Connect(function() Framework.Hide() end)
    minB.MouseButton1Click:Connect(function() Framework.Toggle() end)

    draggable(hdr, win)

    -- Watermark update
    local fpsB = {}; local lt = os.clock()
    RunService.Heartbeat:Connect(function()
        local n = os.clock()
        table.insert(fpsB, 1/(n-lt)); lt = n
        if #fpsB > 20 then table.remove(fpsB, 1) end
        if #fpsB % 10 == 0 then
            local s=0; for _,v in ipairs(fpsB) do s=s+v end
            local fps = math.floor(s/#fpsB)
            local ping = 0
            pcall(function() ping = math.floor(LP:GetNetworkPing()*1000) end)
            local name = ""; pcall(function() name = LP.Name end)
            wm.Text = name.."   ·   "..fps.." fps   ·   "..ping.."ms"
            wm.TextColor3 = fps > 45 and TEXTMID or WARN
        end
    end)

    -- ── SIDEBAR ───────────────────────────────────────
    local sidebar = frame(win, {
        BackgroundColor3 = SURF,
        Size = UDim2.fromOffset(SIDEBAR_W, CONTENT_H),
        Position = UDim2.fromOffset(0, HEADER_H),
        ClipsDescendants = true,
        ZIndex = 20,
    })

    -- Séparateur droite
    frame(sidebar, {
        BackgroundColor3 = BORDER,
        Size = UDim2.fromOffset(1, CONTENT_H),
        Position = UDim2.fromOffset(SIDEBAR_W-1, 0),
        ZIndex = 21,
    })

    -- Logo Aurora en bas sidebar
    label(sidebar, {
        Text = "AURORA", Font = Enum.Font.GothamBold, TextSize = 9,
        TextColor3 = TEXTLOW,
        Size = UDim2.fromOffset(SIDEBAR_W, 30),
        Position = UDim2.fromOffset(0, CONTENT_H-30),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 21,
    })

    sideList = scrollFrame(sidebar, {
        Size = UDim2.fromOffset(SIDEBAR_W, CONTENT_H-36),
        Position = UDim2.fromOffset(0, 4),
        ZIndex = 22,
        ScrollBarThickness = 0,
    })
    listLayout(sideList, 2)
    padding(sideList, 6, 6, 8, 8)

    -- ── CONTENT AREA ──────────────────────────────────
    local contentArea = frame(win, {
        BackgroundColor3 = BG,
        Size = UDim2.fromOffset(CONTENT_W, CONTENT_H),
        Position = UDim2.fromOffset(CONTENT_X, HEADER_H),
        ClipsDescendants = true,
        ZIndex = 10,
    })

    Framework._gui        = gui
    Framework._win        = win
    Framework._sideList   = sideList
    Framework._contentArea = contentArea

    -- INSERT pour toggle
    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.Insert then Framework.Toggle() end
    end)
end

-- ── AddTab ────────────────────────────────────────────
function Framework.AddTab(name, icon)
    if not sideList then return end
    local order = #tabs + 1

    -- Bouton sidebar (taille fixe)
    local sBtn = btn(sideList, {
        Name = "STab_"..name,
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(SIDEBAR_W - 16, 38),
        Text = "",
        LayoutOrder = order,
        ZIndex = 23,
    })
    corner(sBtn, 8)

    -- Barre indicateur gauche
    local sBar = frame(sBtn, {
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(3, 20),
        Position = UDim2.fromOffset(0, 9),
        ZIndex = 24,
    })
    corner(sBar, UDim.new(1,0))

    -- Icône badge
    local sBadge = label(sBtn, {
        Text = icon or "·",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = TEXTLOW,
        BackgroundColor3 = SURF2,
        BackgroundTransparency = 0.2,
        Size = UDim2.fromOffset(30, 22),
        Position = UDim2.fromOffset(8, 8),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 24,
    })
    corner(sBadge, 5)

    -- Nom du tab
    local sTxt = label(sBtn, {
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = TEXTLOW,
        Size = UDim2.fromOffset(SIDEBAR_W-68, 38),
        Position = UDim2.fromOffset(44, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 24,
    })

    -- Hover
    sBtn.MouseEnter:Connect(function()
        if activeTab ~= name then
            tween(sBtn, {BackgroundTransparency=0.92}, 0.1)
            tween(sTxt, {TextColor3=TEXTMID}, 0.1)
        end
    end)
    sBtn.MouseLeave:Connect(function()
        if activeTab ~= name then
            tween(sBtn, {BackgroundTransparency=1}, 0.12)
            tween(sTxt, {TextColor3=TEXTLOW}, 0.12)
        end
    end)
    sBtn.MouseButton1Click:Connect(function() switchTab(name) end)

    -- Zone contenu du tab (taille fixe = toute la content area)
    local tabContent = frame(Framework._contentArea, {
        Name = "Tab_"..name,
        BackgroundColor3 = BG,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(CONTENT_W, CONTENT_H),
        Position = UDim2.fromOffset(0, 0),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 11,
    })

    -- Header du tab
    local tabHdr = frame(tabContent, {
        BackgroundColor3 = SURF,
        Size = UDim2.fromOffset(CONTENT_W, 42),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 12,
    })

    label(tabHdr, {
        Text = name:upper(),
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = TEXT,
        Size = UDim2.fromOffset(CONTENT_W-20, 42),
        Position = UDim2.fromOffset(16, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    })

    frame(tabHdr, {
        BackgroundColor3 = ACCENT, BackgroundTransparency = 0.7,
        Size = UDim2.fromOffset(CONTENT_W, 1),
        Position = UDim2.fromOffset(0, 41),
        ZIndex = 13,
    })

    -- Scroll du contenu (sous le header)
    local scroll = scrollFrame(tabContent, {
        Name = "Scroll",
        Size = UDim2.fromOffset(CONTENT_W, CONTENT_H-42),
        Position = UDim2.fromOffset(0, 42),
        ZIndex = 12,
    })
    listLayout(scroll, 10)
    padding(scroll, 12, 16, 14, 14)

    tabs[name] = {
        name=name, content=tabContent, scroll=scroll,
        sBtn=sBtn, sTxt=sTxt, sBar=sBar, sIcon=sBadge,
        active=false,
    }

    if not activeTab then switchTab(name) end
    return tabs[name]
end

-- ── AddSection ────────────────────────────────────────
function Framework.AddSection(tabName, title)
    local t = tabs[tabName]
    if not t then return nil end

    -- Container section
    local sec = frame(t.scroll, {
        BackgroundColor3 = SURF,
        Size = UDim2.fromOffset(CONTENT_W - 28, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 13,
    })
    corner(sec, 10)
    uiStroke(sec, BORDER, 1, 0)

    -- Header section
    local sh = frame(sec, {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(CONTENT_W-28, 32),
        Position = UDim2.fromOffset(0, 0),
        ZIndex = 14,
    })

    -- Ligne accent gauche
    local acLine = frame(sh, {
        BackgroundColor3 = ACCENT,
        BackgroundTransparency = 0.3,
        Size = UDim2.fromOffset(3, 14),
        Position = UDim2.fromOffset(12, 9),
        ZIndex = 15,
    })
    corner(acLine, UDim.new(1,0))

    label(sh, {
        Text = title:upper(),
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = ACCENT2,
        Size = UDim2.fromOffset(CONTENT_W-60, 32),
        Position = UDim2.fromOffset(22, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
    })

    -- Séparateur
    frame(sec, {
        BackgroundColor3 = BORDER,
        Size = UDim2.fromOffset(CONTENT_W-56, 1),
        Position = UDim2.fromOffset(12, 32),
        ZIndex = 14,
    })

    -- Container items
    local items = frame(sec, {
        Name = "Items",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(CONTENT_W-28, 0),
        Position = UDim2.fromOffset(0, 36),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 14,
    })
    listLayout(items, 0)
    padding(items, 4, 8, 10, 10)

    return {frame=sec, container=items}
end

-- ── Init ──────────────────────────────────────────────
function Framework.Init(deps)
    Framework._buildGui()

    local tabDefs = {
        {"ESP","ESP"}, {"Combat","CMB"}, {"Movement","MOV"},
        {"World","WLD"}, {"AI","AI"}, {"Utility","UTL"}, {"Config","CFG"},
    }
    for _, td in ipairs(tabDefs) do Framework.AddTab(td[1], td[2]) end

    -- Anim d'entrée
    win.Size = UDim2.fromOffset(0, 0)
    win.BackgroundTransparency = 1
    tween(win, {Size=UDim2.fromOffset(W_WIDTH,W_HEIGHT), BackgroundTransparency=0}, 0.5, Enum.EasingStyle.Back)
end

-- ── Visibility ────────────────────────────────────────
function Framework.Show()
    if not win then return end
    visible = true; win.Visible = true
    tween(win, {Size=UDim2.fromOffset(W_WIDTH,W_HEIGHT), BackgroundTransparency=0}, 0.35, Enum.EasingStyle.Back)
end

function Framework.Hide()
    if not win then return end
    visible = false
    tween(win, {BackgroundTransparency=1}, 0.2)
    task.delay(0.22, function() if win then win.Visible=false end end)
end

function Framework.Toggle()
    if visible then Framework.Hide() else Framework.Show() end
end

function Framework.IsVisible() return visible end
function Framework.GetGui()    return gui end
function Framework.GetWindow() return win end

return Framework
