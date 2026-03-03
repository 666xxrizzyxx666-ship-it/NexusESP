-- ============================================================
--  Config.lua — Module de configuration centralisé
--  Gère les valeurs par défaut, sauvegarde/chargement JSON
--  et reset de configuration via writefile/readfile (executor)
-- ============================================================

local Config = {}

-- ── Valeurs par défaut ──────────────────────────────────────
Config.Defaults = {

    -- ── Général ──
    Enabled         = false,
    TeamCheck       = true,
    VisibilityCheck = true,
    PerformanceMode = false,
    DebugMode       = false,

    -- ── Box 2D ──
    Box = {
        Enabled   = true,
        Color     = { R = 255, G = 255, B = 255 },
        Thickness = 1,
        Filled    = false,
        FillColor = { R = 255, G = 255, B = 255 },
        FillTrans = 0.5,
    },

    -- ── Skeleton ──
    Skeleton = {
        Enabled   = true,
        Color     = { R = 255, G = 255, B = 255 },
        Thickness = 1,
    },

    -- ── Tracers ──
    Tracers = {
        Enabled  = true,
        Color    = { R = 255, G = 255, B = 255 },
        Position = "Bottom",  -- "Bottom" | "Center" | "Top"
        Thickness = 1,
    },

    -- ── Health Bar ──
    Health = {
        Enabled      = true,
        Position     = "Left",   -- "Left" | "Right" | "Top" | "Bottom"
        Width        = 3,
        ShowText     = false,
        OutlineColor = { R = 0, G = 0, B = 0 },
    },

    -- ── Name Tag ──
    Name = {
        Enabled   = true,
        Color     = { R = 255, G = 255, B = 255 },
        Size      = 13,
        OffsetY   = 5,
        Outline   = true,
    },

    -- ── Distance Tag ──
    Distance = {
        Enabled  = true,
        Color    = { R = 200, G = 200, B = 200 },
        Size     = 11,
        Format   = "{dist}m",  -- placeholders: {dist}
        MaxDist  = 1000,
    },

    -- ── Player List ──
    PlayerList = {
        Enabled      = true,
        ShowDistance = true,
        ShowHealth   = true,
        ShowTeam     = true,
        ShowVisible  = true,
    },
}

-- ── Chemin de sauvegarde ────────────────────────────────────
local SAVE_PATH = "RobloxESP_Config.json"

-- ── Config active (copie des defaults au démarrage) ─────────
Config.Current = {}

-- ── Utilitaires internes ─────────────────────────────────────
local function deepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[deepCopy(k)] = deepCopy(v)
        end
        setmetatable(copy, getmetatable(orig))
    else
        copy = orig
    end
    return copy
end

local function mergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = {}
            end
            mergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

-- ── Convertion Color3 ↔ table {R,G,B} ──────────────────────
function Config.ToColor3(t)
    return Color3.fromRGB(t.R or 255, t.G or 255, t.B or 255)
end

function Config.FromColor3(c)
    return {
        R = math.floor(c.R * 255),
        G = math.floor(c.G * 255),
        B = math.floor(c.B * 255),
    }
end

-- ── Init ─────────────────────────────────────────────────────
function Config:Init()
    Config.Current = deepCopy(Config.Defaults)
    Config:Load()
    return Config.Current
end

-- ── Sauvegarde JSON ──────────────────────────────────────────
function Config:Save()
    local ok, encoded = pcall(function()
        -- Roblox executor : HttpService n'est pas dispo, on sérialise manuellement
        -- ou on utilise la function game:GetService("HttpService"):JSONEncode
        return game:GetService("HttpService"):JSONEncode(Config.Current)
    end)
    if ok then
        pcall(writefile, SAVE_PATH, encoded)
        if Config.Current.DebugMode then
            print("[ESP Config] Config sauvegardée →", SAVE_PATH)
        end
    else
        warn("[ESP Config] Erreur de sérialisation:", encoded)
    end
end

-- ── Chargement JSON ──────────────────────────────────────────
function Config:Load()
    local ok, raw = pcall(readfile, SAVE_PATH)
    if not ok or not raw or raw == "" then
        if Config.Current.DebugMode then
            print("[ESP Config] Aucun fichier trouvé, defaults utilisés.")
        end
        return
    end

    local decoded
    local ok2
    ok2, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(raw)
    end)

    if ok2 and type(decoded) == "table" then
        -- Fusionne en gardant les nouvelles clés des defaults
        mergeDefaults(decoded, Config.Defaults)
        Config.Current = decoded
        if Config.Current.DebugMode then
            print("[ESP Config] Config chargée depuis", SAVE_PATH)
        end
    else
        warn("[ESP Config] JSON invalide, reset aux defaults.")
        Config.Current = deepCopy(Config.Defaults)
    end
end

-- ── Reset ────────────────────────────────────────────────────
function Config:Reset()
    Config.Current = deepCopy(Config.Defaults)
    Config:Save()
    print("[ESP Config] Reset aux valeurs par défaut.")
end

-- ── Getter raccourci ─────────────────────────────────────────
function Config:Get(key)
    return Config.Current[key]
end

function Config:Set(key, value)
    Config.Current[key] = value
    Config:Save()
end

return Config
