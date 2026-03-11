-- ══════════════════════════════════════════════════════════════════
--   Aurora v7.0.0 — All-in-One
-- ══════════════════════════════════════════════════════════════════
local VERSION    = "7.1.0"
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera
local PLACE_ID   = game.PlaceId
local IS_ARSENAL = PLACE_ID == 286090429

-- ══════════════════════════════════════════════════════════════════
-- ESP OPTIONS
-- ══════════════════════════════════════════════════════════════════
local opt = {
    Box=false, BoxStyle="Box",
    Skeleton=false, Tracers=false, TracerOrigin="Bottom",
    Name=false, Health=false, Distance=false,
    Weapon=false, Chams=false, ChamsStyle="Outline",
    HeadDot=false, HandChams=false,
    HandChamsColor=Color3.fromRGB(255,100,100), HandChamsTransp=0.5,
    WallCheck=false,
    VisibleColor=Color3.fromRGB(0,255,100),
    NotVisibleColor=Color3.fromRGB(255,60,60),
    EnemyColor=Color3.fromRGB(255,60,60),
    TeamColor=Color3.fromRGB(60,255,120),
    TeamCheck=false, MaxDist=500,
}

local function anyESP()
    return opt.Box or opt.Skeleton or opt.Tracers or opt.Name
        or opt.Health or opt.Distance or opt.Weapon
        or opt.Chams or opt.HeadDot or opt.HandChams
end

local function getColor(player, root)
    if opt.TeamCheck and LP.Team and player.Team and LP.Team==player.Team then
        return nil
    end
    if LP.Team and player.Team and LP.Team==player.Team then
        return opt.TeamColor
    end
    if opt.WallCheck and root then
        -- cast ray depuis camera vers le joueur
        local dir=(root.Position-Camera.CFrame.Position)
        local dist=dir.Magnitude
        local params=RaycastParams.new()
        params.FilterDescendantsInstances={LP.Character,workspace.CurrentCamera}
        params.FilterType=Enum.RaycastFilterType.Exclude
        local result=workspace:Raycast(Camera.CFrame.Position,dir.Unit*(dist-1),params)
        local visible=result==nil
        return visible and opt.VisibleColor or opt.NotVisibleColor
    end
    return opt.EnemyColor
end

-- ══════════════════════════════════════════════════════════════════
-- DRAWING HELPERS
-- ══════════════════════════════════════════════════════════════════
local function newLine()
    local l=Drawing.new("Line")
    l.Visible=false l.Thickness=1 l.Color=Color3.new(1,1,1)
    l.Transparency=1 l.ZIndex=2 return l
end
local function newText()
    local t=Drawing.new("Text")
    t.Visible=false t.Center=true t.Outline=true
    t.Size=13 t.Font=Drawing.Fonts.Plex return t
end

-- ══════════════════════════════════════════════════════════════════
-- BONES
-- ══════════════════════════════════════════════════════════════════
local BONES_R15={
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"RightUpperLeg","RightLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},{"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},{"RightUpperArm","RightLowerArm"},
    {"LeftLowerArm","LeftHand"},{"RightLowerArm","RightHand"},
}
local BONES_R6={
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local MAX_BONES=#BONES_R15

-- ══════════════════════════════════════════════════════════════════
-- PLAYER DRAWINGS
-- ══════════════════════════════════════════════════════════════════
local playerData={}
local function createDrawings()
    local box={} for i=1,4 do box[i]=newLine() end
    local cor={} for i=1,8 do cor[i]=newLine() end
    local sk={}  for i=1,MAX_BONES do sk[i]=newLine() end
    return{box=box,cor=cor,sk=sk,tr=newLine(),
        name=newText(),hbar=newLine(),dist=newText(),
        weap=newText(),dot=newLine(),highlight=nil,handhl=nil}
end
local function hideDrawings(d)
    if not d then return end
    for i=1,4 do d.box[i].Visible=false end
    for i=1,8 do d.cor[i].Visible=false end
    for i=1,MAX_BONES do d.sk[i].Visible=false end
    d.tr.Visible=false d.name.Visible=false d.hbar.Visible=false
    d.dist.Visible=false d.weap.Visible=false d.dot.Visible=false
    if d.highlight then d.highlight.Enabled=false end
    if d.handhl then d.handhl.Enabled=false end
end
local function removeDrawings(d)
    if not d then return end
    for i=1,4 do pcall(function() d.box[i]:Remove() end) end
    for i=1,8 do pcall(function() d.cor[i]:Remove() end) end
    for i=1,MAX_BONES do pcall(function() d.sk[i]:Remove() end) end
    pcall(function() d.tr:Remove() end)
    pcall(function() d.name:Remove() end)
    pcall(function() d.hbar:Remove() end)
    pcall(function() d.dist:Remove() end)
    pcall(function() d.weap:Remove() end)
    pcall(function() d.dot:Remove() end)
    if d.highlight then pcall(function() d.highlight:Destroy() end) d.highlight=nil end
    if d.handhl then pcall(function() d.handhl:Destroy() end) d.handhl=nil end
end

-- ══════════════════════════════════════════════════════════════════
-- BOUNDING BOX
-- ══════════════════════════════════════════════════════════════════
local function getBB(char)
    local root=char:FindFirstChild("HumanoidRootPart")
    local head=char:FindFirstChild("Head")
    if not root or not head then return nil end
    local hs=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,head.Size.Y/2,0))
    local fs=Camera:WorldToViewportPoint(root.Position-Vector3.new(0,3,0))
    if hs.Z<=0 or fs.Z<=0 then return nil end
    local h=math.abs(hs.Y-fs.Y)
    if h<5 then return nil end
    local w=h*0.55
    local cx=(hs.X+fs.X)/2
    return{x=cx-w/2,y=hs.Y,width=w,height=h,cx=cx,botY=fs.Y,
        headX=hs.X,headY=hs.Y}
end

-- ══════════════════════════════════════════════════════════════════
-- DRAW FUNCTIONS
-- ══════════════════════════════════════════════════════════════════
local function drawBox(d,bb,col)
    local x,y,w,h=bb.x,bb.y,bb.width,bb.height
    d.box[1].From=Vector2.new(x,y)   d.box[1].To=Vector2.new(x+w,y)
    d.box[2].From=Vector2.new(x,y+h) d.box[2].To=Vector2.new(x+w,y+h)
    d.box[3].From=Vector2.new(x,y)   d.box[3].To=Vector2.new(x,y+h)
    d.box[4].From=Vector2.new(x+w,y) d.box[4].To=Vector2.new(x+w,y+h)
    for i=1,4 do d.box[i].Color=col d.box[i].Visible=true end
    for i=1,8 do d.cor[i].Visible=false end
end
local function drawCorner(d,bb,col)
    local x,y,w,h=bb.x,bb.y,bb.width,bb.height
    local cw,ch=w*0.28,h*0.28
    d.cor[1].From=Vector2.new(x,y)         d.cor[1].To=Vector2.new(x+cw,y)
    d.cor[2].From=Vector2.new(x,y)         d.cor[2].To=Vector2.new(x,y+ch)
    d.cor[3].From=Vector2.new(x+w-cw,y)   d.cor[3].To=Vector2.new(x+w,y)
    d.cor[4].From=Vector2.new(x+w,y)       d.cor[4].To=Vector2.new(x+w,y+ch)
    d.cor[5].From=Vector2.new(x,y+h-ch)   d.cor[5].To=Vector2.new(x,y+h)
    d.cor[6].From=Vector2.new(x,y+h)       d.cor[6].To=Vector2.new(x+cw,y+h)
    d.cor[7].From=Vector2.new(x+w,y+h-ch) d.cor[7].To=Vector2.new(x+w,y+h)
    d.cor[8].From=Vector2.new(x+w-cw,y+h) d.cor[8].To=Vector2.new(x+w,y+h)
    for i=1,8 do d.cor[i].Color=col d.cor[i].Visible=true end
    for i=1,4 do d.box[i].Visible=false end
end
local function drawSkeleton(sk,char,col)
    local isR15=char:FindFirstChild("UpperTorso")~=nil
    local bones=isR15 and BONES_R15 or BONES_R6
    for i=1,MAX_BONES do
        local line=sk[i] local bone=bones[i]
        if bone then
            local pA=char:FindFirstChild(bone[1])
            local pB=char:FindFirstChild(bone[2])
            if pA and pB then
                local sA=Camera:WorldToViewportPoint(pA.Position)
                local sB=Camera:WorldToViewportPoint(pB.Position)
                if sA.Z>0 and sB.Z>0 then
                    line.From=Vector2.new(sA.X,sA.Y)
                    line.To=Vector2.new(sB.X,sB.Y)
                    line.Color=col line.Visible=true
                else line.Visible=false end
            else line.Visible=false end
        else line.Visible=false end
    end
end
local function drawTracer(tr,bb,col)
    local vp=Camera.ViewportSize
    local fromY=opt.TracerOrigin=="Top" and 0 or vp.Y
    local toY=opt.TracerOrigin=="Top" and bb.y or bb.botY
    tr.From=Vector2.new(vp.X/2,fromY) tr.To=Vector2.new(bb.cx,toY)
    tr.Color=col tr.Thickness=1 tr.Visible=true
end
local function getHPColor(pct)
    if pct>0.6 then return Color3.fromRGB(74,222,128)
    elseif pct>0.3 then return Color3.fromRGB(251,191,36)
    else return Color3.fromRGB(248,113,113) end
end
local function drawHealth(d,bb,hum)
    local maxHp=hum.MaxHealth>0 and hum.MaxHealth or 100
    local pct=math.clamp(hum.Health/maxHp,0,1)
    local col=getHPColor(pct)
    local x=bb.x-4 local yBot=bb.y+bb.height
    local yTop=bb.y+bb.height*(1-pct)
    d.hbar.From=Vector2.new(x,yBot) d.hbar.To=Vector2.new(x,yTop)
    d.hbar.Color=col d.hbar.Thickness=3 d.hbar.Visible=true
end
local function drawName(nameD,player,bb,col)
    nameD.Text=player.Name nameD.Color=col
    nameD.Position=Vector2.new(bb.cx,bb.y-16) nameD.Visible=true
end
local function drawDistance(distD,bb,dist,col)
    distD.Text=dist.."m" distD.Size=15 distD.Color=col
    distD.Position=Vector2.new(bb.cx,bb.y+bb.height+3) distD.Visible=true
end
local function drawWeapon(weapD,player,char,bb,col)
    local weapName=nil
    local ew=char:FindFirstChild("EquippedWep")
    if ew and ew.Value~="" then weapName=ew.Value end
    if not weapName then
        local tool=char:FindFirstChildOfClass("Tool")
        if tool then weapName=tool.Name end
    end
    if not weapName or weapName=="" then weapD.Visible=false return end
    local yOffset=opt.Distance and 18 or 0
    weapD.Text="["..weapName.."]" weapD.Size=11 weapD.Color=col
    weapD.Position=Vector2.new(bb.cx,bb.y+bb.height+3+yOffset)
    weapD.Visible=true
end
local function drawHeadDot(dot,bb,col)
    dot.From=Vector2.new(bb.headX-3,bb.headY)
    dot.To=Vector2.new(bb.headX+3,bb.headY)
    dot.Color=col dot.Thickness=5 dot.Visible=true
end
local function updateChams(d,player,col)
    local char=player.Character
    if not char then if d.highlight then d.highlight.Enabled=false end return end
    if not d.highlight then
        local h=Instance.new("Highlight")
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency=1 h.OutlineTransparency=0
        h.Parent=char d.highlight=h
    else
        if d.highlight.Parent~=char then d.highlight.Parent=char end
    end
    if opt.ChamsStyle=="Filled" then
        d.highlight.FillTransparency=0.5
    else d.highlight.FillTransparency=1 end
    d.highlight.FillColor=col d.highlight.OutlineColor=col
    d.highlight.Enabled=true
end
local function updateHandChams(d,char)
    if not char then
        if d.handhl then d.handhl.Enabled=false end return
    end
    -- Crée un Highlight sur les mains uniquement via un dossier temporaire
    if not d.handhl then
        local h=Instance.new("Highlight")
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency=opt.HandChamsTransp
        h.OutlineTransparency=0
        h.FillColor=opt.HandChamsColor
        h.OutlineColor=opt.HandChamsColor
        -- on parent au char entier mais on masque tout sauf les mains via adornee
        local hand=char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
            or char:FindFirstChild("RightLowerArm")
        if not hand then h.Parent=nil d.handhl=h return end
        h.Adornee=hand
        h.Parent=char
        d.handhl=h
    else
        local hand=char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
            or char:FindFirstChild("RightLowerArm")
        if hand then d.handhl.Adornee=hand end
        if d.handhl.Parent~=char then d.handhl.Parent=char end
    end
    d.handhl.FillColor=opt.HandChamsColor
    d.handhl.OutlineColor=opt.HandChamsColor
    d.handhl.FillTransparency=opt.HandChamsTransp
    d.handhl.OutlineTransparency=0
    d.handhl.Enabled=true
end

-- ══════════════════════════════════════════════════════════════════
-- RENDER
-- ══════════════════════════════════════════════════════════════════
local function renderPlayer(player,d)
    local char=player.Character
    if not char then hideDrawings(d) return end
    local root=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then hideDrawings(d) return end
    local sp=Camera:WorldToViewportPoint(root.Position)
    if sp.Z<=0 then hideDrawings(d) return end
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local dist=myRoot and math.floor((root.Position-myRoot.Position).Magnitude) or 9999
    if dist>opt.MaxDist then hideDrawings(d) return end
    local col=getColor(player,root)
    if not col then hideDrawings(d) return end
    local bb=getBB(char)
    if opt.Box and bb then
        if opt.BoxStyle=="CornerBox" then drawCorner(d,bb,col)
        else drawBox(d,bb,col) end
    else
        for i=1,4 do d.box[i].Visible=false end
        for i=1,8 do d.cor[i].Visible=false end
    end
    if opt.Skeleton then drawSkeleton(d.sk,char,col)
    else for i=1,MAX_BONES do d.sk[i].Visible=false end end
    if opt.Tracers and bb then drawTracer(d.tr,bb,col)
    else d.tr.Visible=false end
    if opt.Health and bb then drawHealth(d,bb,hum)
    else d.hbar.Visible=false end
    if opt.Name and bb then drawName(d.name,player,bb,col)
    else d.name.Visible=false end
    if opt.Distance and bb then drawDistance(d.dist,bb,dist,col)
    else d.dist.Visible=false end
    if opt.Weapon and bb then drawWeapon(d.weap,player,char,bb,col)
    else d.weap.Visible=false end
    if opt.HeadDot and bb then drawHeadDot(d.dot,bb,col)
    else d.dot.Visible=false end
    if opt.Chams then updateChams(d,player,col)
    else if d.highlight then d.highlight.Enabled=false end end
    if opt.HandChams then updateHandChams(d,char)
    else if d.handhl then d.handhl.Enabled=false end end
end

RunService:BindToRenderStep("AuroraESP",Enum.RenderPriority.Camera.Value+1,function()
    if not anyESP() then return end
    for player,d in pairs(playerData) do
        if not player or not player.Parent then
            removeDrawings(d) playerData[player]=nil
        else pcall(renderPlayer,player,d) end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- PLAYER MANAGEMENT
-- ══════════════════════════════════════════════════════════════════
local function addPlayer(p)
    if playerData[p] then return end
    playerData[p]=createDrawings()
    p.CharacterRemoving:Connect(function()
        if playerData[p] then hideDrawings(playerData[p]) end
    end)
end
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then addPlayer(p) end end
Players.PlayerAdded:Connect(function(p) if p~=LP then addPlayer(p) end end)
Players.PlayerRemoving:Connect(function(p)
    if playerData[p] then removeDrawings(playerData[p]) playerData[p]=nil end
end)

-- ══════════════════════════════════════════════════════════════════
-- AIMBOT
-- ══════════════════════════════════════════════════════════════════
local aimbotOpt={
    Enabled=false, FOV=120, Smoothness=10,
    Bone="Head", TeamCheck=true,
    Method="Camera Lerp",
    Priority="FOV",
    StickyAim=false, StickyTarget=nil,
    RetargetDelay=0, lastRetarget=0,
    HitChance=100,
    Prediction=false, PredictionAmount=0.1,
    DistMultiplier=false, DistMult=1,
    BulletDrop=false, DropStrength=0.5,
}
local trigOpt={
    Enabled=false, MinDelay=0.05, MaxDelay=0.15,
    MissChance=0, HoldMode=false, lastShot=0,
}
local FOV_SEG=64
local fovLines={}
for i=1,FOV_SEG do
    local l=Drawing.new("Line")
    l.Visible=false l.Thickness=1
    l.Color=Color3.fromRGB(255,255,255) l.ZIndex=6
    fovLines[i]=l
end
local function renderFOV()
    local show=aimbotOpt.Enabled
    local cx=Camera.ViewportSize.X/2
    local cy=Camera.ViewportSize.Y/2
    local r=aimbotOpt.FOV
    for i=1,FOV_SEG do
        local l=fovLines[i]
        if show then
            local a1=(i-1)/FOV_SEG*math.pi*2
            local a2=i/FOV_SEG*math.pi*2
            l.From=Vector2.new(cx+math.cos(a1)*r,cy+math.sin(a1)*r)
            l.To=Vector2.new(cx+math.cos(a2)*r,cy+math.sin(a2)*r)
            l.Visible=true
        else l.Visible=false end
    end
end
local function getScore(player,bone,screenPos,center,dist)
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if aimbotOpt.Priority=="FOV" then
        return (screenPos-center).Magnitude
    elseif aimbotOpt.Priority=="Distance" then
        return myRoot and (bone.Position-myRoot.Position).Magnitude or 9999
    elseif aimbotOpt.Priority=="HP" then
        return hum and hum.Health or 9999
    else -- Intelligent = mix fov + distance
        local fovScore=(screenPos-center).Magnitude
        local distScore=myRoot and (bone.Position-myRoot.Position).Magnitude/100 or 0
        return fovScore + distScore
    end
end
local function getBestTarget()
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local best=nil local bestScore=math.huge
    local now=tick()
    -- sticky aim
    if aimbotOpt.StickyAim and aimbotOpt.StickyTarget then
        local p=aimbotOpt.StickyTarget
        if p and p.Parent and p.Character then
            local bone=p.Character:FindFirstChild(aimbotOpt.Bone)
                or p.Character:FindFirstChild("HumanoidRootPart")
            if bone then
                local sp=Camera:WorldToViewportPoint(bone.Position)
                if sp.Z>0 and (Vector2.new(sp.X,sp.Y)-center).Magnitude<=aimbotOpt.FOV then
                    return bone,p
                end
            end
        end
        aimbotOpt.StickyTarget=nil
    end
    if now-aimbotOpt.lastRetarget < aimbotOpt.RetargetDelay then
        return nil,nil
    end
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LP and player.Character then
            local char=player.Character
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then
                if aimbotOpt.TeamCheck and LP.Team and player.Team and LP.Team==player.Team then
                    -- skip
                else
                    local bone=char:FindFirstChild(aimbotOpt.Bone)
                        or char:FindFirstChild("HumanoidRootPart")
                    if bone then
                        local sp=Camera:WorldToViewportPoint(bone.Position)
                        if sp.Z>0 then
                            local screenPos=Vector2.new(sp.X,sp.Y)
                            local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            local dist=myRoot and (bone.Position-myRoot.Position).Magnitude or 9999
                            if (screenPos-center).Magnitude<=aimbotOpt.FOV then
                                local score=getScore(player,bone,screenPos,center,dist)
                                if score<bestScore then
                                    bestScore=score best=bone
                                    if aimbotOpt.StickyAim then aimbotOpt.StickyTarget=player end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if best then aimbotOpt.lastRetarget=now end
    return best,nil
end

RunService:BindToRenderStep("AuroraAimbot",Enum.RenderPriority.Camera.Value+2,function()
    renderFOV()
    if not aimbotOpt.Enabled then return end
    local holding=UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not holding then return end
    if math.random(1,100)>aimbotOpt.HitChance then return end
    local bone=getBestTarget()
    if not bone then return end
    local targetPos=bone.Position
    -- Prediction
    if aimbotOpt.Prediction and bone.Parent then
        local root=bone.Parent:FindFirstChild("HumanoidRootPart")
        if root then
            targetPos=targetPos+root.AssemblyLinearVelocity*aimbotOpt.PredictionAmount
        end
    end
    -- Bullet drop compensation
    if aimbotOpt.BulletDrop then
        local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local dist=myRoot and (targetPos-myRoot.Position).Magnitude or 0
        targetPos=targetPos+Vector3.new(0,dist*aimbotOpt.DropStrength*0.01,0)
    end
    -- Distance multiplier
    if aimbotOpt.DistMultiplier then
        local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local dist=myRoot and (targetPos-myRoot.Position).Magnitude or 1
        local smooth=math.max(1,aimbotOpt.Smoothness*(dist/100)*aimbotOpt.DistMult)
        local camCF=Camera.CFrame
        local targetCF=CFrame.new(camCF.Position,targetPos)
        Camera.CFrame=camCF:Lerp(targetCF,1/smooth)
        return
    end
    local camCF=Camera.CFrame
    local targetCF=CFrame.new(camCF.Position,targetPos)
    local smooth=math.max(1,aimbotOpt.Smoothness)
    if aimbotOpt.Method=="Instant" then
        Camera.CFrame=targetCF
    else
        Camera.CFrame=camCF:Lerp(targetCF,1/smooth)
    end
end)

-- ── Triggerbot ────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not trigOpt.Enabled then return end
    local holding=trigOpt.HoldMode and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if trigOpt.HoldMode and not holding then return end
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local ray=Camera:ScreenPointToRay(center.X,center.Y)
    local result=workspace:Raycast(ray.Origin,ray.Direction*1000,
        RaycastParams.new())
    if not result then return end
    local hit=result.Instance
    if not hit then return end
    local char=hit:FindFirstAncestorOfClass("Model")
    if not char then return end
    local player=Players:GetPlayerFromCharacter(char)
    if not player or player==LP then return end
    if aimbotOpt.TeamCheck and LP.Team and player.Team and LP.Team==player.Team then return end
    local now=tick()
    if now-trigOpt.lastShot < trigOpt.MinDelay then return end
    if math.random(1,100)<=trigOpt.MissChance then return end
    local delay=trigOpt.MinDelay+math.random()*(trigOpt.MaxDelay-trigOpt.MinDelay)
    trigOpt.lastShot=now+delay
    task.delay(delay,function()
        local vInput=Instance.new("InputObject")
        vInput.KeyCode=Enum.KeyCode.Unknown
        vInput.UserInputType=Enum.UserInputType.MouseButton1
        vInput.UserInputState=Enum.UserInputState.Begin
        game:GetService("UserInputService").InputBegan:Fire(vInput,false)
    end)
end)

-- ══════════════════════════════════════════════════════════════════
-- RADAR
-- ══════════════════════════════════════════════════════════════════
local radarOpt={
    Enabled=false, Size=200, MaxDist=300, PlayerSize=5,
    Position="Bottom Right", TeamCheck=false, ShowNames=false,
    CustomColors=false,
    TeamColor=Color3.fromRGB(60,255,120),
    EnemyColor=Color3.fromRGB(255,60,60),
    LocalColor=Color3.fromRGB(255,255,255),
    BgColor=Color3.fromRGB(0,0,0), BgTransp=0.5,
}
local radarGui=nil
local radarDots={}

local function getRadarPos()
    local vp=Camera.ViewportSize
    local s=radarOpt.Size
    local p=radarOpt.Position
    if p=="Top Left" then return UDim2.fromOffset(10,10)
    elseif p=="Top Right" then return UDim2.fromOffset(vp.X-s-10,10)
    elseif p=="Bottom Left" then return UDim2.fromOffset(10,vp.Y-s-10)
    else return UDim2.fromOffset(vp.X-s-10,vp.Y-s-10) end
end

local function buildRadar()
    if radarGui then radarGui:Destroy() radarGui=nil end
    if not radarOpt.Enabled then return end
    local sg=Instance.new("ScreenGui")
    sg.Name="AuroraRadar" sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true sg.Parent=LP.PlayerGui
    local bg=Instance.new("Frame")
    bg.Size=UDim2.fromOffset(radarOpt.Size,radarOpt.Size)
    bg.Position=getRadarPos()
    bg.BackgroundColor3=radarOpt.BgColor
    bg.BackgroundTransparency=radarOpt.BgTransp
    bg.BorderSizePixel=1 bg.Parent=sg
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
    -- local dot
    local ld=Instance.new("Frame")
    ld.Size=UDim2.fromOffset(6,6)
    ld.Position=UDim2.fromScale(0.5,0.5)
    ld.AnchorPoint=Vector2.new(0.5,0.5)
    ld.BackgroundColor3=radarOpt.LocalColor
    ld.BorderSizePixel=0 ld.Parent=bg
    Instance.new("UICorner",ld).CornerRadius=UDim.new(1,0)
    radarGui={sg=sg,bg=bg}
    radarDots={}
end

RunService.Heartbeat:Connect(function()
    if not radarOpt.Enabled or not radarGui then return end
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local camCF=Camera.CFrame
    local s=radarOpt.Size/2
    -- update dots
    local seen={}
    for _,player in ipairs(Players:GetPlayers()) do
        if player~=LP then
            local char=player.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local rel=myRoot.CFrame:ToObjectSpace(root.CFrame)
                local rx=rel.X/radarOpt.MaxDist
                local rz=rel.Z/radarOpt.MaxDist
                if math.abs(rx)<=1 and math.abs(rz)<=1 then
                    seen[player]=true
                    if not radarDots[player] then
                        local dot=Instance.new("Frame")
                        dot.Size=UDim2.fromOffset(radarOpt.PlayerSize,radarOpt.PlayerSize)
                        dot.AnchorPoint=Vector2.new(0.5,0.5)
                        dot.BorderSizePixel=0
                        dot.Parent=radarGui.bg
                        Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
                        if radarOpt.ShowNames then
                            local lbl=Instance.new("TextLabel")
                            lbl.Size=UDim2.new(0,60,0,12)
                            lbl.Position=UDim2.fromOffset(6,0)
                            lbl.BackgroundTransparency=1
                            lbl.TextColor3=Color3.new(1,1,1)
                            lbl.TextSize=9 lbl.Text=player.Name
                            lbl.Parent=dot
                        end
                        radarDots[player]=dot
                    end
                    local dot=radarDots[player]
                    dot.Position=UDim2.fromOffset(s+rx*s,s+rz*s)
                    local isTeam=LP.Team and player.Team and LP.Team==player.Team
                    if radarOpt.CustomColors then
                        dot.BackgroundColor3=isTeam and radarOpt.TeamColor or radarOpt.EnemyColor
                    else
                        dot.BackgroundColor3=isTeam and Color3.fromRGB(60,255,120) or Color3.fromRGB(255,60,60)
                    end
                    if radarOpt.TeamCheck and isTeam then dot.Visible=false
                    else dot.Visible=true end
                end
            end
        end
    end
    for player,dot in pairs(radarDots) do
        if not seen[player] then dot:Destroy() radarDots[player]=nil end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- MOVEMENT
-- ══════════════════════════════════════════════════════════════════
local movOpt={
    Speed=false, SpeedVal=24,
    Fly=false, FlySpeed=50,
    Noclip=false, BunnyHop=false,
    InfJump=false, JumpPower=false, JumpPowerVal=50,
    ClickTP=false, FreeCamera=false, FreeCamSpeed=50, FreeCamSprintMult=3,
    AntiVoid=false, AntiFling=false,
}
local movConns={}
local function movClean(key)
    if movConns[key] then movConns[key]:Disconnect() movConns[key]=nil end
end
local function applySpeed()
    movClean("speed")
    if not movOpt.Speed then
        local char=LP.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=16 end return
    end
    movConns["speed"]=RunService.Heartbeat:Connect(function()
        if not movOpt.Speed then return end
        local char=LP.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=movOpt.SpeedVal end
    end)
end
local flyBody=nil
local function applyFly()
    movClean("fly")
    if flyBody then flyBody:Destroy() flyBody=nil end
    if not movOpt.Fly then return end
    local char=LP.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bg=Instance.new("BodyGyro")
    bg.MaxTorque=Vector3.new(4e5,4e5,4e5) bg.P=1e4 bg.Parent=root
    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.Velocity=Vector3.zero
    bv.Parent=root flyBody=bv
    movConns["fly"]=RunService.Heartbeat:Connect(function()
        if not movOpt.Fly then return end
        local cf=Camera.CFrame local vel=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel=vel+cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel=vel-cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel=vel-cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel=vel+cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel=vel+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel=vel-Vector3.new(0,1,0) end
        bv.Velocity=vel*movOpt.FlySpeed bg.CFrame=cf
    end)
end
local function applyNoclip()
    movClean("noclip")
    if not movOpt.Noclip then return end
    movConns["noclip"]=RunService.Stepped:Connect(function()
        if not movOpt.Noclip then return end
        local char=LP.Character if not char then return end
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end
local function applyBhop()
    movClean("bhop")
    if not movOpt.BunnyHop then return end
    movConns["bhop"]=RunService.Heartbeat:Connect(function()
        if not movOpt.BunnyHop then return end
        local char=LP.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            if hum.FloorMaterial~=Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end
local function applyInfJump()
    movClean("infjump")
    if not movOpt.InfJump then return end
    movConns["infjump"]=RunService.Heartbeat:Connect(function()
        if not movOpt.InfJump then return end
        local char=LP.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
local function applyJumpPower()
    movClean("jumppower")
    if not movOpt.JumpPower then return end
    movConns["jumppower"]=RunService.Heartbeat:Connect(function()
        if not movOpt.JumpPower then return end
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            if hum.FloorMaterial~=Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                root.AssemblyLinearVelocity=Vector3.new(
                    root.AssemblyLinearVelocity.X,
                    movOpt.JumpPowerVal,
                    root.AssemblyLinearVelocity.Z)
            end
        end
    end)
end
-- Click TP
local clickTPConn=nil
local function applyClickTP()
    if clickTPConn then clickTPConn:Disconnect() clickTPConn=nil end
    if not movOpt.ClickTP then return end
    clickTPConn=UIS.InputBegan:Connect(function(input,gpe)
        if gpe or not movOpt.ClickTP then return end
        -- T key ou MouseButton1
        local isT=input.KeyCode==Enum.KeyCode.T
        local isClick=input.UserInputType==Enum.UserInputType.MouseButton1
        if isT or isClick then
            local mouse=LP:GetMouse()
            local target=mouse.Hit
            if target then
                local char=LP.Character
                local root=char and char:FindFirstChild("HumanoidRootPart")
                if root then root.CFrame=target+Vector3.new(0,3,0) end
            end
        end
    end)
end
-- Free Camera
local freeCamConn=nil
local freeCamCF=nil
local freeCamSprintDown=false
local function applyFreeCamera()
    movClean("freecam")
    if freeCamConn then freeCamConn:Disconnect() freeCamConn=nil end
    if not movOpt.FreeCamera then
        -- teleport joueur à la position freecam au retour
        if freeCamCF then
            local char=LP.Character
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame=CFrame.new(freeCamCF.Position) end
        end
        Camera.CameraType=Enum.CameraType.Custom
        -- reaffiche le character
        local char=LP.Character
        if char then for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then p.LocalTransparencyModifier=0 end
        end end
        return
    end
    Camera.CameraType=Enum.CameraType.Scriptable
    freeCamCF=Camera.CFrame
    -- cache le character localement
    local char=LP.Character
    if char then for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then p.LocalTransparencyModifier=1 end
    end end
    freeCamConn=UIS.InputBegan:Connect(function(i,gpe)
        if i.KeyCode==Enum.KeyCode.LeftShift then freeCamSprintDown=true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.KeyCode==Enum.KeyCode.LeftShift then freeCamSprintDown=false end
    end)
    movConns["freecam"]=RunService.RenderStepped:Connect(function(dt)
        if not movOpt.FreeCamera then return end
        local speed=movOpt.FreeCamSpeed*(freeCamSprintDown and movOpt.FreeCamSprintMult or 1)*dt
        local cf=freeCamCF
        local lookVec=cf.LookVector
        local rightVec=cf.RightVector
        if UIS:IsKeyDown(Enum.KeyCode.W) then cf=CFrame.new(cf.Position+lookVec*speed)*CFrame.fromEulerAnglesXYZ(cf:ToEulerAnglesXYZ()) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then cf=CFrame.new(cf.Position-lookVec*speed)*CFrame.fromEulerAnglesXYZ(cf:ToEulerAnglesXYZ()) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then cf=CFrame.new(cf.Position-rightVec*speed)*CFrame.fromEulerAnglesXYZ(cf:ToEulerAnglesXYZ()) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then cf=CFrame.new(cf.Position+rightVec*speed)*CFrame.fromEulerAnglesXYZ(cf:ToEulerAnglesXYZ()) end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then cf=CFrame.new(cf.Position+Vector3.new(0,speed,0))*CFrame.fromEulerAnglesXYZ(cf:ToEulerAnglesXYZ()) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then cf=CFrame.new(cf.Position-Vector3.new(0,speed,0))*CFrame.fromEulerAnglesXYZ(cf:ToEulerAnglesXYZ()) end
        local delta=UIS:GetMouseDelta()
        local rx,ry,rz=cf:ToEulerAnglesXYZ()
        cf=CFrame.new(cf.Position)*CFrame.Angles(0,ry-delta.X*0.003,0)*CFrame.Angles(math.clamp(rx-delta.Y*0.003,-1.5,1.5),0,0)
        freeCamCF=cf Camera.CFrame=cf
    end)
end
-- Anti Void
RunService.Heartbeat:Connect(function()
    if not movOpt.AntiVoid then return end
    local char=LP.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if root and root.Position.Y<-100 then
        root.CFrame=CFrame.new(0,50,0)
    end
end)
-- Anti Fling
RunService.Heartbeat:Connect(function()
    if not movOpt.AntiFling then return end
    local char=LP.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local vel=root.AssemblyLinearVelocity
        if vel.Magnitude>200 then
            root.AssemblyLinearVelocity=Vector3.zero
        end
    end
end)
LP.CharacterAdded:Connect(function()
    flyBody=nil
    if movOpt.Fly then task.wait(0.1) applyFly() end
    if movOpt.Speed then applySpeed() end
    if movOpt.Noclip then applyNoclip() end
    if movOpt.BunnyHop then applyBhop() end
    if movOpt.InfJump then applyInfJump() end
    if movOpt.JumpPower then applyJumpPower() end
end)

-- ══════════════════════════════════════════════════════════════════
-- MISC
-- ══════════════════════════════════════════════════════════════════
local miscOpt={
    InfAmmo=false, RapidFire=false, NoRecoil=false,
    Fullbright=false, NoFog=false,
    AntiAFK=false, AutoRejoin=false,
    FPSBoost=false, NoFallDamage=false,
    Watermark=true, InstantInteract=false,
    RemoveShadow=false, ChangeTime=false, TimeValue=14,
    HitboxExpander=false, HitboxSize=5,
}
local miscConns={}
local function miscClean(key)
    if miscConns[key] then miscConns[key]:Disconnect() miscConns[key]=nil end
end
local function applyInfAmmo()
    miscClean("ammo")
    if not miscOpt.InfAmmo then return end
    miscConns["ammo"]=RunService.Heartbeat:Connect(function()
        if not miscOpt.InfAmmo then return end
        local char=LP.Character if not char then return end
        local ammo=char:FindFirstChild("Ammo") or char:FindFirstChild("PrimaryAmmo")
            or char:FindFirstChild("PrimaryOUT")
        if ammo and ammo:IsA("IntValue") then ammo.Value=999 end
    end)
end
local function applyRapidFire()
    miscClean("rapid")
    if not miscOpt.RapidFire then return end
    miscConns["rapid"]=RunService.Heartbeat:Connect(function()
        if not miscOpt.RapidFire then return end
        local char=LP.Character if not char then return end
        local cd=char:FindFirstChild("ShootingCooldown") or char:FindFirstChild("Movetitude")
        if cd and cd:IsA("NumberValue") then cd.Value=0 end
    end)
end
local function applyNoRecoil()
    miscClean("recoil")
    if not miscOpt.NoRecoil then return end
    local lastCF=Camera.CFrame
    miscConns["recoil"]=RunService.RenderStepped:Connect(function()
        if not miscOpt.NoRecoil then return end
        local cur=Camera.CFrame
        local diff=math.abs(cur.LookVector.Y-lastCF.LookVector.Y)
        if diff>0.03 then
            Camera.CFrame=CFrame.new(cur.Position)*CFrame.Angles(
                math.asin(lastCF.LookVector.Y),
                math.atan2(-lastCF.LookVector.X,-lastCF.LookVector.Z),0)
        end
        lastCF=Camera.CFrame
    end)
end
local origAmbient=game.Lighting.Ambient
local origBrightness=game.Lighting.Brightness
local function applyFullbright()
    if miscOpt.Fullbright then
        game.Lighting.Ambient=Color3.fromRGB(255,255,255)
        game.Lighting.Brightness=2
    else
        game.Lighting.Ambient=origAmbient
        game.Lighting.Brightness=origBrightness
    end
end
local origFogEnd=game.Lighting.FogEnd
local origFogStart=game.Lighting.FogStart
local function applyNoFog()
    if miscOpt.NoFog then
        game.Lighting.FogEnd=1e6 game.Lighting.FogStart=1e6
    else
        game.Lighting.FogEnd=origFogEnd game.Lighting.FogStart=origFogStart
    end
end
local function applyAntiAFK()
    miscClean("afk")
    if not miscOpt.AntiAFK then return end
    miscConns["afk"]=RunService.Heartbeat:Connect(function()
        if not miscOpt.AntiAFK then return end
        local vc=LP.Character
        local hum=vc and vc:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.new(0,0,0)) end
    end)
end
local function applyFPSBoost()
    if miscOpt.FPSBoost then
        game.Lighting.GlobalShadows=false
        game.Lighting.FogEnd=1e6
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled=false
            end
        end
    else
        game.Lighting.GlobalShadows=true
    end
end
local function applyNoFallDamage()
    miscClean("falldmg")
    if not miscOpt.NoFallDamage then return end
    miscConns["falldmg"]=RunService.Heartbeat:Connect(function()
        if not miscOpt.NoFallDamage then return end
        local char=LP.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.StateChanged:Connect(function(old,new)
            if new==Enum.HumanoidStateType.Freefall then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
            end
        end) end
    end)
end
local function applyRemoveShadow()
    local char=LP.Character if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if miscOpt.RemoveShadow then p.CastShadow=false
            else p.CastShadow=true end
        end
    end
end
local function applyChangeTime()
    miscClean("time")
    if not miscOpt.ChangeTime then return end
    miscConns["time"]=RunService.Heartbeat:Connect(function()
        if not miscOpt.ChangeTime then return end
        game.Lighting.ClockTime=miscOpt.TimeValue
    end)
end
local function applyHitboxExpander()
    miscClean("hitbox")
    if not miscOpt.HitboxExpander then return end
    miscConns["hitbox"]=RunService.Heartbeat:Connect(function()
        if not miscOpt.HitboxExpander then return end
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LP and player.Character then
                local root=player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size=Vector3.new(miscOpt.HitboxSize,miscOpt.HitboxSize,miscOpt.HitboxSize)
                end
            end
        end
    end)
end
local function applyInstantInteract()
    miscClean("interact")
    if not miscOpt.InstantInteract then return end
    miscConns["interact"]=RunService.Heartbeat:Connect(function()
        if not miscOpt.InstantInteract then return end
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                v.HoldDuration=0 v.MaxActivationDistance=50
            end
        end
    end)
end
-- Watermark
local wmText=Drawing.new("Text")
wmText.Size=14 wmText.Font=Drawing.Fonts.Plex wmText.Outline=true
wmText.Color=Color3.fromRGB(255,255,255)
wmText.Position=Vector2.new(10,30) wmText.ZIndex=10
RunService.RenderStepped:Connect(function()
    wmText.Text="Aurora v"..VERSION.." | "..game.Players.LocalPlayer.Name
    wmText.Visible=miscOpt.Watermark
end)
-- Auto Rejoin
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
    if state==Enum.TeleportState.Failed and miscOpt.AutoRejoin then
        task.wait(5)
        game:GetService("TeleportService"):TeleportToPlaceInstance(PLACE_ID,game.JobId,LP)
    end
end)
LP.CharacterAdded:Connect(function()
    if miscOpt.InfAmmo then task.wait(0.1) applyInfAmmo() end
    if miscOpt.RapidFire then applyRapidFire() end
    if miscOpt.NoRecoil then applyNoRecoil() end
    if miscOpt.AntiAFK then applyAntiAFK() end
    if miscOpt.NoFallDamage then applyNoFallDamage() end
    if miscOpt.RemoveShadow then applyRemoveShadow() end
end)

-- ══════════════════════════════════════════════════════════════════
-- UI FLUENT
-- ══════════════════════════════════════════════════════════════════
local Fluent=loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()
local Window=Fluent:CreateWindow({
    Title="Aurora  •  v"..VERSION, SubTitle="",
    TabWidth=160, Size=UDim2.fromOffset(580,460),
    Theme="Dark", MinimizeKey=Enum.KeyCode.Insert,
})

-- ── ESP Tab ───────────────────────────────────────────────────────
local TabESP=Window:AddTab({Title="ESP",Icon="eye"})
TabESP:AddToggle("ESPBox",{Title="Box",Default=false,Callback=function(v) opt.Box=v end})
TabESP:AddDropdown("ESPBoxStyle",{Title="Style",Default="Box",Values={"Box","CornerBox"},Callback=function(v) opt.BoxStyle=v end})
TabESP:AddToggle("ESPSkeleton",{Title="Skeleton",Default=false,Callback=function(v) opt.Skeleton=v end})
TabESP:AddToggle("ESPTracers",{Title="Tracers",Default=false,Callback=function(v) opt.Tracers=v end})
TabESP:AddDropdown("ESPTracerOrigin",{Title="Origine Tracers",Default="Bottom",Values={"Bottom","Top"},Callback=function(v) opt.TracerOrigin=v end})
TabESP:AddToggle("ESPName",{Title="Name",Default=false,Callback=function(v) opt.Name=v end})
TabESP:AddToggle("ESPHealth",{Title="Health Bar",Default=false,Callback=function(v) opt.Health=v end})
if IS_ARSENAL then TabESP:AddParagraph({Title="⚠ Health Bar",Content="Arsenal ne réplique pas les HP. Indisponible sur ce jeu."}) end
TabESP:AddToggle("ESPDistance",{Title="Distance",Default=false,Callback=function(v) opt.Distance=v end})
TabESP:AddToggle("ESPWeapon",{Title="Weapon",Default=false,Callback=function(v) opt.Weapon=v end})
if IS_ARSENAL then TabESP:AddParagraph({Title="⚠ Weapon",Content="Arsenal ne réplique pas les armes. Indisponible sur ce jeu."}) end
TabESP:AddToggle("ESPHeadDot",{Title="Head Dot",Default=false,Callback=function(v) opt.HeadDot=v end})
TabESP:AddToggle("ESPChams",{Title="Chams",Default=false,Callback=function(v) opt.Chams=v end})
TabESP:AddDropdown("ESPChamsStyle",{Title="Style Chams",Default="Outline",Values={"Outline","Filled"},Callback=function(v) opt.ChamsStyle=v end})
TabESP:AddToggle("ESPHandChams",{Title="Hand Chams",Default=false,Callback=function(v) opt.HandChams=v end})
TabESP:AddColorpicker("ESPHandChamsColor",{Title="Hand Chams Color",Default=Color3.fromRGB(255,100,100),Callback=function(v) opt.HandChamsColor=v end})
TabESP:AddSlider("ESPHandChamsTransp",{Title="Hand Chams Transparency",Default=50,Min=0,Max=100,Rounding=0,Callback=function(v) opt.HandChamsTransp=v/100 end})
TabESP:AddToggle("ESPWallCheck",{Title="Wall Check (couleur selon visibilité)",Default=false,Callback=function(v) opt.WallCheck=v end})
TabESP:AddColorpicker("ESPVisibleColor",{Title="Couleur Visible",Default=Color3.fromRGB(0,255,100),Callback=function(v) opt.VisibleColor=v end})
TabESP:AddColorpicker("ESPNotVisibleColor",{Title="Couleur Non Visible",Default=Color3.fromRGB(255,60,60),Callback=function(v) opt.NotVisibleColor=v end})
TabESP:AddColorpicker("ESPEnemyColor",{Title="Enemy Color",Default=Color3.fromRGB(255,60,60),Callback=function(v) opt.EnemyColor=v end})
TabESP:AddColorpicker("ESPTeamColor",{Title="Team Color",Default=Color3.fromRGB(60,255,120),Callback=function(v) opt.TeamColor=v end})
TabESP:AddToggle("ESPTeamCheck",{Title="Team Check",Default=false,Callback=function(v) opt.TeamCheck=v end})
TabESP:AddSlider("ESPDist",{Title="Distance max",Default=500,Min=50,Max=2000,Rounding=0,Callback=function(v) opt.MaxDist=v end})

-- ── Aim Tab ───────────────────────────────────────────────────────
local TabAim=Window:AddTab({Title="Aim",Icon="crosshair"})
TabAim:AddToggle("AimEnabled",{Title="Aimbot",Default=false,Callback=function(v) aimbotOpt.Enabled=v end})
TabAim:AddParagraph({Title="ℹ Touche de visée",Content="Touche par défaut : Hold Clic Droit. Choix de touche disponible dans l'UI finale."})
TabAim:AddDropdown("AimMethod",{Title="Méthode",Default="Camera Lerp",Values={"Camera Lerp","Instant"},Callback=function(v) aimbotOpt.Method=v end})
TabAim:AddDropdown("AimPriority",{Title="Priorité",Default="FOV",Values={"FOV","Distance","HP","Intelligent"},Callback=function(v) aimbotOpt.Priority=v end})
TabAim:AddSlider("AimFOV",{Title="Rayon de visée (FOV Circle)",Default=120,Min=10,Max=500,Rounding=0,Callback=function(v) aimbotOpt.FOV=v end})
TabAim:AddSlider("AimSmooth",{Title="Smoothness",Default=10,Min=1,Max=50,Rounding=0,Callback=function(v) aimbotOpt.Smoothness=v end})
TabAim:AddDropdown("AimBone",{Title="Partie du corps",Default="Head",
    Values={"Tête=Head","Torse Haut=UpperTorso","Torse=Torso","Torse Bas=LowerTorso","Centre=HumanoidRootPart"},
    Callback=function(v)
        local map={["Tête=Head"]="Head",["Torse Haut=UpperTorso"]="UpperTorso",
            ["Torse=Torso"]="Torso",["Torse Bas=LowerTorso"]="LowerTorso",
            ["Centre=HumanoidRootPart"]="HumanoidRootPart"}
        aimbotOpt.Bone=map[v] or "Head"
    end})
TabAim:AddToggle("AimStickyAim",{Title="Sticky Aim",Default=false,Callback=function(v) aimbotOpt.StickyAim=v end})
TabAim:AddSlider("AimRetarget",{Title="Retarget Delay (s)",Default=0,Min=0,Max=3,Rounding=1,Callback=function(v) aimbotOpt.RetargetDelay=v end})
TabAim:AddSlider("AimHitChance",{Title="Hit Chance (%)",Default=100,Min=1,Max=100,Rounding=0,Callback=function(v) aimbotOpt.HitChance=v end})
TabAim:AddToggle("AimPrediction",{Title="Prediction",Default=false,Callback=function(v) aimbotOpt.Prediction=v end})
TabAim:AddSlider("AimPredAmount",{Title="Prediction Amount",Default=10,Min=1,Max=100,Rounding=0,Callback=function(v) aimbotOpt.PredictionAmount=v/100 end})
TabAim:AddToggle("AimDistMult",{Title="Distance Multiplier",Default=false,Callback=function(v) aimbotOpt.DistMultiplier=v end})
TabAim:AddSlider("AimDistMultVal",{Title="Multiplier",Default=10,Min=1,Max=50,Rounding=0,Callback=function(v) aimbotOpt.DistMult=v/10 end})
TabAim:AddToggle("AimBulletDrop",{Title="Bullet Drop Compensation",Default=false,Callback=function(v) aimbotOpt.BulletDrop=v end})
TabAim:AddSlider("AimDropStr",{Title="Drop Strength",Default=5,Min=1,Max=50,Rounding=0,Callback=function(v) aimbotOpt.DropStrength=v/10 end})
TabAim:AddToggle("AimTeamCheck",{Title="Team Check",Default=true,Callback=function(v) aimbotOpt.TeamCheck=v end})
-- Triggerbot
TabAim:AddToggle("TrigEnabled",{Title="Triggerbot",Default=false,Callback=function(v) trigOpt.Enabled=v end})
TabAim:AddToggle("TrigHold",{Title="Hold Mode (Clic Droit)",Default=false,Callback=function(v) trigOpt.HoldMode=v end})
TabAim:AddSlider("TrigMinDelay",{Title="Min Delay (s)",Default=5,Min=0,Max=100,Rounding=0,Callback=function(v) trigOpt.MinDelay=v/100 end})
TabAim:AddSlider("TrigMaxDelay",{Title="Max Delay (s)",Default=15,Min=0,Max=100,Rounding=0,Callback=function(v) trigOpt.MaxDelay=v/100 end})
TabAim:AddSlider("TrigMissChance",{Title="Miss Chance (%)",Default=0,Min=0,Max=100,Rounding=0,Callback=function(v) trigOpt.MissChance=v end})
-- Weapon options
TabAim:AddToggle("MiscInfAmmo",{Title="Infinite Ammo",Default=false,Callback=function(v) miscOpt.InfAmmo=v applyInfAmmo() end})
TabAim:AddParagraph({Title="⚠ Infinite Ammo",Content="Modifie les valeurs locales. Peut ne pas fonctionner si le jeu vérifie côté serveur."})
TabAim:AddToggle("MiscRapidFire",{Title="Rapid Fire",Default=false,Callback=function(v) miscOpt.RapidFire=v applyRapidFire() end})
TabAim:AddToggle("MiscNoRecoil",{Title="No Recoil",Default=false,Callback=function(v) miscOpt.NoRecoil=v applyNoRecoil() end})
TabAim:AddToggle("MiscHitbox",{Title="Hitbox Expander",Default=false,Callback=function(v) miscOpt.HitboxExpander=v applyHitboxExpander() end})
TabAim:AddSlider("MiscHitboxSize",{Title="Hitbox Size",Default=5,Min=1,Max=30,Rounding=0,Callback=function(v) miscOpt.HitboxSize=v end})

-- ── Radar Tab ─────────────────────────────────────────────────────
local TabRadar=Window:AddTab({Title="Radar",Icon="map"})
TabRadar:AddToggle("RadarEnabled",{Title="Radar",Default=false,Callback=function(v) radarOpt.Enabled=v buildRadar() end})
TabRadar:AddToggle("RadarTeamCheck",{Title="Team Check",Default=false,Callback=function(v) radarOpt.TeamCheck=v end})
TabRadar:AddToggle("RadarNames",{Title="Afficher Noms",Default=false,Callback=function(v) radarOpt.ShowNames=v buildRadar() end})
TabRadar:AddSlider("RadarSize",{Title="Taille Radar",Default=200,Min=100,Max=400,Rounding=0,Callback=function(v) radarOpt.Size=v if radarGui then radarGui.bg.Size=UDim2.fromOffset(v,v) radarGui.bg.Position=getRadarPos() end end})
TabRadar:AddSlider("RadarDist",{Title="Distance Max",Default=300,Min=50,Max=1000,Rounding=0,Callback=function(v) radarOpt.MaxDist=v end})
TabRadar:AddSlider("RadarPlayerSize",{Title="Taille Points",Default=5,Min=2,Max=15,Rounding=0,Callback=function(v) radarOpt.PlayerSize=v end})
TabRadar:AddDropdown("RadarPos",{Title="Position",Default="Bottom Right",Values={"Top Left","Top Right","Bottom Left","Bottom Right"},Callback=function(v) radarOpt.Position=v if radarGui then radarGui.bg.Position=getRadarPos() end end})
TabRadar:AddToggle("RadarCustomColors",{Title="Couleurs Personnalisées",Default=false,Callback=function(v) radarOpt.CustomColors=v end})
TabRadar:AddColorpicker("RadarTeamColor",{Title="Couleur Équipe",Default=Color3.fromRGB(60,255,120),Callback=function(v) radarOpt.TeamColor=v end})
TabRadar:AddColorpicker("RadarEnemyColor",{Title="Couleur Ennemi",Default=Color3.fromRGB(255,60,60),Callback=function(v) radarOpt.EnemyColor=v end})
TabRadar:AddColorpicker("RadarLocalColor",{Title="Couleur Joueur Local",Default=Color3.fromRGB(255,255,255),Callback=function(v) radarOpt.LocalColor=v buildRadar() end})
TabRadar:AddColorpicker("RadarBgColor",{Title="Couleur Fond",Default=Color3.fromRGB(0,0,0),Callback=function(v) radarOpt.BgColor=v if radarGui then radarGui.bg.BackgroundColor3=v end end})
TabRadar:AddSlider("RadarBgTransp",{Title="Transparence Fond",Default=50,Min=0,Max=100,Rounding=0,Callback=function(v) radarOpt.BgTransp=v/100 if radarGui then radarGui.bg.BackgroundTransparency=v/100 end end})

-- ── Movement Tab ──────────────────────────────────────────────────
local TabMov=Window:AddTab({Title="Movement",Icon="zap"})
TabMov:AddToggle("MovSpeed",{Title="Speed",Default=false,Callback=function(v) movOpt.Speed=v applySpeed() end})
TabMov:AddSlider("MovSpeedVal",{Title="Walk Speed",Default=24,Min=16,Max=150,Rounding=0,Callback=function(v) movOpt.SpeedVal=v end})
TabMov:AddToggle("MovFly",{Title="Fly (WASD + Space/Ctrl)",Default=false,Callback=function(v) movOpt.Fly=v applyFly() end})
TabMov:AddSlider("MovFlySpeed",{Title="Fly Speed",Default=50,Min=10,Max=300,Rounding=0,Callback=function(v) movOpt.FlySpeed=v end})
TabMov:AddToggle("MovNoclip",{Title="Noclip",Default=false,Callback=function(v) movOpt.Noclip=v applyNoclip() end})
TabMov:AddToggle("MovBhop",{Title="BunnyHop",Default=false,Callback=function(v) movOpt.BunnyHop=v applyBhop() end})
TabMov:AddToggle("MovInfJump",{Title="Infinite Jump",Default=false,Callback=function(v) movOpt.InfJump=v applyInfJump() end})
TabMov:AddToggle("MovJumpPower",{Title="Jump Power",Default=false,Callback=function(v) movOpt.JumpPower=v applyJumpPower() end})
TabMov:AddSlider("MovJumpPowerVal",{Title="Jump Force",Default=50,Min=50,Max=500,Rounding=0,Callback=function(v) movOpt.JumpPowerVal=v end})
TabMov:AddToggle("MovClickTP",{Title="Click TP (T ou Clic Gauche)",Default=false,Callback=function(v) movOpt.ClickTP=v applyClickTP() end})
TabMov:AddToggle("MovFreeCamera",{Title="Free Camera (WASD + Shift sprint)",Default=false,Callback=function(v) movOpt.FreeCamera=v applyFreeCamera() end})
TabMov:AddSlider("MovFreeCamSpeed",{Title="Free Cam Speed",Default=50,Min=5,Max=200,Rounding=0,Callback=function(v) movOpt.FreeCamSpeed=v end})
TabMov:AddSlider("MovFreeCamSprint",{Title="Sprint Multiplier",Default=3,Min=1,Max=10,Rounding=0,Callback=function(v) movOpt.FreeCamSprintMult=v end})
TabMov:AddToggle("MovAntiVoid",{Title="Anti Void",Default=false,Callback=function(v) movOpt.AntiVoid=v end})
TabMov:AddToggle("MovAntiFling",{Title="Anti Fling",Default=false,Callback=function(v) movOpt.AntiFling=v end})

-- ── World Tab ─────────────────────────────────────────────────────
local TabWorld=Window:AddTab({Title="World",Icon="sun"})
TabWorld:AddToggle("WorldFullbright",{Title="Fullbright",Default=false,Callback=function(v) miscOpt.Fullbright=v applyFullbright() end})
TabWorld:AddToggle("WorldNoFog",{Title="No Fog",Default=false,Callback=function(v) miscOpt.NoFog=v applyNoFog() end})
TabWorld:AddToggle("WorldRemoveShadow",{Title="Remove Shadow",Default=false,Callback=function(v) miscOpt.RemoveShadow=v applyRemoveShadow() end})
TabWorld:AddToggle("WorldChangeTime",{Title="Change Time",Default=false,Callback=function(v) miscOpt.ChangeTime=v applyChangeTime() end})
TabWorld:AddSlider("WorldTimeVal",{Title="Heure",Default=14,Min=0,Max=24,Rounding=0,Callback=function(v) miscOpt.TimeValue=v end})
TabWorld:AddParagraph({Title="ℹ Third Person",Content="Disponible dans l'UI finale. Arsenal empêche la modification du zoom."})

-- ── Misc Tab ──────────────────────────────────────────────────────
local TabMisc=Window:AddTab({Title="Misc",Icon="settings"})
TabMisc:AddToggle("MiscAntiAFK",{Title="Anti-AFK",Default=false,Callback=function(v) miscOpt.AntiAFK=v applyAntiAFK() end})
TabMisc:AddToggle("MiscAutoRejoin",{Title="Auto Rejoin",Default=false,Callback=function(v) miscOpt.AutoRejoin=v end})
TabMisc:AddToggle("MiscFPSBoost",{Title="FPS Boost",Default=false,Callback=function(v) miscOpt.FPSBoost=v applyFPSBoost() end})
TabMisc:AddToggle("MiscNoFallDmg",{Title="No Fall Damage",Default=false,Callback=function(v) miscOpt.NoFallDamage=v applyNoFallDamage() end})
TabMisc:AddToggle("MiscWatermark",{Title="Watermark",Default=true,Callback=function(v) miscOpt.Watermark=v end})
TabMisc:AddToggle("MiscInstantInteract",{Title="Instant Interact",Default=false,Callback=function(v) miscOpt.InstantInteract=v applyInstantInteract() end})

Window:SelectTab(1)
print("[Aurora v"..VERSION.."] Chargé ✓")
