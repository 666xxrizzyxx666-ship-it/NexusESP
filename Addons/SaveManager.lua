local SaveManager = {}
local HttpService = game:GetService("HttpService")
local library, folder = nil, "NexusESP"

function SaveManager:SetLibrary(lib)    library = lib end
function SaveManager:SetFolder(f)
    folder = f
    pcall(function() if not isfolder(f) then makefolder(f) end end)
    pcall(function() if not isfolder(f.."/configs") then makefolder(f.."/configs") end end)
end
function SaveManager:IgnoreThemeSettings() end
function SaveManager:SetIgnoreIndexes(_) end

local ignoreList = {}

local function serialize()
    local data = {}
    for k, t in pairs(getgenv().Toggles or {}) do
        if not ignoreList[k] then data["t_"..k] = t.Value end
    end
    for k, o in pairs(getgenv().Options or {}) do
        if not ignoreList[k] then
            pcall(function()
                if o.Type == "ColorPicker" then
                    data["o_"..k] = {R=math.floor(o.Value.R*255),G=math.floor(o.Value.G*255),B=math.floor(o.Value.B*255)}
                else
                    data["o_"..k] = o.Value
                end
            end)
        end
    end
    return data
end

local function deserialize(data)
    for k, v in pairs(data) do
        if k:sub(1,2)=="t_" then
            local tog = (getgenv().Toggles or {})[k:sub(3)]
            if tog then pcall(function() tog:SetValue(v) end) end
        elseif k:sub(1,2)=="o_" then
            local opt = (getgenv().Options or {})[k:sub(3)]
            if opt then
                pcall(function()
                    if opt.Type=="ColorPicker" and type(v)=="table" then
                        opt:SetValueRGB(Color3.fromRGB(v.R,v.G,v.B))
                    else opt:SetValue(v) end
                end)
            end
        end
    end
end

function SaveManager:Save(name)
    name = name or "default"
    local ok, data = pcall(serialize)
    if not ok then return end
    local ok2, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if ok2 then pcall(writefile, folder.."/configs/"..name..".json", enc) end
end

function SaveManager:Load(name)
    name = name or "default"
    local ok, raw = pcall(readfile, folder.."/configs/"..name..".json")
    if not ok or not raw or raw=="" then return false end
    local ok2, dec = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok2 and type(dec)=="table" then deserialize(dec); return true end
    return false
end

function SaveManager:GetConfigs()
    local c = {}
    pcall(function()
        for _, f in ipairs(listfiles(folder.."/configs")) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(c, n) end
        end
    end)
    if #c == 0 then table.insert(c, "default") end
    return c
end

function SaveManager:BuildConfigSection(group)
    if not group then return end
    group:AddDropdown("ConfigList", { Text="Profil", Values=self:GetConfigs(), Default="default", Callback=function(_)end })
    group:AddButton({ Text="Sauvegarder", Func=function()
        local v = (getgenv().Options or {}).ConfigList
        local n = v and v.Value or "default"
        self:Save(n)
        if library then library:Notify("Profil '"..n.."' sauvegarde", 3) end
    end})
    group:AddButton({ Text="Charger", Func=function()
        local v = (getgenv().Options or {}).ConfigList
        local n = v and v.Value or "default"
        local ok = self:Load(n)
        if library then library:Notify(ok and "Profil charge" or "Introuvable", 3) end
    end})
end

return SaveManager
