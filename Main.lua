-- Main.lua

local function include(url)
    return loadstring(game:HttpGet(url))()
end

local base = "https://raw.githubusercontent.com/TON-PSEUDO/NexusESP/main/Modules/"

-- ESP MASTER TABLE
ESP = {
    Enabled = true,

    Boxes = {},
    HealthBars = {},
    Skeletons = {},
    Names = {},
    Tracers = {},
    Glows = {},

    Box = false,
    BoxColor = Color3.fromRGB(255, 0, 0),
}

include(base .. "Box.lua")

game:GetService("RunService").RenderStepped:Connect(function()
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local char = player.Character
            if char then
                UpdateBox(player, char)
            end
        end
    end
end)
