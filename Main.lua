--========================================================--
--  NEXUS BASE — INTERFACE SEULEMENT
--========================================================--

-- Chargement de Linoria
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

-- Création de la fenêtre
local Window = Library:CreateWindow({
    Title = "Nexus ESP by Rizzy",
    Center = true,
    AutoShow = true
})

-- Création d’un onglet
local Tabs = {
    Main = Window:AddTab("Accueil")
}

-- Groupbox dans l’onglet
local Group = Tabs.Main:AddLeftGroupbox("Test Interface")

Group:AddLabel("L'interface fonctionne !")
Group:AddButton("Bouton test", function()
    Library:Notify("Bouton cliqué !", 2)
end)

-- Initialisation des managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:ApplyToTab(Tabs.Main)

Library:Notify("Interface chargée avec succès", 3)
