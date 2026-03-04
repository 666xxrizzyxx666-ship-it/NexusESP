local FOV = {}
local Utils, Config
local RunService = game:GetService("RunService")
local conn, circle

function FOV.SetDependencies(u,c) Utils=u; Config=c end

function FOV.Show(cfg)
    FOV.Hide()
    cfg = cfg or {}
    circle = Drawing.new("Circle")
    circle.Radius   = cfg.Radius or 100
    circle.Color    = Utils.C3(cfg.Color)
    circle.Thickness = 1
    circle.NumSides  = 256   -- very smooth
    circle.Filled    = false
    circle.Visible   = true

    conn = RunService.RenderStepped:Connect(function()
        if not circle then return end
        local cur = Config and Config.Current and Config.Current.FOV
        local r   = cur and cur.Radius or cfg.Radius or 100
        local en  = cur == nil or cur.Enabled ~= false
        circle.Position = Utils.ScreenCenter()
        circle.Radius   = r
        circle.Visible  = en
        if cur and cur.Color then
            circle.Color = Utils.C3(cur.Color)
        end
    end)
end

function FOV.Hide()
    if conn   then conn:Disconnect(); conn=nil end
    if circle then pcall(function() circle:Remove() end); circle=nil end
end

function FOV.UpdateRadius(r)
    if circle then circle.Radius=r end
end

return FOV
