local PlayerList = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer
local Utils, Config, ESP_ref
function PlayerList.SetDependencies(u,c,e) Utils=u; Config=c; ESP_ref=e end

local function C(r,g,b) return Color3.fromRGB(r,g,b) end

local gui, mainFrame, listScroll, specFrame, tabMainBtn, tabSpecBtn
local rows, updateConn, specConn = {}, nil, nil
local spectateTarget = nil
local filterMode = "All"
local espOff = {}   -- [player]=bool
local expanded = {} -- [player]=bool
local visible = false

local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p end
local function mkLabel(props)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1
    l.Font=Enum.Font.GothamMedium; l.TextColor3=C(220,220,230); l.TextSize=12
    for k,v in pairs(props) do pcall(function() l[k]=v end) end; return l
end
local function mkBtn(props, cb)
    local b=Instance.new("TextButton"); b.Font=Enum.Font.GothamBold; b.TextSize=11
    b.TextColor3=Color3.new(1,1,1); b.BorderSizePixel=0; b.AutoButtonColor=true
    for k,v in pairs(props) do pcall(function() b[k]=v end) end
    if cb then b.MouseButton1Click:Connect(cb) end; return b
end

local function getCLR()
    local ui = Config and Config.Current and Config.Current.UI or {}
    return {
        accent = ui.Accent and C(ui.Accent.R,ui.Accent.G,ui.Accent.B) or C(0,120,255),
        bg     = ui.Bg     and C(ui.Bg.R,    ui.Bg.G,    ui.Bg.B)     or C(12,12,15),
        row    = ui.Row    and C(ui.Row.R,    ui.Row.G,   ui.Row.B)    or C(20,20,26),
        text   = ui.Text   and C(ui.Text.R,   ui.Text.G,  ui.Text.B)   or C(220,220,230),
    }
end

local function buildGUI()
    local CLR = getCLR()
    gui=Instance.new("ScreenGui"); gui.Name="NexusESP_PL"; gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
    pcall(function() syn.protect_gui(gui) end)
    pcall(function() gui.Parent=game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent=LP:WaitForChild("PlayerGui") end

    mainFrame=Instance.new("Frame"); mainFrame.BackgroundColor3=CLR.bg
    mainFrame.BorderSizePixel=0; mainFrame.ClipsDescendants=false
    mainFrame.Size=UDim2.fromOffset(360,500); mainFrame.Position=UDim2.fromOffset(400,60)
    mainFrame.Parent=gui; corner(mainFrame,10)
    local fs=Instance.new("UIStroke"); fs.Color=C(35,35,55); fs.Thickness=1; fs.Parent=mainFrame

    -- Header
    local header=Instance.new("Frame"); header.BackgroundColor3=C(6,6,10)
    header.BorderSizePixel=0; header.Size=UDim2.new(1,0,0,38); header.Parent=mainFrame; corner(header,10)
    local acc=Instance.new("Frame"); acc.BackgroundColor3=CLR.accent
    acc.BorderSizePixel=0; acc.Size=UDim2.fromOffset(3,38); acc.Parent=header
    mkLabel({Text="👥  PLAYER LIST",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.new(1,1,1),
        TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-110,1,0),Position=UDim2.fromOffset(10,0),Parent=header})
    mkLabel({Name="CountLbl",Text="0 players",TextSize=11,TextColor3=C(130,130,145),
        TextXAlignment=Enum.TextXAlignment.Right,Size=UDim2.fromOffset(80,38),Position=UDim2.new(1,-108,0,0),Parent=header})
    local closeB=mkBtn({Text="×",TextSize=18,BackgroundColor3=C(150,25,25),
        Size=UDim2.fromOffset(26,26),Position=UDim2.new(1,-30,0,6),Parent=header},
        function() PlayerList.Hide() end); corner(closeB,5)

    -- Drag
    do local drag,ds,sp_
        header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;sp_=mainFrame.Position end end)
        header.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
        UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds; mainFrame.Position=UDim2.fromOffset(sp_.X.Offset+d.X,sp_.Y.Offset+d.Y) end end)
    end

    -- Resize
    local rsz=mkBtn({Text="⇲",TextSize=11,BackgroundColor3=C(20,20,32),
        Size=UDim2.fromOffset(16,16),Position=UDim2.new(1,-16,1,-16),Parent=mainFrame}); corner(rsz,3)
    do local res,rs_,rSz_
        rsz.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then res=true;rs_=i.Position;rSz_=mainFrame.AbsoluteSize end end)
        rsz.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then res=false end end)
        UIS.InputChanged:Connect(function(i) if res and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-rs_; local nw=math.clamp(rSz_.X+d.X,280,700); local nh=math.clamp(rSz_.Y+d.Y,280,800)
            mainFrame.Size=UDim2.fromOffset(nw,nh) end end)
    end

    -- Filter bar
    local fb=Instance.new("Frame"); fb.BackgroundColor3=C(12,12,18); fb.BorderSizePixel=0
    fb.Size=UDim2.new(1,0,0,28); fb.Position=UDim2.fromOffset(0,38); fb.Parent=mainFrame
    local fl=Instance.new("UIListLayout"); fl.FillDirection=Enum.FillDirection.Horizontal
    fl.Padding=UDim.new(0,4); fl.VerticalAlignment=Enum.VerticalAlignment.Center; fl.Parent=fb
    local pd=Instance.new("UIPadding"); pd.PaddingLeft=UDim.new(0,6); pd.PaddingRight=UDim.new(0,6); pd.Parent=fb
    local fmap={{"All","Tous"},{"Enemies","Ennemis"},{"Allies","Allies"}}
    for _,f in ipairs(fmap) do
        local mode,label=f[1],f[2]
        local b=mkBtn({Name="F_"..mode,Text=label,TextSize=10,
            BackgroundColor3=(filterMode==mode and CLR.accent or C(28,28,42)),
            Size=UDim2.fromOffset(66,20),Parent=fb}, function()
            filterMode=mode
            for _,child in ipairs(fb:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3=(child.Name=="F_"..mode) and CLR.accent or C(28,28,42)
                end
            end
            for p in pairs(rows) do
                if rows[p] and rows[p].f then rows[p].f:Destroy(); rows[p]=nil end
            end
        end); corner(b,4)
    end

    -- Tabs
    local tabBar=Instance.new("Frame"); tabBar.BackgroundColor3=C(8,8,12); tabBar.BorderSizePixel=0
    tabBar.Size=UDim2.new(1,0,0,26); tabBar.Position=UDim2.fromOffset(0,66); tabBar.Parent=mainFrame
    local tl=Instance.new("UIListLayout"); tl.FillDirection=Enum.FillDirection.Horizontal
    tl.Padding=UDim.new(0,3); tl.VerticalAlignment=Enum.VerticalAlignment.Center; tl.Parent=tabBar
    local tpad=Instance.new("UIPadding"); tpad.PaddingLeft=UDim.new(0,5); tpad.Parent=tabBar

    tabMainBtn=mkBtn({Name="TM",Text="🗂  Players",TextSize=11,BackgroundColor3=CLR.accent,
        Size=UDim2.fromOffset(110,20),Parent=tabBar}); corner(tabMainBtn,5)
    tabSpecBtn=mkBtn({Name="TS",Text="🎥  Spectating",TextSize=11,BackgroundColor3=C(28,28,42),
        Size=UDim2.fromOffset(120,20),Parent=tabBar,Visible=false}); corner(tabSpecBtn,5)

    -- List scroll
    listScroll=Instance.new("ScrollingFrame"); listScroll.BackgroundTransparency=1
    listScroll.BorderSizePixel=0; listScroll.ScrollBarThickness=3
    listScroll.ScrollBarImageColor3=CLR.accent
    listScroll.Size=UDim2.new(1,0,1,-92); listScroll.Position=UDim2.fromOffset(0,92)
    listScroll.CanvasSize=UDim2.new(0,0,0,0); listScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    listScroll.Parent=mainFrame
    local ll=Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder
    ll.Padding=UDim.new(0,2); ll.Parent=listScroll
    local lpad=Instance.new("UIPadding"); lpad.PaddingLeft=UDim.new(0,4); lpad.PaddingRight=UDim.new(0,4)
    lpad.PaddingTop=UDim.new(0,4); lpad.Parent=listScroll

    -- Spec frame
    specFrame=Instance.new("Frame"); specFrame.BackgroundTransparency=1
    specFrame.Size=UDim2.new(1,0,1,-92); specFrame.Position=UDim2.fromOffset(0,92)
    specFrame.Visible=false; specFrame.Parent=mainFrame

    local sbg=Instance.new("Frame"); sbg.BackgroundColor3=C(15,15,22); sbg.BorderSizePixel=0
    sbg.Size=UDim2.new(1,-10,1,-10); sbg.Position=UDim2.fromOffset(5,5); sbg.Parent=specFrame; corner(sbg,8)
    mkLabel({Name="SN",Text="No target",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=Color3.new(1,1,1),
        TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.new(1,0,0,32),Position=UDim2.fromOffset(0,10),Parent=sbg})
    mkLabel({Name="SI",Text="",TextSize=11,TextColor3=C(140,140,155),TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Center,Size=UDim2.new(1,-10,0,70),Position=UDim2.fromOffset(5,45),Parent=sbg})
    local hbg=Instance.new("Frame"); hbg.Name="HBg"; hbg.BackgroundColor3=C(28,28,38)
    hbg.BorderSizePixel=0; hbg.Size=UDim2.new(1,-20,0,6); hbg.Position=UDim2.fromOffset(10,118); hbg.Parent=sbg; corner(hbg,3)
    local hf=Instance.new("Frame"); hf.Name="HF"; hf.BackgroundColor3=C(40,210,90)
    hf.BorderSizePixel=0; hf.Size=UDim2.new(0.75,0,1,0); hf.Parent=hbg; corner(hf,3)
    mkBtn({Text="⏹  Stop spectating",TextSize=12,BackgroundColor3=C(150,25,25),
        Size=UDim2.new(1,-20,0,30),Position=UDim2.fromOffset(10,132),Parent=sbg},
        function() PlayerList.StopSpectate() end)

    -- Tab switching
    tabMainBtn.MouseButton1Click:Connect(function()
        listScroll.Visible=true; specFrame.Visible=false
        tabMainBtn.BackgroundColor3=CLR.accent; tabSpecBtn.BackgroundColor3=C(28,28,42)
    end)
    tabSpecBtn.MouseButton1Click:Connect(function()
        listScroll.Visible=false; specFrame.Visible=true
        tabSpecBtn.BackgroundColor3=CLR.accent; tabMainBtn.BackgroundColor3=C(28,28,42)
    end)
end

local function buildRow(player, idx)
    local CLR=getCLR()
    local exp = expanded[player] or false
    local rowH = exp and 130 or 60

    local f=Instance.new("Frame"); f.BackgroundColor3=(idx%2==0) and CLR.row or C(16,16,22)
    f.BorderSizePixel=0; f.Size=UDim2.new(1,0,0,rowH); f.LayoutOrder=idx; f.Parent=listScroll; corner(f,6)

    local vd=Instance.new("Frame"); vd.Name="VD"; vd.BackgroundColor3=C(40,210,90)
    vd.BorderSizePixel=0; vd.Size=UDim2.fromOffset(5,5); vd.Position=UDim2.fromOffset(6,8); vd.Parent=f; corner(vd,3)

    mkLabel({Name="NL",Text=player.Name,Font=Enum.Font.GothamBold,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-120,0,16),Position=UDim2.fromOffset(14,4),Parent=f})
    mkLabel({Name="DL",Text="?",TextSize=11,TextColor3=C(130,130,145),
        TextXAlignment=Enum.TextXAlignment.Right,Size=UDim2.fromOffset(60,14),Position=UDim2.new(1,-64,0,5),Parent=f})
    mkLabel({Name="TL",Text="No Team",TextSize=10,TextColor3=C(130,130,145),
        TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(0.6,0,0,12),Position=UDim2.fromOffset(14,22),Parent=f})

    local hbg=Instance.new("Frame"); hbg.BackgroundColor3=C(28,28,38); hbg.BorderSizePixel=0
    hbg.Size=UDim2.new(1,-16,0,3); hbg.Position=UDim2.fromOffset(8,36); hbg.Parent=f; corner(hbg,2)
    local hb=Instance.new("Frame"); hb.Name="HB"; hb.BackgroundColor3=C(40,210,90)
    hb.BorderSizePixel=0; hb.Size=UDim2.new(1,0,1,0); hb.Parent=hbg; corner(hb,2)

    -- ESP button
    local off=espOff[player] or false
    local eb=mkBtn({Name="EB",Text=off and "🚫 OFF" or "👁 ON",TextSize=10,
        BackgroundColor3=off and C(140,25,25) or C(20,110,50),
        Size=UDim2.fromOffset(70,18),Position=UDim2.fromOffset(8,42),Parent=f}, function()
        espOff[player]=not (espOff[player] or false)
        local o=espOff[player]
        local btn=f:FindFirstChild("EB"); if btn then
            btn.Text=o and "🚫 OFF" or "👁 ON"
            btn.BackgroundColor3=o and C(140,25,25) or C(20,110,50)
        end
        if ESP_ref then local e=ESP_ref.GetEntities(); if e[player] then e[player].disabled=o end end
    end); corner(eb,4)

    -- Spec button
    local isSpec=(spectateTarget==player)
    local sb=mkBtn({Name="SB",Text=isSpec and "⏹ Stop" or "🎥 Spec",TextSize=10,
        BackgroundColor3=isSpec and C(150,25,25) or C(70,50,10),
        Size=UDim2.fromOffset(72,18),Position=UDim2.fromOffset(81,42),Parent=f}, function()
        if spectateTarget==player then PlayerList.StopSpectate()
        else PlayerList.StartSpectate(player) end
    end); corner(sb,4)

    -- Expand arrow
    local ab=mkBtn({Name="AB",Text=exp and "▲" or "▼",TextSize=10,
        BackgroundColor3=C(28,28,42),Size=UDim2.fromOffset(22,18),
        Position=UDim2.new(1,-26,0,42),Parent=f}, function()
        expanded[player]=not (expanded[player] or false)
        if rows[player] then rows[player].f:Destroy(); rows[player]=nil end
    end); corner(ab,4)

    -- Expanded info
    local eframe=Instance.new("Frame"); eframe.Name="EF"; eframe.BackgroundTransparency=1
    eframe.Size=UDim2.new(1,0,0,68); eframe.Position=UDim2.fromOffset(0,60)
    eframe.Visible=exp; eframe.Parent=f
    mkLabel({Name="IL",Text="",TextSize=10,TextColor3=C(130,130,145),TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-8,0,62),Position=UDim2.fromOffset(8,2),Parent=eframe})

    local rd={f=f,vd=vd,eb=eb,sb=sb,ab=ab,hb=hb,eframe=eframe}
    rows[player]=rd; return rd
end

local function shouldShow(p)
    if filterMode=="Enemies" then return not Utils.SameTeam(p) end
    if filterMode=="Allies"  then return Utils.SameTeam(p) end
    return true
end

local function updateRows()
    if not visible or not listScroll then return end
    local list=Players:GetPlayers()
    local idx,count=0,0

    for p in pairs(rows) do
        if not p.Parent then if rows[p] then rows[p].f:Destroy() end; rows[p]=nil end
    end

    for _,player in ipairs(list) do
        if player==LP then continue end
        if not shouldShow(player) then
            if rows[player] then rows[player].f.Visible=false end; continue
        end
        count=count+1; idx=idx+1
        if not rows[player] then buildRow(player,idx) end
        local r=rows[player]; if not r then continue end
        r.f.Visible=true; r.f.LayoutOrder=idx

        local char=player.Character
        local root=char and Utils.GetRoot(char)
        local dist=root and math.floor(Utils.GetDistance(root.Position)) or -1
        local hp=char and Utils.GetHealthPercent(char) or 0
        local vis=root and Utils.IsVisible(root.Position) or false

        r.f:FindFirstChild("DL") and (r.f.DL.Text=(dist>=0 and dist.."m" or "??"))
        r.f:FindFirstChild("VD") and (r.f.VD.BackgroundColor3=(vis and C(40,210,90) or C(210,40,40)))
        local hb=r.f:FindFirstChild("HB"); if hb then hb.Size=UDim2.new(math.max(0,hp),0,1,0); hb.BackgroundColor3=Utils.HealthColor(hp) end
        local nl=r.f:FindFirstChild("NL")
        if player.Team then
            if nl then nl.TextColor3=player.Team.TeamColor.Color end
            local tl=r.f:FindFirstChild("TL"); if tl then tl.Text="⬡ "..player.Team.Name end
        end

        -- Expanded info
        if expanded[player] then
            r.f.Size=UDim2.new(1,0,0,130); r.eframe.Visible=true; r.ab.Text="▲"
            local hum=char and Utils.GetHumanoid(char)
            local tool=char and char:FindFirstChildOfClass("Tool")
            local il=r.eframe:FindFirstChild("IL"); if il then
                il.Text=string.format(
                    "HP: %s / %s  |  Dist: %s\nTeam: %s  |  Visible: %s\nTool: %s",
                    hum and math.floor(hum.Health) or "?",
                    hum and math.floor(hum.MaxHealth) or "?",
                    dist>=0 and dist.."m" or "??",
                    player.Team and player.Team.Name or "None",
                    vis and "✅" or "❌",
                    tool and tool.Name or "None"
                )
            end
        else
            r.f.Size=UDim2.new(1,0,0,60); r.eframe.Visible=false; r.ab.Text="▼"
        end

        local off=espOff[player] or false
        local eb=r.f:FindFirstChild("EB"); if eb then
            eb.Text=off and "🚫 OFF" or "👁 ON"
            eb.BackgroundColor3=off and C(140,25,25) or C(20,110,50)
        end
        local sb=r.f:FindFirstChild("SB"); if sb then
            local isSpec=(spectateTarget==player)
            sb.Text=isSpec and "⏹ Stop" or "🎥 Spec"
            sb.BackgroundColor3=isSpec and C(150,25,25) or C(70,50,10)
        end
    end

    -- Update counter
    if mainFrame then
        local h=mainFrame:FindFirstChildOfClass("Frame")
        if h then local cl=h:FindFirstChild("CountLbl"); if cl then cl.Text=count.." player"..(count~=1 and "s" or "") end end
    end

    -- Update spec frame
    if spectateTarget and specFrame then
        local sbg=specFrame:FindFirstChildOfClass("Frame")
        if sbg then
            local sn=sbg:FindFirstChild("SN"); if sn then sn.Text="🎥  "..spectateTarget.Name; sn.TextColor3=spectateTarget.Team and spectateTarget.Team.TeamColor.Color or Color3.new(1,1,1) end
            local char2=spectateTarget.Character
            local hum2=char2 and Utils.GetHumanoid(char2)
            local root2=char2 and Utils.GetRoot(char2)
            local si=sbg:FindFirstChild("SI"); if si then
                local tool=char2 and char2:FindFirstChildOfClass("Tool")
                si.Text=string.format("HP: %s/%s  |  Dist: %sm\nTeam: %s  |  Tool: %s",
                    hum2 and math.floor(hum2.Health) or "?",
                    hum2 and math.floor(hum2.MaxHealth) or "?",
                    root2 and math.floor(Utils.GetDistance(root2.Position)) or "??",
                    spectateTarget.Team and spectateTarget.Team.Name or "None",
                    tool and tool.Name or "None")
            end
            local hp2=char2 and Utils.GetHealthPercent(char2) or 0
            local hbg2=sbg:FindFirstChild("HBg"); if hbg2 then local hf2=hbg2:FindFirstChild("HF"); if hf2 then hf2.Size=UDim2.new(math.max(0,hp2),0,1,0); hf2.BackgroundColor3=Utils.HealthColor(hp2) end end
        end
    end
end

function PlayerList.StartSpectate(player)
    PlayerList.StopSpectate()
    spectateTarget=player
    if tabSpecBtn then tabSpecBtn.Visible=true end
    if listScroll then listScroll.Visible=false end
    if specFrame  then specFrame.Visible=true end
    if tabSpecBtn then tabSpecBtn.BackgroundColor3=getCLR().accent end
    if tabMainBtn then tabMainBtn.BackgroundColor3=C(28,28,42) end
    -- Use CameraSubject (player keeps full camera control)
    local cam=Workspace.CurrentCamera; cam.CameraType=Enum.CameraType.Custom
    specConn=RunService.RenderStepped:Connect(function()
        if not spectateTarget or not spectateTarget.Character then return end
        local hum=spectateTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject=hum end
    end)
end

function PlayerList.StopSpectate()
    spectateTarget=nil
    if specConn then specConn:Disconnect(); specConn=nil end
    local cam=Workspace.CurrentCamera; cam.CameraType=Enum.CameraType.Custom
    local lchar=LP.Character; if lchar then local lh=lchar:FindFirstChildOfClass("Humanoid"); if lh then cam.CameraSubject=lh end end
    if tabSpecBtn then tabSpecBtn.Visible=false; tabSpecBtn.BackgroundColor3=C(28,28,42) end
    if tabMainBtn then tabMainBtn.BackgroundColor3=getCLR().accent end
    if listScroll then listScroll.Visible=true end
    if specFrame  then specFrame.Visible=false end
end

function PlayerList.Show()
    if visible then return end; visible=true
    buildGUI()
    updateConn=RunService.Heartbeat:Connect(function() pcall(updateRows) end)
end

function PlayerList.Hide()
    visible=false
    if updateConn then updateConn:Disconnect(); updateConn=nil end
    PlayerList.StopSpectate()
    if gui then gui:Destroy(); gui=nil end
    mainFrame=nil; listScroll=nil; specFrame=nil; tabMainBtn=nil; tabSpecBtn=nil; rows={}
end

function PlayerList.Toggle() if visible then PlayerList.Hide() else PlayerList.Show() end end
function PlayerList.Cleanup() PlayerList.Hide() end
function PlayerList.TogglePlayerESP(player)
    espOff[player]=not(espOff[player] or false)
    if ESP_ref then local e=ESP_ref.GetEntities(); if e[player] then e[player].disabled=espOff[player] end end
end

return PlayerList
