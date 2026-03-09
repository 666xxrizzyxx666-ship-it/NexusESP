-- ══════════════════════════════════════════════════════
--   Aurora — Modules/ESP/ESP.lua  v2.0
--   State interne propre, pas de Config dépendance
-- ══════════════════════════════════════════════════════

local ESP = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

-- ── State interne ─────────────────────────────────────
local opt = {
    Enabled      = false,
    Box          = false,
    BoxStyle     = "2D Normal",
    Skeleton     = false,
    SkeletonHP   = true,   -- couleur skeleton par HP
    Tracers      = false,
    TracerStyle  = "Ligne",
    Name         = false,
    Weapon       = false,
    Distance     = false,
    Health       = false,
    HealthPos    = "Gauche",
    TeamCheck    = false,
    WallCheck    = false,
    FOVCircle    = false,
    FOVRadius    = 120,
    MaxDist      = 500,
    EnemyColor   = Color3.fromRGB(255, 80, 80),
    TeamColor    = Color3.fromRGB(80, 255, 120),
    BoxColor     = Color3.fromRGB(255, 255, 255),
    TracerColor  = Color3.fromRGB(255, 255, 255),
}

-- ── FOV Circle (géré par ESP) ─────────────────────────
local fovLines   = {}
local FOV_SEG    = 64
local FOV_RADIUS = 120

local function buildFOV()
    for i = 1, FOV_SEG do
        local l = Drawing.new("Line")
        l.Visible   = false
        l.Thickness = 1
        l.ZIndex    = 6
        l.Outline   = false
        l.Color     = Color3.fromRGB(255, 255, 255)
        fovLines[i] = l
    end
end

local function renderFOV()
    local cam = workspace.CurrentCamera
    local cx = cam.ViewportSize.X / 2
    local cy = cam.ViewportSize.Y / 2
    local r   = opt.FOVRadius or 120
    local show = opt.FOVCircle
    for i = 1, FOV_SEG do
        local l = fovLines[i]
        if not l then break end
        if show then
            local a1 = (i-1)/FOV_SEG * math.pi*2
            local a2 = i    /FOV_SEG * math.pi*2
            l.From    = Vector2.new(cx + math.cos(a1)*r, cy + math.sin(a1)*r)
            l.To      = Vector2.new(cx + math.cos(a2)*r, cy + math.sin(a2)*r)
            l.Visible = true
        else
            l.Visible = false
        end
    end
end

local playerData = {}
local renderConn = nil
local Utils      = nil

-- ── Submodules chargés par ESP.Init ───────────────────
local M = {}

-- ── Helpers ───────────────────────────────────────────
local function getTeamColor(player)
    if opt.TeamCheck and LP.Team and player.Team and LP.Team == player.Team then
        return opt.TeamColor
    end
    return opt.EnemyColor
end

local function isOnScreen(pos)
    local _, onScreen = Camera:WorldToViewportPoint(pos)
    return onScreen
end

local function getBB(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not root or not head then return nil end

    local headScrn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y/2, 0))
    local feetScrn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

    local h = math.abs(headScrn.Y - feetScrn.Y)
    if h < 5 then return nil end
    local w  = h * 0.55
    local cx = (headScrn.X + feetScrn.X) / 2

    return {
        x      = cx - w/2,
        y      = headScrn.Y,
        width  = w,
        height = h,
        cx     = cx,
        cy     = headScrn.Y + h/2,
    }
end

-- ── Init ──────────────────────────────────────────────
function ESP.Init(deps)
    Utils = deps and deps.Utils or Utils
    buildFOV()

    local REPO = "https://raw.githubusercontent.com/666xxrizzyxx666-ship-it/NexusESP/refs/heads/main/"
    local function load(p)
        local ok, r = pcall(function()
            return loadstring(game:HttpGet(REPO..p, true))()
        end)
        return ok and r or nil
    end

    M.Box       = load("Modules/ESP/Box.lua")
    M.CornerBox = load("Modules/ESP/CornerBox.lua")
    M.Skeleton  = load("Modules/ESP/Skeleton.lua")
    M.Tracers   = load("Modules/ESP/Tracers.lua")
    M.Health    = load("Modules/ESP/Health.lua")
    M.Name      = load("Modules/ESP/Name.lua")
    M.Distance  = load("Modules/ESP/Distance.lua")

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then ESP._addPlayer(p) end
    end
    Players.PlayerAdded:Connect(function(p)
        if p ~= LP then ESP._addPlayer(p) end
    end)
    Players.PlayerRemoving:Connect(function(p)
        ESP._removePlayer(p)
    end)
end

-- ── Gestion joueurs ───────────────────────────────────
function ESP._addPlayer(player)
    if playerData[player] then return end
    playerData[player] = { drawings = {} }

    local function onChar(char)
        task.wait(0.1)
        ESP._setupChar(player, char)
    end

    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
    player.CharacterRemoving:Connect(function()
        ESP._clearDrawings(player)
    end)
end

function ESP._setupChar(player, char)
    ESP._clearDrawings(player)
    local d = playerData[player]
    if not d then return end
    d.char = char

    if M.Box       then d.drawings.box      = M.Box.Create()      end
    if M.CornerBox then d.drawings.corner   = M.CornerBox.Create() end
    if M.Skeleton  then d.drawings.skeleton = M.Skeleton.Create()  end
    if M.Tracers   then d.drawings.tracers  = M.Tracers.Create()   end
    if M.Health    then d.drawings.health   = M.Health.Create()    end
    if M.Name      then d.drawings.name     = M.Name.Create()      end
    if M.Distance  then d.drawings.distance = M.Distance.Create()  end
end

function ESP._clearDrawings(player)
    local d = playerData[player]
    if not d then return end
    for key, dr in pairs(d.drawings) do
        local mod = M[key:sub(1,1):upper()..key:sub(2)]
        if mod and mod.Remove then pcall(mod.Remove, dr) end
    end
    d.drawings = {}
    d.char = nil
end

function ESP._removePlayer(player)
    ESP._clearDrawings(player)
    playerData[player] = nil
end

function ESP._hidePlayerDrawings(d)
    if not d then return end
    if M.Box      and d.drawings.box      then pcall(M.Box.Hide,      d.drawings.box)      end
    if M.CornerBox and d.drawings.corner  then pcall(M.CornerBox.Hide, d.drawings.corner)   end
    if M.Skeleton and d.drawings.skeleton then pcall(M.Skeleton.Hide, d.drawings.skeleton)  end
    if M.Tracers  and d.drawings.tracers  then pcall(M.Tracers.Hide,  d.drawings.tracers)   end
    if M.Health   and d.drawings.health   then pcall(M.Health.Hide,   d.drawings.health)    end
    if M.Name     and d.drawings.name     then pcall(M.Name.Hide,     d.drawings.name)      end
    if M.Distance and d.drawings.distance then pcall(M.Distance.Hide, d.drawings.distance)  end
end

-- ── Render ────────────────────────────────────────────
function ESP._render()
    renderFOV()
    for player, d in pairs(playerData) do
        if not player or not player.Parent then
            ESP._removePlayer(player)
        else
            local char = d.char or player.Character
            if not char then
                ESP._hidePlayerDrawings(d)
            else
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum  = char:FindFirstChildOfClass("Humanoid")

                -- Vérifications
                local alive = hum and hum.Health > 0
                local rootPos = root and root.Position or Vector3.new()
                local onScreen = isOnScreen(rootPos)
                local dist = root and (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
                    and math.floor((rootPos - LP.Character.HumanoidRootPart.Position).Magnitude)
                    or 9999

                -- Team check
                local sameTeam = opt.TeamCheck
                    and LP.Team ~= nil
                    and player.Team ~= nil
                    and LP.Team == player.Team

                -- Wall check — raycast simple vers HumanoidRootPart
                local visible = true
                if opt.WallCheck and root then
                    local ok, result = pcall(function()
                        local origin = Camera.CFrame.Position
                        local dir    = rootPos - origin
                        local params = RaycastParams.new()
                        params.FilterDescendantsInstances = {LP.Character, char}
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        return workspace:Raycast(origin, dir, params)
                    end)
                    -- nil = rien entre camera et joueur = visible
                    -- non-nil = un mur bloque
                    visible = ok and (result == nil)
                end

                local show = opt.Enabled and alive and onScreen
                    and dist <= opt.MaxDist
                    and not sameTeam
                    and visible

                if show then
                    local bb = getBB(char)
                    if not bb then
                        ESP._hidePlayerDrawings(d)
                    else
                        local col = getTeamColor(player)

                        -- Arme tenue par le joueur
                        local weaponName = ""
                        if opt.Weapon then
                            local tool = char:FindFirstChildOfClass("Tool")
                            weaponName = tool and tool.Name or ""
                        end

                        -- Box
                        if M.Box and d.drawings.box then
                            if opt.Box and opt.BoxStyle == "2D Normal" then
                                M.Box.Update(d.drawings.box, bb, col, opt.BoxColor, dist)
                            else
                                M.Box.Hide(d.drawings.box)
                            end
                        end

                        -- CornerBox
                        if M.CornerBox and d.drawings.corner then
                            if opt.Box and opt.BoxStyle == "Corner Box" then
                                M.CornerBox.Update(d.drawings.corner, bb, col, opt.BoxColor, dist)
                            else
                                M.CornerBox.Hide(d.drawings.corner)
                            end
                        end

                        -- Skeleton (couleur HP si option activée)
                        if M.Skeleton and d.drawings.skeleton then
                            if opt.Skeleton then
                                M.Skeleton.Update(d.drawings.skeleton, char, col, opt.SkeletonHP)
                            else
                                M.Skeleton.Hide(d.drawings.skeleton)
                            end
                        end

                        -- Tracers avec style
                        if M.Tracers and d.drawings.tracers then
                            if opt.Tracers then
                                M.Tracers.Update(d.drawings.tracers, bb, opt.TracerColor, opt.TracerStyle)
                            else
                                M.Tracers.Hide(d.drawings.tracers)
                            end
                        end

                        -- Health
                        if M.Health and d.drawings.health then
                            if opt.Health then
                                local hp, maxHp = hum.Health, hum.MaxHealth
                                M.Health.Update(d.drawings.health, bb, hp, maxHp, opt.HealthPos)
                            else
                                M.Health.Hide(d.drawings.health)
                            end
                        end

                        -- Name + arme
                        if M.Name and d.drawings.name then
                            if opt.Name then
                                M.Name.Update(d.drawings.name, bb, player.Name, col, weaponName)
                            else
                                M.Name.Hide(d.drawings.name)
                            end
                        end

                        -- Distance
                        if M.Distance and d.drawings.distance then
                            if opt.Distance then
                                M.Distance.Update(d.drawings.distance, bb, dist)
                            else
                                M.Distance.Hide(d.drawings.distance)
                            end
                        end
                    end
                else
                    ESP._hidePlayerDrawings(d)
                end
            end
        end
    end
end

-- ── API publique ──────────────────────────────────────
function ESP.Enable()
    opt.Enabled = true
    if not renderConn then
        renderConn = RunService.RenderStepped:Connect(ESP._render)
    end
end

function ESP.Disable()
    opt.Enabled = false
    for _, d in pairs(playerData) do
        ESP._hidePlayerDrawings(d)
    end
    -- Garde le renderConn si FOV circle actif
    if not opt.FOVCircle and renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
end

function ESP.HideAll()
    for _, d in pairs(playerData) do
        ESP._hidePlayerDrawings(d)
    end
end

function ESP.IsEnabled() return opt.Enabled end

function ESP.SetOption(key, value)
    opt[key] = value
    -- FOV circle : démarre/arrête le render si nécessaire
    if key == "FOVCircle" then
        if value and not renderConn then
            renderConn = RunService.RenderStepped:Connect(ESP._render)
        elseif not value and not opt.Enabled and renderConn then
            renderConn:Disconnect()
            renderConn = nil
        end
    end
end

function ESP.GetOption(key)
    return opt[key]
end

return ESP
