-- Aurora — Da Hood v5.0 — EXPLOITATION TOTALE
-- Dump confirmé : Ammo/MaxAmmo/Damage/Range/ShootingCooldown/RemoteEvent
local DaHood = {}

local Players  = game:GetService("Players")
local RunSvc   = game:GetService("RunService")
local UIS      = game:GetService("UserInputService")
local RepS     = game:GetService("ReplicatedStorage")
local WS       = game:GetService("Workspace")
local LP       = Players.LocalPlayer
local Camera   = WS.CurrentCamera

-- ══════════════════════════════════════════════════════
-- REMOTES (tous confirmés)
-- ══════════════════════════════════════════════════════
local Remotes    = RepS:WaitForChild("Remotes", 5)
local Network    = Remotes and Remotes:FindFirstChild("Network")
local MainEvent  = RepS:FindFirstChild("MainEvent")
local MainRF     = RepS:FindFirstChild("MainRemoteFunction")
local SetBounty  = Remotes and Remotes:FindFirstChild("SetBounty")
local TapBall    = Remotes and Remotes:FindFirstChild("TapBall")
local CasinoRR   = Remotes and Remotes:FindFirstChild("CasinoRR")
local CasinoVis  = Remotes and Remotes:FindFirstChild("CasinoVisuals")
local Handshake  = Remotes and Remotes:FindFirstChild("Handshake")
local Luffy      = Remotes and Remotes:FindFirstChild("Luffy")
local IM         = RepS:FindFirstChild("IM")
local IM_Suit    = IM and IM.Events and IM.Events:FindFirstChild("IronmanSuit")
local IM_Mark45  = IM and IM.Items and IM.Items:FindFirstChild("Mark45") and IM.Items.Mark45:FindFirstChild("RemoteEvent")
local InvisHit   = IM and IM.Utility and IM.Utility:FindFirstChild("INVISHIT [ON]") and IM.Utility["INVISHIT [ON]"]:FindFirstChild("rf")
local LightSword = RepS:FindFirstChild("LightAssets") and RepS.LightAssets:FindFirstChild("Remotes") and RepS.LightAssets.Remotes:FindFirstChild("LightSwordRemote")
local BikePacket = RepS:FindFirstChild("Bike") and RepS.Bike:FindFirstChild("Events") and RepS.Bike.Events:FindFirstChild("PacketReceiver")

-- ══════════════════════════════════════════════════════
-- DATA PLAYER
-- ══════════════════════════════════════════════════════
local function getDFValue(p, n)
    local df = p:FindFirstChild("DataFolder")
    local v = df and df:FindFirstChild(n)
    return v and v.Value or nil
end
local getCash   = function(p) return getDFValue(p,"Currency") end
local getBank   = function(p) return getDFValue(p,"BankDeposit") end
local getWanted = function(p) return getDFValue(p,"Wanted") or 0 end
local isOfficer = function(p) return getDFValue(p,"Officer")==1 end
local getBoxing = function(p) return getDFValue(p,"BoxingValue") or 0 end
local getTask   = function(p) return getDFValue(p,"TaskInfo") or "" end

-- ══════════════════════════════════════════════════════
-- OPTIONS
-- ══════════════════════════════════════════════════════
local opt = {
    -- ESP
    MoneyESP=false, WantedESP=false, OfficerESP=false,
    WeaponESP=false, StatsESP=false, BoxingESP=false,
    -- Combat GUN (noms exacts du dump)
    InfiniteAmmo=false,     -- Ammo + MaxAmmo = 999
    OneShot=false,          -- Damage = 9999
    RapidFire=false,        -- ShootingCooldown = 0.001
    InfiniteRange=false,    -- Range = 9999
    AutoShoot=false,        -- fire RemoteEvent du gun en boucle
    -- Combat melee
    AutoParry=false,
    -- Mouvement
    Speed=false, SpeedVal=32,
    Fly=false, FlySpeed=50,
    Noclip=false,
    -- Exploits
    GodMode=false,
    InfiniteEnergy=false,
    FreezeWanted=false,
    AntiWanted=false,
    AutoTask=false,
    AutoTapBall=false,
    CasinoAuto=false,
    SpamBounty=false,
    AutoHandshake=false,
}

-- ══════════════════════════════════════════════════════
-- GUN UTILS — noms exacts confirmés par dump
-- ══════════════════════════════════════════════════════
local function getAllGuns()
    local guns = {}
    for _, source in ipairs({LP.Character, LP:FindFirstChild("Backpack")}) do
        if source then
            for _, tool in ipairs(source:GetChildren()) do
                if tool:IsA("Tool") then
                    -- Vérifie que c'est un gun (a Ammo ou ShootingCooldown)
                    if tool:FindFirstChild("Ammo") or tool:FindFirstChild("ShootingCooldown") then
                        guns[#guns+1] = tool
                    end
                end
            end
        end
    end
    return guns
end

local function getGunValue(tool, name)
    local v = tool:FindFirstChild(name)
    return v
end

local function setGunValue(tool, name, value)
    local v = tool:FindFirstChild(name)
    if v then pcall(function() v.Value = value end) end
end

local function getGunRemote(tool)
    -- RemoteEvent directement dans le tool (confirmé par dump)
    return tool:FindFirstChildOfClass("RemoteEvent")
end

-- Applique tous les mods gun
local function applyGunMods(tool)
    if opt.InfiniteAmmo then
        setGunValue(tool, "Ammo",    999)
        setGunValue(tool, "MaxAmmo", 999)
    end
    if opt.OneShot then
        setGunValue(tool, "Damage",  9999)
    end
    if opt.RapidFire then
        setGunValue(tool, "ShootingCooldown", 0.001)
    end
    if opt.InfiniteRange then
        setGunValue(tool, "Range", 9999)
    end
end

local function applyAllGuns()
    for _, gun in ipairs(getAllGuns()) do
        applyGunMods(gun)
    end
end

-- Auto Shoot : fire le RemoteEvent du gun sur la cible la plus proche
local function getClosestEnemy()
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, minDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = p
                end
            end
        end
    end
    return closest, minDist
end

local autoShootConn = nil
local function startAutoShoot()
    if autoShootConn then autoShootConn:Disconnect() end
    autoShootConn = RunSvc.Heartbeat:Connect(function()
        if not opt.AutoShoot then return end
        local char = LP.Character; if not char then return end
        local tool = char:FindFirstChildOfClass("Tool"); if not tool then return end
        if not (tool:FindFirstChild("Ammo") or tool:FindFirstChild("ShootingCooldown")) then return end
        local remote = getGunRemote(tool); if not remote then return end
        local target, dist = getClosestEnemy()
        if not target or dist > 500 then return end
        local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not tRoot then return end
        -- Fire le remote avec la position de la cible
        pcall(function()
            remote:FireServer(tRoot.Position, tRoot.CFrame, target.Character)
        end)
        pcall(function()
            remote:FireServer(tRoot.Position)
        end)
    end)
end

-- ══════════════════════════════════════════════════════
-- ESP LABELS
-- ══════════════════════════════════════════════════════
local labels = {}
local function T(sz,col)
    local t=Drawing.new("Text")
    t.Visible=false t.Outline=true t.Center=true
    t.Font=Drawing.Fonts.Plex t.Size=sz or 11
    t.Color=col or Color3.new(1,1,1) return t
end
local function getLbl(p)
    if not labels[p] then
        labels[p]={
            cash   =T(11,Color3.fromRGB(80,255,120)),
            bank   =T(10,Color3.fromRGB(60,200,255)),
            wanted =T(12,Color3.fromRGB(255,60,60)),
            officer=T(12,Color3.fromRGB(80,140,255)),
            weapon =T(10,Color3.fromRGB(255,220,80)),
            boxing =T(10,Color3.fromRGB(200,100,255)),
            task   =T(9, Color3.fromRGB(180,180,180)),
        }
    end
    return labels[p]
end
local function hideLbl(p)
    local l=labels[p]; if not l then return end
    for _,v in pairs(l) do v.Visible=false end
end
local function removeLbl(p)
    local l=labels[p]; if not l then return end
    for _,v in pairs(l) do pcall(function() v:Remove() end) end
    labels[p]=nil
end

-- ══════════════════════════════════════════════════════
-- RENDER ESP
-- ══════════════════════════════════════════════════════
local enabled = false
local function renderESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local l=getLbl(p)
            local char=p.Character
            if not char then hideLbl(p) else
                local root=char:FindFirstChild("HumanoidRootPart")
                if not root then hideLbl(p) else
                    local sp,on=Camera:WorldToViewportPoint(root.Position)
                    if not on then hideLbl(p) else
                        local x,y,off=sp.X,sp.Y-30,0
                        local function show(lbl,txt)
                            lbl.Text=txt lbl.Position=Vector2.new(x,y-off)
                            lbl.Visible=true off=off+14
                        end
                        if opt.MoneyESP then
                            local c=getCash(p)
                            if c then show(l.cash,"$"..c) else l.cash.Visible=false end
                            local b=getBank(p)
                            if b and b>0 then show(l.bank,"🏦 $"..b) else l.bank.Visible=false end
                        else l.cash.Visible=false l.bank.Visible=false end
                        if opt.WantedESP then
                            local w=tonumber(getWanted(p)) or 0
                            if w>0 then show(l.wanted,"WANTED "..string.rep("★",math.min(w,5)))
                            else l.wanted.Visible=false end
                        else l.wanted.Visible=false end
                        if opt.OfficerESP and isOfficer(p) then show(l.officer,"🚔 COP")
                        else l.officer.Visible=false end
                        if opt.WeaponESP then
                            local tool=char:FindFirstChildOfClass("Tool")
                            if tool then show(l.weapon,"🔫 "..tool.Name)
                            else l.weapon.Visible=false end
                        else l.weapon.Visible=false end
                        if opt.BoxingESP then
                            local bv=getBoxing(p)
                            if bv and bv>0 then show(l.boxing,"🥊 Lvl "..bv)
                            else l.boxing.Visible=false end
                        else l.boxing.Visible=false end
                        if opt.StatsESP then
                            local tk=getTask(p)
                            if tk and tk~="" then show(l.task,"📋 "..tk)
                            else l.task.Visible=false end
                        else l.task.Visible=false end
                    end
                end
            end
        end
    end
end

-- ══════════════════════════════════════════════════════
-- MOUVEMENT
-- ══════════════════════════════════════════════════════
local function doSpeed()
    local char=LP.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    pcall(function() hum.WalkSpeed=opt.Speed and opt.SpeedVal or 16 end)
end

local flyConn,bodyVel,bodyGyro=nil,nil,nil
local function startFly()
    local char=LP.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.PlatformStand=true
    bodyVel=Instance.new("BodyVelocity")
    bodyVel.MaxForce=Vector3.new(1e5,1e5,1e5)
    bodyVel.Velocity=Vector3.zero bodyVel.Parent=root
    bodyGyro=Instance.new("BodyGyro")
    bodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5)
    bodyGyro.CFrame=root.CFrame bodyGyro.Parent=root
    flyConn=RunSvc.RenderStepped:Connect(function()
        if not opt.Fly then return end
        local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not r then return end
        local dir=Vector3.zero local cf=Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
        if dir.Magnitude>0 then dir=dir.Unit end
        bodyVel.Velocity=dir*opt.FlySpeed bodyGyro.CFrame=cf
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if bodyVel then bodyVel:Destroy() bodyVel=nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro=nil end
    local char=LP.Character
    if char then
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=false end
    end
end

local function doNoclip()
    local char=LP.Character; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.CanCollide=not opt.Noclip end) end
    end
end

-- ══════════════════════════════════════════════════════
-- EXPLOITS
-- ══════════════════════════════════════════════════════
local function doGodMode()
    local char=LP.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if opt.GodMode then pcall(function() hum.MaxHealth=math.huge hum.Health=math.huge end) end
end

local function doAutoParry()
    local myChar=LP.Character; if not myChar then return end
    local myRoot=myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if root and (myRoot.Position-root.Position).Magnitude<15 then
                local hum=p.Character:FindFirstChildOfClass("Humanoid")
                local anim=hum and hum:FindFirstChildOfClass("Animator")
                if anim then
                    for _,track in ipairs(anim:GetPlayingAnimationTracks()) do
                        local n=track.Name:lower()
                        if n:find("punch") or n:find("kick") or n:find("attack") or n:find("combo") then
                            if Network then
                                pcall(function() Network:FireServer("Block",true) end)
                                pcall(function() Network:FireServer("Parry") end)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function tryAntiWanted()
    for _,r in ipairs({Network,MainEvent}) do
        if r then
            for _,a in ipairs({"ClearWanted","ResetWanted","Wanted","SetWanted"}) do
                pcall(function() r:FireServer(a,0) end)
                pcall(function() r:FireServer(a) end)
            end
        end
    end
    if MainRF then pcall(function() MainRF:InvokeServer("ClearWanted") end) end
end

local wantedConn=nil
local function startFreezeWanted()
    local df=LP:FindFirstChild("DataFolder"); if not df then return end
    local w=df:FindFirstChild("Wanted"); if not w then return end
    wantedConn=w.Changed:Connect(function(v)
        if opt.FreezeWanted and v>0 then pcall(tryAntiWanted) end
    end)
end

local taskRunning=false
local function doAutoTask()
    if taskRunning then return end
    taskRunning=true
    task.spawn(function()
        while opt.AutoTask do
            task.wait(1.5)
            for _,r in ipairs({Network,MainEvent}) do
                if r then
                    pcall(function() r:FireServer("ClaimTask") end)
                    pcall(function() r:FireServer("CompleteTask") end)
                    pcall(function() r:FireServer("TaskComplete") end)
                    pcall(function() r:FireServer("BuyItem",1) end)
                    pcall(function() r:FireServer("BuyItem",2) end)
                    pcall(function() r:FireServer("TaskClaim") end)
                end
            end
        end
        taskRunning=false
    end)
end

local tapRunning=false
local function doAutoTapBall()
    if tapRunning or not TapBall then return end
    tapRunning=true
    task.spawn(function()
        while opt.AutoTapBall do
            task.wait(0.05)
            pcall(function() TapBall:FireServer() end)
        end
        tapRunning=false
    end)
end

local casinoRunning=false
local function doAutoCasino()
    if casinoRunning then return end
    casinoRunning=true
    task.spawn(function()
        while opt.CasinoAuto do
            task.wait(1)
            if CasinoRR  then pcall(function() CasinoRR:FireServer("Spin") end) pcall(function() CasinoRR:FireServer() end) end
            if CasinoVis then pcall(function() CasinoVis:FireServer("Spin") end) end
        end
        casinoRunning=false
    end)
end

local function doSpamBounty()
    if not SetBounty then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            pcall(function() SetBounty:FireServer(p,999999) end)
            pcall(function() SetBounty:FireServer(p.UserId,999999) end)
        end
    end
end

-- Items spéciaux
local function tryIronMan()
    if IM_Suit   then pcall(function() IM_Suit:FireServer("Equip") end) pcall(function() IM_Suit:FireServer() end) end
    if IM_Mark45 then pcall(function() IM_Mark45:FireServer("Equip") end) pcall(function() IM_Mark45:FireServer() end) end
end
local function tryLightSword()
    if LightSword then pcall(function() LightSword:FireServer("Equip") end) pcall(function() LightSword:FireServer() end) end
end
local function tryBike()
    if BikePacket then
        pcall(function() BikePacket:FireServer("MaxSpeed",999) end)
        pcall(function() BikePacket:FireServer("Speed",999) end)
    end
end
local function tryLuffy()
    if Luffy then pcall(function() Luffy:FireServer("Enable") end) pcall(function() Luffy:FireServer() end) end
end

-- ══════════════════════════════════════════════════════
-- RENDER LOOP
-- ══════════════════════════════════════════════════════
local frame=0
RunSvc.RenderStepped:Connect(function()
    if not enabled then return end
    frame=frame+1
    pcall(renderESP)

    -- Chaque frame : gun mods (Ammo se recharge vite)
    if opt.InfiniteAmmo or opt.OneShot or opt.RapidFire or opt.InfiniteRange then
        pcall(applyAllGuns)
    end

    if frame%3==0 then
        pcall(doAutoParry)
        pcall(doGodMode)
        pcall(doNoclip)
    end
    if frame%10==0 then
        if opt.Speed then pcall(doSpeed) end
    end
    if frame%30==0 then
        if opt.AntiWanted  then pcall(tryAntiWanted) end
        if opt.SpamBounty  then pcall(doSpamBounty)  end
        frame=0
    end
end)

-- ══════════════════════════════════════════════════════
-- INIT & API
-- ══════════════════════════════════════════════════════
function DaHood.Init(deps)
    Players.PlayerRemoving:Connect(removeLbl)
    pcall(startFreezeWanted)
    startAutoShoot()

    LP.CharacterAdded:Connect(function()
        task.wait(1)
        if opt.Speed then pcall(doSpeed) end
        if opt.Fly   then pcall(startFly) end
    end)

    -- Hook nouveau tool équipé → applique mods immédiatement
    LP.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                applyGunMods(child)
            end
        end)
    end)
    if LP.Character then
        LP.Character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                applyGunMods(child)
            end
        end)
    end

    _G._p = _G._p or print
    _G._p("[DaHood v5.0] Chargé ✓")
    _G._p("[DaHood] Guns trouvés: "..#getAllGuns())
end

function DaHood.Enable()  enabled=true  end
function DaHood.Disable()
    enabled=false
    for _,p in ipairs(Players:GetPlayers()) do hideLbl(p) end
    stopFly()
    local char=LP.Character
    if char then
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.WalkSpeed=16 hum.PlatformStand=false end) end
    end
end

function DaHood.SetOption(k,v)
    opt[k]=v
    if k=="Fly" then if v then pcall(startFly) else pcall(stopFly) end
    elseif k=="Speed" then pcall(doSpeed)
    elseif k=="AntiWanted" and v then pcall(tryAntiWanted)
    elseif k=="AutoTask" and v then pcall(doAutoTask)
    elseif k=="AutoTapBall" and v then pcall(doAutoTapBall)
    elseif k=="CasinoAuto" and v then pcall(doAutoCasino)
    elseif k=="InfiniteAmmo" or k=="OneShot" or k=="RapidFire" or k=="InfiniteRange" then
        pcall(applyAllGuns)
    end
end

function DaHood.GetOption(k) return opt[k] end
DaHood.TryIronMan    = tryIronMan
DaHood.TryLightSword = tryLightSword
DaHood.TryBike       = tryBike
DaHood.TryLuffy      = tryLuffy
DaHood.AntiWanted    = tryAntiWanted
DaHood.GetCash       = getCash
DaHood.GetBank       = getBank
DaHood.GetWanted     = getWanted
DaHood.IsOfficer     = isOfficer

return DaHood
