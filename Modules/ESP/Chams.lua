-- Aurora v3.2.0 — Modules/ESP/Chams.lua
local Chams = {}
local Players    = game:GetService("Players")
local LP         = Players.LocalPlayer
local enabled    = false
local chamData   = {}
local COLOR_TEAM = Color3.fromRGB(74,222,128)
local COLOR_ENEMY= Color3.fromRGB(248,113,113)

local function getTeam(player)
    local ok,r = pcall(function() return player.Team end)
    return ok and r or nil
end

local function applyChams(player)
    local char = player.Character
    if not char then return end
    chamData[player] = chamData[player] or {}
    local isEnemy = getTeam(player) ~= getTeam(LP)
    local col = isEnemy and COLOR_ENEMY or COLOR_TEAM

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            -- Sauvegarde l'original
            if not chamData[player][part] then
                chamData[player][part] = {
                    material = part.Material,
                    color    = part.BrickColor,
                    trans    = part.Transparency,
                    castShadow = part.CastShadow,
                }
            end
            part.Material    = Enum.Material.Neon
            part.BrickColor  = BrickColor.new(col)
            part.Transparency = 0.35
            part.CastShadow  = false
        end
    end
end

local function removeChams(player)
    local data = chamData[player]
    if not data then return end
    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and data[part] then
                local orig = data[part]
                pcall(function()
                    part.Material    = orig.material
                    part.BrickColor  = orig.color
                    part.Transparency = orig.trans
                    part.CastShadow  = orig.castShadow
                end)
            end
        end
    end
    chamData[player] = nil
end

function Chams.Init(deps) end

function Chams.Enable()
    if enabled then return end
    enabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            pcall(applyChams, p)
            p.CharacterAdded:Connect(function()
                task.wait(0.5)
                if enabled then pcall(applyChams, p) end
            end)
        end
    end
    Players.PlayerAdded:Connect(function(p)
        if not enabled then return end
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if enabled then pcall(applyChams, p) end
        end)
    end)
end

function Chams.Disable()
    if not enabled then return end
    enabled = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then pcall(removeChams, p) end
    end
end

function Chams.Toggle()
    if enabled then Chams.Disable() else Chams.Enable() end
end

function Chams.SetColor(isTeam, col)
    if isTeam then COLOR_TEAM = col else COLOR_ENEMY = col end
    if enabled then
        Chams.Disable(); task.wait(0.05); Chams.Enable()
    end
end

function Chams.IsEnabled() return enabled end
return Chams
