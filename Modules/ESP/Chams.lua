-- Aurora — Chams.lua v3.1
local Chams = {}
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local enabled    = false
local style      = "Neon"
local enemyColor = Color3.fromRGB(255, 60, 60)
local teamColor  = Color3.fromRGB(60, 255, 100)
local originals  = {}  -- [part] = {mat, col, trans, shadow}

local MATS = {
    Neon      = Enum.Material.Neon,
    Flat      = Enum.Material.SmoothPlastic,
    Glass     = Enum.Material.Glass,
    Wireframe = Enum.Material.Neon,
}
local TRANS = {
    Neon=0, Flat=0, Glass=0.35, Wireframe=0.8
}

local function isEnemy(p)
    return not (LP.Team and p.Team and LP.Team == p.Team)
end

local function applyChar(char, col)
    local mat   = MATS[style]   or MATS.Neon
    local trans = TRANS[style]  or 0
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if not originals[p] then
                originals[p] = {
                    mat   = p.Material,
                    col   = p.Color,
                    trans = p.Transparency,
                    shadow= p.CastShadow,
                }
            end
            pcall(function()
                p.Material    = mat
                p.Color       = col
                p.Transparency= trans
                p.CastShadow  = false
            end)
        end
    end
end

local function restoreChar(char)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and originals[p] then
            local o = originals[p]
            pcall(function()
                p.Material    = o.mat
                p.Color       = o.col
                p.Transparency= o.trans
                p.CastShadow  = o.shadow
            end)
            originals[p] = nil
        end
    end
end

local conns = {}

local function hookPlayer(player)
    if player == LP then return end
    if player.Character then
        pcall(applyChar, player.Character, isEnemy(player) and enemyColor or teamColor)
    end
    conns[player] = player.CharacterAdded:Connect(function(char)
        task.wait(0.25)
        if enabled then
            pcall(applyChar, char, isEnemy(player) and enemyColor or teamColor)
        end
    end)
end

function Chams.Init(deps) end

function Chams.Enable()
    if enabled then return end
    enabled = true
    originals = {}
    for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
    conns["pa"] = Players.PlayerAdded:Connect(hookPlayer)
end

function Chams.Disable()
    if not enabled then return end
    enabled = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            pcall(restoreChar, p.Character)
        end
    end
    for k, c in pairs(conns) do
        pcall(function() c:Disconnect() end)
        conns[k] = nil
    end
    originals = {}
end

local function reapplyAll()
    if not enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            -- Reset originals pour ce perso pour forcer re-save
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then originals[part] = nil end
            end
            pcall(applyChar, p.Character, isEnemy(p) and enemyColor or teamColor)
        end
    end
end

function Chams.SetStyle(s)
    style = s
    reapplyAll()
end

function Chams.SetEnemyColor(c)
    enemyColor = c
    if enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and isEnemy(p) then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.Color = c end)
                    end
                end
            end
        end
    end
end

function Chams.SetTeamColor(c)
    teamColor = c
    if enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and not isEnemy(p) then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.Color = c end)
                    end
                end
            end
        end
    end
end

return Chams
