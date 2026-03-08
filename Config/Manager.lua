-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Config/Manager.lua
--   Rôle : Gestion complète de la configuration
--          Sauvegarde locale + Firebase sync
-- ══════════════════════════════════════════════════════

local Manager = {}

local HS     = game:GetService("HttpService")
local FOLDER = "NexusESP"
local AUTO   = FOLDER .. "/config.json"

-- ── Valeurs par défaut ────────────────────────────────
Manager.Defaults = {
    -- Global
    Enabled          = false,
    TeamCheck        = true,
    VisCheck         = false,
    PerformanceMode  = false,

    -- ESP
    Box = {
        Enabled    = true,
        Color      = {R=255, G=255, B=255},
        Thickness  = 1,
        Filled     = false,
        FillColor  = {R=255, G=60,  B=60},
        FillTrans  = 0.7,
    },
    CornerBox = {
        Enabled   = false,
        Color     = {R=255, G=255, B=255},
        Thickness = 1,
    },
    Skeleton = {
        Enabled   = true,
        Color     = {R=255, G=255, B=255},
        Thickness = 1,
    },
    Tracers = {
        Enabled   = false,
        Color     = {R=255, G=255, B=255},
        Position  = "Bottom",
        Thickness = 1,
    },
    Health = {
        Enabled  = true,
        Position = "Left",
        Width    = 3,
        ShowText = false,
    },
    Name = {
        Enabled = true,
        Color   = {R=255, G=255, B=255},
        Size    = 13,
        OffsetY = 5,
    },
    Distance = {
        Enabled = true,
        Color   = {R=180, G=180, B=180},
        Size    = 11,
        MaxDist = 800,
    },
    Chams = {
        Enabled     = false,
        Color       = {R=255, G=0, B=0},
        FillColor   = {R=0,   G=0, B=255},
        Transparent = 0.5,
    },
    Hitbox = {
        Enabled   = false,
        Color     = {R=255, G=0, B=0},
        Thickness = 1,
    },
    Arrows = {
        Enabled = false,
        Color   = {R=255, G=255, B=0},
        Size    = 20,
    },
    WeaponTag = {
        Enabled = false,
        Color   = {R=200, G=200, B=200},
        Size    = 10,
    },

    -- Combat
    Aimbot = {
        Enabled     = false,
        Mode        = "Normal",   -- Lite / Normal / Rage
        Bone        = "Head",
        Smoothness  = 10,
        FOV         = 100,
        ShowFOV     = true,
        WallCheck   = true,
        TeamCheck   = true,
        Priority    = "Closest", -- Closest / LowestHP / MostVisible
        AutoFire    = false,
        KillDelay   = 0.1,
    },
    SilentAim = {
        Enabled   = false,
        FOV       = 30,
        WallCheck = true,
        TeamCheck = true,
    },
    Triggerbot = {
        Enabled   = false,
        Delay     = 0.05,
        TeamCheck = true,
    },
    RecoilControl = {
        Enabled   = false,
        Strength  = 50,
    },

    -- Movement
    Speed = {
        Enabled = false,
        Value   = 32,
    },
    Fly = {
        Enabled = false,
        Speed   = 50,
    },
    Noclip = {
        Enabled = false,
    },
    BunnyHop = {
        Enabled = false,
    },
    InfiniteJump = {
        Enabled = false,
    },
    AntiRagdoll = {
        Enabled = false,
    },
    AntiKnockback = {
        Enabled = false,
    },

    -- World
    FullBright = {
        Enabled = false,
    },
    NoFog = {
        Enabled = false,
    },
    NoWeather = {
        Enabled = false,
    },
    ItemESP = {
        Enabled = false,
        Color   = {R=255, G=215, B=0},
        MaxDist = 500,
    },

    -- UI
    FOV = {
        Enabled = false,
        Radius  = 100,
        Color   = {R=255, G=255, B=255},
    },
    Radar = {
        Enabled   = false,
        Size      = 200,
        Range     = 300,
        ShowNames = true,
    },
    PlayerList = {
        Enabled = false,
    },

    -- Theme UI
    UI = {
        Accent     = {R=91,  G=107, B=248},
        Background = {R=10,  G=10,  B=14},
        Surface    = {R=14,  G=14,  B=20},
        Border     = {R=35,  G=35,  B=55},
        Text       = {R=220, G=220, B=230},
        TextSub    = {R=100, G=100, B=120},
    },

    -- Keybinds
    Keybinds = {
        ToggleMenu  = "RightControl",
        PanicKey    = "RightShift",
        Aimbot      = "None",
        SilentAim   = "None",
        Fly         = "None",
        Noclip      = "None",
        Speed       = "None",
    },

    -- AI
    AI = {
        Enabled       = true,
        AutoTrain     = true,
        SaveProfile   = true,
        AimAssist     = true,
        Humanizer     = true,
        ThreatLevel   = true,
    },
}

Manager.Current = {}

-- ── Helpers ───────────────────────────────────────────
local function deepCopy(o)
    if type(o) ~= "table" then return o end
    local c = {}
    for k, v in pairs(o) do
        c[deepCopy(k)] = deepCopy(v)
    end
    return c
end

local function merge(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            merge(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

-- ── Color helpers ─────────────────────────────────────
function Manager.ToC3(t)
    if not t then return Color3.new(1,1,1) end
    return Color3.fromRGB(t.R or 255, t.G or 255, t.B or 255)
end

function Manager.FromC3(c)
    return {
        R = math.floor(c.R * 255),
        G = math.floor(c.G * 255),
        B = math.floor(c.B * 255),
    }
end

-- ── Init ──────────────────────────────────────────────
function Manager:Init()
    Manager.Current = deepCopy(Manager.Defaults)
    pcall(function()
        if not isfolder(FOLDER) then
            makefolder(FOLDER)
        end
        if not isfolder(FOLDER .. "/profiles") then
            makefolder(FOLDER .. "/profiles")
        end
    end)
    Manager:_load(AUTO)
    return Manager.Current
end

-- ── Save / Load ───────────────────────────────────────
function Manager:_load(path)
    local ok, raw = pcall(readfile, path)
    if not ok or not raw or raw == "" then return false end
    local ok2, dec = pcall(function()
        return HS:JSONDecode(raw)
    end)
    if ok2 and type(dec) == "table" then
        merge(dec, Manager.Defaults)
        Manager.Current = dec
        return true
    end
    return false
end

function Manager:_save(path)
    local ok, enc = pcall(function()
        return HS:JSONEncode(Manager.Current)
    end)
    if ok then
        pcall(writefile, path, enc)
    end
end

function Manager:Save()
    Manager:_save(AUTO)
end

function Manager:SaveProfile(name)
    name = name:gsub("[^%w_%-]", "_")
    Manager:_save(FOLDER .. "/profiles/" .. name .. ".json")
    Manager:Save()
end

function Manager:LoadProfile(name)
    return Manager:_load(FOLDER .. "/profiles/" .. name .. ".json")
end

function Manager:Reset()
    Manager.Current = deepCopy(Manager.Defaults)
    Manager:Save()
end

function Manager:ListProfiles()
    local list = {}
    pcall(function()
        for _, f in ipairs(listfiles(FOLDER .. "/profiles")) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(list, n) end
        end
    end)
    return list
end

-- ── Get / Set rapide ──────────────────────────────────
function Manager:Get(key)
    return Manager.Current[key]
end

function Manager:Set(key, value)
    Manager.Current[key] = value
    Manager:Save()
end

-- ── SetAll — charge un profil entier ──────────────────
function Manager.SetAll(data)
    if type(data) ~= "table" then return end
    for k, v in pairs(data) do
        Manager.Current[k] = v
    end
    pcall(function() Manager:Save() end)
end

return Manager
