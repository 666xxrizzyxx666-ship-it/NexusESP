--========================================================--
--  NEXUS ESP — MAIN FILE
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--========================================================--
--  ESP MASTER TABLE
--========================================================--

ESP = {
    Enabled = true,

    Box = true,
    BoxColor = Color3.fromRGB(255, 0, 0),

    Boxes = {}
}

--========================================================--
--  MODULE LOADER
--========================================================--

local function include(url)
    local source = game:HttpGet(url)
    local fn = loadstring(source)
    return fn()
end

local base = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/main/Modules/"

include(base .. "Box.lua")

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
