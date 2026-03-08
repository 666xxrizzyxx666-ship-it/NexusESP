-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Config/Profiles.lua
--   📁 Dossier : Config/
--   Rôle : Gestion des profils de configuration
--          Save / Load / Export / Import / Cloud
-- ══════════════════════════════════════════════════════

local Profiles = {}

local HS = game:GetService("HttpService")

local FOLDER   = "NexusESP/profiles"
local MAX_PROF = 10
local profiles = {}
local current  = "Default"

-- ── Profil par défaut ─────────────────────────────────
local DEFAULT_PROFILE = {
    name    = "Default",
    created = 0,
    Config  = {
        ESP = {
            Enabled    = true,
            Box        = {Enabled=true,  Color={R=255,G=255,B=255}, Thickness=1, Filled=false},
            CornerBox  = {Enabled=false, Color={R=255,G=100,B=100}, Thickness=1},
            Skeleton   = {Enabled=true,  Color={R=200,G=200,B=200}, Thickness=1},
            Tracers    = {Enabled=false, Color={R=255,G=255,B=255}, Thickness=1, Position="Bottom"},
            Health     = {Enabled=true,  Position="Left", Width=3, ShowText=false},
            Name       = {Enabled=true,  Color={R=255,G=255,B=255}, Size=13},
            Distance   = {Enabled=true,  Color={R=180,G=180,B=180}, Size=11},
            Chams      = {Enabled=false, Color={R=255,G=60,B=60}},
            TeamCheck  = false,
        },
        Aimbot = {
            Enabled    = false,
            Mode       = "Normal",   -- Lite / Normal / Rage
            FOV        = 100,
            Smoothness = 10,
            Bone       = "Head",
            HoldKey    = true,
            Prediction = 50,
            TeamCheck  = true,
            WallCheck  = false,
            ShowFOV    = true,
            AIBlend    = 0.5,
        },
        SilentAim = {
            Enabled   = false,
            FOV       = 30,
            TeamCheck = true,
            WallCheck = false,
        },
        Triggerbot = {
            Enabled   = false,
            Delay     = 0.08,
            TeamCheck = true,
        },
        RecoilControl = {
            Enabled  = false,
            Strength = 50,
        },
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
        FullBright = {
            Enabled = false,
        },
        NoFog = {
            Enabled = false,
        },
        ItemESP = {
            Enabled = false,
            MaxDist = 500,
            Color   = {R=255,G=215,B=0},
        },
        AntiAFK = {
            Enabled = true,
        },
        FPSUnlock = {
            Enabled = false,
            Target  = 144,
        },
        PanicKey = {
            Key = "Delete",
        },
        Distance = {
            MaxDist = 800,
        },
        TeamCheck = false,
        Watermark = {
            Enabled  = true,
        },
        Radar = {
            Enabled  = false,
        },
    }
}

-- ── Init ──────────────────────────────────────────────
function Profiles.Init()
    pcall(function()
        if not isfolder("NexusESP") then makefolder("NexusESP") end
        if not isfolder(FOLDER)     then makefolder(FOLDER)     end
    end)
    Profiles.Load("Default")
    print("[Profiles] Initialisé ✓")
end

-- ── Save ──────────────────────────────────────────────
function Profiles.Save(name, configData)
    name = name or current
    local prof = {
        name    = name,
        created = os.time(),
        Config  = configData or DEFAULT_PROFILE.Config,
    }
    profiles[name] = prof

    pcall(function()
        writefile(FOLDER.."/"..name..".json", HS:JSONEncode(prof))
    end)

    print("[Profiles] Sauvegardé : "..name)
    return true
end

-- ── Load ──────────────────────────────────────────────
function Profiles.Load(name)
    name = name or "Default"
    current = name

    -- Essaie de charger depuis le fichier
    local ok, data = pcall(function()
        local raw = readfile(FOLDER.."/"..name..".json")
        return HS:JSONDecode(raw)
    end)

    if ok and data then
        profiles[name] = data
        print("[Profiles] Chargé : "..name)
        return data.Config
    end

    -- Fallback : profil par défaut
    print("[Profiles] "..name.." introuvable — default utilisé")
    profiles[name] = DEFAULT_PROFILE
    return DEFAULT_PROFILE.Config
end

-- ── List ──────────────────────────────────────────────
function Profiles.List()
    local list = {}
    pcall(function()
        for _, file in ipairs(listfiles(FOLDER)) do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end)
    if #list == 0 then table.insert(list, "Default") end
    return list
end

-- ── Delete ────────────────────────────────────────────
function Profiles.Delete(name)
    if name == "Default" then return false end
    profiles[name] = nil
    pcall(function() delfile(FOLDER.."/"..name..".json") end)
    print("[Profiles] Supprimé : "..name)
    return true
end

-- ── Export (JSON string) ──────────────────────────────
function Profiles.Export(name)
    name = name or current
    local prof = profiles[name]
    if not prof then return nil end
    return HS:JSONEncode(prof)
end

-- ── Import ────────────────────────────────────────────
function Profiles.Import(jsonStr)
    local ok, data = pcall(function()
        return HS:JSONDecode(jsonStr)
    end)
    if not ok or not data or not data.name then return false end
    if #Profiles.List() >= MAX_PROF then return false end
    return Profiles.Save(data.name, data.Config)
end

-- ── Reset to default ─────────────────────────────────
function Profiles.Reset(name)
    name = name or current
    profiles[name] = DEFAULT_PROFILE
    Profiles.Save(name, DEFAULT_PROFILE.Config)
    print("[Profiles] Reset : "..name)
    return DEFAULT_PROFILE.Config
end

function Profiles.GetCurrent()   return current end
function Profiles.GetDefault()   return DEFAULT_PROFILE.Config end
function Profiles.Get(name)
    return profiles[name or current]
end

return Profiles
