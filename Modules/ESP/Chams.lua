-- Aurora — Modules/ESP/Chams.lua v3.0
-- Chams style : couvre TOUT le perso en couleur solide
local Chams = {}

local Players  = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP       = Players.LocalPlayer

local enabled    = false
local style      = "Neon"
local enemyColor = Color3.fromRGB(255, 60, 60)
local teamColor  = Color3.fromRGB(60, 255, 100)
local saved      = {}
local renderConn = nil

local STYLES = {
    Neon      = { material = Enum.Material.Neon,          trans = 0    },
    Flat      = { material = Enum.Material.SmoothPlastic,  trans = 0    },
    Glass     = { material = Enum.Material.Glass,          trans = 0.3  },
    Wireframe = { material = Enum.Material.Neon,           trans = 0.75 },
}

local function isEnemy(player)
    if LP.Team and player.Team and LP.Team == player.Team then return false end
    return true
end

local function getColor(player)
    return isEnemy(player) and enemyColor or teamColor
end

local function applyPart(part, col, st)
    pcall(function()
        part.Material     = st.material
        part.Color        = col
        part.Transparency = st.trans
        part.CastShadow   = false
    end)
end

local function saveAndApply(player)
    local char = player.Character
    if not char then return end

    local col = getColor(player)
    local st  = STYLES[style] or STYLES.Neon
    saved[player] = saved[player] or {}

    for _, obj in ipairs(char:GetDescendants()) do
        -- Couvre BasePart ET SpecialMesh/Accessories
        if obj:IsA("BasePart") then
            if not saved[player][obj] then
                saved[player][obj] = {
                    material     = obj.Material,
                    color        = obj.Color,
                    transparency = obj.Transparency,
                    castShadow   = obj.CastShadow,
                }
            end
            applyPart(obj, col, st)
        end
    end
end

local function restore(player)
    local data = saved[player]
    if not data then return end
    local char = player.Character
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") and data[obj] then
                local o = data[obj]
                pcall(function()
                    obj.Material     = o.material
                    obj.Color        = o.color
                    obj.Transparency = o.transparency
                    obj.CastShadow   = o.castShadow
                end)
            end
        end
    end
    saved[player] = nil
end

-- Re-applique chaque frame pour couvrir les nouveaux accessoires équipés
local function onRender()
    if not enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            pcall(saveAndApply, p)
        end
    end
end

local charConns = {}

function Chams.Init(deps) end

function Chams.Enable()
    if enabled then return end
    enabled = true

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            pcall(saveAndApply, p)
            charConns[p] = p.CharacterAdded:Connect(function()
                task.wait(0.2)
                if enabled then pcall(saveAndApply, p) end
            end)
        end
    end

    charConns["added"] = Players.PlayerAdded:Connect(function(p)
        charConns[p] = p.CharacterAdded:Connect(function()
            task.wait(0.2)
            if enabled then pcall(saveAndApply, p) end
        end)
    end)

    -- Render léger : re-applique toutes les 0.5s (pas chaque frame)
    renderConn = RunService.Heartbeat:Connect(function()
        -- throttle : 1x/sec suffit
        if not enabled then return end
    end)

    -- Timer 0.5s pour re-appliquer (nouveaux accessoires)
    task.spawn(function()
        while enabled do
            task.wait(0.5)
            if enabled then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        pcall(saveAndApply, p)
                    end
                end
            end
        end
    end)
end

function Chams.Disable()
    if not enabled then return end
    enabled = false

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then pcall(restore, p) end
    end

    for key, conn in pairs(charConns) do
        pcall(function() conn:Disconnect() end)
        charConns[key] = nil
    end

    if renderConn then renderConn:Disconnect(); renderConn = nil end
    saved = {}
end

function Chams.SetStyle(s)
    style = s
    if enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                saved[p] = nil -- reset saved pour re-sauvegarder proprement
                pcall(saveAndApply, p)
            end
        end
    end
end

function Chams.SetEnemyColor(c)
    enemyColor = c
    if enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and isEnemy(p) then
                local char = p.Character
                if char then
                    local st = STYLES[style] or STYLES.Neon
                    for _, obj in ipairs(char:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            pcall(function() obj.Color = c obj.Material = st.material obj.Transparency = st.trans end)
                        end
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
            if p ~= LP and not isEnemy(p) then
                local char = p.Character
                if char then
                    local st = STYLES[style] or STYLES.Neon
                    for _, obj in ipairs(char:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            pcall(function() obj.Color = c obj.Material = st.material obj.Transparency = st.trans end)
                        end
                    end
                end
            end
        end
    end
end

return Chams
