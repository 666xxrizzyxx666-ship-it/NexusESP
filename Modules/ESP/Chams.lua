-- Aurora — Chams.lua v3.1 — stable, pas de scintillement
local Chams = {}

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local enabled    = false
local style      = "Neon"
local enemyColor = Color3.fromRGB(255, 60, 60)
local teamColor  = Color3.fromRGB(60, 255, 100)
local saved      = {}   -- [player][part] = original data
local applied    = {}   -- [player] = true si déjà appliqué

local STYLES = {
    Neon      = { material = Enum.Material.Neon,           trans = 0    },
    Flat      = { material = Enum.Material.SmoothPlastic,  trans = 0    },
    Glass     = { material = Enum.Material.Glass,          trans = 0.3  },
    Wireframe = { material = Enum.Material.Neon,           trans = 0.8  },
}

local function isEnemy(player)
    if LP.Team and player.Team and LP.Team == player.Team then return false end
    return true
end

local function applyToPlayer(player)
    local char = player.Character
    if not char then return end
    local col = isEnemy(player) and enemyColor or teamColor
    local st  = STYLES[style] or STYLES.Neon
    saved[player] = saved[player] or {}

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Sauvegarde UNE SEULE FOIS
            if not saved[player][part] then
                saved[player][part] = {
                    material = part.Material,
                    color    = part.Color,
                    trans    = part.Transparency,
                    shadow   = part.CastShadow,
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
    applied[player] = true
end

local function restorePlayer(player)
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
                    part.Transparency = o.trans
                    part.CastShadow   = o.shadow
                end)
            end
        end
    end
    saved[player]   = nil
    applied[player] = nil
end

local charConns = {}

function Chams.Init(deps) end

function Chams.Enable()
    if enabled then return end
    enabled = true

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            pcall(applyToPlayer, p)
            -- Re-applique uniquement à chaque nouveau perso
            charConns[p] = p.CharacterAdded:Connect(function()
                task.wait(0.5)
                saved[p]   = nil
                applied[p] = nil
                if enabled then pcall(applyToPlayer, p) end
            end)
        end
    end

    charConns["added"] = Players.PlayerAdded:Connect(function(p)
        charConns[p] = p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if enabled then pcall(applyToPlayer, p) end
        end)
    end)
end

function Chams.Disable()
    if not enabled then return end
    enabled = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then pcall(restorePlayer, p) end
    end
    for k, c in pairs(charConns) do
        pcall(function() c:Disconnect() end)
        charConns[k] = nil
    end
    saved = {}; applied = {}
end

function Chams.SetStyle(s)
    style = s
    if not enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            saved[p]   = nil
            applied[p] = nil
            pcall(applyToPlayer, p)
        end
    end
end

function Chams.SetEnemyColor(c)
    enemyColor = c
    if not enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isEnemy(p) then
            saved[p] = nil; applied[p] = nil
            pcall(applyToPlayer, p)
        end
    end
end

function Chams.SetTeamColor(c)
    teamColor = c
    if not enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and not isEnemy(p) then
            saved[p] = nil; applied[p] = nil
            pcall(applyToPlayer, p)
        end
    end
end

return Chams
