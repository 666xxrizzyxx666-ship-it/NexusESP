-- ============================================================
--  Radar.lua — Mini-radar 2D moderne, draggable + resizable
-- ============================================================
local Radar = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer

local Utils, Config
function Radar.SetDependencies(u,c) Utils=u; Config=c end

-- ── Etat ─────────────────────────────────────────────────────
local gui, frame, canvas, titleLbl, dotPool
local conn, visible = nil, false
local SIZE_MIN, SIZE_MAX = 100, 400
local posX, posY = 10, nil   -- nil = calculé au Show

-- ── Build GUI ─────────────────────────────────────────────────
local function buildGUI(sz)
    local LP = Players.LocalPlayer
    gui = Instance.new("ScreenGui")
    gui.Name = "NexusESP_Radar"; gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
    pcall(function() syn.protect_gui(gui) end)
    pcall(function() gui.Parent=game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent=LP:WaitForChild("PlayerGui") end

    local vp = Utils.GetViewport()
    posY = posY or (vp.Y - sz - 40)

    frame = Instance.new("Frame")
    frame.Name="RadarFrame"; frame.BackgroundColor3=Color3.fromRGB(10,10,14)
    frame.BorderSizePixel=0; frame.Size=UDim2.fromOffset(sz, sz+24)
    frame.Position=UDim2.fromOffset(posX, posY); frame.ClipsDescendants=true
    frame.Parent=gui

    local stroke = Instance.new("UIStroke")
    stroke.Color=Color3.fromRGB(40,40,60); stroke.Thickness=1; stroke.Parent=frame
    local corner = Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,8); corner.Parent=frame

    -- Header drag
    local header = Instance.new("Frame")
    header.BackgroundColor3=Color3.fromRGB(6,6,10); header.BorderSizePixel=0
    header.Size=UDim2.new(1,0,0,24); header.Parent=frame
    local hc=Instance.new("UICorner"); hc.CornerRadius=UDim.new(0,8); hc.Parent=header

    titleLbl = Instance.new("TextLabel")
    titleLbl.Text="⬡ RADAR"; titleLbl.Font=Enum.Font.GothamBold
    titleLbl.TextSize=11; titleLbl.TextColor3=Color3.fromRGB(0,180,255)
    titleLbl.BackgroundTransparency=1; titleLbl.Size=UDim2.new(1,-30,1,0)
    titleLbl.Position=UDim2.fromOffset(8,0); titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    titleLbl.Parent=header

    -- Bouton close
    local closeBtn=Instance.new("TextButton")
    closeBtn.Text="×"; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=16
    closeBtn.TextColor3=Color3.new(1,1,1); closeBtn.BackgroundColor3=Color3.fromRGB(160,30,30)
    closeBtn.BorderSizePixel=0; closeBtn.Size=UDim2.fromOffset(20,20)
    closeBtn.Position=UDim2.new(1,-22,0,2); closeBtn.Parent=header
    local cc2=Instance.new("UICorner"); cc2.CornerRadius=UDim.new(0,4); cc2.Parent=closeBtn
    closeBtn.MouseButton1Click:Connect(function() Radar.Hide() end)

    -- Zone de dessin radar
    canvas = Instance.new("Frame")
    canvas.BackgroundTransparency=1; canvas.BorderSizePixel=0
    canvas.Size=UDim2.new(1,0,1,-24); canvas.Position=UDim2.fromOffset(0,24)
    canvas.Parent=frame

    -- ── Drag ──────────────────────────────────────────────
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=inp.Position
            startPos=frame.Position
        end
    end)
    header.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-dragStart
            local nx=startPos.X.Offset+d.X
            local ny=startPos.Y.Offset+d.Y
            frame.Position=UDim2.fromOffset(nx, ny)
            posX=nx; posY=ny
        end
    end)

    -- ── Resize (coin bas-droit) ────────────────────────────
    local resizeHandle=Instance.new("TextButton")
    resizeHandle.Text="⊞"; resizeHandle.Font=Enum.Font.Gotham; resizeHandle.TextSize=12
    resizeHandle.TextColor3=Color3.fromRGB(80,80,100)
    resizeHandle.BackgroundColor3=Color3.fromRGB(20,20,30)
    resizeHandle.BorderSizePixel=0; resizeHandle.Size=UDim2.fromOffset(16,16)
    resizeHandle.Position=UDim2.new(1,-16,1,-16); resizeHandle.Parent=frame
    local rc=Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,3); rc.Parent=resizeHandle

    local resizing, resizeStart, startSize
    resizeHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            resizing=true; resizeStart=inp.Position
            startSize=frame.AbsoluteSize
        end
    end)
    resizeHandle.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if resizing and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-resizeStart
            local ns=math.clamp(startSize.X+d.X, SIZE_MIN, SIZE_MAX)
            frame.Size=UDim2.fromOffset(ns, ns+24)
            if Config then Config.Current.Radar = Config.Current.Radar or {}; Config.Current.Radar.Size=ns end
        end
    end)

    dotPool = {}
end

-- ── Blips ─────────────────────────────────────────────────────
local function getBlip(i)
    if not dotPool[i] then
        local out=Drawing.new("Circle"); out.Radius=5; out.Filled=true; out.Color=Color3.new(0,0,0); out.NumSides=8; out.Visible=false
        local dot=Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Color=Color3.fromRGB(255,60,60); dot.NumSides=8; dot.Visible=false
        local lbl=Drawing.new("Text");   lbl.Size=9;   lbl.Color=Color3.new(1,1,1); lbl.Outline=true; lbl.Center=true; lbl.Visible=false
        dotPool[i]={out=out,dot=dot,lbl=lbl}
    end
    return dotPool[i]
end

local function worldToRadar(center, lpPos, tPos, halfSz, range)
    local camCF = Workspace.CurrentCamera.CFrame
    local rel   = tPos - lpPos
    local right = camCF.RightVector
    local fwd   = Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z).Unit
    local dx    =  rel:Dot(right)
    local dz    = -rel:Dot(fwd)
    local scale = (halfSz-6)/range
    local px    = math.clamp(center.X+dx*scale, center.X-halfSz+4, center.X+halfSz-4)
    local py    = math.clamp(center.Y+dz*scale, center.Y-halfSz+4, center.Y+halfSz-4)
    return Vector2.new(px, py)
end

-- ── Update ────────────────────────────────────────────────────
local localDot, localOut

local function updateRadar()
    if not visible or not frame or not frame.Parent then return end
    local cfg = Config and Config.Current and Config.Current.Radar or {}
    if cfg.Enabled==false then return end

    local sz     = frame.AbsoluteSize.X
    local halfSz = sz/2
    local abs    = frame.AbsolutePosition
    local center = Vector2.new(abs.X + halfSz, abs.Y + 24 + halfSz)
    local range  = cfg.Range or 200

    -- Joueur local (croix bleue)
    if not localOut then
        localOut = Drawing.new("Circle"); localOut.Radius=6; localOut.Filled=true; localOut.Color=Color3.new(0,0,0); localOut.NumSides=8
        localDot = Drawing.new("Circle"); localDot.Radius=5; localDot.Filled=true; localDot.Color=Color3.fromRGB(0,200,255); localDot.NumSides=8
    end
    localOut.Position=center; localOut.Visible=true
    localDot.Position=center; localDot.Visible=true

    local char  = LP.Character
    local lpPos = char and Utils.GetRoot(char) and Utils.GetRoot(char).Position or Vector3.new(0,0,0)

    local idx = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player==LP then continue end
        local pc   = player.Character
        local root = pc and Utils.GetRoot(pc)
        if not root then continue end

        local dist = Utils.GetDistance(root.Position)
        if dist > range*2 then continue end

        idx = idx+1
        local blip = getBlip(idx)
        local bpos = worldToRadar(center, lpPos, root.Position, halfSz, range)
        local col  = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(220,60,60)
        local hp   = Utils.GetHealthPercent(pc)

        blip.out.Position=bpos; blip.out.Visible=true
        blip.dot.Position=bpos; blip.dot.Color=col; blip.dot.Visible=true
        blip.lbl.Text=player.Name:sub(1,6)
        blip.lbl.Position=bpos+Vector2.new(0,-11)
        blip.lbl.Visible=(cfg.ShowNames~=false)
    end

    for i=idx+1, #dotPool do
        if dotPool[i] then
            dotPool[i].out.Visible=false; dotPool[i].dot.Visible=false; dotPool[i].lbl.Visible=false
        end
    end
end

-- ── API ───────────────────────────────────────────────────────
function Radar.Show()
    if visible then return end
    visible = true
    local sz = (Config and Config.Current and Config.Current.Radar and Config.Current.Radar.Size) or 160
    buildGUI(sz)
    conn = RunService.RenderStepped:Connect(function() pcall(updateRadar) end)
end

function Radar.Hide()
    visible = false
    if conn    then conn:Disconnect(); conn=nil end
    if gui     then gui:Destroy(); gui=nil; frame=nil; canvas=nil end
    if localDot  then pcall(function() localDot:Remove()  end); localDot=nil  end
    if localOut  then pcall(function() localOut:Remove()  end); localOut=nil  end
    if dotPool then
        for _, b in ipairs(dotPool) do
            pcall(function() b.out:Remove(); b.dot:Remove(); b.lbl:Remove() end)
        end
        dotPool={}
    end
end

function Radar.Toggle()
    if visible then Radar.Hide() else Radar.Show() end
end

return Radar
