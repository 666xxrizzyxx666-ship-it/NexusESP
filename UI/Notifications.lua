-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Notifications.lua
--   📁 Dossier : UI/
--   Rôle : Toast notifications animées
-- ══════════════════════════════════════════════════════

local Notifications = {}

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local LP           = Players.LocalPlayer

local Theme, Animation
local gui           = nil
local container     = nil
local queue         = {}
local MAX_VISIBLE   = 4

local ICONS = {
    success = "✓",
    error   = "✕",
    warning = "⚠",
    info    = "ℹ",
}

local COLORS = {
    success = nil,   -- sera Theme.Colors.Success
    error   = nil,
    warning = nil,
    info    = nil,
}

function Notifications.Init(theme, anim)
    Theme     = theme
    Animation = anim

    COLORS.success = theme.Colors.Success
    COLORS.error   = theme.Colors.Danger
    COLORS.warning = theme.Colors.Warning
    COLORS.info    = theme.Colors.Info

    -- Crée le container
    gui = Instance.new("ScreenGui")
    gui.Name              = "NexusESP_Notifs"
    gui.ResetOnSpawn      = false
    gui.IgnoreGuiInset    = true
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Global
    gui.DisplayOrder      = 1000

    local n = getgenv().NexusESP
    if n and n.ProtectGui then n.ProtectGui(gui) end
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    container = Instance.new("Frame", gui)
    container.Name               = "NotifContainer"
    container.BackgroundTransparency = 1
    container.BorderSizePixel    = 0
    container.Size               = UDim2.fromOffset(280, 500)
    container.Position           = UDim2.new(1, -290, 1, -20)
    container.AnchorPoint        = Vector2.new(0, 1)

    local layout = Instance.new("UIListLayout", container)
    layout.SortOrder             = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment     = Enum.VerticalAlignment.Bottom
    layout.Padding               = UDim.new(0, 6)
end

function Notifications.Send(opts)
    opts = opts or {}
    local notifType = opts.type    or "info"
    local title     = opts.title   or "NexusESP"
    local message   = opts.message or ""
    local duration  = opts.duration or 3

    if not container then return end

    local accentColor = COLORS[notifType] or COLORS.info
    local icon        = ICONS[notifType]  or ICONS.info

    -- Frame principale
    local notif = Instance.new("Frame", container)
    notif.BackgroundColor3       = Theme.Colors.Surface
    notif.BorderSizePixel        = 0
    notif.Size                   = UDim2.fromOffset(275, 64)
    notif.BackgroundTransparency = 1
    notif.ClipsDescendants       = true

    local corner = Instance.new("UICorner", notif)
    corner.CornerRadius = UDim.new(0,10)

    local stroke = Instance.new("UIStroke", notif)
    stroke.Color     = Theme.Colors.Border
    stroke.Thickness = 1

    -- Barre accent gauche
    local bar = Instance.new("Frame", notif)
    bar.BackgroundColor3 = accentColor
    bar.BorderSizePixel  = 0
    bar.Size             = UDim2.fromOffset(3, 64)
    local barCorner = Instance.new("UICorner", bar)
    barCorner.CornerRadius = UDim.new(0,2)

    -- Icône
    local ico = Instance.new("TextLabel", notif)
    ico.Text               = icon
    ico.Font               = Theme.Fonts.Bold
    ico.TextSize           = 18
    ico.TextColor3         = accentColor
    ico.BackgroundTransparency = 1
    ico.BorderSizePixel    = 0
    ico.Size               = UDim2.fromOffset(30, 64)
    ico.Position           = UDim2.fromOffset(12, 0)

    -- Titre
    local titleLbl = Instance.new("TextLabel", notif)
    titleLbl.Text          = title
    titleLbl.Font          = Theme.Fonts.Bold
    titleLbl.TextSize      = Theme.TextSize.Body
    titleLbl.TextColor3    = Theme.Colors.Text
    titleLbl.BackgroundTransparency = 1
    titleLbl.BorderSizePixel = 0
    titleLbl.Size          = UDim2.fromOffset(220, 20)
    titleLbl.Position      = UDim2.fromOffset(46, 10)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Message
    local msgLbl = Instance.new("TextLabel", notif)
    msgLbl.Text            = message
    msgLbl.Font            = Theme.Fonts.Regular
    msgLbl.TextSize        = Theme.TextSize.Small
    msgLbl.TextColor3      = Theme.Colors.TextSub
    msgLbl.BackgroundTransparency = 1
    msgLbl.BorderSizePixel = 0
    msgLbl.Size            = UDim2.fromOffset(220, 18)
    msgLbl.Position        = UDim2.fromOffset(46, 32)
    msgLbl.TextXAlignment  = Enum.TextXAlignment.Left
    msgLbl.TextTruncate    = Enum.TextTruncate.AtEnd

    -- Progress bar
    local progress = Instance.new("Frame", notif)
    progress.BackgroundColor3 = accentColor
    progress.BorderSizePixel  = 0
    progress.Size             = UDim2.new(1,0,0,2)
    progress.Position         = UDim2.new(0,0,1,-2)
    progress.BackgroundTransparency = 0.5

    -- Animation entrée
    notif.Position = UDim2.fromOffset(300, 0)
    notif.BackgroundTransparency = 0

    TweenService:Create(notif,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.fromOffset(0,0)}
    ):Play()

    -- Progress bar animation
    TweenService:Create(progress,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0,0,0,2)}
    ):Play()

    -- Auto-dismiss
    task.delay(duration, function()
        if not notif or not notif.Parent then return end
        TweenService:Create(notif,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            {Position = UDim2.fromOffset(300,0), BackgroundTransparency = 1}
        ):Play()
        task.delay(0.25, function()
            if notif and notif.Parent then notif:Destroy() end
        end)
    end)

    -- Click pour dismiss
    local clickBtn = Instance.new("TextButton", notif)
    clickBtn.BackgroundTransparency = 1
    clickBtn.BorderSizePixel        = 0
    clickBtn.Size                   = UDim2.fromScale(1,1)
    clickBtn.Text                   = ""
    clickBtn.ZIndex                 = 5
    clickBtn.MouseButton1Click:Connect(function()
        TweenService:Create(notif,
            TweenInfo.new(0.2),
            {Position = UDim2.fromOffset(300,0), BackgroundTransparency=1}
        ):Play()
        task.delay(0.2, function()
            if notif and notif.Parent then notif:Destroy() end
        end)
    end)
end

-- Raccourcis
function Notifications.Success(title, msg, dur)
    Notifications.Send({type="success", title=title, message=msg, duration=dur})
end
function Notifications.Error(title, msg, dur)
    Notifications.Send({type="error",   title=title, message=msg, duration=dur})
end
function Notifications.Warning(title, msg, dur)
    Notifications.Send({type="warning", title=title, message=msg, duration=dur})
end
function Notifications.Info(title, msg, dur)
    Notifications.Send({type="info",    title=title, message=msg, duration=dur})
end

return Notifications
