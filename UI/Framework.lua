-- Aurora v3.1.5 — UI/Framework.lua
local Framework = {}
local TweenS     = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer

local Theme, Animation, Config
local gui, window, sideScroll, contentArea
local tabs       = {}
local activeTab  = nil
local visible    = true

-- ── Palette ───────────────────────────────────────────
local P = {
    BG        = Color3.fromRGB(7,7,12),
    SURFACE   = Color3.fromRGB(11,11,19),
    SURFACE2  = Color3.fromRGB(15,15,26),
    BORDER    = Color3.fromRGB(28,28,50),
    ACCENT    = Color3.fromRGB(91,107,248),
    ACCENT2   = Color3.fromRGB(120,140,255),
    TEXT      = Color3.fromRGB(225,225,235),
    TEXTMID   = Color3.fromRGB(150,150,175),
    TEXTMUTE  = Color3.fromRGB(80,80,110),
    SUCCESS   = Color3.fromRGB(74,222,128),
    DANGER    = Color3.fromRGB(248,113,113),
    WARNING   = Color3.fromRGB(251,191,36),
}

-- ── Helpers ───────────────────────────────────────────
local function T(inst, props, dur, style, dir)
    if not inst or not inst.Parent then return end
    local ok, tw = pcall(function()
        return TweenS:Create(inst,
            TweenInfo.new(dur or 0.22,
                style or Enum.EasingStyle.Quart,
                dir   or Enum.EasingDirection.Out),
            props)
    end)
    if ok and tw then tw:Play() return tw end
end

local function mk(cls, props, parent)
    local i = Instance.new(cls)
    for k,v in pairs(props) do
        pcall(function() i[k] = v end)
    end
    if parent then i.Parent = parent end
    return i
end

local function corner(p, r)
    return mk("UICorner",{CornerRadius=r or UDim.new(0,8)},p)
end

local function stroke(p, col, thick, trans)
    return mk("UIStroke",{
        Color=col or P.BORDER,
        Thickness=thick or 1,
        Transparency=trans or 0,
    },p)
end

local function listlayout(p, pad, dir)
    return mk("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder,
        FillDirection=dir or Enum.FillDirection.Vertical,
        Padding=UDim.new(0,pad or 0),
    },p)
end

local function pad(p,a,t,b,l,r)
    return mk("UIPadding",{
        PaddingTop=UDim.new(0,t or a or 0),
        PaddingBottom=UDim.new(0,b or a or 0),
        PaddingLeft=UDim.new(0,l or a or 0),
        PaddingRight=UDim.new(0,r or a or 0),
    },p)
end

local function gradient(p, c0, c1, rot)
    local g = mk("UIGradient",{
        Color=ColorSequence.new(c0,c1),
        Rotation=rot or 90,
    },p)
    return g
end

local function protectGui(g)
    pcall(function() g.Parent = game:GetService("CoreGui") end)
    if not g.Parent then g.Parent = LP:WaitForChild("PlayerGui") end
end

-- ── Draggable ─────────────────────────────────────────
local function draggable(handle, target)
    local drag, ds, dp = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; dp=target.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d = i.Position-ds
            target.Position = UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ── Particles ─────────────────────────────────────────
local function spawnParticles(parent)
    for i=1,20 do
        task.spawn(function()
            task.wait(math.random()*2)
            local p = mk("Frame",{
                BackgroundColor3=P.ACCENT,
                BackgroundTransparency=0.85,
                BorderSizePixel=0,
                Size=UDim2.fromOffset(math.random(2,3),math.random(2,3)),
                Position=UDim2.fromScale(math.random()*0.9+0.05, math.random()*0.9+0.05),
                ZIndex=1,
            },parent)
            corner(p,UDim.new(1,0))
            while p and p.Parent do
                local x = p.Position.X.Scale
                local y = p.Position.Y.Scale
                local nx = math.clamp(x+(math.random()-0.5)*0.05,0.02,0.97)
                local ny = math.clamp(y+(math.random()-0.5)*0.04,0.02,0.97)
                local d  = 2.5+math.random()*2
                T(p,{Position=UDim2.fromScale(nx,ny),BackgroundTransparency=0.7+math.random()*0.2},d)
                task.wait(d)
            end
        end)
    end
end

-- ── Tab switch ────────────────────────────────────────
local function switchTab(name)
    if activeTab == name then return end

    -- Désactive ancien tab
    if activeTab and tabs[activeTab] then
        local old = tabs[activeTab]
        old.active = false
        T(old.btn,{BackgroundTransparency=1},0.18)
        T(old.btnTxt,{TextColor3=P.TEXTMUTE},0.18)
        if old.indicator then T(old.indicator,{BackgroundTransparency=1},0.18) end
        if old.content then
            T(old.content,{BackgroundTransparency=1},0.15)
            task.delay(0.18,function()
                if old.content then old.content.Visible=false end
            end)
        end
    end

    activeTab = name
    local t = tabs[name]
    if not t then return end
    t.active = true

    T(t.btn,{BackgroundTransparency=0.86},0.2)
    T(t.btnTxt,{TextColor3=P.TEXT},0.2)
    if t.indicator then T(t.indicator,{BackgroundTransparency=0},0.2) end
    if t.content then
        t.content.Visible = true
        t.content.BackgroundTransparency = 1
        T(t.content,{BackgroundTransparency=0},0.22)
    end
end

-- ── Build UI ──────────────────────────────────────────
function Framework._buildGui()
    gui = mk("ScreenGui",{
        Name="Aurora_UI",
        ResetOnSpawn=false,
        IgnoreGuiInset=true,
        ZIndexBehavior=Enum.ZIndexBehavior.Global,
        DisplayOrder=500,
    })
    protectGui(gui)

    -- Fenêtre
    window = mk("Frame",{
        Name="Window",
        BackgroundColor3=P.BG,
        BorderSizePixel=0,
        Size=UDim2.fromOffset(740,490),
        Position=UDim2.fromScale(0.5,0.5),
        AnchorPoint=Vector2.new(0.5,0.5),
        ClipsDescendants=true,
    },gui)
    corner(window,UDim.new(0,14))
    local ws = stroke(window,P.ACCENT,1,0.6)

    spawnParticles(window)

    -- ── HEADER ────────────────────────────────────────
    local header = mk("Frame",{
        BackgroundColor3=P.SURFACE,
        BorderSizePixel=0,
        Size=UDim2.new(1,0,0,46),
        ZIndex=20,
    },window)

    -- Ligne bas header
    mk("Frame",{
        BackgroundColor3=P.ACCENT,
        BackgroundTransparency=0.75,
        BorderSizePixel=0,
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        ZIndex=21,
    },header)

    -- Gradient header
    gradient(header,Color3.fromRGB(14,12,26),Color3.fromRGB(11,11,19))

    -- Logo badge
    local logoBg = mk("Frame",{
        BackgroundColor3=P.ACCENT,
        BorderSizePixel=0,
        Size=UDim2.fromOffset(30,30),
        Position=UDim2.new(0,12,0.5,-15),
        ZIndex=22,
    },header)
    corner(logoBg,UDim.new(0,8))
    mk("TextLabel",{
        Text="A",Font=Enum.Font.GothamBold,TextSize=16,
        TextColor3=Color3.new(1,1,1),BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1),ZIndex=23,
    },logoBg)

    -- Titre
    mk("TextLabel",{
        Text="Aurora",Font=Enum.Font.GothamBold,TextSize=17,
        TextColor3=Color3.new(1,1,1),BackgroundTransparency=1,
        Size=UDim2.fromOffset(80,46),Position=UDim2.fromOffset(48,0),
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=22,
    },header)

    -- Version
    mk("TextLabel",{
        Text="v3.1.5",Font=Enum.Font.Gotham,TextSize=11,
        TextColor3=P.ACCENT,BackgroundTransparency=1,
        Size=UDim2.fromOffset(50,46),Position=UDim2.fromOffset(130,0),
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=22,
    },header)

    -- Watermark
    local wm = mk("TextLabel",{
        Name="WM",Text="",Font=Enum.Font.Code,TextSize=12,
        TextColor3=P.TEXTMID,BackgroundTransparency=1,
        Size=UDim2.fromOffset(300,46),
        Position=UDim2.new(1,-370,0,0),
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=22,
    },header)

    -- Btn helper
    local function hBtn(txt,offX,hCol)
        local b=mk("TextButton",{
            Text=txt,Font=Enum.Font.GothamBold,TextSize=12,
            TextColor3=P.TEXTMID,BackgroundColor3=P.SURFACE2,
            BackgroundTransparency=0.3,BorderSizePixel=0,
            Size=UDim2.fromOffset(28,28),
            Position=UDim2.new(1,offX,0.5,-14),
            AutoButtonColor=false,ZIndex=22,
        },header)
        corner(b,UDim.new(0,6))
        b.MouseEnter:Connect(function()
            T(b,{BackgroundColor3=hCol or P.SURFACE2,TextColor3=Color3.new(1,1,1)},0.1)
        end)
        b.MouseLeave:Connect(function()
            T(b,{BackgroundColor3=P.SURFACE2,TextColor3=P.TEXTMID},0.12)
        end)
        return b
    end

    local closeB = hBtn("✕",-10,Color3.fromRGB(200,50,50))
    local minB   = hBtn("─",-44,P.SURFACE2)
    closeB.MouseButton1Click:Connect(function() Framework.Hide() end)
    minB.MouseButton1Click:Connect(function() Framework.Toggle() end)
    draggable(header,window)

    -- Watermark loop
    local fpsB = {}; local lt = os.clock()
    RunService.Heartbeat:Connect(function()
        local n=os.clock(); table.insert(fpsB,1/(n-lt)); lt=n
        if #fpsB>20 then table.remove(fpsB,1) end
        if #fpsB%8==0 then
            local s=0; for _,v in ipairs(fpsB) do s=s+v end
            local fps=math.floor(s/#fpsB)
            local ping=0; pcall(function() ping=math.floor(LP:GetNetworkPing()*1000) end)
            local name=""; pcall(function() name=LP.Name end)
            local pc = ping<=60 and "◆" or ping<=120 and "◇" or "✕"
            wm.Text = name.."  ·  "..fps.." fps  ·  "..pc.." "..ping.."ms"
            wm.TextColor3 = fps>45 and P.TEXTMID or P.WARNING
        end
    end)

    -- ── SIDEBAR ───────────────────────────────────────
    local sidebar = mk("Frame",{
        Name="Sidebar",
        BackgroundColor3=P.SURFACE,
        BorderSizePixel=0,
        Size=UDim2.new(0,175,1,-46),
        Position=UDim2.fromOffset(0,46),
        ClipsDescendants=true,
        ZIndex=10,
    },window)
    gradient(sidebar,Color3.fromRGB(11,9,22),Color3.fromRGB(11,11,19),0)

    -- Séparateur droite sidebar
    mk("Frame",{
        BackgroundColor3=P.ACCENT,BackgroundTransparency=0.78,
        BorderSizePixel=0,Size=UDim2.fromOffset(1,9999),
        Position=UDim2.new(1,-1,0,0),ZIndex=11,
    },sidebar)

    sideScroll = mk("ScrollingFrame",{
        BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.fromScale(1,1),
        ScrollBarThickness=0,
        CanvasSize=UDim2.fromOffset(0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ZIndex=12,
    },sidebar)
    listlayout(sideScroll,3)
    pad(sideScroll,8,10,10,8,8)

    -- ── CONTENT ───────────────────────────────────────
    contentArea = mk("Frame",{
        Name="Content",
        BackgroundColor3=P.BG,
        BackgroundTransparency=0,
        BorderSizePixel=0,
        Size=UDim2.new(1,-175,1,-46),
        Position=UDim2.fromOffset(175,46),
        ClipsDescendants=true,
        ZIndex=5,
    },window)

    Framework._gui     = gui
    Framework._window  = window
    Framework._sideScroll = sideScroll
    Framework._content = contentArea

    -- Keybind INSERT
    UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode==Enum.KeyCode.Insert then Framework.Toggle() end
    end)
end

-- ── AddTab ────────────────────────────────────────────
function Framework.AddTab(name, icon)
    if not sideScroll then return end
    local order = #tabs+1

    -- Bouton sidebar
    local btn = mk("TextButton",{
        Name="Btn_"..name,
        BackgroundColor3=P.ACCENT,
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Size=UDim2.new(1,0,0,40),
        Text="",
        AutoButtonColor=false,
        LayoutOrder=order,
        ZIndex=13,
    },sideScroll)
    corner(btn,UDim.new(0,8))

    -- Indicateur actif
    local ind = mk("Frame",{
        BackgroundColor3=P.ACCENT,
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Size=UDim2.fromOffset(3,20),
        Position=UDim2.new(0,0,0.5,-10),
        ZIndex=14,
    },btn)
    corner(ind,UDim.new(1,0))

    -- Badge icône
    local badge = mk("TextLabel",{
        Text=icon or "•",
        Font=Enum.Font.GothamBold,
        TextSize=10,
        TextColor3=P.TEXTMUTE,
        BackgroundColor3=P.SURFACE2,
        BackgroundTransparency=0.3,
        BorderSizePixel=0,
        Size=UDim2.fromOffset(28,22),
        Position=UDim2.new(0,10,0.5,-11),
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=14,
    },btn)
    corner(badge,UDim.new(0,5))

    -- Label nom
    local bTxt = mk("TextLabel",{
        Text=name,
        Font=Enum.Font.GothamMedium,
        TextSize=13,
        TextColor3=P.TEXTMUTE,
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Size=UDim2.new(1,-48,1,0),
        Position=UDim2.fromOffset(44,0),
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=14,
    },btn)

    -- Hover
    btn.MouseEnter:Connect(function()
        if not (tabs[name] and tabs[name].active) then
            T(btn,{BackgroundTransparency=0.92},0.12)
            T(bTxt,{TextColor3=P.TEXTMID},0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if not (tabs[name] and tabs[name].active) then
            T(btn,{BackgroundTransparency=1},0.15)
            T(bTxt,{TextColor3=P.TEXTMUTE},0.15)
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)

    -- Zone contenu
    local tabFrame = mk("Frame",{
        Name="Tab_"..name,
        BackgroundColor3=P.BG,
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Size=UDim2.fromScale(1,1),
        Visible=false,
        ZIndex=6,
    },contentArea)

    -- Header tab (titre + ligne)
    local tabHeader = mk("Frame",{
        BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,44),ZIndex=7,
    },tabFrame)
    mk("TextLabel",{
        Text=name,Font=Enum.Font.GothamBold,TextSize=15,
        TextColor3=Color3.new(1,1,1),BackgroundTransparency=1,
        Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(18,0),
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8,
    },tabHeader)
    mk("Frame",{
        BackgroundColor3=P.BORDER,BackgroundTransparency=0,
        BorderSizePixel=0,Size=UDim2.new(1,-18,0,1),
        Position=UDim2.new(0,9,1,-1),ZIndex=7,
    },tabHeader)

    -- Scroll du contenu
    local scroll = mk("ScrollingFrame",{
        Name="Scroll",BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,1,-44),Position=UDim2.fromOffset(0,44),
        ScrollBarThickness=3,ScrollBarImageColor3=P.ACCENT,
        CanvasSize=UDim2.fromOffset(0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ZIndex=7,
    },tabFrame)
    listlayout(scroll,10)
    pad(scroll,12,8,16,12,12)

    tabs[name] = {
        name=name, content=tabFrame, scroll=scroll,
        btn=btn, btnTxt=bTxt, indicator=ind,
        active=false,
    }

    if not activeTab then switchTab(name) end
    return tabs[name]
end

-- ── AddSection ────────────────────────────────────────
function Framework.AddSection(tabName, title)
    local t = tabs[tabName]
    if not t then return nil end

    local sec = mk("Frame",{
        BackgroundColor3=P.SURFACE,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        ZIndex=8,
    },t.scroll)
    corner(sec,UDim.new(0,10))
    stroke(sec,P.BORDER,1,0.1)

    -- Ligne accent + titre section
    local sh = mk("Frame",{
        BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,34),ZIndex=9,
    },sec)
    mk("Frame",{
        BackgroundColor3=P.ACCENT,BorderSizePixel=0,
        BackgroundTransparency=0.5,
        Size=UDim2.fromOffset(3,14),
        Position=UDim2.new(0,12,0.5,-7),ZIndex=10,
    },sh)
    local lf = Instance.new("UICorner",sh:FindFirstChild("Frame") or sh)
    lf.CornerRadius = UDim.new(1,0)

    mk("TextLabel",{
        Text=title,Font=Enum.Font.GothamBold,TextSize=11,
        TextColor3=P.ACCENT,BackgroundTransparency=1,
        Size=UDim2.new(1,-26,1,0),Position=UDim2.fromOffset(22,0),
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10,
    },sh)

    mk("Frame",{
        BackgroundColor3=P.BORDER,BorderSizePixel=0,
        Size=UDim2.new(1,-24,0,1),Position=UDim2.fromOffset(12,34),ZIndex=9,
    },sec)

    local items = mk("Frame",{
        Name="Items",BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        Position=UDim2.fromOffset(0,38),ZIndex=9,
    },sec)
    listlayout(items,0)
    pad(items,0,2,8,8,8)

    return {frame=sec,container=items,layout=items:FindFirstChildOfClass("UIListLayout")}
end

-- ── Init ──────────────────────────────────────────────
function Framework.Init(deps)
    Theme=deps.Theme or {}; Animation=deps.Animation or {}; Config=deps.Config
    Framework._buildGui()

    local tabDefs = {
        {"ESP","ESP"},{"Combat","CMB"},{"Movement","MOV"},
        {"World","WLD"},{"AI","AI"},{"Utility","UTL"},{"Config","CFG"},
    }
    for _,td in ipairs(tabDefs) do Framework.AddTab(td[1],td[2]) end

    -- Animation d'ouverture
    window.Size=UDim2.fromOffset(0,0)
    window.BackgroundTransparency=1
    T(window,{Size=UDim2.fromOffset(740,490),BackgroundTransparency=0},0.5,Enum.EasingStyle.Back)
end

-- ── Visibility ────────────────────────────────────────
function Framework.Show()
    if not window then return end
    visible=true; window.Visible=true
    T(window,{Size=UDim2.fromOffset(740,490),BackgroundTransparency=0},0.35,Enum.EasingStyle.Back)
end
function Framework.Hide()
    if not window then return end
    visible=false
    T(window,{Size=UDim2.fromOffset(720,470),BackgroundTransparency=1},0.22)
    task.delay(0.25,function() if window then window.Visible=false end end)
end
function Framework.Toggle()
    if visible then Framework.Hide() else Framework.Show() end
end
function Framework.IsVisible() return visible end
function Framework.GetGui()    return gui    end
function Framework.GetWindow() return window end

return Framework
