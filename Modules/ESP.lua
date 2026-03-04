local ESP = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local Utils, Config, Box, CornerBox, Skeleton, Tracers, Health, NameMod, Distance
local entities = {}
local renderConn, addConn, remConn, prevConn
local enabled = false
local frameCount = 0
local previewDummy = nil

ESP.ProfileData = {Box=0,Skeleton=0,Tracers=0,Health=0,Name=0,Distance=0}

local function safeCreate(mod, player)
    if mod and mod.Create then
        local ok, r = pcall(mod.Create, player)
        if ok and r then return r end
    end
    return {Update=function()end, Hide=function()end, Remove=function()end}
end

function ESP.Init(deps)
    Utils=deps.Utils; Config=deps.Config; Box=deps.Box; CornerBox=deps.CornerBox
    Skeleton=deps.Skeleton; Tracers=deps.Tracers; Health=deps.Health
    NameMod=deps.Name; Distance=deps.Distance
    if Box       then Box.SetDependencies(Utils,Config)       end
    if CornerBox then CornerBox.SetDependencies(Utils,Config) end
    if Skeleton  then Skeleton.SetDependencies(Utils,Config)  end
    if Tracers   then Tracers.SetDependencies(Utils,Config)   end
    if Health    then Health.SetDependencies(Utils,Config)    end
    if NameMod   then NameMod.SetDependencies(Utils,Config)   end
    if Distance  then Distance.SetDependencies(Utils,Config)  end
end

local function createEntity(player)
    if entities[player] then return end
    entities[player] = {
        box=safeCreate(Box,player), cornerBox=safeCreate(CornerBox,player),
        skeleton=safeCreate(Skeleton,player), tracers=safeCreate(Tracers,player),
        health=safeCreate(Health,player), name=safeCreate(NameMod,player),
        distance=safeCreate(Distance,player), disabled=false,
    }
end

local function removeEntity(player)
    local e=entities[player]; if not e then return end
    e.box:Remove(); e.cornerBox:Remove(); e.skeleton:Remove()
    e.tracers:Remove(); e.health:Remove(); e.name:Remove(); e.distance:Remove()
    entities[player]=nil
end

local function hideEntity(e)
    e.box:Hide(); e.cornerBox:Hide(); e.skeleton:Hide()
    e.tracers:Hide(); e.health:Hide(); e.name:Hide(); e.distance:Hide()
end

local function updateEntity(player, ent)
    local cfg = Config.Current
    local char = player.Character
    local lp   = Players.LocalPlayer
    if not char or player==lp or ent.disabled then hideEntity(ent); return end
    if cfg.TeamCheck and Utils.SameTeam(player) then hideEntity(ent); return end
    local root = Utils.GetRoot(char)
    if not root then hideEntity(ent); return end
    local dist = Utils.GetDistance(root.Position)
    if dist > (cfg.Distance and cfg.Distance.MaxDist or 800) then hideEntity(ent); return end

    local full = not cfg.PerformanceMode or (frameCount%3==0)

    Utils.ProfileStart("Box")
    if cfg.CornerBox and cfg.CornerBox.Enabled then
        ent.box:Hide(); ent.cornerBox:Update(char, cfg.CornerBox)
    else
        ent.cornerBox:Hide(); ent.box:Update(char, cfg.Box)
    end
    ESP.ProfileData.Box = Utils.ProfileEnd("Box")

    if full then
        Utils.ProfileStart("Skeleton")
        ent.skeleton:Update(char, cfg.Skeleton)
        ESP.ProfileData.Skeleton = Utils.ProfileEnd("Skeleton")
    end

    Utils.ProfileStart("Tracers")
    ent.tracers:Update(char, cfg.Tracers)
    ESP.ProfileData.Tracers = Utils.ProfileEnd("Tracers")

    Utils.ProfileStart("Health")
    ent.health:Update(char, cfg.Health)
    ESP.ProfileData.Health = Utils.ProfileEnd("Health")

    Utils.ProfileStart("Name")
    ent.name:Update(char, cfg.Name)
    ESP.ProfileData.Name = Utils.ProfileEnd("Name")

    Utils.ProfileStart("Distance")
    ent.distance:Update(char, cfg.Distance)
    ESP.ProfileData.Distance = Utils.ProfileEnd("Distance")
end

local function onRender()
    if not enabled then return end
    frameCount = frameCount+1
    for player, ent in pairs(entities) do
        pcall(updateEntity, player, ent)
    end
end

function ESP.Enable()
    if enabled then return end; enabled=true
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=Players.LocalPlayer then createEntity(p) end
    end
    addConn = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() task.wait(0.5); createEntity(p) end)
        task.wait(0.1); createEntity(p)
    end)
    remConn = Players.PlayerRemoving:Connect(removeEntity)
    renderConn = RunService.RenderStepped:Connect(onRender)
    Config.Current.Enabled=true
end

function ESP.Disable()
    if not enabled then return end; enabled=false
    if renderConn then renderConn:Disconnect(); renderConn=nil end
    if addConn    then addConn:Disconnect(); addConn=nil end
    if remConn    then remConn:Disconnect(); remConn=nil end
    for _,ent in pairs(entities) do hideEntity(ent) end
    Config.Current.Enabled=false
end

function ESP.Cleanup()
    ESP.Disable()
    for p in pairs(entities) do removeEntity(p) end
    ESP.RemovePreview()
end

function ESP.GetEntities() return entities end

function ESP.ShowPreview()
    ESP.RemovePreview()
    local folder=Instance.new("Folder"); folder.Name="ESP_Preview"; folder.Parent=Workspace
    local camCF=Workspace.CurrentCamera.CFrame*CFrame.new(0,0,-14)
    local parts={
        {n="Head",sz=Vector3.new(2,1,1),off=Vector3.new(0,3.5,0)},
        {n="UpperTorso",sz=Vector3.new(2,1.5,1),off=Vector3.new(0,2,0)},
        {n="LowerTorso",sz=Vector3.new(2,1,1),off=Vector3.new(0,0.75,0)},
        {n="RightUpperArm",sz=Vector3.new(1,1.5,1),off=Vector3.new(1.5,2,0)},
        {n="RightLowerArm",sz=Vector3.new(1,1,1),off=Vector3.new(1.5,0.5,0)},
        {n="RightHand",sz=Vector3.new(1,0.5,1),off=Vector3.new(1.5,-0.2,0)},
        {n="LeftUpperArm",sz=Vector3.new(1,1.5,1),off=Vector3.new(-1.5,2,0)},
        {n="LeftLowerArm",sz=Vector3.new(1,1,1),off=Vector3.new(-1.5,0.5,0)},
        {n="LeftHand",sz=Vector3.new(1,0.5,1),off=Vector3.new(-1.5,-0.2,0)},
        {n="RightUpperLeg",sz=Vector3.new(1,1.5,1),off=Vector3.new(0.5,-1,0)},
        {n="RightLowerLeg",sz=Vector3.new(1,1.5,1),off=Vector3.new(0.5,-2.5,0)},
        {n="RightFoot",sz=Vector3.new(1,0.5,1),off=Vector3.new(0.5,-3.5,0)},
        {n="LeftUpperLeg",sz=Vector3.new(1,1.5,1),off=Vector3.new(-0.5,-1,0)},
        {n="LeftLowerLeg",sz=Vector3.new(1,1.5,1),off=Vector3.new(-0.5,-2.5,0)},
        {n="LeftFoot",sz=Vector3.new(1,0.5,1),off=Vector3.new(-0.5,-3.5,0)},
        {n="HumanoidRootPart",sz=Vector3.new(2,2,1),off=Vector3.new(0,1.5,0)},
    }
    for _,d in ipairs(parts) do
        local p=Instance.new("Part"); p.Name=d.n; p.Size=d.sz
        p.CFrame=camCF*CFrame.new(d.off); p.Anchored=true; p.CanCollide=false
        p.Transparency=0.85; p.Color=Color3.fromRGB(200,200,200); p.Parent=folder
    end
    local hum=Instance.new("Humanoid"); hum.Health=75; hum.MaxHealth=100; hum.Parent=folder
    previewDummy=folder
    local fake={Name="Preview", Character=folder, Team=nil}
    local ent={
        box=safeCreate(Box,fake), cornerBox=safeCreate(CornerBox,fake),
        skeleton=safeCreate(Skeleton,fake), tracers=safeCreate(Tracers,fake),
        health=safeCreate(Health,fake), name=safeCreate(NameMod,fake),
        distance=safeCreate(Distance,fake), disabled=false,
    }
    entities["__preview__"]=ent
    prevConn=RunService.RenderStepped:Connect(function()
        pcall(updateEntity, fake, ent)
    end)
end

function ESP.RemovePreview()
    if prevConn then prevConn:Disconnect(); prevConn=nil end
    local e=entities["__preview__"]
    if e then
        e.box:Remove(); e.cornerBox:Remove(); e.skeleton:Remove()
        e.tracers:Remove(); e.health:Remove(); e.name:Remove(); e.distance:Remove()
        entities["__preview__"]=nil
    end
    if previewDummy then previewDummy:Destroy(); previewDummy=nil end
end

return ESP
