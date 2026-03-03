--========================================================--
--  AUTO-KILL ANCIEN SCRIPT
--========================================================--

if getgenv().NEXUS_RUNNING then
    if getgenv().NEXUS_SHUTDOWN then
        getgenv().NEXUS_SHUTDOWN()
    end
end

getgenv().NEXUS_RUNNING = true

--========================================================--
--  SERVICES
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--========================================================--
--  SHUTDOWN GLOBAL
--========================================================--

getgenv().NEXUS_SHUTDOWN = function()
    -- Supprimer toutes les box
    if getgenv().ESP and getgenv().ESP.Boxes then
        for _, box in pairs(getgenv().ESP.Boxes) do
            pcall(function() box:Remove() end)
        end
    end

    -- Supprimer toutes les healthbars
    if getgenv().ESP and getgenv().ESP.HealthBars then
        for _, hb in pairs(getgenv().ESP.HealthBars) do
            pcall(function()
                hb.bg:Remove()
                hb.bar:Remove()
            end)
        end
    end

    -- Détruire l’UI Linoria
    if getgenv().NEXUS_UI then
        pcall(function() getgenv().NEXUS_UI:Destroy() end)
    end

    getgenv().NEXUS_RUNNING = false
end

--========================================================--
--  LINORIA
--========================================================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy",
    Center = true,
    AutoShow = true
})

getgenv().NEXUS_UI = Window

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

local VisualTab = Window:AddTab("Visual")
local ESPGroup = VisualTab:AddLeftGroupbox("ESP")

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
--  SETTINGS TAB (SHUTDOWN)
--========================================================--

local SettingsTab = Window:AddTab("Settings")
local SettingsGroup = SettingsTab:AddLeftGroupbox("System")

SettingsGroup:AddButton("Shutdown Nexus", function()
    getgenv().NEXUS_SHUTDOWN()
end)

--========================================================--
--  BOUTON X (FERMETURE)
--========================================================--

local CloseButton = Library:Create('TextButton', {
    Text = "X",
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(1, -26, 0, 4),
    BackgroundColor3 = Color3.fromRGB(180, 50, 50),
    TextColor3 = Color3.new(1,1,1),
    Parent = Window.Container
})

CloseButton.MouseButton1Click:Connect(function()
    getgenv().NEXUS_SHUTDOWN()
end)

--========================================================--
--  UPDATE LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    if not getgenv().NEXUS_RUNNING then return end
    ESP:UpdateAll()
end)

Library:Notify("Nexus by Rizzy chargé !", 3)
