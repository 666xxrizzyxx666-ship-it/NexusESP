--==============================--
--  TEST 2 : INCLUDE SIMPLE
--==============================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy - TEST 2",
    Center = true,
    AutoShow = true
})

local Tab = Window:AddTab("Main")
local Group = Tab:AddLeftGroupbox("Include Test")

--==============================--
--  INCLUDE FUNCTION
--==============================--

local function include(path)
    local url = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/main/" .. path
    local content = game:HttpGet(url)

    return loadstring(content)()
end

--==============================--
--  TEST MODULE
--==============================--

local testModule = include("Modules/Test.lua")

Group:AddLabel("Module loaded: " .. tostring(testModule))

Group:AddButton("Show Value", function()
    Library:Notify("Module says: " .. tostring(testModule.Value), 3)
end)
