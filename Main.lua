--==============================--
--  TEST 3 : ESP MODULE SIMPLE
--==============================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy - TEST 3",
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
--  LOAD ESP MODULE
--==============================--

local ESP = include("Modules/ESP.lua")

Group:AddLabel("ESP loaded: " .. tostring(ESP))

Group:AddButton("Run ESP Update", function()
    ESP:UpdateAll()
    Library:Notify("ESP UpdateAll() executed", 3)
end)
