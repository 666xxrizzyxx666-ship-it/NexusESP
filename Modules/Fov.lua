-- ============================================================
--  FOV.lua — Cercle de champ de vision autour du viseur
-- ============================================================
local FOV = {}

local Utils, Config
local RunService = game:GetService("RunService")

function FOV.SetDependencies(u, c) Utils = u; Config = c end

local circle     = nil
local circleOut  = nil
local conn       = nil

function FOV.Show(cfg)
    FOV.Hide()
    cfg = cfg or {}

    -- outline noir
    circleOut = Utils.NewDrawing("Circle", {
        Radius      = cfg.Radius or 100,
        Color       = Color3.new(0,0,0),
        Thickness   = 3,
        NumSides    = 64,
        Filled      = false,
        Visible     = true,
    })

    -- cercle coloré
    circle = Utils.NewDrawing("Circle", {
        Radius      = cfg.Radius or 100,
        Color       = Color3.fromRGB(cfg.Color and cfg.Color.R or 255,
                                      cfg.Color and cfg.Color.G or 255,
                                      cfg.Color and cfg.Color.B or 255),
        Thickness   = 1,
        NumSides    = 64,
        Filled      = false,
        Visible     = true,
    })

    conn = RunService.RenderStepped:Connect(function()
        if not circle then return end
        local vp = Utils.GetViewport()
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        local r = (Config and Config.Current.FOV and Config.Current.FOV.Radius) or cfg.Radius or 100
        local col = Config and Config.Current.FOV and Config.Current.FOV.Color
        circle.Position    = center
        circle.Radius      = r
        if col then
            circle.Color = Color3.fromRGB(col.R or 255, col.G or 255, col.B or 255)
        end
        circleOut.Position = center
        circleOut.Radius   = r
        circle.Visible    = (Config and Config.Current.FOV and Config.Current.FOV.Enabled) or true
        circleOut.Visible  = circle.Visible
    end)
end

function FOV.Hide()
    if conn then conn:Disconnect(); conn = nil end
    Utils.RemoveDrawing(circle)
    Utils.RemoveDrawing(circleOut)
    circle    = nil
    circleOut = nil
end

function FOV.UpdateRadius(r)
    if circle    then circle.Radius    = r end
    if circleOut then circleOut.Radius = r end
end

return FOV
