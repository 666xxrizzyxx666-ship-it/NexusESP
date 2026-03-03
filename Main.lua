--==============================--
--  TEST 5 : BOX MODULE SIMPLE
--==============================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy - TEST 5",
    Center = true,
    AutoShow = true
})

local Tab = Window:AddTab("Main")
local Group = Tab:AddLeftGroupbox("Box Test")

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

Group:AddLabel("ESP loaded: " .. tostring(ESP))
Group:AddLabel("Box loaded: " .. tostring(Box))

Group:AddButton("Test Box.Create", function()
    Box.Create(game.Players.LocalPlayer)
    Library:Notify("Box.Create() executed", 3)
end)

Group:AddButton("Test Box.Update", function()
    Box.Update(game.Players.LocalPlayer)
    Library:Notify("Box.Update() executed", 3)
end)
