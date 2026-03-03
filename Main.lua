--========================================================--
--  NEXUS BY RIZZY — MAIN FILE (MODULAR)
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--========================================================--
--  LINORIA
--========================================================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy",
    Center = true,
    AutoShow = true
})

local VisualTab = Window:AddTab("Visual")
local ESPGroup = VisualTab:AddLeftGroupbox("ESP")

--========================================================--
--  MODULE LOADER
--========================================================--

local function include(path)
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/main/" .. path))()
end

local ESP = include("Modules/ESP.lua")
local Box = include("Modules/Box.lua")
local Health = include("Modules/Health.lua")

--========================================================--
--  UI
--========================================================--

local BoxToggle = ESPGroup:AddToggle("Box", {
    Text = "Box",
    Default = false,
    Callback = function(v)
        ESP.Enabled = v
    end
})

BoxToggle:AddColorPicker("BoxColor", {
    Title = "Box Color",
    Default = ESP.Color,
    Callback = function(c)
        ESP.Color = c
    end
})

local HealthToggle = ESPGroup:AddToggle("Health", {
    Text = "Health Bar",
    Default = false,
    Callback = function(v)
        ESP.HealthBar = v
    end
})

HealthToggle:AddColorPicker("HPColor", {
    Title = "Health Color",
    Default = ESP.HealthColor,
    Callback = function(c)
        ESP.HealthColor = c
    end
})

ESPGroup:AddDropdown("HPPos", {
    Text = "Health Position",
    Default = "Left",
    Values = {"Left", "Right"},
    Callback = function(v)
        ESP.HealthPosition = v
    end
})

--========================================================--
--  UPDATE LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    ESP:UpdateAll()
end)

Library:Notify("Nexus by Rizzy chargé !", 3)
