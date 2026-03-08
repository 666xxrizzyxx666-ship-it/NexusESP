-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/ESP/Skeleton.lua
--   📁 Dossier : Modules/ESP/
--   Rôle : Skeleton ESP R6 + R15
--          Pas de continue keyword
-- ══════════════════════════════════════════════════════

local Skeleton = {}

local Camera = workspace.CurrentCamera

local R6_BONES = {
    {"Head",             "UpperTorso"},
    {"UpperTorso",       "LowerTorso"},
    {"UpperTorso",       "Left Arm"},
    {"Left Arm",         "Left Leg"},
    {"UpperTorso",       "Right Arm"},
    {"Right Arm",        "Right Leg"},
    {"LowerTorso",       "Left Leg"},
    {"LowerTorso",       "Right Leg"},
}

local R15_BONES = {
    {"Head",             "UpperTorso"},
    {"UpperTorso",       "LowerTorso"},
    {"LowerTorso",       "LeftUpperLeg"},
    {"LowerTorso",       "RightUpperLeg"},
    {"LeftUpperLeg",     "LeftLowerLeg"},
    {"RightUpperLeg",    "RightLowerLeg"},
    {"LeftLowerLeg",     "LeftFoot"},
    {"RightLowerLeg",    "RightFoot"},
    {"UpperTorso",       "LeftUpperArm"},
    {"UpperTorso",       "RightUpperArm"},
    {"LeftUpperArm",     "LeftLowerArm"},
    {"RightUpperArm",    "RightLowerArm"},
    {"LeftLowerArm",     "LeftHand"},
    {"RightLowerArm",    "RightHand"},
}

local function newLine()
    local l = Drawing.new("Line")
    l.Visible  = false
    l.ZIndex   = 3
    l.Outline  = false
    return l
end

function Skeleton.Create()
    local d = {}
    local maxBones = #R15_BONES
    for i = 1, maxBones do
        d[i] = newLine()
    end
    return d
end

function Skeleton.Update(d, char, cfg)
    if not d or not char then return end

    local color = cfg.Color and Color3.fromRGB(cfg.Color.R, cfg.Color.G, cfg.Color.B) or Color3.new(1,1,1)
    local thick = cfg.Thickness or 1

    -- Détecte R6 vs R15
    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and R15_BONES or R6_BONES

    -- R6 : Head = Head, UpperTorso = Torso, LowerTorso = HumanoidRootPart
    -- R15 : direct mapping
    local function getPart(name)
        if not isR15 then
            if name == "UpperTorso" then return char:FindFirstChild("Torso")
            elseif name == "LowerTorso" then return char:FindFirstChild("HumanoidRootPart")
            elseif name == "Left Arm" then return char:FindFirstChild("Left Arm")
            elseif name == "Right Arm" then return char:FindFirstChild("Right Arm")
            elseif name == "Left Leg" then return char:FindFirstChild("Left Leg")
            elseif name == "Right Leg" then return char:FindFirstChild("Right Leg")
            else return char:FindFirstChild(name) end
        end
        return char:FindFirstChild(name)
    end

    for i = 1, #bones do
        local line    = d[i]
        if line then
            local bone    = bones[i]
            local partA   = getPart(bone[1])
            local partB   = getPart(bone[2])

            if partA and partB then
                local screenA, onA = Camera:WorldToViewportPoint(partA.Position)
                local screenB, onB = Camera:WorldToViewportPoint(partB.Position)

                if onA and onB then
                    line.From      = Vector2.new(screenA.X, screenA.Y)
                    line.To        = Vector2.new(screenB.X, screenB.Y)
                    line.Color     = color
                    line.Thickness = thick
                    line.Visible   = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end

    -- Cache les lignes non utilisées
    for i = #bones + 1, #d do
        if d[i] then d[i].Visible = false end
    end
end

function Skeleton.Hide(d)
    if not d then return end
    for i = 1, #d do
        if d[i] then d[i].Visible = false end
    end
end

function Skeleton.Remove(d)
    if not d then return end
    for i = 1, #d do
        if d[i] then pcall(function() d[i]:Remove() end) end
    end
end

return Skeleton
