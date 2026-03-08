local Toggle = {}
Toggle.__index = Toggle

local TweenS = game:GetService("TweenService")
local function T(i,p,t,s)
    if not i or not i.Parent then return end
    local ok,tw=pcall(function()
        return TweenS:Create(i,TweenInfo.new(t or 0.18,s or Enum.EasingStyle.Quart,Enum.EasingDirection.Out),p)
    end)
    if ok and tw then tw:Play() return tw end
end
local C=Color3.fromRGB

-- Couleurs autonomes
local ON   = C(91,107,248)
local OFF  = C(35,35,55)
local TXT  = C(220,220,235)
local TXTS = C(100,100,130)
local HOV  = C(20,20,32)

function Toggle.Init() end

function Toggle.new(parent, opts)
    opts = opts or {}
    local self = setmetatable({}, Toggle)
    self.value    = opts.default ~= nil and opts.default or false
    self.callback = opts.onChange or opts.callback or function() end
    self.label    = opts.label or "Toggle"
    self.disabled = opts.disabled or false

    -- Row conteneur
    local row = Instance.new("TextButton")
    row.Name                   = "Toggle_"..self.label
    row.BackgroundColor3       = HOV
    row.BackgroundTransparency = 0.94
    row.BorderSizePixel        = 0
    row.Size                   = UDim2.new(1,0,0,36)
    row.Text                   = ""
    row.AutoButtonColor        = false
    row.ClipsDescendants       = false
    row.Parent                 = parent

    local rc = Instance.new("UICorner",row)
    rc.CornerRadius = UDim.new(0,6)

    -- Label
    local lbl = Instance.new("TextLabel",row)
    lbl.Text                = self.label
    lbl.Font                = Enum.Font.GothamMedium
    lbl.TextSize            = 13
    lbl.TextColor3          = self.disabled and TXTS or TXT
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel     = 0
    lbl.Size                = UDim2.new(1,-56,1,0)
    lbl.Position            = UDim2.fromOffset(12,0)
    lbl.TextXAlignment      = Enum.TextXAlignment.Left

    -- Toggle pill (fond)
    local pill = Instance.new("Frame",row)
    pill.BackgroundColor3 = self.value and ON or OFF
    pill.BorderSizePixel  = 0
    pill.Size             = UDim2.fromOffset(40,22)
    pill.Position         = UDim2.new(1,-48,0.5,-11)
    local pc = Instance.new("UICorner",pill)
    pc.CornerRadius = UDim.new(1,0)

    -- Knob
    local knob = Instance.new("Frame",pill)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel  = 0
    knob.Size             = UDim2.fromOffset(18,18)
    knob.Position         = self.value
        and UDim2.new(1,-20,0.5,-9)
        or  UDim2.new(0,2,0.5,-9)
    local kc = Instance.new("UICorner",knob)
    kc.CornerRadius = UDim.new(1,0)

    -- Ombre knob
    local ks = Instance.new("UIStroke",knob)
    ks.Color = Color3.new(0,0,0)
    ks.Thickness = 1.5
    ks.Transparency = 0.75

    self._row  = row
    self._pill = pill
    self._knob = knob
    self._lbl  = lbl

    -- Hover
    row.MouseEnter:Connect(function()
        if self.disabled then return end
        T(row,{BackgroundTransparency=0.88},0.1)
    end)
    row.MouseLeave:Connect(function()
        T(row,{BackgroundTransparency=0.94},0.12)
    end)

    -- Click
    row.MouseButton1Click:Connect(function()
        if self.disabled then return end
        self:Set(not self.value)
    end)

    return self
end

function Toggle:Set(val)
    self.value = val
    T(self._pill, {BackgroundColor3 = val and ON or OFF}, 0.15)
    T(self._knob, {
        Position = val
            and UDim2.new(1,-20,0.5,-9)
            or  UDim2.new(0,2,0.5,-9)
    }, 0.2, Enum.EasingStyle.Back)
    local ok,err = pcall(self.callback, val)
    if not ok then warn("[Toggle/"..self.label.."] "..tostring(err)) end
end

function Toggle:Get()    return self.value end
function Toggle:SetDisabled(v)
    self.disabled = v
    self._lbl.TextColor3 = v and TXTS or TXT
end
function Toggle:Destroy()
    if self._row then self._row:Destroy() end
end

return Toggle
