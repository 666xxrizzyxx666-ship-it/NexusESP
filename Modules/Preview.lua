-- ============================================================
--  Preview — Draggable window with live ESP preview
--  Uses a real R15 dummy in Workspace, updates with config
-- ============================================================
local Preview = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")

local Utils, Config, ESP_ref

function Preview.SetDependencies(u, c, e)
    Utils   = u; Config = c; ESP_ref = e
end

local gui, frame, visible = nil, nil, false
local dummy, fakePlayer, entity
local renderConn, uiConn

-- ── Build the R15 dummy ───────────────────────────────────────
local COLORS = {
    Head         = Color3.fromRGB(255, 220, 177),
    UpperTorso   = Color3.fromRGB(40,  90,  160),
    LowerTorso   = Color3.fromRGB(40,  90,  160),
    RightUpperArm= Color3.fromRGB(255, 220, 177),
    RightLowerArm= Color3.fromRGB(255, 220, 177),
    RightHand    = Color3.fromRGB(255, 220, 177),
    LeftUpperArm = Color3.fromRGB(255, 220, 177),
    LeftLowerArm = Color3.fromRGB(255, 220, 177),
    LeftHand     = Color3.fromRGB(255, 220, 177),
    RightUpperLeg= Color3.fromRGB(30,  50,  120),
    RightLowerLeg= Color3.fromRGB(30,  50,  120),
    RightFoot    = Color3.fromRGB(20,  20,  20),
    LeftUpperLeg = Color3.fromRGB(30,  50,  120),
    LeftLowerLeg = Color3.fromRGB(30,  50,  120),
    LeftFoot     = Color3.fromRGB(20,  20,  20),
    HumanoidRootPart=Color3.fromRGB(40,90,160),
}
local PARTS = {
    {n="Head",          sz=Vector3.new(1.2,1.2,1.2), off=Vector3.new(0,3.2,0)},
    {n="UpperTorso",    sz=Vector3.new(1.8,1.4,1),   off=Vector3.new(0,1.9,0)},
    {n="LowerTorso",    sz=Vector3.new(1.8,0.8,1),   off=Vector3.new(0,0.85,0)},
    {n="RightUpperArm", sz=Vector3.new(0.9,1.2,0.9), off=Vector3.new(1.4,1.9,0)},
    {n="RightLowerArm", sz=Vector3.new(0.8,1,0.8),   off=Vector3.new(1.4,0.65,0)},
    {n="RightHand",     sz=Vector3.new(0.8,0.5,0.8), off=Vector3.new(1.4,-0.05,0)},
    {n="LeftUpperArm",  sz=Vector3.new(0.9,1.2,0.9), off=Vector3.new(-1.4,1.9,0)},
    {n="LeftLowerArm",  sz=Vector3.new(0.8,1,0.8),   off=Vector3.new(-1.4,0.65,0)},
    {n="LeftHand",      sz=Vector3.new(0.8,0.5,0.8), off=Vector3.new(-1.4,-0.05,0)},
    {n="RightUpperLeg", sz=Vector3.new(0.9,1.2,0.9), off=Vector3.new(0.55,-0.65,0)},
    {n="RightLowerLeg", sz=Vector3.new(0.85,1.1,0.85),off=Vector3.new(0.55,-1.8,0)},
    {n="RightFoot",     sz=Vector3.new(0.9,0.4,1.2), off=Vector3.new(0.55,-2.65,0)},
    {n="LeftUpperLeg",  sz=Vector3.new(0.9,1.2,0.9), off=Vector3.new(-0.55,-0.65,0)},
    {n="LeftLowerLeg",  sz=Vector3.new(0.85,1.1,0.85),off=Vector3.new(-0.55,-1.8,0)},
    {n="LeftFoot",      sz=Vector3.new(0.9,0.4,1.2), off=Vector3.new(-0.55,-2.65,0)},
    {n="HumanoidRootPart",sz=Vector3.new(2,1.5,1),   off=Vector3.new(0,1.5,0)},
}

local function buildDummy()
    if dummy then dummy:Destroy() end
    dummy = Instance.new("Folder"); dummy.Name="NexusESP_Preview"; dummy.Parent=Workspace
    local camCF = Workspace.CurrentCamera.CFrame * CFrame.new(0,0,-10)
    for _,d in ipairs(PARTS) do
        local p=Instance.new("Part"); p.Name=d.n; p.Size=d.sz
        p.CFrame=camCF*CFrame.new(d.off); p.Anchored=true; p.CanCollide=false
        p.Color=COLORS[d.n] or Color3.fromRGB(200,200,200)
        p.Material=Enum.Material.SmoothPlastic; p.CastShadow=false
        p.Parent=dummy
    end
    local hum=Instance.new("Humanoid"); hum.Health=75; hum.MaxHealth=100; hum.Parent=dummy
    fakePlayer = {Name="Preview", Character=dummy, Team=nil}
end

-- ── Build the GUI window ──────────────────────────────────────
local function buildGUI()
    gui=Instance.new("ScreenGui")
    gui.Name="NexusESP_Preview"; gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
    pcall(function() syn.protect_gui(gui) end)
    pcall(function() gui.Parent=game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end

    frame=Instance.new("Frame")
    frame.BackgroundColor3=Color3.fromRGB(10,10,14); frame.BorderSizePixel=0
    frame.Size=UDim2.fromOffset(260,100); frame.Position=UDim2.fromOffset(700,100)
    frame.Parent=gui
    local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(0,10); fc.Parent=frame
    local fs=Instance.new("UIStroke"); fs.Color=Color3.fromRGB(35,35,55); fs.Thickness=1; fs.Parent=frame

    local header=Instance.new("Frame")
    header.BackgroundColor3=Color3.fromRGB(5,5,10); header.BorderSizePixel=0
    header.Size=UDim2.new(1,0,0,32); header.Parent=frame
    local hc=Instance.new("UICorner"); hc.CornerRadius=UDim.new(0,10); hc.Parent=header

    local acc=Instance.new("Frame"); acc.BackgroundColor3=Color3.fromRGB(0,120,255)
    acc.BorderSizePixel=0; acc.Size=UDim2.fromOffset(3,32); acc.Parent=header

    local title=Instance.new("TextLabel")
    title.Text="👁  PREVIEW  — live"; title.Font=Enum.Font.GothamBold
    title.TextSize=12; title.TextColor3=Color3.fromRGB(0,200,255)
    title.BackgroundTransparency=1; title.Size=UDim2.new(1,-40,1,0)
    title.Position=UDim2.fromOffset(10,0); title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=header

    local close=Instance.new("TextButton")
    close.Text="×"; close.Font=Enum.Font.GothamBold; close.TextSize=18
    close.TextColor3=Color3.new(1,1,1); close.BackgroundColor3=Color3.fromRGB(150,25,25)
    close.BorderSizePixel=0; close.Size=UDim2.fromOffset(24,24)
    close.Position=UDim2.new(1,-28,0,4); close.Parent=header
    local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,5); cc.Parent=close
    close.MouseButton1Click:Connect(function() Preview.Hide() end)

    local infoLbl=Instance.new("TextLabel")
    infoLbl.Name="InfoLbl"; infoLbl.Text="Dummy spawne devant ta camera"
    infoLbl.Font=Enum.Font.Gotham; infoLbl.TextSize=10
    infoLbl.TextColor3=Color3.fromRGB(130,130,145)
    infoLbl.BackgroundTransparency=1; infoLbl.Size=UDim2.new(1,0,0,30)
    infoLbl.Position=UDim2.fromOffset(0,34); infoLbl.TextXAlignment=Enum.TextXAlignment.Center
    infoLbl.Parent=frame

    local relocBtn=Instance.new("TextButton")
    relocBtn.Text="🔄  Repositionner dummy"
    relocBtn.Font=Enum.Font.GothamMedium; relocBtn.TextSize=11
    relocBtn.TextColor3=Color3.new(1,1,1); relocBtn.BackgroundColor3=Color3.fromRGB(30,80,30)
    relocBtn.BorderSizePixel=0; relocBtn.Size=UDim2.new(1,-16,0,26)
    relocBtn.Position=UDim2.fromOffset(8,66); relocBtn.Parent=frame
    local rc=Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,6); rc.Parent=relocBtn
    relocBtn.MouseButton1Click:Connect(function()
        if dummy then
            local camCF=Workspace.CurrentCamera.CFrame*CFrame.new(0,0,-10)
            for _,d in ipairs(PARTS) do
                local p=dummy:FindFirstChild(d.n)
                if p then p.CFrame=camCF*CFrame.new(d.off) end
            end
        end
    end)

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
            frame.Position=UDim2.fromOffset(sp_.X.Offset+d.X, sp_.Y.Offset+d.Y)
        end
    end)
end

-- ── Entity for dummy ─────────────────────────────────────────
local function makeSafe(mod, arg)
    if mod and mod.Create then
        local ok,r=pcall(mod.Create, arg); if ok and r then return r end
    end
    return {Update=function()end,Hide=function()end,Remove=function()end}
end

function Preview.Show()
    if visible then return end; visible=true
    buildDummy(); buildGUI()

    -- Get modules from ESP
    local mods = ESP_ref and ESP_ref._modules or {}
    entity = {
        box       = makeSafe(mods.Box),
        cornerBox = makeSafe(mods.CornerBox),
        skeleton  = makeSafe(mods.Skeleton),
        tracers   = makeSafe(mods.Tracers),
        health    = makeSafe(mods.Health),
        name      = makeSafe(mods.Name, fakePlayer),
        distance  = makeSafe(mods.Distance),
    }

    renderConn = RunService.RenderStepped:Connect(function()
        if not dummy or not dummy.Parent then return end
        local cfg = Config.Current
        entity.box:Update(dummy, cfg.Box)
        if cfg.CornerBox and cfg.CornerBox.Enabled then entity.box:Hide() else entity.cornerBox:Hide() end
        entity.cornerBox:Update(dummy, cfg.CornerBox)
        entity.skeleton:Update(dummy, cfg.Skeleton)
        entity.tracers:Update(dummy, cfg.Tracers)
        entity.health:Update(dummy, cfg.Health)
        entity.name:Update(dummy, cfg.Name)
        entity.distance:Update(dummy, cfg.Distance)
    end)
end

function Preview.Hide()
    visible=false
    if renderConn then renderConn:Disconnect(); renderConn=nil end
    if entity then
        for _,e in pairs(entity) do pcall(function() e:Remove() end) end
        entity=nil
    end
    if dummy then dummy:Destroy(); dummy=nil end
    if gui   then gui:Destroy(); gui=nil; frame=nil end
    fakePlayer=nil
end

function Preview.Toggle() if visible then Preview.Hide() else Preview.Show() end end
return Preview
