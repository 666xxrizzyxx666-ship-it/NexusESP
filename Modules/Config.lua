local Config = {}

local SAVE_PATH = "NexusESP_Config.json"

Config.Defaults = {
    Enabled = false, TeamCheck = true, VisibilityCheck = true,
    PerformanceMode = false, DebugMode = false,

    Box       = { Enabled=true,  Color={R=255,G=255,B=255}, Thickness=1, Filled=false, FillColor={R=255,G=60,B=60}, FillTrans=0.7 },
    CornerBox = { Enabled=false, Color={R=255,G=255,B=255}, Thickness=1 },
    Skeleton  = { Enabled=true,  Color={R=255,G=255,B=255}, Thickness=1 },
    Tracers   = { Enabled=false, Color={R=255,G=255,B=255}, Position="Bottom", Thickness=1 },
    Health    = { Enabled=true,  Position="Left", Width=3, ShowText=false },
    Name      = { Enabled=true,  Color={R=255,G=255,B=255}, Size=13, OffsetY=5, Outline=true },
    Distance  = { Enabled=true,  Color={R=180,G=180,B=180}, Size=11, Format="{dist}m", MaxDist=800 },
    FOV       = { Enabled=false, Radius=100, Color={R=255,G=255,B=255} },
    Radar     = { Enabled=false, Size=160, Range=200, ShowNames=true },
    PlayerList = { Enabled=false, ShowDistance=true, ShowHealth=true, ShowTeam=true, ShowVisible=true },
}

Config.Current = {}

local function deepCopy(o)
    if type(o) ~= "table" then return o end
    local c = {}
    for k,v in pairs(o) do c[deepCopy(k)] = deepCopy(v) end
    return c
end

local function merge(t, d)
    for k,v in pairs(d) do
        if type(v) == "table" then
            if type(t[k]) ~= "table" then t[k] = {} end
            merge(t[k], v)
        elseif t[k] == nil then
            t[k] = v
        end
    end
end

function Config.ToColor3(t)
    if not t then return Color3.new(1,1,1) end
    return Color3.fromRGB(t.R or 255, t.G or 255, t.B or 255)
end
function Config.FromColor3(c)
    return { R=math.floor(c.R*255), G=math.floor(c.G*255), B=math.floor(c.B*255) }
end

function Config:Init()
    Config.Current = deepCopy(Config.Defaults)
    Config:Load()
    return Config.Current
end

function Config:Save()
    local ok, enc = pcall(function()
        return game:GetService("HttpService"):JSONEncode(Config.Current)
    end)
    if ok then pcall(writefile, SAVE_PATH, enc) end
end

function Config:Load()
    local ok, raw = pcall(readfile, SAVE_PATH)
    if not ok or not raw or raw=="" then return end
    local ok2, dec = pcall(function()
        return game:GetService("HttpService"):JSONDecode(raw)
    end)
    if ok2 and type(dec)=="table" then
        merge(dec, Config.Defaults)
        Config.Current = dec
    end
end

function Config:Reset()
    Config.Current = deepCopy(Config.Defaults)
    Config:Save()
end

function Config:Get(k)   return Config.Current[k] end
function Config:Set(k,v) Config.Current[k]=v; Config:Save() end

return Config
