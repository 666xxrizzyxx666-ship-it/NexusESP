local SaveManager = {}
local library, cfg_ref = nil, nil

function SaveManager:SetLibrary(lib) library  = lib end
function SaveManager:SetConfig(cfg)  cfg_ref  = cfg end

function SaveManager:BuildSection(group)
    if not group or not cfg_ref then return end

    group:AddInput("ProfileNameInput", {
        Text        = "Profile name",
        Default     = "my_profile",
        Placeholder = "Enter a name...",
        Callback    = function() end,
    })

    group:AddButton({ Text = "Save profile", Func = function()
        local opt  = (getgenv and getgenv().Options or {})[("ProfileNameInput")]
        local name = (opt and opt.Value and opt.Value ~= "") and opt.Value or "profile_1"
        name = name:gsub("[^%w_%-]", "_")
        cfg_ref:SaveProfile(name)
        -- Refresh dropdown
        local dd = (getgenv and getgenv().Options or {})[("ProfileSelector")]
        if dd then
            local list = cfg_ref:ListProfiles()
            if #list == 0 then list = {"(none)"} end
            dd.Values = list
            pcall(function() dd:SetValue(name) end)
            pcall(function() dd:Refresh() end)
        end
        if library then library:Notify("Profile '"..name.."' saved!", 3) end
    end})

    local profiles = cfg_ref:ListProfiles()
    if #profiles == 0 then profiles = {"(none)"} end

    group:AddDropdown("ProfileSelector", {
        Text     = "Saved profiles",
        Values   = profiles,
        Default  = profiles[1],
        Callback = function() end,
    })

    group:AddButton({ Text = "Load selected", Func = function()
        local dd = (getgenv and getgenv().Options or {})[("ProfileSelector")]
        if not dd or not dd.Value or dd.Value == "(none)" then
            if library then library:Notify("No profile selected", 2) end; return
        end
        local ok = cfg_ref:LoadProfile(dd.Value)
        if library then library:Notify(ok and "Profile loaded!" or "Profile not found", 3) end
    end})

    group:AddButton({ Text = "Refresh list", Func = function()
        local dd = (getgenv and getgenv().Options or {})[("ProfileSelector")]
        if dd then
            local list = cfg_ref:ListProfiles()
            if #list == 0 then list = {"(none)"} end
            dd.Values = list
            pcall(function() dd:Refresh() end)
        end
    end})
end

return SaveManager
