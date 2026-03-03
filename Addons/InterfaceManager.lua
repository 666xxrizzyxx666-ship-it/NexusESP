-- ============================================================
--  Addons/InterfaceManager.lua — Gestionnaire de thèmes UI
--  Compatible avec la librairie Linoria
--  Permet de personnaliser les couleurs de l'interface
-- ============================================================

local InterfaceManager = {}

local HttpService = game:GetService("HttpService")

local library  = nil
local folder   = "RobloxESP"

-- ── Thèmes prédéfinis ────────────────────────────────────────
local Themes = {
    Default = {
        FontColor       = Color3.fromRGB(255, 255, 255),
        MainColor       = Color3.fromRGB(28, 28, 28),
        BackgroundColor = Color3.fromRGB(20, 20, 20),
        AccentColor     = Color3.fromRGB(0, 85, 255),
        OutlineColor    = Color3.fromRGB(50, 50, 50),
        RiskColor       = Color3.fromRGB(255, 50, 50),
    },
    Dark = {
        FontColor       = Color3.fromRGB(220, 220, 220),
        MainColor       = Color3.fromRGB(15, 15, 15),
        BackgroundColor = Color3.fromRGB(10, 10, 10),
        AccentColor     = Color3.fromRGB(0, 100, 200),
        OutlineColor    = Color3.fromRGB(35, 35, 35),
        RiskColor       = Color3.fromRGB(200, 30, 30),
    },
    Midnight = {
        FontColor       = Color3.fromRGB(180, 200, 255),
        MainColor       = Color3.fromRGB(12, 16, 36),
        BackgroundColor = Color3.fromRGB(8, 10, 24),
        AccentColor     = Color3.fromRGB(60, 100, 255),
        OutlineColor    = Color3.fromRGB(30, 40, 80),
        RiskColor       = Color3.fromRGB(220, 50, 80),
    },
    Forest = {
        FontColor       = Color3.fromRGB(200, 255, 200),
        MainColor       = Color3.fromRGB(10, 25, 10),
        BackgroundColor = Color3.fromRGB(6, 15, 6),
        AccentColor     = Color3.fromRGB(30, 180, 60),
        OutlineColor    = Color3.fromRGB(20, 50, 20),
        RiskColor       = Color3.fromRGB(220, 80, 30),
    },
    Rose = {
        FontColor       = Color3.fromRGB(255, 220, 230),
        MainColor       = Color3.fromRGB(35, 15, 20),
        BackgroundColor = Color3.fromRGB(22, 8, 12),
        AccentColor     = Color3.fromRGB(220, 60, 100),
        OutlineColor    = Color3.fromRGB(60, 25, 35),
        RiskColor       = Color3.fromRGB(255, 50, 50),
    },
}

-- ── Dépendances ───────────────────────────────────────────────
function InterfaceManager:SetLibrary(lib)
    library = lib
end

function InterfaceManager:SetFolder(folderName)
    folder = folderName
    pcall(function()
        if not isfolder(folder) then
            makefolder(folder)
        end
    end)
end

-- ── Appliquer un thème ────────────────────────────────────────
function InterfaceManager:ApplyTheme(themeName)
    local theme = Themes[themeName]
    if not theme or not library then return end

    library.FontColor       = theme.FontColor
    library.MainColor       = theme.MainColor
    library.BackgroundColor = theme.BackgroundColor
    library.AccentColor     = theme.AccentColor
    library.OutlineColor    = theme.OutlineColor
    library.RiskColor       = theme.RiskColor

    -- Forcer le rafraîchissement du registry
    library:UpdateColorsFromRegistry()

    -- Sauvegarder le thème choisi
    pcall(function()
        writefile(folder .. "/theme.json",
            game:GetService("HttpService"):JSONEncode({ theme = themeName })
        )
    end)
end

-- ── Charger le thème sauvegardé ──────────────────────────────
function InterfaceManager:LoadSavedTheme()
    local ok, raw = pcall(readfile, folder .. "/theme.json")
    if ok and raw and raw ~= "" then
        local decoded
        ok, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(raw)
        end)
        if ok and decoded and decoded.theme then
            self:ApplyTheme(decoded.theme)
            return decoded.theme
        end
    end
    return "Default"
end

-- ── Thème custom via colorpickers ────────────────────────────
function InterfaceManager:ApplyCustomColors(colors)
    if not library then return end

    for key, val in pairs(colors) do
        if library[key] ~= nil then
            library[key] = val
        end
    end

    pcall(function()
        library:UpdateColorsFromRegistry()
    end)
end

-- ── Construire la section UI ──────────────────────────────────
function InterfaceManager:BuildInterfaceSection(groupbox)
    if not groupbox then return end

    local themeNames = {}
    for k, _ in pairs(Themes) do
        table.insert(themeNames, k)
    end
    table.sort(themeNames)

    local savedTheme = self:LoadSavedTheme()

    groupbox:AddDropdown("ThemeSelector", {
        Text    = "Thème de l'interface",
        Values  = themeNames,
        Default = savedTheme,
        Tooltip = "Choisir un thème de couleurs pour l'UI",
        Callback = function(val)
            self:ApplyTheme(val)
        end,
    })

    -- Couleur d'accentuation custom
    groupbox:AddColorpicker("CustomAccent", {
        Text    = "Couleur d'accent",
        Default = library and library.AccentColor or Color3.fromRGB(0, 85, 255),
        Tooltip = "Couleur principale de l'interface",
        Callback = function(val)
            if library then
                library.AccentColor = val
                pcall(function() library:UpdateColorsFromRegistry() end)
            end
        end,
    })

    groupbox:AddColorpicker("CustomFont", {
        Text    = "Couleur du texte",
        Default = library and library.FontColor or Color3.fromRGB(255, 255, 255),
        Callback = function(val)
            if library then
                library.FontColor = val
                pcall(function() library:UpdateColorsFromRegistry() end)
            end
        end,
    })

    groupbox:AddButton({
        Text    = "🎨 Appliquer thème",
        Func    = function()
            local opt = (getgenv().Options or {})["ThemeSelector"]
            if opt then
                self:ApplyTheme(opt.Value)
                if library then
                    library:Notify("Thème '" .. opt.Value .. "' appliqué", 3)
                end
            end
        end,
    })

    groupbox:AddButton({
        Text    = "↩ Thème par défaut",
        Func    = function()
            self:ApplyTheme("Default")
            if library then
                library:Notify("Thème Default restauré", 2)
            end
        end,
    })
end

-- ── Liste des thèmes disponibles ─────────────────────────────
function InterfaceManager:GetThemes()
    local names = {}
    for k in pairs(Themes) do
        table.insert(names, k)
    end
    return names
end

-- ── Ajouter un thème custom ───────────────────────────────────
function InterfaceManager:AddTheme(name, colors)
    Themes[name] = colors
end

return InterfaceManager
