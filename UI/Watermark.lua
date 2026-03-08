-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Watermark.lua
--   📁 Dossier : UI/
--   Rôle : Watermark HUD — FPS / Ping / Jeu / User
-- ══════════════════════════════════════════════════════

local Watermark = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats      = game:GetService("Stats")
local LP         = Players.LocalPlayer

local Theme, Animation
local gui, frame, label
local conn    = nil
local enabled = true
local frame_t = 0
local fps     = 60

function Watermark.Init(theme, anim)
    Theme     = theme
    Animation = anim

    gui = Instance.new("ScreenGui")
    gui.Name              = "NexusESP_Watermark"
    gui.ResetOnSpawn      = false
    gui.IgnoreGuiInset    = true
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Global
    gui.DisplayOrder      = 999

    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Container
    frame = Instance.new("Frame", gui)
    frame.Name               = "Watermark"
    frame.BackgroundColor3   = Theme.Colors.Surface
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel    = 0
    frame.Size               = UDim2.fromOffset(320, 28)
    frame.Position           = UDim2.fromOffset(10, 8)
    frame.AnchorPoint        = Vector2.new(0, 0)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color     = Theme.Colors.Border
    stroke.Thickness = 1

    -- Accent bar gauche
    local accent = Instance.new("Frame", frame)
    accent.BackgroundColor3 = Theme.Colors.Accent
    accent.BorderSizePixel  = 0
    accent.Size             = UDim2.fromOffset(3, 28)
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0,2)

    -- Label
    label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.BorderSizePixel        = 0
    label.Size                   = UDim2.new(1,-10,1,0)
    label.Position               = UDim2.fromOffset(10, 0)
    label.Font                   = Theme.Fonts.Bold
    label.TextSize               = Theme.TextSize.Small
    label.TextColor3             = Theme.Colors.Text
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.RichText               = true

    -- Update loop
    local frameCount = 0
    local lastTime   = os.clock()

    conn = RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now  = os.clock()
        if now - lastTime >= 0.5 then
            fps       = math.floor(frameCount / (now - lastTime))
            frameCount = 0
            lastTime   = now
            Watermark._update()
        end
    end)

    print("[Watermark] Initialisé ✓")
end

function Watermark._update()
    if not label then return end

    local ping = math.floor(LP:GetNetworkPing() * 1000)
    local game_name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    local user  = LP.Name

    -- Couleur FPS
    local fpsColor = fps >= 55 and "#4ADE80" or fps >= 30 and "#FBBF24" or "#F87171"
    -- Couleur Ping
    local pingColor = ping <= 80 and "#4ADE80" or ping <= 150 and "#FBBF24" or "#F87171"

    label.Text = string.format(
        '<font color="#%s">N</font><font color="#FFFFFF">exus</font>'
        ..' <font color="#888888">|</font>'
        ..' <font color="#5B6BF8">%s</font>'
        ..' <font color="#888888">|</font>'
        ..' <font color="%s">%d fps</font>'
        ..' <font color="#888888">|</font>'
        ..' <font color="%s">%dms</font>',
        "5B6BF8",
        user,
        fpsColor,  fps,
        pingColor, ping
    )
end

function Watermark.Show()
    enabled = true
    if frame then frame.Visible = true end
end

function Watermark.Hide()
    enabled = false
    if frame then frame.Visible = false end
end

function Watermark.Toggle()
    if enabled then Watermark.Hide() else Watermark.Show() end
end

function Watermark.SetPosition(x, y)
    if frame then frame.Position = UDim2.fromOffset(x, y) end
end

function Watermark.Destroy()
    if conn then conn:Disconnect() end
    if gui  then gui:Destroy() end
end

return Watermark
