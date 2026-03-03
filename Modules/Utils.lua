local Utils = {}
local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer

-- ── Logs ──────────────────────────────────────────────────────
local logs   = {}
local MAX_LOG = 300
function Utils.Log(msg, level)
    level = level or "INFO"
    local e = string.format("[%.3f][%s] %s", os.clock(), level, msg)
    table.insert(logs, e)
    if #logs > MAX_LOG then table.remove(logs, 1) end
    if level ~= "INFO" then warn("[ESP] " .. msg) end
end
function Utils.GetLogs()  return logs end
function Utils.ClearLogs() logs = {} end

-- ── Profiler ──────────────────────────────────────────────────
local pdata = {}
function Utils.ProfileStart(n) pdata[n] = os.clock() end
function Utils.ProfileEnd(n)
    if pdata[n] then local e=(os.clock()-pdata[n])*1000; pdata[n]=nil; return e end; return 0
end

-- ── WorldToViewport ───────────────────────────────────────────
function Utils.WorldToViewport(p)
    local sp, on = Workspace.CurrentCamera:WorldToViewportPoint(p)
    return Vector2.new(sp.X, sp.Y), on, sp.Z
end
function Utils.W2V(p)
    local sp, on, d = Utils.WorldToViewport(p)
    if not on or d <= 0 then return nil, false, d end
    return sp, true, d
end

-- ── Bounding Box 2D ───────────────────────────────────────────
function Utils.GetBoundingBox2D(model)
    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local any = false
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            local cf, s = v.CFrame, v.Size/2
            for _, off in ipairs({
                Vector3.new( s.X, s.Y, s.Z), Vector3.new(-s.X, s.Y, s.Z),
                Vector3.new( s.X,-s.Y, s.Z), Vector3.new(-s.X,-s.Y, s.Z),
                Vector3.new( s.X, s.Y,-s.Z), Vector3.new(-s.X, s.Y,-s.Z),
                Vector3.new( s.X,-s.Y,-s.Z), Vector3.new(-s.X,-s.Y,-s.Z),
            }) do
                local sp, on, d = Utils.WorldToViewport(cf * off)
                if on and d > 0 then
                    any = true
                    if sp.X < minX then minX = sp.X end
                    if sp.Y < minY then minY = sp.Y end
                    if sp.X > maxX then maxX = sp.X end
                    if sp.Y > maxY then maxY = sp.Y end
                end
            end
        end
    end
    if not any then return nil end
    local tl = Vector2.new(minX, minY)
    local sz = Vector2.new(maxX-minX, maxY-minY)
    return tl, sz, tl + sz/2
end

-- ── Distance ─────────────────────────────────────────────────
function Utils.GetDistance(p)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return math.huge end
    return (root.Position - p).Magnitude
end

-- ── Visibilité ────────────────────────────────────────────────
function Utils.IsVisible(targetPos)
    local char = LP.Character
    if not char then return false end
    local origin = Workspace.CurrentCamera.CFrame.Position
    local dir    = targetPos - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { char }
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local res = Workspace:Raycast(origin, dir.Unit * dir.Magnitude, params)
    return res == nil
end

-- ── Math ──────────────────────────────────────────────────────
function Utils.Lerp(a,b,t)    return a + (b-a)*t end
function Utils.LerpColor(c1,c2,t)
    return Color3.new(Utils.Lerp(c1.R,c2.R,t), Utils.Lerp(c1.G,c2.G,t), Utils.Lerp(c1.B,c2.B,t))
end
function Utils.HealthColor(hp)
    hp = math.clamp(hp, 0, 1)
    return Utils.LerpColor(Color3.fromRGB(220,40,40), Color3.fromRGB(40,220,80), hp)
end
function Utils.GetViewport()   return Workspace.CurrentCamera.ViewportSize end
function Utils.ScreenCenter()  local v=Utils.GetViewport(); return Vector2.new(v.X/2, v.Y/2) end

-- ── Character helpers ─────────────────────────────────────────
function Utils.GetRoot(char)     return char and char:FindFirstChild("HumanoidRootPart") end
function Utils.GetHumanoid(char) return char and char:FindFirstChildOfClass("Humanoid") end
function Utils.GetHealthPercent(char)
    local h = Utils.GetHumanoid(char)
    if not h or h.MaxHealth <= 0 then return 1 end
    return math.clamp(h.Health / h.MaxHealth, 0, 1)
end
function Utils.GetCharTop(char)
    local head = char and char:FindFirstChild("Head")
    if head then return head.Position + Vector3.new(0, head.Size.Y/2+0.1, 0) end
    local root = Utils.GetRoot(char)
    if root then return root.Position + Vector3.new(0,3,0) end
end
function Utils.GetCharBottom(char)
    local root = Utils.GetRoot(char)
    return root and root.Position - Vector3.new(0,3,0)
end

-- ── Drawing ───────────────────────────────────────────────────
function Utils.NewDrawing(t, props)
    local d = Drawing.new(t)
    d.Visible = false
    if props then for k,v in pairs(props) do pcall(function() d[k]=v end) end end
    return d
end
function Utils.RemoveDrawing(d) if d then pcall(function() d:Remove() end) end end
function Utils.ClearDrawings(tbl)
    if not tbl then return end
    for k,d in pairs(tbl) do Utils.RemoveDrawing(d); tbl[k]=nil end
end

-- ── Misc ──────────────────────────────────────────────────────
function Utils.SameTeam(player)
    return LP.Team ~= nil and LP.Team == player.Team
end
function Utils.Truncate(s, n)
    return #s > n and s:sub(1,n).."…" or s
end
function Utils.FormatDistance(studs, fmt)
    fmt = fmt or "{dist}m"
    return fmt:gsub("{dist}", tostring(math.floor(studs)))
              :gsub("{m}",    tostring(math.floor(studs*0.28)))
end

return Utils
