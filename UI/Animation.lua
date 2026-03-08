-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Animation.lua
--   📁 Dossier : UI/
--   Rôle : Animations fluides pour tous les composants
-- ══════════════════════════════════════════════════════

local Animation = {}

local TweenService = game:GetService("TweenService")
local Theme        = nil

local activeTweens = {}

function Animation.Init(theme)
    Theme = theme
end

-- ── Tween propre ──────────────────────────────────────
function Animation.Tween(instance, props, tweenInfo)
    if not instance or not props then return end
    local key = tostring(instance)
    if activeTweens[key] then
        pcall(function() activeTweens[key]:Cancel() end)
    end
    local info = tweenInfo or TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local ok, t = pcall(function()
        return TweenService:Create(instance, info, props)
    end)
    if ok and t then
        activeTweens[key] = t
        t:Play()
        return t
    end
end

-- ── Raccourcis ────────────────────────────────────────
function Animation.FadeIn(frame, duration)
    frame.BackgroundTransparency = 1
    Animation.Tween(frame,
        {BackgroundTransparency = 0},
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    )
end

function Animation.FadeOut(frame, duration, callback)
    Animation.Tween(frame,
        {BackgroundTransparency = 1},
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    )
    if callback then
        task.delay(duration or 0.2, callback)
    end
end

function Animation.SlideIn(frame, fromDir, duration)
    fromDir = fromDir or "Right"
    local target = frame.Position
    local start
    if fromDir == "Right" then
        start = UDim2.new(target.X.Scale + 0.05, target.X.Offset + 20, target.Y.Scale, target.Y.Offset)
    elseif fromDir == "Left" then
        start = UDim2.new(target.X.Scale - 0.05, target.X.Offset - 20, target.Y.Scale, target.Y.Offset)
    elseif fromDir == "Bottom" then
        start = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale + 0.05, target.Y.Offset + 20)
    else
        start = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale - 0.05, target.Y.Offset - 20)
    end
    frame.Position = start
    Animation.Tween(frame,
        {Position = target},
        TweenInfo.new(duration or 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    )
end

function Animation.Scale(frame, from, to, duration)
    frame.Size = from
    Animation.Tween(frame,
        {Size = to},
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    )
end

function Animation.Color(instance, prop, toColor, duration)
    Animation.Tween(instance,
        {[prop] = toColor},
        TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    )
end

-- ── Toggle animé ──────────────────────────────────────
function Animation.Toggle(bg, knob, enabled, accentColor, offColor)
    local targetBg   = enabled and accentColor or offColor
    local targetKnob = enabled
        and UDim2.new(1, -18, 0.5, 0)
        or  UDim2.new(0,  2,  0.5, 0)

    Animation.Tween(bg,   {BackgroundColor3 = targetBg},   TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
    Animation.Tween(knob, {Position = targetKnob},          TweenInfo.new(0.18, Enum.EasingStyle.Back,  Enum.EasingDirection.Out))
end

-- ── Hover effect ──────────────────────────────────────
function Animation.HoverIn(frame, hoverColor)
    Animation.Tween(frame, {BackgroundColor3 = hoverColor},
        TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
end

function Animation.HoverOut(frame, normalColor)
    Animation.Tween(frame, {BackgroundColor3 = normalColor},
        TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
end

-- ── Pulse (glow effect) ───────────────────────────────
function Animation.Pulse(frame, color, times)
    times = times or 2
    local original = frame.BackgroundColor3
    local function pulse(n)
        if n <= 0 then
            Animation.Tween(frame, {BackgroundColor3 = original},
                TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            return
        end
        Animation.Tween(frame, {BackgroundColor3 = color},
            TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
        task.delay(0.15, function()
            Animation.Tween(frame, {BackgroundColor3 = original},
                TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            task.delay(0.15, function() pulse(n-1) end)
        end)
    end
    pulse(times)
end

-- ── Notification slide ────────────────────────────────
function Animation.NotifSlideIn(frame)
    local target = frame.Position
    frame.Position = UDim2.new(target.X.Scale, target.X.Offset + 300, target.Y.Scale, target.Y.Offset)
    frame.BackgroundTransparency = 1
    Animation.Tween(frame,
        {Position = target, BackgroundTransparency = 0},
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    )
end

function Animation.NotifSlideOut(frame, callback)
    local target = UDim2.new(
        frame.Position.X.Scale,
        frame.Position.X.Offset + 300,
        frame.Position.Y.Scale,
        frame.Position.Y.Offset
    )
    Animation.Tween(frame,
        {Position = target, BackgroundTransparency = 1},
        TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    )
    if callback then
        task.delay(0.25, callback)
    end
end

return Animation
