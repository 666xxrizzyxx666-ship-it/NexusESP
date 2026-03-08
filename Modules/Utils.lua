-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Modules/Utils.lua
--   📁 Dossier : Modules/
--   Rôle : Fonctions utilitaires partagées par tous
-- ══════════════════════════════════════════════════════

local Utils = {}

local Camera   = workspace.CurrentCamera
local Players  = game:GetService("Players")
local LP       = Players.LocalPlayer

-- ── Caractère local ───────────────────────────────────
function Utils.GetCharacter()
    return LP and LP.Character
end

function Utils.GetRootPart(char)
    char = char or Utils.GetCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function Utils.GetHumanoid(char)
    char = char or Utils.GetCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ── World → Screen ────────────────────────────────────
function Utils.WorldToScreen(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

-- ── Distance ──────────────────────────────────────────
function Utils.GetDistance(pos)
    local root = Utils.GetRootPart()
    if not root then return 0 end
    return math.floor((root.Position - pos).Magnitude)
end

-- ── Bounding box ──────────────────────────────────────
function Utils.GetBoundingBox(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local head = char:FindFirstChild("Head")
    if not head then return nil end

    local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y/2 + 0.1, 0))
    local feetPos, feetOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.1, 0))

    if not headOn and not feetOn then return nil end

    local height = math.abs(headPos.Y - feetPos.Y)
    local width  = height * 0.45
    local cx     = (headPos.X + feetPos.X) / 2

    return {
        x      = cx - width/2,
        y      = headPos.Y,
        width  = width,
        height = height,
        cx     = cx,
        cy     = (headPos.Y + feetPos.Y) / 2,
    }
end

-- ── Visibilité ────────────────────────────────────────
function Utils.IsVisible(part)
    if not part then return false end
    local origin = Camera.CFrame.Position
    local dir    = (part.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = Utils.GetCharacter()
    local exclude = {workspace.CurrentCamera}
    if char then table.insert(exclude, char) end
    params.FilterDescendantsInstances = exclude

    local result = workspace:Raycast(origin, dir, params)
    if not result then return true end

    local hit = result.Instance
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    return player ~= nil
end

-- ── Team check ────────────────────────────────────────
function Utils.IsSameTeam(player)
    if not player then return false end
    if not LP.Team or not player.Team then return false end
    return LP.Team == player.Team
end

-- ── Santé ─────────────────────────────────────────────
function Utils.GetHealth(char)
    local hum = Utils.GetHumanoid(char)
    if not hum then return 0, 100 end
    return hum.Health, hum.MaxHealth
end

function Utils.GetHealthPct(char)
    local hp, max = Utils.GetHealth(char)
    if max == 0 then return 0 end
    return hp / max
end

-- ── Health color ──────────────────────────────────────
function Utils.GetHealthColor(pct)
    if pct > 0.6 then
        return Color3.fromRGB(74,222,128)
    elseif pct > 0.3 then
        return Color3.fromRGB(251,191,36)
    else
        return Color3.fromRGB(248,113,113)
    end
end

-- ── Arme ──────────────────────────────────────────────
function Utils.GetWeapon(char)
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

-- ── Ping ──────────────────────────────────────────────
function Utils.GetPing()
    local ok, ping = pcall(function()
        return math.floor(LP:GetNetworkPing() * 1000)
    end)
    return ok and ping or 0
end

-- ── Angle de vision ───────────────────────────────────
function Utils.GetAngleFromCenter(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    if not onScreen then return 9999 end
    local center = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )
    return (Vector2.new(screen.X, screen.Y) - center).Magnitude
end

-- ── Direction regard ──────────────────────────────────
function Utils.GetLookDirection(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    return root.CFrame.LookVector
end

-- ── Prédiction position ───────────────────────────────
function Utils.PredictPosition(part, ping, multiplier)
    if not part then return nil end
    multiplier = multiplier or 1
    local vel = part.AssemblyLinearVelocity
    local pred = part.Position + vel * (ping/1000) * multiplier
    return pred
end

-- ── Is player alive ───────────────────────────────────
function Utils.IsAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- ── Get bone position ─────────────────────────────────
function Utils.GetBone(char, bone)
    if not char then return nil end
    local part = char:FindFirstChild(bone)
    if part then return part.Position end
    -- Fallback
    local root = char:FindFirstChild("HumanoidRootPart")
    return root and root.Position or nil
end

-- ── Format nombre ─────────────────────────────────────
function Utils.FormatNum(n)
    if n >= 1000 then
        return string.format("%.1fk", n/1000)
    end
    return tostring(math.floor(n))
end

-- ── Clamp color ───────────────────────────────────────
function Utils.LerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

return Utils
