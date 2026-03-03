-- ============================================================
--  Skeleton.lua — CORRIGE : outlines EN PREMIER (derriere)
--  lignes colorees EN SECOND (devant) → bones visibles
-- ============================================================
local Skeleton = {}
Skeleton.__index = Skeleton

local Utils, Config

function Skeleton.SetDependencies(u, c) Utils = u; Config = c end

local BONES_R15 = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"},  {"LeftUpperArm","LeftLowerArm"},   {"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"},  {"LeftUpperLeg","LeftLowerLeg"},   {"LeftLowerLeg","LeftFoot"},
}

local BONES_R6 = {
    {"Head","Torso"},
    {"Torso","Right Arm"}, {"Right Arm","Right Leg"},
    {"Torso","Left Arm"},  {"Left Arm","Left Leg"},
    {"Torso","Right Leg"}, {"Torso","Left Leg"},
}

local MAX = math.max(#BONES_R15, #BONES_R6)

function Skeleton.Create(player)
    local self = setmetatable({}, Skeleton)
    self.Player = player
    self.Out = {}   -- outlines
    self.Col = {}   -- lignes colorees

    -- OUTLINES EN PREMIER (rendus derriere)
    for i = 1, MAX do
        self.Out[i] = Utils.NewDrawing("Line", { Thickness=3, Color=Color3.new(0,0,0), Visible=false })
    end
    -- LIGNES COLOREES EN SECOND (rendus devant)
    for i = 1, MAX do
        self.Col[i] = Utils.NewDrawing("Line", { Thickness=1, Color=Color3.new(1,1,1), Visible=false })
    end

    return self
end

local function getRig(char)
    if char:FindFirstChild("UpperTorso") then return "R15", BONES_R15 end
    if char:FindFirstChild("Torso")      then return "R6",  BONES_R6  end
    return nil, {}
end

function Skeleton:Update(character, cfg)
    cfg = cfg or {}
    if not cfg.Enabled or not character then self:Hide(); return end

    local _, bones = getRig(character)
    if not bones or #bones == 0 then self:Hide(); return end

    local c   = cfg.Color
    local col = Color3.fromRGB(c and c.R or 255, c and c.G or 255, c and c.B or 255)
    local th  = math.max(1, cfg.Thickness or 1)

    -- reset tous
    for i = 1, MAX do
        self.Out[i].Visible = false
        self.Col[i].Visible = false
    end

    for i, pair in ipairs(bones) do
        local pA = character:FindFirstChild(pair[1])
        local pB = character:FindFirstChild(pair[2])
        if pA and pB then
            local sA, onA = Utils.W2V(pA.Position)
            local sB, onB = Utils.W2V(pB.Position)
            if onA and onB then
                self.Out[i].From = sA; self.Out[i].To = sB
                self.Out[i].Thickness = th + 2
                self.Out[i].Visible = true

                self.Col[i].From = sA; self.Col[i].To = sB
                self.Col[i].Thickness = th
                self.Col[i].Color = col
                self.Col[i].Visible = true
            end
        end
    end
end

function Skeleton:Hide()
    for i = 1, MAX do
        self.Out[i].Visible = false
        self.Col[i].Visible = false
    end
end

function Skeleton:Remove()
    for i = 1, MAX do
        Utils.RemoveDrawing(self.Out[i])
        Utils.RemoveDrawing(self.Col[i])
    end
    self.Out = {}
    self.Col = {}
end

return Skeleton
