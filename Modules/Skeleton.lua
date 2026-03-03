-- ============================================================
--  Skeleton.lua — Dessin du squelette d'un character Roblox
--  Projette les articulations en 2D et relie les parties
--  avec des lignes Drawing.new("Line")
-- ============================================================

local Skeleton = {}
Skeleton.__index = Skeleton

local Utils
local Config

function Skeleton.SetDependencies(utils, config)
    Utils  = utils
    Config = config
end

-- ── Définition des liaisons squelettiques ────────────────────
-- Chaque paire {A, B} = ligne entre les deux parts nommées
local BONE_PAIRS = {
    -- Tronc
    { "Head",              "UpperTorso"    },
    { "UpperTorso",        "LowerTorso"    },
    -- Bras droit
    { "UpperTorso",        "RightUpperArm" },
    { "RightUpperArm",     "RightLowerArm" },
    { "RightLowerArm",     "RightHand"     },
    -- Bras gauche
    { "UpperTorso",        "LeftUpperArm"  },
    { "LeftUpperArm",      "LeftLowerArm"  },
    { "LeftLowerArm",      "LeftHand"      },
    -- Jambe droite
    { "LowerTorso",        "RightUpperLeg" },
    { "RightUpperLeg",     "RightLowerLeg" },
    { "RightLowerLeg",     "RightFoot"     },
    -- Jambe gauche
    { "LowerTorso",        "LeftUpperLeg"  },
    { "LeftUpperLeg",      "LeftLowerLeg"  },
    { "LeftLowerLeg",      "LeftFoot"      },
}

-- Fallback pour les R6 (ancienne rig)
local BONE_PAIRS_R6 = {
    { "Head",       "Torso"      },
    { "Torso",      "Left Arm"   },
    { "Torso",      "Right Arm"  },
    { "Left Arm",   "Left Leg"   },
    { "Right Arm",  "Right Leg"  },
    { "Torso",      "Left Leg"   },
    { "Torso",      "Right Leg"  },
}

-- ── Constructeur ─────────────────────────────────────────────
function Skeleton.Create(player)
    local self = setmetatable({}, Skeleton)
    self.Player = player
    self.Lines  = {}  -- Drawing Lines indexées par boneIndex

    -- On alloue les lignes pour les deux rigs (max = R15)
    local maxBones = math.max(#BONE_PAIRS, #BONE_PAIRS_R6)
    for i = 1, maxBones do
        self.Lines[i] = Utils.NewDrawing("Line", {
            Thickness = 1,
            Color     = Color3.new(1, 1, 1),
            Visible   = false,
        })
        -- Outline
        self.Lines[i .. "_out"] = Utils.NewDrawing("Line", {
            Thickness = 3,
            Color     = Color3.new(0, 0, 0),
            Visible   = false,
        })
    end

    return self
end

-- ── Détecter le rig (R6 / R15) ───────────────────────────────
local function detectRig(character)
    if character:FindFirstChild("UpperTorso") then
        return "R15", BONE_PAIRS
    elseif character:FindFirstChild("Torso") then
        return "R6", BONE_PAIRS_R6
    end
    return nil, {}
end

-- ── Mise à jour chaque frame ──────────────────────────────────
function Skeleton:Update(character, cfg)
    cfg = cfg or (Config and Config.Current and Config.Current.Skeleton) or {}

    if cfg.Enabled == false or not character then
        self:Hide()
        return
    end

    local rigType, pairs = detectRig(character)
    if not rigType then
        self:Hide()
        return
    end

    local color     = cfg.Color and
                      Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B)
                      or Color3.new(1, 1, 1)
    local thickness = cfg.Thickness or 1

    -- Désactive toutes les lignes d'abord
    for i = 1, math.max(#BONE_PAIRS, #BONE_PAIRS_R6) do
        if self.Lines[i] then
            self.Lines[i].Visible = false
            self.Lines[i .. "_out"].Visible = false
        end
    end

    -- Dessine uniquement les bones du rig détecté
    for i, pair in ipairs(pairs) do
        local partA = character:FindFirstChild(pair[1])
        local partB = character:FindFirstChild(pair[2])

        if partA and partB then
            local posA, onA = Utils.W2V(partA.Position)
            local posB, onB = Utils.W2V(partB.Position)

            if onA and onB then
                local outline = self.Lines[i .. "_out"]
                local line    = self.Lines[i]

                if outline then
                    outline.From      = posA
                    outline.To        = posB
                    outline.Thickness = thickness + 2
                    outline.Color     = Color3.new(0, 0, 0)
                    outline.Visible   = true
                end

                if line then
                    line.From      = posA
                    line.To        = posB
                    line.Thickness = thickness
                    line.Color     = color
                    line.Visible   = true
                end
            end
        end
    end
end

-- ── Cacher ───────────────────────────────────────────────────
function Skeleton:Hide()
    for _, line in pairs(self.Lines) do
        line.Visible = false
    end
end

-- ── Destruction ──────────────────────────────────────────────
function Skeleton:Remove()
    for _, line in pairs(self.Lines) do
        Utils.RemoveDrawing(line)
    end
    self.Lines = {}
end

return Skeleton
