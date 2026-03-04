local Skeleton = {}; Skeleton.__index = Skeleton
local Utils, Config
function Skeleton.SetDependencies(u,c) Utils=u; Config=c end

local R15 = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
}
local R6 = {
    {"Head","Torso"},
    {"Torso","Right Arm"},{"Right Arm","Right Leg"},
    {"Torso","Left Arm"}, {"Left Arm","Left Leg"},
    {"Torso","Right Leg"},{"Torso","Left Leg"},
}
local MAX = math.max(#R15,#R6)

function Skeleton.Create()
    local s = setmetatable({}, Skeleton)
    s.Lines = {}
    for i=1,MAX do
        s.Lines[i] = Utils.NewDrawing("Line", {Thickness=1, Color=Color3.new(1,1,1)})
    end
    return s
end

local function rig(char)
    if char:FindFirstChild("UpperTorso") then return R15 end
    if char:FindFirstChild("Torso")      then return R6  end
end

function Skeleton:Update(char, cfg)
    for i=1,MAX do self.Lines[i].Visible=false end
    if not cfg or not cfg.Enabled or not char then return end
    local bones = rig(char)
    if not bones then return end
    local col = Utils.C3(cfg.Color)
    local th  = math.max(1, cfg.Thickness or 1)
    for i, pair in ipairs(bones) do
        local pA = char:FindFirstChild(pair[1])
        local pB = char:FindFirstChild(pair[2])
        if pA and pB then
            local sA, onA = Utils.W2V(pA.Position)
            local sB, onB = Utils.W2V(pB.Position)
            if onA and onB then
                self.Lines[i].From=sA; self.Lines[i].To=sB
                self.Lines[i].Color=col; self.Lines[i].Thickness=th
                self.Lines[i].Visible=true
            end
        end
    end
end

function Skeleton:Hide() for i=1,MAX do self.Lines[i].Visible=false end end
function Skeleton:Remove() for i=1,MAX do Utils.Kill(self.Lines[i]) end end
return Skeleton
