-- PlayerList — zero use of 'continue' keyword (executor compatibility)
local PlayerList = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer
local Utils, Config, ESP_ref

function PlayerList.SetDependencies(u, c, e)
    Utils   = u
    Config  = c
    ESP_ref = e
end

local function C(r,g,b) return Color3.fromRGB(r,g,b) end

local gui, mainFrame, listScroll, specFrame, tabMainBtn, tabSpecBtn
local rows       = {}
local updateConn = nil
local specConn   = nil
local spectateTarget = nil
local filterMode     = "All"
local espOff         = {}
local expanded       = {}
local visible        = false

-- ── Helpers ───────────────────────────────────────────────────
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p
end
local function mkLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font      = Enum.Font.GothamMedium
    l.TextColor3 = C(220,220,230)
    l.TextSize   = 12
    for k, v in pairs(props) do pcall(function() l[k] = v end) end
    return l
end
local function mkBtn(props, cb)
    local b = Instance.new("TextButton")
    b.Font           = Enum.Font.GothamBold
    b.TextSize       = 11
    b.TextColor3     = Color3.new(1,1,1)
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    for k, v in pairs(props) do pcall(function() b[k] = v end) end
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end
local function getAccent()
    local ui = Config and Config.Current and Config.Current.UI
    if ui and ui.Accent then return C(ui.Accent.R, ui.Accent.G, ui.Accent.B) end
    return C(0,120,255)
end

-- ── GUI build ─────────────────────────────────────────────────
local function buildGUI()
    gui = Instance.new("ScreenGui")
    gui.Name            = "NexusESP_PL"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Global
    pcall(function() syn.protect_gui(gui) end)
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local accent = getAccent()

    mainFrame = Instance.new("Frame")
    mainFrame.BackgroundColor3 = C(12,12,15)
    mainFrame.BorderSizePixel  = 0
    mainFrame.Size     = UDim2.fromOffset(360, 500)
    mainFrame.Position = UDim2.fromOffset(400, 60)
    mainFrame.Parent   = gui
    corner(mainFrame, 10)
    local fs = Instance.new("UIStroke"); fs.Color = C(35,35,55); fs.Thickness = 1; fs.Parent = mainFrame

    -- Header
    local hdr = Instance.new("Frame")
    hdr.BackgroundColor3 = C(6,6,10); hdr.BorderSizePixel = 0
    hdr.Size = UDim2.new(1,0,0,38); hdr.Parent = mainFrame; corner(hdr,10)

    local acbar = Instance.new("Frame")
    acbar.BackgroundColor3 = accent; acbar.BorderSizePixel = 0
    acbar.Size = UDim2.fromOffset(3,38); acbar.Parent = hdr
    corner(acbar, 2)

    mkLabel({Text="👥  PLAYER LIST", Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-110,1,0), Position=UDim2.fromOffset(10,0), Parent=hdr})

    local countLbl = mkLabel({Name="CountLbl", Text="0 players", TextSize=11, TextColor3=C(130,130,145),
        TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.fromOffset(80,38), Position=UDim2.new(1,-108,0,0), Parent=hdr})

    local closeB = mkBtn({Text="×", TextSize=18, BackgroundColor3=C(150,25,25),
        Size=UDim2.fromOffset(26,26), Position=UDim2.new(1,-30,0,6), Parent=hdr},
        function() PlayerList.Hide() end)
    corner(closeB, 5)

    -- Drag
    local drag, ds, sp_
    hdr.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; sp_ = mainFrame.Position
        end
    end)
    hdr.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            mainFrame.Position = UDim2.fromOffset(sp_.X.Offset+d.X, sp_.Y.Offset+d.Y)
        end
    end)

    -- Resize
    local rsz = mkBtn({Text="⇲", TextSize=11, BackgroundColor3=C(20,20,32),
        Size=UDim2.fromOffset(16,16), Position=UDim2.new(1,-16,1,-16), Parent=mainFrame})
    corner(rsz, 3)
    local res, rs_, rSz_
    rsz.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            res = true; rs_ = i.Position; rSz_ = mainFrame.AbsoluteSize
        end
    end)
    rsz.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then res = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if res and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d  = i.Position - rs_
            local nw = math.clamp(rSz_.X + d.X, 280, 700)
            local nh = math.clamp(rSz_.Y + d.Y, 280, 800)
            mainFrame.Size = UDim2.fromOffset(nw, nh)
        end
    end)

    -- Filter bar
    local fb = Instance.new("Frame")
    fb.BackgroundColor3 = C(10,10,16); fb.BorderSizePixel = 0
    fb.Size = UDim2.new(1,0,0,28); fb.Position = UDim2.fromOffset(0,38); fb.Parent = mainFrame
    local fll = Instance.new("UIListLayout")
    fll.FillDirection = Enum.FillDirection.Horizontal
    fll.Padding = UDim.new(0,4); fll.VerticalAlignment = Enum.VerticalAlignment.Center; fll.Parent = fb
    local fpd = Instance.new("UIPadding"); fpd.PaddingLeft = UDim.new(0,6); fpd.Parent = fb

    local filterDefs = {{"All","Tous"}, {"Enemies","Ennemis"}, {"Allies","Allies"}}
    local filterBtns = {}
    for _, f in ipairs(filterDefs) do
        local mode, label = f[1], f[2]
        local active = (filterMode == mode)
        local fb2 = mkBtn({Name="F_"..mode, Text=label, TextSize=10,
            BackgroundColor3 = active and accent or C(28,28,42),
            Size=UDim2.fromOffset(66,20), Parent=fb},
            function()
                filterMode = mode
                for _, b in ipairs(filterBtns) do
                    b.BackgroundColor3 = (b.Name == "F_"..mode) and getAccent() or C(28,28,42)
                end
                for p, rd in pairs(rows) do
                    if rd and rd.f then rd.f:Destroy() end
                    rows[p] = nil
                end
            end)
        corner(fb2, 4)
        table.insert(filterBtns, fb2)
    end

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.BackgroundColor3 = C(8,8,12); tabBar.BorderSizePixel = 0
    tabBar.Size = UDim2.new(1,0,0,26); tabBar.Position = UDim2.fromOffset(0,66); tabBar.Parent = mainFrame
    local tl = Instance.new("UIListLayout")
    tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0,3)
    tl.VerticalAlignment = Enum.VerticalAlignment.Center; tl.Parent = tabBar
    local tpd = Instance.new("UIPadding"); tpd.PaddingLeft = UDim.new(0,5); tpd.Parent = tabBar

    tabMainBtn = mkBtn({Name="TM", Text="🗂  Players", TextSize=11,
        BackgroundColor3=accent, Size=UDim2.fromOffset(110,20), Parent=tabBar})
    corner(tabMainBtn, 5)
    tabSpecBtn = mkBtn({Name="TS", Text="🎥  Spectating", TextSize=11,
        BackgroundColor3=C(28,28,42), Size=UDim2.fromOffset(120,20), Parent=tabBar, Visible=false})
    corner(tabSpecBtn, 5)

    -- List scroll
    listScroll = Instance.new("ScrollingFrame")
    listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 3; listScroll.ScrollBarImageColor3 = accent
    listScroll.Size = UDim2.new(1,0,1,-92); listScroll.Position = UDim2.fromOffset(0,92)
    listScroll.CanvasSize = UDim2.new(0,0,0,0); listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.Parent = mainFrame
    local ll = Instance.new("UIListLayout"); ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0,2); ll.Parent = listScroll
    local lpd = Instance.new("UIPadding"); lpd.PaddingLeft = UDim.new(0,4); lpd.PaddingRight = UDim.new(0,4)
    lpd.PaddingTop = UDim.new(0,4); lpd.Parent = listScroll

    -- Spec frame
    specFrame = Instance.new("Frame"); specFrame.BackgroundTransparency = 1
    specFrame.Size = UDim2.new(1,0,1,-92); specFrame.Position = UDim2.fromOffset(0,92)
    specFrame.Visible = false; specFrame.Parent = mainFrame

    local sbg = Instance.new("Frame")
    sbg.BackgroundColor3 = C(15,15,22); sbg.BorderSizePixel = 0
    sbg.Size = UDim2.new(1,-10,0,180); sbg.Position = UDim2.fromOffset(5,5); sbg.Parent = specFrame
    corner(sbg, 8)

    mkLabel({Name="SN", Text="No target", Font=Enum.Font.GothamBold, TextSize=18,
        TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,0,0,32), Position=UDim2.fromOffset(0,8), Parent=sbg})
    mkLabel({Name="SI", Text="", TextSize=11, TextColor3=C(140,140,155), TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,-10,0,70), Position=UDim2.fromOffset(5,44), Parent=sbg})

    local hbg = Instance.new("Frame"); hbg.Name="HBg"; hbg.BackgroundColor3=C(28,28,38)
    hbg.BorderSizePixel=0; hbg.Size=UDim2.new(1,-20,0,6); hbg.Position=UDim2.fromOffset(10,120)
    hbg.Parent=sbg; corner(hbg,3)
    local hf = Instance.new("Frame"); hf.Name="HF"; hf.BackgroundColor3=C(40,210,90)
    hf.BorderSizePixel=0; hf.Size=UDim2.new(0.75,0,1,0); hf.Parent=hbg; corner(hf,3)

    mkBtn({Text="⏹  Stop spectating", TextSize=12, BackgroundColor3=C(150,25,25),
        Size=UDim2.new(1,-20,0,30), Position=UDim2.fromOffset(10,135), Parent=sbg},
        function() PlayerList.StopSpectate() end)

    -- Tab switching
    tabMainBtn.MouseButton1Click:Connect(function()
        listScroll.Visible = true; specFrame.Visible = false
        tabMainBtn.BackgroundColor3 = getAccent(); tabSpecBtn.BackgroundColor3 = C(28,28,42)
    end)
    tabSpecBtn.MouseButton1Click:Connect(function()
        listScroll.Visible = false; specFrame.Visible = true
        tabSpecBtn.BackgroundColor3 = getAccent(); tabMainBtn.BackgroundColor3 = C(28,28,42)
    end)
end

-- ── Row builder ───────────────────────────────────────────────
local function buildRow(player, idx)
    local accent = getAccent()
    local exp    = expanded[player] or false
    local rowH   = exp and 130 or 62

    local f = Instance.new("Frame")
    f.BackgroundColor3 = (idx % 2 == 0) and C(20,20,26) or C(16,16,22)
    f.BorderSizePixel = 0
    f.Size = UDim2.new(1,0,0,rowH); f.LayoutOrder = idx; f.Parent = listScroll
    corner(f, 6)

    -- Visibility dot
    local vd = Instance.new("Frame"); vd.Name="VD"
    vd.BackgroundColor3 = C(40,210,90); vd.BorderSizePixel = 0
    vd.Size = UDim2.fromOffset(5,5); vd.Position = UDim2.fromOffset(6,8); vd.Parent = f; corner(vd,3)

    mkLabel({Name="NL", Text=player.Name, Font=Enum.Font.GothamBold, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-120,0,16), Position=UDim2.fromOffset(14,4), Parent=f})
    mkLabel({Name="DL", Text="?", TextSize=11, TextColor3=C(130,130,145),
        TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.fromOffset(60,14), Position=UDim2.new(1,-64,0,5), Parent=f})
    mkLabel({Name="TL", Text="No Team", TextSize=10, TextColor3=C(130,130,145),
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0.6,0,0,12), Position=UDim2.fromOffset(14,22), Parent=f})

    local hbg = Instance.new("Frame"); hbg.BackgroundColor3=C(28,28,38); hbg.BorderSizePixel=0
    hbg.Size = UDim2.new(1,-16,0,3); hbg.Position = UDim2.fromOffset(8,37); hbg.Parent=f; corner(hbg,2)
    local hb = Instance.new("Frame"); hb.Name="HB"; hb.BackgroundColor3=C(40,210,90)
    hb.BorderSizePixel=0; hb.Size=UDim2.new(1,0,1,0); hb.Parent=hbg; corner(hb,2)

    -- ESP button
    local off = espOff[player] or false
    local eb = mkBtn({Name="EB",
        Text = off and "🚫 OFF" or "👁 ON", TextSize=10,
        BackgroundColor3 = off and C(140,25,25) or C(20,110,50),
        Size=UDim2.fromOffset(70,18), Position=UDim2.fromOffset(8,43), Parent=f},
        function()
            espOff[player] = not (espOff[player] or false)
            local o   = espOff[player]
            local btn = f:FindFirstChild("EB")
            if btn then
                btn.Text = o and "🚫 OFF" or "👁 ON"
                btn.BackgroundColor3 = o and C(140,25,25) or C(20,110,50)
            end
            if ESP_ref then
                local ents = ESP_ref.GetEntities()
                if ents[player] then ents[player].disabled = o end
            end
        end)
    corner(eb, 4)

    -- Spec button
    local isSpec = (spectateTarget == player)
    local sb = mkBtn({Name="SB",
        Text = isSpec and "⏹ Stop" or "🎥 Spec", TextSize=10,
        BackgroundColor3 = isSpec and C(150,25,25) or C(70,50,10),
        Size=UDim2.fromOffset(72,18), Position=UDim2.fromOffset(81,43), Parent=f},
        function()
            if spectateTarget == player then PlayerList.StopSpectate()
            else PlayerList.StartSpectate(player) end
        end)
    corner(sb, 4)

    -- Expand arrow
    local ab = mkBtn({Name="AB", Text = exp and "▲" or "▼", TextSize=10,
        BackgroundColor3=C(28,28,42),
        Size=UDim2.fromOffset(22,18), Position=UDim2.new(1,-26,0,43), Parent=f},
        function()
            expanded[player] = not (expanded[player] or false)
            if rows[player] then rows[player].f:Destroy(); rows[player] = nil end
        end)
    corner(ab, 4)

    -- Expanded info
    local eframe = Instance.new("Frame"); eframe.Name="EF"; eframe.BackgroundTransparency=1
    eframe.Size = UDim2.new(1,0,0,68); eframe.Position = UDim2.fromOffset(0,62)
    eframe.Visible = exp; eframe.Parent = f
    mkLabel({Name="IL", Text="", TextSize=10, TextColor3=C(130,130,145), TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-8,0,62), Position=UDim2.fromOffset(8,2), Parent=eframe})

    rows[player] = {f=f, vd=vd, hb=hb, eframe=eframe}
end

-- ── Filter check ──────────────────────────────────────────────
local function shouldShow(p)
    if filterMode == "Enemies" then return not Utils.SameTeam(p) end
    if filterMode == "Allies"  then return Utils.SameTeam(p) end
    return true
end

-- ── Update rows ───────────────────────────────────────────────
local function updateRows()
    if not visible or not listScroll then return end

    -- Clean disconnected players
    for p, rd in pairs(rows) do
        if not p.Parent then
            if rd and rd.f then rd.f:Destroy() end
            rows[p] = nil
        end
    end

    local list  = Players:GetPlayers()
    local idx   = 0
    local count = 0

    for i = 1, #list do
        local player = list[i]
        if player ~= LP then
            if shouldShow(player) then
                count = count + 1
                idx   = idx + 1
                if not rows[player] then buildRow(player, idx) end
                local r = rows[player]
                if r then
                    r.f.Visible     = true
                    r.f.LayoutOrder = idx
                    local char  = player.Character
                    local root  = char and Utils.GetRoot(char)
                    local dist  = root and math.floor(Utils.GetDistance(root.Position)) or -1
                    local hp    = char and Utils.GetHealthPercent(char) or 0
                    local vis   = root and Utils.IsVisible(root.Position) or false
                    local dlbl  = r.f:FindFirstChild("DL")
                    if dlbl then dlbl.Text = dist >= 0 and dist.."m" or "??" end
                    r.vd.BackgroundColor3 = vis and C(40,210,90) or C(210,40,40)
                    r.hb.Size             = UDim2.new(math.max(0,hp),0,1,0)
                    r.hb.BackgroundColor3 = Utils.HealthColor(hp)
                    local nlbl = r.f:FindFirstChild("NL")
                    local tlbl = r.f:FindFirstChild("TL")
                    if player.Team then
                        if nlbl then nlbl.TextColor3 = player.Team.TeamColor.Color end
                        if tlbl then tlbl.Text = "⬡ "..player.Team.Name end
                    end
                    -- Expanded info
                    if expanded[player] then
                        r.f.Size    = UDim2.new(1,0,0,130)
                        r.eframe.Visible = true
                        local ablbl = r.f:FindFirstChild("AB"); if ablbl then ablbl.Text = "▲" end
                        local hum  = char and Utils.GetHumanoid(char)
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        local il   = r.eframe:FindFirstChild("IL")
                        if il then
                            il.Text = string.format(
                                "HP: %s / %s  |  Dist: %s\nTeam: %s  |  Visible: %s\nTool: %s",
                                hum and math.floor(hum.Health) or "?",
                                hum and math.floor(hum.MaxHealth) or "?",
                                dist >= 0 and dist.."m" or "??",
                                player.Team and player.Team.Name or "None",
                                vis and "✅" or "❌",
                                tool and tool.Name or "None"
                            )
                        end
                    else
                        r.f.Size = UDim2.new(1,0,0,62)
                        r.eframe.Visible = false
                        local ablbl = r.f:FindFirstChild("AB"); if ablbl then ablbl.Text = "▼" end
                    end
                    -- Sync buttons
                    local o  = espOff[player] or false
                    local eb = r.f:FindFirstChild("EB"); if eb then
                        eb.Text = o and "🚫 OFF" or "👁 ON"
                        eb.BackgroundColor3 = o and C(140,25,25) or C(20,110,50)
                    end
                    local spc = (spectateTarget == player)
                    local sb  = r.f:FindFirstChild("SB"); if sb then
                        sb.Text = spc and "⏹ Stop" or "🎥 Spec"
                        sb.BackgroundColor3 = spc and C(150,25,25) or C(70,50,10)
                    end
                end
            else
                if rows[player] then rows[player].f.Visible = false end
            end
        end
    end

    -- Counter
    if mainFrame then
        local hdr = mainFrame:FindFirstChildOfClass("Frame")
        if hdr then
            local cl = hdr:FindFirstChild("CountLbl")
            if cl then cl.Text = count.." player"..(count ~= 1 and "s" or "") end
        end
    end

    -- Update spec frame live
    if spectateTarget and specFrame then
        local sbg = specFrame:FindFirstChildOfClass("Frame")
        if sbg then
            local sn   = sbg:FindFirstChild("SN")
            local si   = sbg:FindFirstChild("SI")
            local hbg2 = sbg:FindFirstChild("HBg")
            local char2  = spectateTarget.Character
            local hum2   = char2 and Utils.GetHumanoid(char2)
            local root2  = char2 and Utils.GetRoot(char2)
            if sn then
                sn.Text      = "🎥  "..spectateTarget.Name
                sn.TextColor3 = spectateTarget.Team and spectateTarget.Team.TeamColor.Color or Color3.new(1,1,1)
            end
            if si then
                local tool2 = char2 and char2:FindFirstChildOfClass("Tool")
                local d2    = root2 and math.floor(Utils.GetDistance(root2.Position)) or -1
                si.Text = string.format("HP: %s/%s  |  Dist: %sm\nTeam: %s  |  Tool: %s",
                    hum2 and math.floor(hum2.Health) or "?",
                    hum2 and math.floor(hum2.MaxHealth) or "?",
                    d2 >= 0 and d2 or "??",
                    spectateTarget.Team and spectateTarget.Team.Name or "None",
                    tool2 and tool2.Name or "None"
                )
            end
            if hbg2 then
                local hp2 = char2 and Utils.GetHealthPercent(char2) or 0
                local hf2 = hbg2:FindFirstChild("HF")
                if hf2 then
                    hf2.Size = UDim2.new(math.max(0,hp2),0,1,0)
                    hf2.BackgroundColor3 = Utils.HealthColor(hp2)
                end
            end
        end
    end
end

-- ── Spectate ──────────────────────────────────────────────────
function PlayerList.StartSpectate(player)
    PlayerList.StopSpectate()
    spectateTarget = player
    if tabSpecBtn then tabSpecBtn.Visible = true end
    if listScroll then listScroll.Visible = false end
    if specFrame  then specFrame.Visible  = true  end
    if tabSpecBtn then tabSpecBtn.BackgroundColor3 = getAccent() end
    if tabMainBtn then tabMainBtn.BackgroundColor3 = C(28,28,42) end

    local cam  = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    specConn = RunService.RenderStepped:Connect(function()
        if not spectateTarget or not spectateTarget.Character then return end
        local hum = spectateTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum and cam.CameraSubject ~= hum then cam.CameraSubject = hum end
    end)
end

function PlayerList.StopSpectate()
    spectateTarget = nil
    if specConn then specConn:Disconnect(); specConn = nil end
    local cam   = Workspace.CurrentCamera
    local lchar = LP.Character
    if lchar then
        local lh = lchar:FindFirstChildOfClass("Humanoid")
        if lh then cam.CameraSubject = lh end
    end
    cam.CameraType = Enum.CameraType.Custom
    if tabSpecBtn then tabSpecBtn.Visible = false; tabSpecBtn.BackgroundColor3 = C(28,28,42) end
    if tabMainBtn then tabMainBtn.BackgroundColor3 = getAccent() end
    if listScroll then listScroll.Visible = true  end
    if specFrame  then specFrame.Visible  = false end
end

-- ── Public ────────────────────────────────────────────────────
function PlayerList.Show()
    if visible then return end; visible = true
    buildGUI()
    updateConn = RunService.Heartbeat:Connect(function() pcall(updateRows) end)
end

function PlayerList.Hide()
    visible = false
    if updateConn then updateConn:Disconnect(); updateConn = nil end
    PlayerList.StopSpectate()
    if gui then gui:Destroy(); gui = nil end
    mainFrame = nil; listScroll = nil; specFrame = nil
    tabMainBtn = nil; tabSpecBtn = nil; rows = {}
end

function PlayerList.Toggle()  if visible then PlayerList.Hide() else PlayerList.Show() end end
function PlayerList.Cleanup() PlayerList.Hide() end

return PlayerList
