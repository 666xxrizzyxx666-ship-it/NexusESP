--==============================--
--  TEST 1 : FENÊTRE SEULE
--==============================--

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Nexus by Rizzy - TEST 1",
    Center = true,
    AutoShow = true
})

local MainTab = Window:AddTab("Main")
local Group = MainTab:AddLeftGroupbox("Debug")

Group:AddLabel("Si tu vois ça, Linoria marche.")
Group:AddButton("Notify", function()
    Library:Notify("Test OK", 3)
end)
