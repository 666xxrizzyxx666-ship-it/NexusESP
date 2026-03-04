local SaveManager = {}
local HS = game:GetService("HttpService")
local library, config_ref = nil, nil

function SaveManager:SetLibrary(lib)    library = lib end
function SaveManager:SetConfig(cfg)     config_ref = cfg end
function SaveManager:SetFolder(_)       end
function SaveManager:IgnoreThemeSettings() end
function SaveManager:SetIgnoreIndexes(_)   end

function SaveManager:BuildConfigSection(group, cfg)
    config_ref = cfg or config_ref
    if not group or not config_ref then return end

    -- Input pour le nom du profil
    group:AddInput("ProfileName", {
        Text="Nom du profil", Default="mon_profil",
        Placeholder="Entrer un nom...",
        Callback=function(_) end,
    })

    group:AddButton({Text="Sauvegarder", Func=function()
        local opt = (getgenv().Options or {}).ProfileName
        local name = (opt and opt.Value and opt.Value~="") and opt.Value or "profil_1"
        -- Nettoyer le nom (pas de / \ etc)
        name = name:gsub("[^%w_%-]","_")
        config_ref:SaveProfile(name)
        if library then library:Notify("Profil '"..name.."' sauvegarde!", 3) end
    end})

    -- Dropdown dynamique des profils existants
    local profiles = config_ref:ListProfiles()
    if #profiles==0 then profiles={"(aucun)"} end

    group:AddDropdown("ProfileList", {
        Text="Charger un profil", Values=profiles, Default=profiles[1],
        Callback=function(_) end,
    })

    group:AddButton({Text="Charger profil", Func=function()
        local opt=(getgenv().Options or {}).ProfileList
        if not opt or not opt.Value or opt.Value=="(aucun)" then
            if library then library:Notify("Aucun profil selectionne", 2) end; return
        end
        local ok = config_ref:LoadProfile(opt.Value)
        if library then library:Notify(ok and "Profil charge!" or "Profil introuvable", 3) end
    end})

    group:AddButton({Text="Rafraichir liste", Func=function()
        local opt=(getgenv().Options or {}).ProfileList
        if opt then
            local p=config_ref:ListProfiles()
            if #p==0 then p={"(aucun)"} end
            opt.Values=p
            pcall(function() opt:Refresh() end)
        end
    end})
end

return SaveManager
