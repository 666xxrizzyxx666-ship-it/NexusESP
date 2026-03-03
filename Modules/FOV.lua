local FOV = {}
local Utils, Config
local RunService = game:GetService("RunService")
local conn, circle, outline

function FOV.SetDependencies(u,c) Utils=u; Config=c end

function FOV.Show(cfg)
    FOV.Hide()
    cfg = cfg or {}
    local r = cfg.Radius or 100
    local c = cfg.Color
    local col = Color3.fromRGB(c and c.R or 255, c and c.G or 255, c and c.B or 255)

    outline = Drawing.new("Circle")
    outline.Radius    = r
    outline.Color     = Color3.new(0,0,0)
    outline.Thickness = 3
    outline.NumSides  = 60
    outline.Filled    = false
    outline.Visible   = true

    circle = Drawing.new("Circle")
    circle.Radius    = r
    circle.Color     = col
    circle.Thickness = 1
    circle.NumSides  = 60
    circle.Filled    = false
    circle.Visible   = true

    conn = RunService.RenderStepped:Connect(function()
        local vp = Utils.GetViewport()
        local pos = Vector2.new(vp.X/2, vp.Y/2)
        local cur = Config and Config.Current and Config.Current.FOV
        local radius = cur and cur.Radius or r
        local cc = cur and cur.Color
        circle.Position  = pos
        circle.Radius    = radius
        if cc then circle.Color = Color3.fromRGB(cc.R or 255, cc.G or 255, cc.B or 255) end
        outline.Position = pos
        outline.Radius   = radius
        local en = cur and cur.Enabled
        circle.Visible  = (en ~= false)
        outline.Visible = circle.Visible
    end)
end

function FOV.Hide()
    if conn then conn:Disconnect(); conn=nil end
    if circle  then pcall(function() circle:Remove()  end); circle=nil  end
    if outline then pcall(function() outline:Remove() end); outline=nil end
end

function FOV.UpdateRadius(r)
    if circle  then circle.Radius  = r end
    if outline then outline.Radius = r end
end

return FOV
