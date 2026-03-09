-- Aurora — Modules/ESP/Skeleton.lua v2.0
local Skeleton = {}
local Camera = workspace.CurrentCamera

-- R15 uniquement (Da Hood = R15)
local BONES_R15 = {
    {"Head",          "UpperTorso"},
    {"UpperTorso",    "LowerTorso"},
    {"LowerTorso",    "LeftUpperLeg"},
    {"LowerTorso",    "RightUpperLeg"},
    {"LeftUpperLeg",  "LeftLowerLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"LeftLowerLeg",  "LeftFoot"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso",    "LeftUpperArm"},
    {"UpperTorso",    "RightUpperArm"},
    {"LeftUpperArm",  "LeftLowerArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"LeftLowerArm",  "LeftHand"},
    {"RightLowerArm", "RightHand"},
}

-- R6 fallback
local BONES_R6 = {
    {"Head",    "Torso"},
    {"Torso",   "Left Arm"},
    {"Torso",   "Right Arm"},
    {"Torso",   "Left Leg"},
    {"Torso",   "Right Leg"},
}

local MAX = math.max(#BONES_R15, #BONES_R6)

local function newLine()
    local l = Drawing.new("Line")
    l.Visible   = false
    l.Thickness = 1
    l.ZIndex    = 3
    l.Outline   = false
    return l
end

function Skeleton.Create()
    local d = {}
    for i = 1, MAX do d[i] = newLine() end
    return d
end

function Skeleton.Update(d, char, col)
    if not d or not char then
        return
    end

    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and BONES_R15 or BONES_R6
    local color = col or Color3.new(1, 1, 1)

    for i = 1, MAX do
        local line = d[i]
        if not line then break end

        local bone = bones[i]
        if bone then
            local pA = char:FindFirstChild(bone[1])
            local pB = char:FindFirstChild(bone[2])

            if pA and pB then
                local sA, onA = Camera:WorldToViewportPoint(pA.Position)
                local sB, onB = Camera:WorldToViewportPoint(pB.Position)

                if onA and onB then
                    line.From      = Vector2.new(sA.X, sA.Y)
                    line.To        = Vector2.new(sB.X, sB.Y)
                    line.Color     = color
                    line.Thickness = 1
                    line.Visible   = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
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
