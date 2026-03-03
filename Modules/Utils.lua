-- ============================================================
--  Utils.lua — Module utilitaire global
--  WorldToViewport, math 3D, smoothing, lerp couleur,
--  visibilité (raycast), gestion des Drawing objects
-- ============================================================

local Utils = {}

-- ── Services ─────────────────────────────────────────────────
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")

local LocalPlayer  = Players.LocalPlayer
local Camera       = Workspace.CurrentCamera

-- ── Logger interne ───────────────────────────────────────────
local LOG_PREFIX   = "[ESP Utils] "
local logBuffer    = {}
local MAX_LOGS     = 200

function Utils.Log(msg, level)
    level = level or "INFO"
    local entry = string.format("[%.3f][%s] %s", os.clock(), level, msg)
    table.insert(logBuffer, entry)
    if #logBuffer > MAX_LOGS then
        table.remove(logBuffer, 1)
    end
    if level == "WARN" then
        warn(LOG_PREFIX .. msg)
    elseif level == "ERROR" then
        warn(LOG_PREFIX .. "ERROR: " .. msg)
    end
end

function Utils.GetLogs()
    return logBuffer
end

function Utils.ClearLogs()
    logBuffer = {}
end

-- ── Profiler léger ───────────────────────────────────────────
local profileData = {}

function Utils.ProfileStart(name)
    profileData[name] = os.clock()
end

function Utils.ProfileEnd(name)
    if profileData[name] then
        local elapsed = (os.clock() - profileData[name]) * 1000
        profileData[name] = nil
        return elapsed
    end
    return 0
end

function Utils.GetProfileData()
    return profileData
end

-- ── WorldToViewport ──────────────────────────────────────────
-- Retourne screenPos (Vector2), onScreen (bool), depth (number)
function Utils.WorldToViewport(worldPos)
    local camera = Workspace.CurrentCamera
    local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- Wrapper pratique retournant nil si hors écran
function Utils.W2V(worldPos)
    local pos, onScreen, depth = Utils.WorldToViewport(worldPos)
    if not onScreen or depth <= 0 then
        return nil, false, depth
    end
    return pos, true, depth
end

-- ── Bounding Box 2D depuis un modèle ─────────────────────────
-- Retourne top-left (Vector2), taille (Vector2), center (Vector2)
-- ou nil si aucun point n'est à l'écran
function Utils.GetBoundingBox2D(model)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyVisible = false

    local parts = {}
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            table.insert(parts, v)
        end
    end

    if #parts == 0 then return nil end

    -- On projette les 8 coins de chaque part
    for _, part in ipairs(parts) do
        local cf  = part.CFrame
        local size = part.Size / 2

        local corners = {
            cf * Vector3.new( size.X,  size.Y,  size.Z),
            cf * Vector3.new(-size.X,  size.Y,  size.Z),
            cf * Vector3.new( size.X, -size.Y,  size.Z),
            cf * Vector3.new(-size.X, -size.Y,  size.Z),
            cf * Vector3.new( size.X,  size.Y, -size.Z),
            cf * Vector3.new(-size.X,  size.Y, -size.Z),
            cf * Vector3.new( size.X, -size.Y, -size.Z),
            cf * Vector3.new(-size.X, -size.Y, -size.Z),
        }

        for _, corner in ipairs(corners) do
            local sp, onScreen, depth = Utils.WorldToViewport(corner)
            if onScreen and depth > 0 then
                anyVisible = true
                if sp.X < minX then minX = sp.X end
                if sp.Y < minY then minY = sp.Y end
                if sp.X > maxX then maxX = sp.X end
                if sp.Y > maxY then maxY = sp.Y end
            end
        end
    end

    if not anyVisible then return nil end

    local topLeft = Vector2.new(minX, minY)
    local size2D  = Vector2.new(maxX - minX, maxY - minY)
    local center  = topLeft + size2D / 2

    return topLeft, size2D, center
end

-- ── Distance entre LocalPlayer et une position ───────────────
function Utils.GetDistance(worldPos)
    local char = LocalPlayer.Character
    if not char then return math.huge end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return math.huge end
    return (root.Position - worldPos).Magnitude
end

-- ── Vérification de visibilité (Raycast) ─────────────────────
function Utils.IsVisible(targetPos)
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local origin    = Camera.CFrame.Position
    local direction = targetPos - origin
    local dist      = direction.Magnitude

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { char, Workspace.CurrentCamera }
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction.Unit * dist, params)

    return result == nil
end

-- ── Lerp scalaire ────────────────────────────────────────────
function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

-- ── Lerp couleur ─────────────────────────────────────────────
function Utils.LerpColor(c1, c2, t)
    return Color3.new(
        Utils.Lerp(c1.R, c2.R, t),
        Utils.Lerp(c1.G, c2.G, t),
        Utils.Lerp(c1.B, c2.B, t)
    )
end

-- ── Couleur de santé (vert → rouge) ──────────────────────────
-- health : 0 → 1
function Utils.HealthColor(health)
    health = math.clamp(health, 0, 1)
    return Utils.LerpColor(
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        health
    )
end

-- ── Smoothing exponentiel ────────────────────────────────────
function Utils.Smooth(current, target, dt, speed)
    speed = speed or 10
    return current + (target - current) * math.min(1, dt * speed)
end

-- ── Viewport size ────────────────────────────────────────────
function Utils.GetViewport()
    return Camera.ViewportSize
end

-- ── Centre de l'écran ─────────────────────────────────────────
function Utils.ScreenCenter()
    local vp = Utils.GetViewport()
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

-- ── Obtenir la racine d'un personnage ────────────────────────
function Utils.GetRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- ── Obtenir l'humanoid ───────────────────────────────────────
function Utils.GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

-- ── Pourcentage de santé ─────────────────────────────────────
function Utils.GetHealthPercent(character)
    local hum = Utils.GetHumanoid(character)
    if not hum or hum.MaxHealth <= 0 then return 1 end
    return math.clamp(hum.Health / hum.MaxHealth, 0, 1)
end

-- ── Factory Drawing ──────────────────────────────────────────
-- Crée un Drawing avec des propriétés par défaut saines
function Utils.NewDrawing(drawType, props)
    local d = Drawing.new(drawType)
    d.Visible = false
    if props then
        for k, v in pairs(props) do
            d[k] = v
        end
    end
    return d
end

-- ── Suppression sécurisée d'un Drawing ───────────────────────
function Utils.RemoveDrawing(d)
    if d then
        pcall(function() d:Remove() end)
    end
end

-- ── Suppression d'une table de Drawings ──────────────────────
function Utils.ClearDrawings(tbl)
    if not tbl then return end
    for k, d in pairs(tbl) do
        Utils.RemoveDrawing(d)
        tbl[k] = nil
    end
end

-- ── Vérifier si un joueur est dans la même équipe ────────────
function Utils.SameTeam(player)
    local lp = Players.LocalPlayer
    if not lp or not player then return false end
    return lp.Team ~= nil and lp.Team == player.Team
end

-- ── Truncature de string ─────────────────────────────────────
function Utils.Truncate(str, maxLen)
    if #str > maxLen then
        return str:sub(1, maxLen) .. "…"
    end
    return str
end

-- ── Format distance ──────────────────────────────────────────
function Utils.FormatDistance(studs, fmt)
    fmt = fmt or "{dist}m"
    local meters = math.floor(studs * 0.28)
    return fmt:gsub("{dist}", tostring(math.floor(studs)))
              :gsub("{m}", tostring(meters))
end

-- ── Obtenir la position Top/Center d'un character ────────────
function Utils.GetCharTop(character)
    local head = character and character:FindFirstChild("Head")
    if head then
        return head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0)
    end
    local root = Utils.GetRoot(character)
    if root then
        return root.Position + Vector3.new(0, 3, 0)
    end
    return nil
end

function Utils.GetCharBottom(character)
    local root = Utils.GetRoot(character)
    if root then
        return root.Position - Vector3.new(0, 3, 0)
    end
    return nil
end

return Utils
