--==============================--
--  TEST 6 : ESP + BOX CONNECTÉS
--==============================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy - TEST 6",
    Center = true,
    AutoShow = true
})

local Tab = Window:AddTab("Main")
local Group = Tab:AddLeftGroupbox("ESP Test")

--==============================--
--  INCLUDE FUNCTION
--==============================--

local function include(path)
    local url = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/main/" .. path
    local content = game:HttpGet(url)
    return loadstring(content)()
end

--==============================--
--  LOAD MODULES
--==============================--

local ESP = include("Modules/ESP.lua")
local Box = include("Modules/Box.lua")

Group:AddToggle("EnableESP", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v)
        ESP.Enabled = v
    end
})

Group:AddButton("Force UpdateAll", function()
    ESP:UpdateAll()
    Library:Notify("ESP UpdateAll() executed", 3)
end)
