local ESP = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local Utils, Config
local Mods     = {}
local entities = {}
local renderConn, addConn, remConn
local enabled = false
local frame   = 0

ESP.ProfileData = {Box=0, Skeleton=0, Tracers=0, Health=0, Name=0, Distance=0}

local function safe(mod, arg)
    if mod and mod.Create then
        local ok, r = pcall(mod.Create, arg)
        if ok and r then return r end
    end
    return {Update=function()end, Hide=function()end, Remove=function()end}
end

function ESP.Init(deps)
    Utils  = deps.Utils;  Config   = deps.Config
    Mods.Box       = deps.Box;       Mods.CornerBox = deps.CornerBox
    Mods.Skeleton  = deps.Skeleton;  Mods.Tracers   = deps.Tracers
    Mods.Health    = deps.Health;    Mods.Name      = deps.Name
    Mods.Distance  = deps.Distance
    ESP._modules   = Mods
    for _, m in pairs(Mods) do
        if m and m.SetDependencies then m.SetDependencies(Utils, Config) end
    end
end

local function create(player)
    if entities[player] then return end
    entities[player] = {
        box       = safe(Mods.Box),
        cornerBox = safe(Mods.CornerBox),
        skeleton  = safe(Mods.Skeleton),
        tracers   = safe(Mods.Tracers),
        health    = safe(Mods.Health),
        name      = safe(Mods.Name, player),
        distance  = safe(Mods.Distance),
        disabled  = false,
    }
end

local function remove(player)
    local e = entities[player]; if not e then return end
    e.box:Remove(); e.cornerBox:Remove(); e.skeleton:Remove()
    e.tracers:Remove(); e.health:Remove(); e.name:Remove(); e.distance:Remove()
    entities[player] = nil
end

local function hideAll(e)
    e.box:Hide(); e.cornerBox:Hide(); e.skeleton:Hide()
    e.tracers:Hide(); e.health:Hide(); e.name:Hide(); e.distance:Hide()
end

local function updateOne(player, ent)
    local cfg  = Config.Current
    local char = player.Character
    local lp   = Players.LocalPlayer
    if not char or player == lp or ent.disabled then hideAll(ent); return end
    if cfg.TeamCheck and Utils.SameTeam(player)  then hideAll(ent); return end
    local root = Utils.GetRoot(char)
    if not root then hideAll(ent); return end
    if Utils.GetDistance(root.Position) > (cfg.Distance and cfg.Distance.MaxDist or 800) then
        hideAll(ent); return
    end
    local full = not cfg.PerformanceMode or (frame % 3 == 0)
    -- Box or CornerBox (mutually exclusive)
    if cfg.CornerBox and cfg.CornerBox.Enabled then
        ent.box:Hide(); ent.cornerBox:Update(char, cfg.CornerBox)
    else
        ent.cornerBox:Hide(); ent.box:Update(char, cfg.Box)
    end
    -- Box fill is Square (drawn before skeleton lines = skeleton appears on top visually)
    if full then ent.skeleton:Update(char, cfg.Skeleton) end
    ent.tracers:Update(char, cfg.Tracers)
    ent.health:Update(char, cfg.Health)
    ent.name:Update(char, cfg.Name)
    ent.distance:Update(char, cfg.Distance)
end

local function onRender()
    if not enabled then return end
    frame = frame + 1
    for p, e in pairs(entities) do
        pcall(updateOne, p, e)
    end
end

function ESP.Enable()
    if enabled then return end; enabled = true
    local lp = Players.LocalPlayer
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then create(p) end
    end
    addConn = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.5); create(p) end)
        task.wait(0.1); create(p)
    end)
    remConn    = Players.PlayerRemoving:Connect(remove)
    renderConn = RunService.RenderStepped:Connect(onRender)
    Config.Current.Enabled = true
end

function ESP.Disable()
    if not enabled then return end; enabled = false
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if addConn    then addConn:Disconnect();    addConn    = nil end
    if remConn    then remConn:Disconnect();    remConn    = nil end
    for _, e in pairs(entities) do hideAll(e) end
    Config.Current.Enabled = false
end

function ESP.Cleanup()
    ESP.Disable()
    for p in pairs(entities) do remove(p) end
end

function ESP.GetEntities() return entities end
return ESP
