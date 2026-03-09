-- Aurora — Modules/ESP/Chams.lua v2.0
-- Vrais styles : Neon, Flat, Glass, Wireframe
local Chams = {}

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local enabled    = false
local style      = "Neon"
local enemyColor = Color3.fromRGB(255, 80, 80)
local teamColor  = Color3.fromRGB(80, 255, 120)
local saved      = {}  -- { [player] = { [part] = {mat, col, trans} } }

local STYLES = {
    Neon      = { material = Enum.Material.Neon,       trans = 0 },
    Flat      = { material = Enum.Material.SmoothPlastic, trans = 0 },
    Glass     = { material = Enum.Material.Glass,      trans = 0.4 },
    Wireframe = { material = Enum.Material.Neon,       trans = 0.85 },
}

local function isEnemy(player)
    if LP.Team and player.Team and LP.Team == player.Team then
        return false
    end
    return true
end

local function applyToChar(player)
    local char = player.Character
    if not char then return end

    local col   = isEnemy(player) and enemyColor or teamColor
    local st    = STYLES[style] or STYLES.Neon
    saved[player] = saved[player] or {}

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not saved[player][part] then
                saved[player][part] = {
                    material     = part.Material,
                    color        = part.Color,
                    transparency = part.Transparency,
                    castShadow   = part.CastShadow,
                }
            end
            pcall(function()
                part.Material     = st.material
                part.Color        = col
                part.Transparency = st.trans
                part.CastShadow   = false
            end)
        end
    end
end

local function restoreChar(player)
    local data = saved[player]
    if not data then return end
    local char = player.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and data[part] then
                local o = data[part]
                pcall(function()
                    part.Material     = o.material
                    part.Color        = o.color
                    part.Transparency = o.transparency
                    part.CastShadow   = o.castShadow
                end)
            end
        end
    end
    saved[player] = nil
end

local connections = {}

function Chams.Init(deps) end

function Chams.Enable()
    if enabled then return end
    enabled = true

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            pcall(applyToChar, p)
            connections[p] = p.CharacterAdded:Connect(function()
                task.wait(0.3)
                if enabled then pcall(applyToChar, p) end
            end)
        end
    end

    connections["PlayerAdded"] = Players.PlayerAdded:Connect(function(p)
        if not enabled then return end
        connections[p] = p.CharacterAdded:Connect(function()
            task.wait(0.3)
            if enabled then pcall(applyToChar, p) end
        end)
    end)
end

function Chams.Disable()
    if not enabled then return end
    enabled = false

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then pcall(restoreChar, p) end
    end

    for key, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
        connections[key] = nil
    end
    saved = {}
end

function Chams.SetStyle(s)
    style = s
    if enabled then
        -- Réapplique le style sur tous
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                pcall(restoreChar, p)
                pcall(applyToChar, p)
            end
        end
    end
end

function Chams.SetEnemyColor(c)
    enemyColor = c
    if enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and isEnemy(p) then
                pcall(restoreChar, p)
                pcall(applyToChar, p)
            end
        end
    end
end

function Chams.SetTeamColor(c)
    teamColor = c
    if enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and not isEnemy(p) then
                pcall(restoreChar, p)
                pcall(applyToChar, p)
            end
        end
    end
end

return Chams
