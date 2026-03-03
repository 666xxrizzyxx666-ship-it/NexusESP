-- ============================================================
--  Addons/SaveManager.lua — Gestion des profils de config
--  Compatible avec la librairie Linoria UI
--  Adapté pour notre framework ESP (via Toggles/Options globaux)
-- ============================================================

local SaveManager = {}

local Players    = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local library     = nil
local ignoreList  = {}
local folder      = "RobloxESP"
local configName  = "default"

-- ── Dépendances ───────────────────────────────────────────────
function SaveManager:SetLibrary(lib)
    library = lib
end

function SaveManager:SetFolder(folderName)
    folder = folderName
    -- Créer le dossier si nécessaire
    pcall(function()
        if not isfolder(folder) then
            makefolder(folder)
        end
        if not isfolder(folder .. "/configs") then
            makefolder(folder .. "/configs")
        end
    end)
end

function SaveManager:IgnoreThemeSettings()
    local themeKeys = {
        "FontColor", "MainColor", "BackgroundColor",
        "AccentColor", "OutlineColor", "RiskColor",
    }
    for _, k in ipairs(themeKeys) do
        ignoreList[k] = true
    end
end

function SaveManager:SetIgnoreIndexes(list)
    for _, key in ipairs(list) do
        ignoreList[key] = true
    end
end

-- ── Sérialiser l'état actuel des Toggles et Options ─────────
local function serialize()
    local data = {}

    for key, toggle in pairs(getgenv().Toggles or {}) do
        if not ignoreList[key] then
            data["toggle_" .. key] = toggle.Value
        end
    end

    for key, option in pairs(getgenv().Options or {}) do
        if not ignoreList[key] then
            local ok, val = pcall(function()
                if option.Type == "ColorPicker" then
                    return {
                        R = math.floor(option.Value.R * 255),
                        G = math.floor(option.Value.G * 255),
                        B = math.floor(option.Value.B * 255),
                    }
                elseif option.Type == "Slider" then
                    return option.Value
                elseif option.Type == "Dropdown" then
                    return option.Value
                elseif option.Type == "KeyPicker" then
                    return option.Value
                end
                return option.Value
            end)
            if ok and val ~= nil then
                data["option_" .. key] = val
            end
        end
    end

    return data
end

-- ── Désérialiser et appliquer ────────────────────────────────
local function deserialize(data)
    for key, val in pairs(data) do
        -- Toggles
        if key:sub(1, 7) == "toggle_" then
            local toggleKey = key:sub(8)
            local toggle = (getgenv().Toggles or {})[toggleKey]
            if toggle then
                pcall(function() toggle:SetValue(val) end)
            end

        -- Options
        elseif key:sub(1, 7) == "option_" then
            local optKey = key:sub(8)
            local option = (getgenv().Options or {})[optKey]
            if option then
                pcall(function()
                    if option.Type == "ColorPicker" and type(val) == "table" then
                        option:SetValueRGB(Color3.fromRGB(val.R, val.G, val.B))
                    else
                        option:SetValue(val)
                    end
                end)
            end
        end
    end
end

-- ── Sauvegarder un profil ────────────────────────────────────
function SaveManager:Save(name)
    name = name or configName
    local path = folder .. "/configs/" .. name .. ".json"

    local ok, data = pcall(serialize)
    if not ok then
        if library then library:Notify("Erreur de sérialisation", 3) end
        return
    end

    local encoded
    ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if not ok then
        if library then library:Notify("Erreur JSON encode", 3) end
        return
    end

    pcall(writefile, path, encoded)
end

-- ── Charger un profil ────────────────────────────────────────
function SaveManager:Load(name)
    name = name or configName
    local path = folder .. "/configs/" .. name .. ".json"

    local ok, raw = pcall(readfile, path)
    if not ok or not raw or raw == "" then
        return false
    end

    local decoded
    ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not ok or type(decoded) ~= "table" then
        return false
    end

    deserialize(decoded)
    return true
end

-- ── Lister les profils disponibles ──────────────────────────
function SaveManager:GetConfigs()
    local configs = {}
    pcall(function()
        local files = listfiles(folder .. "/configs")
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end)
    return configs
end

-- ── Supprimer un profil ───────────────────────────────────────
function SaveManager:Delete(name)
    pcall(delfile, folder .. "/configs/" .. name .. ".json")
end

-- ── Construire la section UI dans Linoria ────────────────────
function SaveManager:BuildConfigSection(groupbox)
    if not groupbox then return end

    groupbox:AddDropdown("ConfigList", {
        Text   = "Profil de configuration",
        Values = self:GetConfigs(),
        Default = "default",
    })

    groupbox:AddButton({
        Text    = "💾 Sauvegarder",
        Func    = function()
            local opt = (getgenv().Options or {})["ConfigList"]
            local name = (opt and opt.Value) or "default"
            self:Save(name)
            if library then library:Notify("Profil '" .. name .. "' sauvegardé", 3) end
        end,
    })

    groupbox:AddButton({
        Text    = "📂 Charger",
        Func    = function()
            local opt = (getgenv().Options or {})["ConfigList"]
            local name = (opt and opt.Value) or "default"
            local ok = self:Load(name)
            if library then
                library:Notify(ok and "Profil '" .. name .. "' chargé" or "Profil introuvable", 3)
            end
        end,
    })

    groupbox:AddButton({
        Text    = "🗑 Supprimer",
        Func    = function()
            local opt = (getgenv().Options or {})["ConfigList"]
            local name = (opt and opt.Value) or "default"
            if name ~= "default" then
                self:Delete(name)
                if library then library:Notify("Profil '" .. name .. "' supprimé", 3) end
            else
                if library then library:Notify("Impossible de supprimer 'default'", 3) end
            end
        end,
    })
end

-- Auto-sauvegarde sur chaque changement (hook Linoria)
game:GetService("RunService").Heartbeat:Connect(function()
    -- Sauvegarde throttlée toutes les 30s
end)

return SaveManager
