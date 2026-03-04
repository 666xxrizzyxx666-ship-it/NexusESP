-- ============================================================
--  PlayerList.lua — Fenetre moderne draggable/resizable
--  Spectate avec onglet dédié | ESP On/Off coloré | Filtres
-- ============================================================
local PlayerList = {}
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Workspace  = game:GetService("Workspace")
local LP         = Players.LocalPlayer

local Utils, Config, ESP_ref
function PlayerList.SetDependencies(u,c,e) Utils=u; Config=c; ESP_ref=e end

-- ── Couleurs (mises à jour depuis Config.UI) ──────────────────
local function C(r,g,b) return Color3.fromRGB(r,g,b) end
local CLR = {
    bg=C(12,12,15), bgRow=C(20,20,26), bgRowAlt=C(16,16,22),
    header=C(8,8,12), accent=C(0,120,255), text=C(220,220,230),
    sub=C(130,130,145), green=C(40,210,90), red=C(210,45,45),
    border=C(35,35,55), specActive=C(200,140,0),
    espOn=C(25,130,60), espOff=C(160,30,30),
}

-- ── Etat ─────────────────────────────────────────────────────
local gui, mainFrame, listScroll, specFrame
local tabMain, tabSpec
local rows = {}
local updateConn, specConn
local spectateTarget = nil
local filterMode = "All"  -- "All","Enemies","Allies"
local expandedPlayers = {}  -- [player] = bool
local espDisabled = {}      -- [player] = bool
local visible = false

-- ── UI helpers ────────────────────────────────────────────────
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p; return c end
local function stroke(p,col,th) local s=Instance.new("UIStroke"); s.Color=col or CLR.border; s.Thickness=th or 1; s.Parent=p; return s end
local function pad(p,n) local pd=Instance.new("UIPadding"); pd.PaddingLeft=UDim.new(0,n); pd.PaddingRight=UDim.new(0,n); pd.PaddingTop=UDim.new(0,n); pd.PaddingBottom=UDim.new(0,n); pd.Parent=p end
local function lbl(props)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1
    l.Font=Enum.Font.GothamMedium; l.TextColor3=CLR.text; l.TextSize=12
    for k,v in pairs(props) do pcall(function() l[k]=v end) end
    return l
end
local function btn(props, cb)
    local b=Instance.new("TextButton"); b.Font=Enum.Font.GothamBold; b.TextSize=11
    b.TextColor3=Color3.new(1,1,1); b.BorderSizePixel=0; b.AutoButtonColor=true
    for k,v in pairs(props) do pcall(function() b[k]=v end) end
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

-- ── Build GUI ─────────────────────────────────────────────────
local function buildGUI()
    gui = Instance.new("ScreenGui")
    gui.Name="NexusESP_PL"; gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
    pcall(function() syn.protect_gui(gui) end)
    pcall(function() gui.Parent=game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent=LP:WaitForChild("PlayerGui") end

    -- Fenetre principale
    mainFrame = Instance.new("Frame")
    mainFrame.Name="PL_Window"; mainFrame.BackgroundColor3=CLR.bg
    mainFrame.BorderSizePixel=0; mainFrame.ClipsDescendants=false
    mainFrame.Size=UDim2.fromOffset(360,480); mainFrame.Position=UDim2.fromOffset(400,60)
    mainFrame.Parent=gui
    corner(mainFrame,10); stroke(mainFrame,CLR.border,1)

    -- ── Header ──────────────────────────────────────────────
    local header=Instance.new("Frame")
    header.BackgroundColor3=CLR.header; header.BorderSizePixel=0
    header.Size=UDim2.new(1,0,0,38); header.Parent=mainFrame
    corner(header,10)

    local accent=Instance.new("Frame")
    accent.BackgroundColor3=CLR.accent; accent.BorderSizePixel=0
    accent.Size=UDim2.fromOffset(3,38); accent.Parent=header

    lbl({Text="👥  PLAYER LIST", Font=Enum.Font.GothamBold, TextSize=13,
         TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Left,
         Size=UDim2.new(1,-100,1,0), Position=UDim2.fromOffset(10,0), Parent=header})

    -- Compteur
    local countLbl=lbl({Name="Count", Text="0", TextColor3=CLR.sub, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.fromOffset(60,38), Position=UDim2.new(1,-90,0,0), Parent=header})

    local closeB=btn({Text="×",TextSize=18,BackgroundColor3=C(160,30,30),
        Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-32,0,5),Parent=header}, function()
        PlayerList.Hide()
    end); corner(closeB,5)

    -- ── Drag ────────────────────────────────────────────────
    do
        local drag,dStart,sPos
        header.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;dStart=i.Position;sPos=mainFrame.Position end
        end)
        header.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
        end)
        UIS.InputChanged:Connect(function(i)
            if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
                local d=i.Position-dStart
                mainFrame.Position=UDim2.fromOffset(sPos.X.Offset+d.X,sPos.Y.Offset+d.Y)
            end
        end)
    end

    -- ── Resize handle ────────────────────────────────────────
    local rsz=btn({Text="⇲",TextSize=13,BackgroundColor3=C(25,25,35),
        Size=UDim2.fromOffset(18,18),Position=UDim2.new(1,-18,1,-18),Parent=mainFrame})
    corner(rsz,4)
    do
        local resizing,rStart,rSize
        rsz.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=true;rStart=i.Position;rSize=mainFrame.AbsoluteSize end
        end)
        rsz.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
        end)
        UIS.InputChanged:Connect(function(i)
            if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
                local d=i.Position-rStart
                local nw=math.clamp(rSize.X+d.X,280,700)
                local nh=math.clamp(rSize.Y+d.Y,300,800)
                mainFrame.Size=UDim2.fromOffset(nw,nh)
            end
        end)
    end

    -- ── Barre de filtres ────────────────────────────────────
    local filterBar=Instance.new("Frame")
    filterBar.BackgroundColor3=C(15,15,20); filterBar.BorderSizePixel=0
    filterBar.Size=UDim2.new(1,0,0,30); filterBar.Position=UDim2.fromOffset(0,38)
    filterBar.Parent=mainFrame
    local fl=Instance.new("UIListLayout"); fl.FillDirection=Enum.FillDirection.Horizontal
    fl.Padding=UDim.new(0,4); fl.VerticalAlignment=Enum.VerticalAlignment.Center
    fl.Parent=filterBar; pad(filterBar,5)

    local function setFilter(name)
        filterMode=name
        for _,child in ipairs(filterBar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3=child.Name==("F_"..name) and CLR.accent or C(32,32,44)
            end
        end
        -- rebuild rows
        for p in pairs(rows) do
            if rows[p] and rows[p].frame then rows[p].frame:Destroy() end
            rows[p]=nil
        end
    end

    for i,name in ipairs({"Tous","Ennemis","Allies"}) do
        local fb=btn({Name="F_"..(name=="Tous" and "All" or name=="Ennemis" and "Enemies" or "Allies"),
            Text=name, TextSize=10,
            BackgroundColor3=(i==1 and CLR.accent or C(32,32,44)),
            Size=UDim2.fromOffset(66,22), Parent=filterBar})
        corner(fb,5)
        fb.MouseButton1Click:Connect(function()
            local mode=(name=="Tous" and "All" or name=="Ennemis" and "Enemies" or "Allies")
            setFilter(mode)
        end)
    end

    -- ── Tabs (Main / Spectate) ───────────────────────────────
    local tabBar=Instance.new("Frame")
    tabBar.BackgroundColor3=C(10,10,14); tabBar.BorderSizePixel=0
    tabBar.Size=UDim2.new(1,0,0,28); tabBar.Position=UDim2.fromOffset(0,68)
    tabBar.Parent=mainFrame
    local tl=Instance.new("UIListLayout"); tl.FillDirection=Enum.FillDirection.Horizontal
    tl.Padding=UDim.new(0,2); tl.Parent=tabBar; pad(tabBar,4)

    tabMain=btn({Name="TabMain",Text="Liste joueurs",TextSize=11,
        BackgroundColor3=CLR.accent, Size=UDim2.fromOffset(120,20),Parent=tabBar})
    corner(tabMain,5)

    tabSpec=btn({Name="TabSpec",Text="Spectate",TextSize=11,
        BackgroundColor3=C(32,32,44), Size=UDim2.fromOffset(100,20),Parent=tabBar,Visible=false})
    corner(tabSpec,5)

    -- ── Contenu liste ────────────────────────────────────────
    listScroll=Instance.new("ScrollingFrame")
    listScroll.Name="ListScroll"; listScroll.BackgroundTransparency=1
    listScroll.BorderSizePixel=0; listScroll.ScrollBarThickness=3
    listScroll.ScrollBarImageColor3=CLR.accent
    listScroll.Size=UDim2.new(1,0,1,-96); listScroll.Position=UDim2.fromOffset(0,96)
    listScroll.CanvasSize=UDim2.new(0,0,0,0); listScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    listScroll.Parent=mainFrame
    local ll=Instance.new("UIListLayout"); ll.SortOrder=Enum.SortOrder.LayoutOrder
    ll.Padding=UDim.new(0,2); ll.Parent=listScroll; pad(listScroll,4)

    -- ── Contenu spectate ─────────────────────────────────────
    specFrame=Instance.new("Frame")
    specFrame.Name="SpecFrame"; specFrame.BackgroundTransparency=1
    specFrame.Size=UDim2.new(1,0,1,-96); specFrame.Position=UDim2.fromOffset(0,96)
    specFrame.Visible=false; specFrame.Parent=mainFrame

    -- UI spectate
    local specBg=Instance.new("Frame")
    specBg.BackgroundColor3=C(15,15,20); specBg.BorderSizePixel=0
    specBg.Size=UDim2.new(1,-8,1,-8); specBg.Position=UDim2.fromOffset(4,4)
    specBg.Parent=specFrame; corner(specBg,8)

    lbl({Name="SpecName",Text="Aucun joueur",Font=Enum.Font.GothamBold,TextSize=16,
         TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Center,
         Size=UDim2.new(1,0,0,30),Position=UDim2.fromOffset(0,10),Parent=specBg})
    lbl({Name="SpecInfo",Text="",TextSize=12,TextColor3=CLR.sub,
         TextXAlignment=Enum.TextXAlignment.Center,
         Size=UDim2.new(1,0,0,60),Position=UDim2.fromOffset(0,45),Parent=specBg})

    -- HP bar spectate
    local hpBgS=Instance.new("Frame"); hpBgS.Name="HpBg"
    hpBgS.BackgroundColor3=C(30,30,40); hpBgS.BorderSizePixel=0
    hpBgS.Size=UDim2.new(1,-20,0,8); hpBgS.Position=UDim2.fromOffset(10,115)
    hpBgS.Parent=specBg; corner(hpBgS,4)
    local hpFillS=Instance.new("Frame"); hpFillS.Name="HpFill"
    hpFillS.BackgroundColor3=CLR.green; hpFillS.BorderSizePixel=0
    hpFillS.Size=UDim2.new(0.75,0,1,0); hpFillS.Parent=hpBgS; corner(hpFillS,4)

    local stopSpecBtn=btn({Text="⏹  Arreter spectate",TextSize=12,
        BackgroundColor3=C(160,30,30),Size=UDim2.new(1,-20,0,32),
        Position=UDim2.fromOffset(10,135),Parent=specBg}, function()
        PlayerList.StopSpectate()
    end); corner(stopSpecBtn,6)

    -- Tabs switch
    tabMain.MouseButton1Click:Connect(function()
        listScroll.Visible=true; specFrame.Visible=false
        tabMain.BackgroundColor3=CLR.accent; tabSpec.BackgroundColor3=C(32,32,44)
    end)
    tabSpec.MouseButton1Click:Connect(function()
        listScroll.Visible=false; specFrame.Visible=true
        tabSpec.BackgroundColor3=CLR.accent; tabMain.BackgroundColor3=C(32,32,44)
    end)
end

-- ── Filtrage ─────────────────────────────────────────────────
local function shouldShow(player)
    if filterMode=="Enemies" then return not Utils.SameTeam(player) end
    if filterMode=="Allies"  then return Utils.SameTeam(player) end
    return true
end

-- ── Créer une row joueur ──────────────────────────────────────
local function buildRow(player, idx)
    local rowData = {}
    local expanded = expandedPlayers[player] or false

    local rowFrame=Instance.new("Frame")
    rowFrame.BackgroundColor3=(idx%2==0) and CLR.bgRow or CLR.bgRowAlt
    rowFrame.BorderSizePixel=0
    rowFrame.Size=UDim2.new(1,-8,0, expanded and 130 or 60)
    rowFrame.LayoutOrder=idx; rowFrame.ClipsDescendants=true
    rowFrame.Parent=listScroll; corner(rowFrame,6)

    -- Dot visibilité
    local visDot=Instance.new("Frame"); visDot.Name="VisDot"
    visDot.BackgroundColor3=CLR.green; visDot.BorderSizePixel=0
    visDot.Size=UDim2.fromOffset(6,6); visDot.Position=UDim2.fromOffset(6,8)
    visDot.Parent=rowFrame; corner(visDot,3)

    -- Nom
    local nameLbl=lbl({Name="NameLbl",Text=player.Name,Font=Enum.Font.GothamBold,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-120,0,16),Position=UDim2.fromOffset(16,4),Parent=rowFrame})

    -- Distance
    local distLbl=lbl({Name="DistLbl",Text="?m",TextSize=11,TextColor3=CLR.sub,
        TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.fromOffset(60,14),Position=UDim2.new(1,-64,0,5),Parent=rowFrame})

    -- Team
    local teamLbl=lbl({Name="TeamLbl",Text="No Team",TextSize=10,TextColor3=CLR.sub,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0.5,0,0,12),Position=UDim2.fromOffset(16,22),Parent=rowFrame})

    -- HP bar
    local hpBg=Instance.new("Frame"); hpBg.BackgroundColor3=C(30,30,40); hpBg.BorderSizePixel=0
    hpBg.Size=UDim2.new(1,-16,0,4); hpBg.Position=UDim2.fromOffset(8,36); hpBg.Parent=rowFrame; corner(hpBg,2)
    local hpBar=Instance.new("Frame"); hpBar.Name="HpBar"; hpBar.BackgroundColor3=CLR.green; hpBar.BorderSizePixel=0
    hpBar.Size=UDim2.new(1,0,1,0); hpBar.Parent=hpBg; corner(hpBar,2)

    -- Boutons ligne 1
    local espDisabledState = espDisabled[player] or false
    local espBtn=btn({Name="EspBtn",
        Text= espDisabledState and "🚫  ESP OFF" or "👁  ESP ON",
        TextSize=10,
        BackgroundColor3= espDisabledState and CLR.espOff or CLR.espOn,
        Size=UDim2.fromOffset(80,18), Position=UDim2.fromOffset(8,42),
        Parent=rowFrame}, function()
        espDisabled[player] = not espDisabled[player]
        local off = espDisabled[player]
        local espBtn2 = rowFrame:FindFirstChild("EspBtn")
        if espBtn2 then
            espBtn2.Text = off and "🚫  ESP OFF" or "👁  ESP ON"
            espBtn2.BackgroundColor3 = off and CLR.espOff or CLR.espOn
        end
        if ESP_ref then
            local ents = ESP_ref.GetEntities()
            if ents[player] then ents[player].disabled = off end
        end
    end); corner(espBtn,4)

    local specBtn=btn({Name="SpecBtn",
        Text= (spectateTarget==player) and "⏹  Stop" or "🎥  Spectate",
        TextSize=10,
        BackgroundColor3=(spectateTarget==player) and CLR.red or C(80,55,10),
        Size=UDim2.fromOffset(86,18), Position=UDim2.fromOffset(92,42),
        Parent=rowFrame}, function()
        if spectateTarget==player then
            PlayerList.StopSpectate()
        else
            PlayerList.StartSpectate(player)
        end
    end); corner(specBtn,4)

    -- Bouton expand (flèche)
    local arrowBtn=btn({Name="ArrowBtn",
        Text= expanded and "▲" or "▼",
        TextSize=10, BackgroundColor3=C(30,30,44),
        Size=UDim2.fromOffset(24,18), Position=UDim2.new(1,-28,0,42),
        Parent=rowFrame}, function()
        expandedPlayers[player] = not (expandedPlayers[player] or false)
        -- Rebuild row
        rowData.frame:Destroy()
        rows[player]=nil
    end); corner(arrowBtn,4)

    -- Zone étendue (infos détaillées)
    local extendedFrame=Instance.new("Frame")
    extendedFrame.Name="Extended"; extendedFrame.BackgroundTransparency=1
    extendedFrame.Size=UDim2.new(1,0,0,68); extendedFrame.Position=UDim2.fromOffset(0,62)
    extendedFrame.Visible=expanded; extendedFrame.Parent=rowFrame

    local infoLbl=lbl({Name="InfoLbl",Text="",TextSize=10,TextColor3=CLR.sub,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        Size=UDim2.new(1,-8,0,44),Position=UDim2.fromOffset(8,2),Parent=extendedFrame})

    rowData = {
        frame=rowFrame, visDot=visDot, nameLbl=nameLbl, distLbl=distLbl,
        teamLbl=teamLbl, hpBar=hpBar, espBtn=espBtn, specBtn=specBtn,
        arrowBtn=arrowBtn, infoLbl=infoLbl, extendedFrame=extendedFrame,
    }
    rows[player] = rowData
    return rowData
end

-- ── Update rows ───────────────────────────────────────────────
local function updateRows()
    if not visible or not listScroll then return end
    local playerList = Players:GetPlayers()
    local idx = 0
    local count = 0

    -- Nettoyer joueurs déconnectés
    for p in pairs(rows) do
        if not p.Parent then
            if rows[p] then rows[p].frame:Destroy(); rows[p]=nil end
        end
    end

    for _, player in ipairs(playerList) do
        if player==LP then continue end
        if not shouldShow(player) then
            if rows[player] then rows[player].frame.Visible=false end
            continue
        end
        count = count+1
        idx = idx+1

        if not rows[player] then buildRow(player, idx) end
        local r = rows[player]
        if not r then continue end

        r.frame.Visible = true
        r.frame.LayoutOrder = idx

        local char = player.Character
        local root = char and Utils.GetRoot(char)

        -- Distance
        local dist = root and math.floor(Utils.GetDistance(root.Position)) or -1
        r.distLbl.Text = dist>=0 and (dist.."m") or "??"

        -- Equipe + couleur nom
        if player.Team then
            r.teamLbl.Text="⬡ "..player.Team.Name
            r.nameLbl.TextColor3=player.Team.TeamColor.Color
        else
            r.teamLbl.Text="No Team"; r.nameLbl.TextColor3=CLR.text
        end

        -- HP
        local hp = char and Utils.GetHealthPercent(char) or 0
        r.hpBar.Size=UDim2.new(math.max(0,hp),0,1,0)
        r.hpBar.BackgroundColor3=Utils.HealthColor(hp)

        -- Visibilité
        local vis = root and Utils.IsVisible(root.Position) or false
        r.visDot.BackgroundColor3 = vis and CLR.green or CLR.red

        -- Infos étendues
        if expandedPlayers[player] then
            r.frame.Size=UDim2.new(1,-8,0,130); r.extendedFrame.Visible=true
            r.arrowBtn.Text="▲"
            local hum = char and Utils.GetHumanoid(char)
            local hpTxt = hum and string.format("%.0f / %.0f", hum.Health, hum.MaxHealth) or "?"
            local acc = player.Character and player.Character:FindFirstChildOfClass("Accessory")
            local tool = char and char:FindFirstChildOfClass("Tool")
            r.infoLbl.Text=string.format(
                "HP: %s  |  Dist: %s\nEquipe: %s  |  Visible: %s\nOutil: %s  |  Ping: %sms",
                hpTxt,
                dist>=0 and (dist.."m") or "??",
                player.Team and player.Team.Name or "Aucune",
                vis and "✅" or "❌",
                tool and tool.Name or "Aucun",
                tostring(player:GetNetworkPing and math.floor(player:GetNetworkPing()*1000) or "?")
            )
        else
            r.frame.Size=UDim2.new(1,-8,0,62); r.extendedFrame.Visible=false
            r.arrowBtn.Text="▼"
        end

        -- ESP button état
        local off = espDisabled[player] or false
        r.espBtn.Text=off and "🚫  ESP OFF" or "👁  ESP ON"
        r.espBtn.BackgroundColor3=off and CLR.espOff or CLR.espOn

        -- Spec button état
        local isSpec = (spectateTarget==player)
        r.specBtn.Text=isSpec and "⏹  Stop" or "🎥  Spectate"
        r.specBtn.BackgroundColor3=isSpec and CLR.red or C(80,55,10)
    end

    -- Compteur
    local header = mainFrame and mainFrame:FindFirstChildOfClass("Frame")
    if header then
        local cl=header:FindFirstChild("Count")
        if cl then cl.Text=count.." joueur"..(count>1 and "s" or "") end
    end
end

-- ── Update spectate frame ──────────────────────────────────────
local function updateSpecFrame()
    if not specFrame or not spectateTarget then return end
    local bg = specFrame:FindFirstChildOfClass("Frame")
    if not bg then return end

    local nameLbl2 = bg:FindFirstChild("SpecName")
    local infoLbl2 = bg:FindFirstChild("SpecInfo")
    local hpBg2    = bg:FindFirstChild("HpBg")

    local char = spectateTarget.Character
    local hum  = char and Utils.GetHumanoid(char)
    local root = char and Utils.GetRoot(char)
    local dist = root and math.floor(Utils.GetDistance(root.Position)) or -1
    local hp   = char and Utils.GetHealthPercent(char) or 0

    if nameLbl2 then
        nameLbl2.Text="🎥  "..spectateTarget.Name
        nameLbl2.TextColor3=spectateTarget.Team and spectateTarget.Team.TeamColor.Color or Color3.new(1,1,1)
    end
    if infoLbl2 then
        local tool = char and char:FindFirstChildOfClass("Tool")
        infoLbl2.Text=string.format(
            "HP: %s/%s  |  Distance: %sm\nEquipe: %s  |  Outil: %s",
            hum and math.floor(hum.Health) or "?",
            hum and math.floor(hum.MaxHealth) or "?",
            dist>=0 and dist or "??",
            spectateTarget.Team and spectateTarget.Team.Name or "Aucune",
            tool and tool.Name or "Aucun"
        )
    end
    if hpBg2 then
        local fill=hpBg2:FindFirstChild("HpFill")
        if fill then
            fill.Size=UDim2.new(math.max(0,hp),0,1,0)
            fill.BackgroundColor3=Utils.HealthColor(hp)
        end
    end
end

-- ── Spectate ──────────────────────────────────────────────────
function PlayerList.StartSpectate(player)
    PlayerList.StopSpectate()
    spectateTarget = player

    -- Afficher l'onglet spectate et y aller
    if tabSpec then tabSpec.Visible=true end
    -- Switch vers tab spec automatiquement
    if listScroll then listScroll.Visible=false end
    if specFrame  then specFrame.Visible=true  end
    if tabSpec    then tabSpec.BackgroundColor3=CLR.accent end
    if tabMain    then tabMain.BackgroundColor3=C(32,32,44) end

    -- Camera mode scriptable avec liberté de mouvement
    local cam = Workspace.CurrentCamera
    cam.CameraType=Enum.CameraType.Custom

    specConn = RunService.RenderStepped:Connect(function()
        if not spectateTarget or not spectateTarget.Character then return end
        local char = spectateTarget.Character
        local root = Utils.GetRoot(char)
        if not root then return end
        -- Camera scriptable : suit en mode "over shoulder" libre
        -- On change juste le CameraSubject pour garder le contrôle natif
        cam.CameraSubject = char:FindFirstChildOfClass("Humanoid") or root
        pcall(updateSpecFrame)
    end)
end

function PlayerList.StopSpectate()
    spectateTarget = nil
    if specConn then specConn:Disconnect(); specConn=nil end

    -- Remettre la caméra sur le joueur local
    local cam = Workspace.CurrentCamera
    local lchar = LP.Character
    if lchar then
        local lhum = lchar:FindFirstChildOfClass("Humanoid")
        if lhum then cam.CameraSubject=lhum end
    end
    cam.CameraType=Enum.CameraType.Custom

    -- Retour tab liste
    if tabSpec    then tabSpec.Visible=false; tabSpec.BackgroundColor3=C(32,32,44) end
    if tabMain    then tabMain.BackgroundColor3=CLR.accent end
    if listScroll then listScroll.Visible=true  end
    if specFrame  then specFrame.Visible=false  end
end

-- ── Show / Hide / Toggle ──────────────────────────────────────
function PlayerList.Show()
    if visible then return end; visible=true
    buildGUI()
    updateConn = RunService.Heartbeat:Connect(function() pcall(updateRows) end)
end

function PlayerList.Hide()
    visible=false
    if updateConn then updateConn:Disconnect(); updateConn=nil end
    PlayerList.StopSpectate()
    if gui then gui:Destroy(); gui=nil end
    mainFrame=nil; listScroll=nil; specFrame=nil; tabMain=nil; tabSpec=nil; rows={}
end

function PlayerList.Toggle()
    if visible then PlayerList.Hide() else PlayerList.Show() end
end

function PlayerList.Cleanup() PlayerList.Hide() end

function PlayerList.TogglePlayerESP(player)
    espDisabled[player] = not (espDisabled[player] or false)
    if ESP_ref then
        local ents=ESP_ref.GetEntities()
        if ents[player] then ents[player].disabled=espDisabled[player] end
    end
end

function PlayerList.StartSpectateByName(name)
    local p=Players:FindFirstChild(name)
    if p then PlayerList.StartSpectate(p) end
end

return PlayerList
