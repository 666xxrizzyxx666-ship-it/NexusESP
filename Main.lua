--========================================================--
--  NEXUS ESP — MAIN FILE (LINORIA + MODULES)
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Camera globale pour les modules
Camera = workspace.CurrentCamera

--========================================================--
--  ESP MASTER TABLE
--========================================================--

ESP = {
    Box = true,
    BoxColor = Color3.fromRGB(255, 0, 0),

    Boxes = {}
}

--========================================================--
--  LINORIA LIBRARY
--========================================================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus ESP by Rizzy",
    Center = true,
    AutoShow = true
})

-- Onglet VISUALS
local Tabs = {
    Visuals = Window:AddTab("Visuals")
}

-- Sous-catégorie ESP
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

--========================================================--
--  MODULE LOADER
--========================================================--

local function include(url)
    local src = game:HttpGet(url)
    local fn = loadstring(src)
    return fn()
end

local base = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/main/Modules/"

include(base .. "Box.lua")

--========================================================--
--  UI (LINORIA)
--========================================================--

ESPGroup:AddToggle("BoxToggle", {
    Text = "Box ESP",
    Default = true,
    Callback = function(v)
        ESP.Box = v
    end
})

ESPGroup:AddColorPicker("BoxColorPicker", {
    Title = "Box Color",
    Default = ESP.BoxColor,
    Callback = function(c)
        ESP.BoxColor = c
    end
})

--========================================================--
--  MAIN LOOP
--========================================================--

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                UpdateBox(player, char)
            end
        end
    end
end)

Library:Notify("Nexus ESP Loaded", 3)
