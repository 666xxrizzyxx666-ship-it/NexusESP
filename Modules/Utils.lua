local Utils = {}
local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP        = Players.LocalPlayer

-- Logs
local logs = {}
function Utils.Log(msg, lv)
    lv = lv or "INFO"
    table.insert(logs, string.format("[%.3f][%s] %s", os.clock(), lv, msg))
    if #logs > 300 then table.remove(logs, 1) end
end
function Utils.GetLogs()   return logs end
function Utils.ClearLogs() logs = {}   end

-- Profiler
local pd = {}
function Utils.ProfileStart(n) pd[n] = os.clock() end
function Utils.ProfileEnd(n)
    if not pd[n] then return 0 end
    local e = (os.clock()-pd[n])*1000; pd[n]=nil; return e
end

-- WorldToViewport
function Utils.W2V(p)
    local sp, on = Workspace.CurrentCamera:WorldToViewportPoint(p)
    if not on or sp.Z <= 0 then return nil, false end
    return Vector2.new(sp.X, sp.Y), true
end

-- 2D Bounding Box
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
                local sp, on = Utils.W2V(cf * off)
                if on then
                    any = true
                    if sp.X < minX then minX = sp.X end
                    if sp.Y < minY then minY = sp.Y end
                    if sp.X > maxX then maxX = sp.X end
                    if sp.Y > maxY then maxY = sp.Y end
                end
            end
        end
    end
    if not any then return nil, nil end
    local tl = Vector2.new(minX, minY)
    local sz = Vector2.new(maxX-minX, maxY-minY)
    return tl, sz
end

-- Distance
function Utils.GetDistance(p)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return math.huge end
    return (root.Position - p).Magnitude
end

-- Visibility
function Utils.IsVisible(targetPos)
    local char = LP.Character
    if not char then return false end
    local origin = Workspace.CurrentCamera.CFrame.Position
    local dir    = targetPos - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType  = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    return Workspace:Raycast(origin, dir.Unit * dir.Magnitude, params) == nil
end

-- Color helpers
function Utils.Lerp(a,b,t) return a+(b-a)*t end
function Utils.LerpColor(c1, c2, t)
    return Color3.new(Utils.Lerp(c1.R,c2.R,t), Utils.Lerp(c1.G,c2.G,t), Utils.Lerp(c1.B,c2.B,t))
end
function Utils.HealthColor(hp)
    return Utils.LerpColor(Color3.fromRGB(220,40,40), Color3.fromRGB(40,220,80), math.clamp(hp,0,1))
end

-- Viewport
function Utils.GetViewport()  return Workspace.CurrentCamera.ViewportSize end
function Utils.ScreenCenter() local v=Utils.GetViewport(); return Vector2.new(v.X/2,v.Y/2) end

-- Character
function Utils.GetRoot(c)     return c and c:FindFirstChild("HumanoidRootPart") end
function Utils.GetHumanoid(c) return c and c:FindFirstChildOfClass("Humanoid") end
function Utils.GetHealthPercent(c)
    local h = Utils.GetHumanoid(c)
    if not h or h.MaxHealth <= 0 then return 1 end
    return math.clamp(h.Health/h.MaxHealth, 0, 1)
end
function Utils.GetCharTop(c)
    local head = c and c:FindFirstChild("Head")
    if head then return head.Position + Vector3.new(0, head.Size.Y/2+0.1, 0) end
    local r = Utils.GetRoot(c)
    return r and r.Position + Vector3.new(0,3,0)
end

-- Drawing
function Utils.NewDrawing(type, props)
    local d = Drawing.new(type)
    d.Visible = false
    if props then for k,v in pairs(props) do pcall(function() d[k]=v end) end end
    return d
end
function Utils.Kill(d) if d then pcall(function() d:Remove() end) end end

-- Misc
function Utils.SameTeam(p) return LP.Team ~= nil and LP.Team == p.Team end
function Utils.FormatDist(studs) return math.floor(studs).."m" end
function Utils.C3(t) return Color3.fromRGB(t and t.R or 255, t and t.G or 255, t and t.B or 255) end

return Utils
