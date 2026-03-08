-- ══════════════════════════════════════════════════════
--   Aurora v3.1.3 — UI/LoadingScreen.lua
--   Rôle : Écran de chargement animé
-- ══════════════════════════════════════════════════════

local LoadingScreen = {}

local TweenS  = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local gui = nil
local T   = function(i,p,t) return TweenS:Create(i,TweenInfo.new(t or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),p) end
local C   = function(r,g,b) return Color3.fromRGB(r,g,b) end

function LoadingScreen.Show(version)
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name           = "Aurora_Loading"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder   = 99999
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Fond plein écran
    local bg = Instance.new("Frame", gui)
    bg.BackgroundColor3 = C(6,6,12)
    bg.BorderSizePixel  = 0
    bg.Size             = UDim2.fromScale(1,1)
    bg.BackgroundTransparency = 0

    -- Particules de fond (petits points)
    for i = 1, 30 do
        local dot = Instance.new("Frame", bg)
        dot.Size               = UDim2.fromOffset(2,2)
        dot.BackgroundColor3   = C(91,107,248)
        dot.BorderSizePixel    = 0
        dot.BackgroundTransparency = 0.6
        dot.Position = UDim2.fromScale(math.random()*0.9+0.05, math.random()*0.9+0.05)
        local corner = Instance.new("UICorner", dot)
        corner.CornerRadius = UDim.new(1,0)
        -- Animation flottante
        task.spawn(function()
            while dot and dot.Parent do
                local y = dot.Position.Y.Scale
                T(dot, {Position=UDim2.fromScale(dot.Position.X.Scale, y-0.02), BackgroundTransparency=0.9}, 1.5+math.random()*1):Play()
                task.wait(1.5+math.random()*1)
                T(dot, {Position=UDim2.fromScale(dot.Position.X.Scale, y), BackgroundTransparency=0.5}, 1.5+math.random()*1):Play()
                task.wait(1.5+math.random()*1)
            end
        end)
    end

    -- Container central
    local box = Instance.new("Frame", bg)
    box.BackgroundTransparency = 1
    box.Size        = UDim2.fromOffset(340, 200)
    box.Position    = UDim2.fromScale(0.5, 0.5)
    box.AnchorPoint = Vector2.new(0.5, 0.5)

    -- Logo "A"
    local logoFrame = Instance.new("Frame", box)
    logoFrame.BackgroundColor3 = C(91,107,248)
    logoFrame.BorderSizePixel  = 0
    logoFrame.Size             = UDim2.fromOffset(56,56)
    logoFrame.Position         = UDim2.new(0.5,0,0,-10)
    logoFrame.AnchorPoint      = Vector2.new(0.5,0)
    local lc = Instance.new("UICorner", logoFrame)
    lc.CornerRadius = UDim.new(0,14)

    local logoTxt = Instance.new("TextLabel", logoFrame)
    logoTxt.Text            = "A"
    logoTxt.Font            = Enum.Font.GothamBold
    logoTxt.TextSize        = 28
    logoTxt.TextColor3      = Color3.new(1,1,1)
    logoTxt.BackgroundTransparency = 1
    logoTxt.Size            = UDim2.fromScale(1,1)

    -- Titre
    local title = Instance.new("TextLabel", box)
    title.Text           = "Aurora"
    title.Font           = Enum.Font.GothamBold
    title.TextSize       = 32
    title.TextColor3     = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.Size           = UDim2.new(1,0,0,40)
    title.Position       = UDim2.fromOffset(0,62)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextTransparency = 1

    local ver = Instance.new("TextLabel", box)
    ver.Text           = version or "v3.1.3"
    ver.Font           = Enum.Font.Gotham
    ver.TextSize       = 13
    ver.TextColor3     = C(91,107,248)
    ver.BackgroundTransparency = 1
    ver.Size           = UDim2.new(1,0,0,20)
    ver.Position       = UDim2.fromOffset(0,102)
    ver.TextXAlignment = Enum.TextXAlignment.Center
    ver.TextTransparency = 1

    -- Barre de chargement (container)
    local barBg = Instance.new("Frame", box)
    barBg.BackgroundColor3 = C(20,20,35)
    barBg.BorderSizePixel  = 0
    barBg.Size             = UDim2.fromOffset(240, 4)
    barBg.Position         = UDim2.new(0.5,0,0,140)
    barBg.AnchorPoint      = Vector2.new(0.5,0)
    local bc = Instance.new("UICorner", barBg)
    bc.CornerRadius = UDim.new(1,0)

    local bar = Instance.new("Frame", barBg)
    bar.BackgroundColor3 = C(91,107,248)
    bar.BorderSizePixel  = 0
    bar.Size             = UDim2.fromOffset(0,4)
    local barc = Instance.new("UICorner", bar)
    barc.CornerRadius = UDim.new(1,0)

    -- Gradient sur la barre
    local barGrad = Instance.new("UIGradient", bar)
    barGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C(91,107,248)),
        ColorSequenceKeypoint.new(1, C(140,160,255)),
    })

    -- Status text
    local status = Instance.new("TextLabel", box)
    status.Text           = "Initialisation..."
    status.Font           = Enum.Font.Gotham
    status.TextSize       = 11
    status.TextColor3     = C(100,100,150)
    status.BackgroundTransparency = 1
    status.Size           = UDim2.new(1,0,0,16)
    status.Position       = UDim2.fromOffset(0,154)
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.TextTransparency = 1

    LoadingScreen._bar    = bar
    LoadingScreen._status = status
    LoadingScreen._bg     = bg
    LoadingScreen._gui    = gui

    -- Animation d'entrée
    task.spawn(function()
        task.wait(0.1)
        T(logoFrame, {BackgroundTransparency=0}, 0.4):Play()
        task.wait(0.15)
        T(title, {TextTransparency=0}, 0.4):Play()
        T(ver,   {TextTransparency=0}, 0.4):Play()
        task.wait(0.2)
        T(status, {TextTransparency=0}, 0.3):Play()
    end)

    return LoadingScreen
end

function LoadingScreen.SetProgress(pct, text)
    if not LoadingScreen._bar then return end
    local width = math.floor(240 * math.clamp(pct, 0, 1))
    T(LoadingScreen._bar, {Size=UDim2.fromOffset(width, 4)}, 0.25):Play()
    if text and LoadingScreen._status then
        LoadingScreen._status.Text = text
    end
end

function LoadingScreen.Hide(onDone)
    if not LoadingScreen._bg then return end
    T(LoadingScreen._bg, {BackgroundTransparency=1}, 0.5):Play()
    task.delay(0.6, function()
        if gui then gui:Destroy(); gui = nil end
        if onDone then pcall(onDone) end
    end)
end

return LoadingScreen
