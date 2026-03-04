-- ============================================================
--  Radar — Modern mini-map, draggable + resizable
--  Dots clipped to circle border
-- ============================================================
local Radar = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer
local Utils, Config
function Radar.SetDependencies(u,c) Utils=u; Config=c end

local gui, frame, titleLbl
local conn, visible = nil, false
local posX, posY = 14, nil
local dots, localDot = {}, nil

local function buildGUI(sz)
    gui = Instance.new("ScreenGui")
    gui.Name="NexusESP_Radar"; gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
    pcall(function() syn.protect_gui(gui) end)
    pcall(function() gui.Parent=game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent=LP:WaitForChild("PlayerGui") end

    local vp = Utils.GetViewport()
    posY = posY or (vp.Y - sz - 50)

    frame = Instance.new("Frame")
    frame.BackgroundColor3=Color3.fromRGB(8,8,12); frame.BorderSizePixel=0
    frame.ClipsDescendants=false
    frame.Size=UDim2.fromOffset(sz, sz+32); frame.Position=UDim2.fromOffset(posX, posY)
    frame.Parent=gui
    local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(0,10); fc.Parent=frame
    local fs=Instance.new("UIStroke"); fs.Color=Color3.fromRGB(35,35,55); fs.Thickness=1; fs.Parent=frame

    -- Header
    local header=Instance.new("Frame")
    header.BackgroundColor3=Color3.fromRGB(5,5,10); header.BorderSizePixel=0
    header.Size=UDim2.new(1,0,0,32); header.Parent=frame
    local hc=Instance.new("UICorner"); hc.CornerRadius=UDim.new(0,10); hc.Parent=header

    -- Accent bar
    local acc=Instance.new("Frame"); acc.BackgroundColor3=Color3.fromRGB(0,120,255)
    acc.BorderSizePixel=0; acc.Size=UDim2.fromOffset(3,32); acc.Parent=header
    local ac=Instance.new("UICorner"); ac.CornerRadius=UDim.new(0,2); ac.Parent=acc

    titleLbl=Instance.new("TextLabel")
    titleLbl.Text="🗺  RADAR"; titleLbl.Font=Enum.Font.GothamBold
    titleLbl.TextSize=12; titleLbl.TextColor3=Color3.fromRGB(0,180,255)
    titleLbl.BackgroundTransparency=1; titleLbl.Size=UDim2.new(1,-60,1,0)
    titleLbl.Position=UDim2.fromOffset(10,0); titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    titleLbl.Parent=header

    -- Close button
    local close=Instance.new("TextButton")
    close.Text="×"; close.Font=Enum.Font.GothamBold; close.TextSize=18
    close.TextColor3=Color3.new(1,1,1); close.BackgroundColor3=Color3.fromRGB(150,25,25)
    close.BorderSizePixel=0; close.Size=UDim2.fromOffset(24,24)
    close.Position=UDim2.new(1,-28,0,4); close.Parent=header
    local cc2=Instance.new("UICorner"); cc2.CornerRadius=UDim.new(0,5); cc2.Parent=close
    close.MouseButton1Click:Connect(function() Radar.Hide() end)

    -- Drag
    local drag,ds,sp_
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;sp_=frame.Position end
    end)
    header.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            local nx=sp_.X.Offset+d.X; local ny=sp_.Y.Offset+d.Y
            frame.Position=UDim2.fromOffset(nx,ny); posX=nx; posY=ny
        end
    end)

    -- Resize handle
    local rsz=Instance.new("TextButton")
    rsz.Text="⇲"; rsz.Font=Enum.Font.GothamBold; rsz.TextSize=12
    rsz.TextColor3=Color3.fromRGB(80,80,100); rsz.BackgroundColor3=Color3.fromRGB(18,18,28)
    rsz.BorderSizePixel=0; rsz.Size=UDim2.fromOffset(16,16)
    rsz.Position=UDim2.new(1,-16,1,-16); rsz.Parent=frame
    local rc=Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,3); rc.Parent=rsz
    local resizing,rs_,rSize_
    rsz.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=true;rs_=i.Position;rSize_=frame.AbsoluteSize end
    end)
    rsz.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-rs_
            local ns=math.clamp(rSize_.X+d.X,100,500)
            frame.Size=UDim2.fromOffset(ns,ns+32)
            if Config then Config.Current.Radar=Config.Current.Radar or {}; Config.Current.Radar.Size=ns end
        end
    end)
end

-- Clamp dot inside circle
local function clampToCircle(center, point, radius)
    local dir = point - center
    if dir.Magnitude > radius then
        dir = dir.Unit * (radius - 2)
    end
    return center + dir
end

local function getOrMakeDot(i)
    if not dots[i] then
        local d = Drawing.new("Circle")
        d.Radius=4; d.Filled=true; d.NumSides=12; d.Color=Color3.fromRGB(220,60,60); d.Visible=false
        local lbl = Drawing.new("Text")
        lbl.Size=9; lbl.Color=Color3.new(1,1,1); lbl.Outline=false; lbl.Center=true; lbl.Visible=false
        dots[i]={dot=d,lbl=lbl}
    end
    return dots[i]
end

local function updateRadar()
    if not visible or not frame or not frame.Parent then return end
    local cfg = Config and Config.Current and Config.Current.Radar or {}
    if cfg.Enabled==false then return end

    local fSz    = frame.AbsoluteSize.X
    local halfSz = (fSz)/2
    local radius = halfSz - 4  -- clipping radius
    local abs    = frame.AbsolutePosition
    local center = Vector2.new(abs.X + halfSz, abs.Y + 32 + halfSz)
    local range  = cfg.Range or 200

    -- Circle border (drawn each frame via Drawing)
    -- Note: we use the circle border as a Drawing overlay
    if not Radar._border then
        Radar._border = Drawing.new("Circle")
        Radar._border.Filled=false; Radar._border.NumSides=128
        Radar._border.Thickness=1; Radar._border.Color=Color3.fromRGB(40,40,65)
        Radar._border.Visible=true
    end
    if not Radar._bgCircle then
        Radar._bgCircle = Drawing.new("Circle")
        Radar._bgCircle.Filled=true; Radar._bgCircle.NumSides=128
        Radar._bgCircle.Color=Color3.fromRGB(8,8,14); Radar._bgCircle.Transparency=0.2
        Radar._bgCircle.Visible=true
    end
    Radar._border.Position = center; Radar._border.Radius = radius+1
    Radar._bgCircle.Position = center; Radar._bgCircle.Radius = radius

    -- Local player dot
    if not localDot then
        localDot = Drawing.new("Circle")
        localDot.Radius=5; localDot.Filled=true; localDot.NumSides=12
        localDot.Color=Color3.fromRGB(0,200,255); localDot.Visible=true
    end
    localDot.Position = center

    -- Radar title count
    local lp    = Players.LocalPlayer
    local char  = lp.Character
    local lpPos = char and Utils.GetRoot(char) and Utils.GetRoot(char).Position or Vector3.new(0,0,0)
    local camCF = Workspace.CurrentCamera.CFrame
    local right = camCF.RightVector
    local fwd   = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
    local scale = radius / range

    local idx = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player==lp then continue end
        local pc   = player.Character
        local root = pc and Utils.GetRoot(pc)
        if not root then continue end

        local rel = root.Position - lpPos
        local dx  =  rel:Dot(right)
        local dz  = -rel:Dot(fwd)
        local raw = Vector2.new(center.X + dx*scale, center.Y + dz*scale)
        local pos = clampToCircle(center, raw, radius)

        idx = idx+1
        local b   = getOrMakeDot(idx)
        local col = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(220,60,60)
        b.dot.Position=pos; b.dot.Color=col; b.dot.Visible=true
        b.lbl.Text=player.Name:sub(1,6)
        b.lbl.Position=pos+Vector2.new(0,-11)
        b.lbl.Visible=(cfg.ShowNames~=false)
    end

    for i=idx+1,#dots do
        if dots[i] then dots[i].dot.Visible=false; dots[i].lbl.Visible=false end
    end
end

function Radar.Show()
    if visible then return end; visible=true
    local sz=(Config and Config.Current and Config.Current.Radar and Config.Current.Radar.Size) or 160
    buildGUI(sz)
    conn=RunService.RenderStepped:Connect(function() pcall(updateRadar) end)
end

function Radar.Hide()
    visible=false
    if conn then conn:Disconnect(); conn=nil end
    if gui  then gui:Destroy(); gui=nil; frame=nil end
    if localDot then pcall(function() localDot:Remove() end); localDot=nil end
    if Radar._border   then pcall(function() Radar._border:Remove() end); Radar._border=nil end
    if Radar._bgCircle then pcall(function() Radar._bgCircle:Remove() end); Radar._bgCircle=nil end
    for _,b in ipairs(dots) do pcall(function() b.dot:Remove(); b.lbl:Remove() end) end
    dots={}
end

function Radar.Toggle() if visible then Radar.Hide() else Radar.Show() end end
return Radar
