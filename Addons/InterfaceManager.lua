local InterfaceManager = {}
local library, folder = nil, "NexusESP"

local Themes = {
    Default  = { AccentColor=Color3.fromRGB(0,85,255),   MainColor=Color3.fromRGB(28,28,28),  BackgroundColor=Color3.fromRGB(20,20,20),  FontColor=Color3.fromRGB(255,255,255), OutlineColor=Color3.fromRGB(50,50,50) },
    Midnight = { AccentColor=Color3.fromRGB(60,100,255),  MainColor=Color3.fromRGB(12,16,36),  BackgroundColor=Color3.fromRGB(8,10,24),   FontColor=Color3.fromRGB(180,200,255), OutlineColor=Color3.fromRGB(30,40,80) },
    Forest   = { AccentColor=Color3.fromRGB(30,180,60),   MainColor=Color3.fromRGB(10,25,10),  BackgroundColor=Color3.fromRGB(6,15,6),    FontColor=Color3.fromRGB(200,255,200), OutlineColor=Color3.fromRGB(20,50,20) },
    Rose     = { AccentColor=Color3.fromRGB(220,60,100),  MainColor=Color3.fromRGB(35,15,20),  BackgroundColor=Color3.fromRGB(22,8,12),   FontColor=Color3.fromRGB(255,220,230), OutlineColor=Color3.fromRGB(60,25,35) },
    Dark     = { AccentColor=Color3.fromRGB(0,100,200),   MainColor=Color3.fromRGB(15,15,15),  BackgroundColor=Color3.fromRGB(10,10,10),  FontColor=Color3.fromRGB(220,220,220), OutlineColor=Color3.fromRGB(35,35,35) },
}

function InterfaceManager:SetLibrary(lib) library = lib end
function InterfaceManager:SetFolder(f)   folder  = f    end

function InterfaceManager:ApplyTheme(name)
    local t = Themes[name]
    if not t or not library then return end
    for k,v in pairs(t) do library[k] = v end
    pcall(function() library:UpdateColorsFromRegistry() end)
    pcall(function() writefile(folder.."/theme.json", game:GetService("HttpService"):JSONEncode({theme=name})) end)
end

function InterfaceManager:LoadSavedTheme()
    local ok, raw = pcall(readfile, folder.."/theme.json")
    if ok and raw and raw~="" then
        local ok2, d = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
        if ok2 and d and d.theme then self:ApplyTheme(d.theme); return d.theme end
    end
    return "Default"
end

function InterfaceManager:BuildInterfaceSection(group)
    if not group then return end
    local names = {}
    for k in pairs(Themes) do table.insert(names, k) end
    table.sort(names)
    local saved = self:LoadSavedTheme()
    group:AddDropdown("ThemeSelector", { Text="Theme", Values=names, Default=saved,
        Callback=function(v) self:ApplyTheme(v) end })
    group:AddButton({ Text="Appliquer theme", Func=function()
        local o = (getgenv().Options or {}).ThemeSelector
        if o then self:ApplyTheme(o.Value) end
        if library then library:Notify("Theme applique", 2) end
    end})
end

return InterfaceManager
