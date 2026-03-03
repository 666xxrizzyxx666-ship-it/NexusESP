--==============================--
--  TEST 7 : BOX ESP DRAWING
--==============================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy - TEST 7",
    Center = true,
    AutoShow = true
})

local Tab = Window:AddTab("Main")
local Group = Tab:AddLeftGroupbox("ESP Test")

local function include(path)
    local url = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/main/" .. path
    local content = game:HttpGet(url)
    return loadstring(content)()
end

local ESP = include("Modules/ESP.lua")
local Box = include("Modules/Box.lua")

Group:AddToggle("EnableESP", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v)
        ESP.Enabled = v
    end
})

game:GetService("RunService").RenderStepped:Connect(function()
    ESP:UpdateAll()
end)
