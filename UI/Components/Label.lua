-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Components/Label.lua
--   📁 Dossier : UI/Components/
--   Rôle : Label simple + Divider
-- ══════════════════════════════════════════════════════

local Label = {}
Label.__index = Label

local Theme, Animation

function Label.Init(theme, anim)
    Theme     = theme
    Animation = anim
end

-- Label simple
function Label.new(parent, opts)
    opts = opts or {}
    local self = setmetatable({}, Label)

    local lbl = Instance.new("TextLabel", parent)
    lbl.Name               = "Label_"..(opts.text or "")
    lbl.Text               = opts.text or ""
    lbl.Font               = opts.bold and Theme.Fonts.Bold or Theme.Fonts.Regular
    lbl.TextSize           = opts.size or Theme.TextSize.Body
    lbl.TextColor3         = opts.color or Theme.Colors.TextSub
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel    = 0
    lbl.Size               = UDim2.new(1,0,0,opts.height or 20)
    lbl.TextXAlignment     = opts.align or Enum.TextXAlignment.Left
    lbl.LayoutOrder        = opts.order or 0
    lbl.TextWrapped        = opts.wrap  or false

    local pad = Instance.new("UIPadding", lbl)
    pad.PaddingLeft  = UDim.new(0,10)
    pad.PaddingRight = UDim.new(0,10)

    self._lbl = lbl
    return self
end

function Label:SetText(text)
    self._lbl.Text = text
end

function Label:SetColor(color)
    self._lbl.TextColor3 = color
end

function Label:Destroy()
    if self._lbl then self._lbl:Destroy() end
end

-- Divider
function Label.Divider(parent, opts)
    opts = opts or {}
    local frame = Instance.new("Frame", parent)
    frame.Name             = "Divider"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel  = 0
    frame.Size             = UDim2.new(1,0,0,opts.height or 16)
    frame.LayoutOrder      = opts.order or 0

    local line = Instance.new("Frame", frame)
    line.BackgroundColor3  = opts.color or Theme.Colors.Border
    line.BorderSizePixel   = 0
    line.AnchorPoint       = Vector2.new(0,0.5)
    line.Size              = UDim2.new(1,-20,0,1)
    line.Position          = UDim2.new(0,10,0.5,0)

    if opts.text then
        line.Size = UDim2.new(0.35,-10,0,1)

        local txt = Instance.new("TextLabel", frame)
        txt.Text           = opts.text
        txt.Font           = Theme.Fonts.Regular
        txt.TextSize       = Theme.TextSize.Tiny
        txt.TextColor3     = Theme.Colors.TextMuted
        txt.BackgroundTransparency = 1
        txt.AnchorPoint    = Vector2.new(0.5,0.5)
        txt.Size           = UDim2.new(0,80,1,0)
        txt.Position       = UDim2.new(0.5,0,0.5,0)
        txt.TextXAlignment = Enum.TextXAlignment.Center

        local line2 = Instance.new("Frame", frame)
        line2.BackgroundColor3 = opts.color or Theme.Colors.Border
        line2.BorderSizePixel  = 0
        line2.AnchorPoint      = Vector2.new(1,0.5)
        line2.Size             = UDim2.new(0.35,-10,0,1)
        line2.Position         = UDim2.new(1,-10,0.5,0)
    end

    return frame
end

return Label
