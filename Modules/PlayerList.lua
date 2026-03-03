-- ============================================================
--  PlayerList.lua — Liste joueurs moderne (ScreenGui)
--  Draggable | Filtrable | Spectate | Toggle ESP par joueur
-- ============================================================
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

-- ── Couleurs du thème ─────────────────────────────────────────
local CLR = {
    bg       = Color3.fromRGB(12, 12, 15),
    bgRow    = Color3.fromRGB(20, 20, 26),
    bgRowAlt = Color3.fromRGB(16, 16, 22),
    header   = Color3.fromRGB(8,  8,  10),
    accent   = Color3.fromRGB(0,  120, 255),
    text     = Color3.fromRGB(220,220,230),
    subtext  = Color3.fromRGB(140,140,155),
    green    = Color3.fromRGB(40, 220, 100),
    red      = Color3.fromRGB(220, 50, 50),
    border   = Color3.fromRGB(35, 35, 50),
    spectate = Color3.fromRGB(255, 180, 0),
}

-- ── Etat ─────────────────────────────────────────────────────
local gui          = nil
local frame        = nil
local listFrame    = nil
local rows         = {}
local updateConn   = nil
local spectateConn = nil
local spectateTarget = nil
local filterMode   = "All"   -- "All" | "Enemies" | "Custom"
local customEnabled = {}     -- [player.Name] = bool
local visible      = false
local searchText   = ""

-- ── Helper UI ─────────────────────────────────────────────────
local function mkFrame(props)
    local f = Instance.new("Frame")
    for k,v in pairs(props) do f[k] = v end
    return f
end

local function mkLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium
    l.TextColor3 = CLR.text
    l.TextSize   = 12
    for k,v in pairs(props) do l[k] = v end
    return l
end

local function mkButton(props, onClick)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = props.Color or CLR.accent
    b.TextColor3       = Color3.new(1,1,1)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 11
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = true
    for k,v in pairs(props) do
        if k ~= "Color" and k ~= "OnClick" then
            pcall(function() b[k] = v end)
        end
    end
    if onClick then b.MouseButton1Click:Connect(onClick) end
    return b
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 4)
    c.Parent = parent
    return c
end

local function addPadding(parent, p)
    local pd = Instance.new("UIPadding")
    pd.PaddingLeft   = UDim.new(0, p)
    pd.PaddingRight  = UDim.new(0, p)
    pd.PaddingTop    = UDim.new(0, p)
    pd.PaddingBottom = UDim.new(0, p)
    pd.Parent = parent
end

-- ── Construction de la GUI ────────────────────────────────────
local function buildGUI()
    -- ScreenGui
    gui = Instance.new("ScreenGui")
    gui.Name              = "NexusESP_PlayerList"
    gui.ResetOnSpawn      = false
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Global
    gui.IgnoreGuiInset    = true
    pcall(function() syn.protect_gui(gui) end)
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Fenetre principale
    frame = mkFrame({
        Name              = "Window",
        BackgroundColor3  = CLR.bg,
        BorderSizePixel   = 0,
        Size              = UDim2.fromOffset(340, 420),
        Position          = UDim2.fromOffset(20, 100),
        ClipsDescendants  = true,
        Parent            = gui,
    })
    addCorner(frame, 8)

    -- Bordure subtile
    local stroke = Instance.new("UIStroke")
    stroke.Color     = CLR.border
    stroke.Thickness = 1
    stroke.Parent    = frame

    -- ── Header ──────────────────────────────────────────────
    local header = mkFrame({
        BackgroundColor3 = CLR.header,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,0,0,36),
        Parent           = frame,
    })
    addCorner(header, 8)

    -- Deco barre accent
    local accentBar = mkFrame({
        BackgroundColor3 = CLR.accent,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0,3,1,0),
        Parent           = header,
    })

    local titleLbl = mkLabel({
        Text             = "  👥  PLAYER LIST",
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextColor3       = Color3.new(1,1,1),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Size             = UDim2.new(1,-70,1,0),
        Position         = UDim2.fromOffset(8,0),
        Parent           = header,
    })

    -- Compteur joueurs
    local countLbl = mkLabel({
        Name           = "CountLabel",
        Text           = "0 joueurs",
        TextColor3     = CLR.subtext,
        TextSize       = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Size           = UDim2.fromOffset(80, 36),
        Position       = UDim2.new(1,-80,0,0),
        Parent         = header,
    })

    -- Bouton fermer
    local closeBtn = mkButton({
        Text             = "×",
        TextSize         = 18,
        Size             = UDim2.fromOffset(28,28),
        Position         = UDim2.new(1,-32,0,4),
        Color            = Color3.fromRGB(180,40,40),
        Parent           = header,
    }, function()
        PlayerList.Hide()
    end)
    addCorner(closeBtn, 4)

    -- ── Drag ────────────────────────────────────────────────
    do
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = inp.Position
                startPos  = frame.Position
            end
        end)
        header.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = inp.Position - dragStart
                frame.Position = UDim2.fromOffset(
                    startPos.X.Offset + delta.X,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- ── Filtres ──────────────────────────────────────────────
    local filterBar = mkFrame({
        BackgroundColor3 = Color3.fromRGB(15,15,20),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,0,0,30),
        Position         = UDim2.fromOffset(0,36),
        Parent           = frame,
    })

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding       = UDim.new(0,4)
    filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    filterLayout.Parent = filterBar
    addPadding(filterBar, 4)

    local filterBtns = {"Tous", "Ennemis", "Allies"}
    for _, name in ipairs(filterBtns) do
        local isActive = (name == "Tous" and filterMode == "All") or
                         (name == "Ennemis" and filterMode == "Enemies") or
                         (name == "Allies" and filterMode == "Allies")
        local fb = mkButton({
            Text     = name,
            TextSize = 10,
            Size     = UDim2.fromOffset(62, 22),
            Color    = isActive and CLR.accent or Color3.fromRGB(35,35,45),
            Name     = "Filter_"..name,
            Parent   = filterBar,
        }, function()
            filterMode = name == "Tous" and "All" or name == "Ennemis" and "Enemies" or "Allies"
            -- Mettre à jour les couleurs
            for _, child in ipairs(filterBar:GetChildren()) do
                if child:IsA("TextButton") then
                    local active = (child.Name == "Filter_"..name)
                    child.BackgroundColor3 = active and CLR.accent or Color3.fromRGB(35,35,45)
                end
            end
        end)
        addCorner(fb, 4)
    end

    -- ── Zone de liste (ScrollingFrame) ───────────────────────
    listFrame = Instance.new("ScrollingFrame")
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel        = 0
    listFrame.Size                   = UDim2.new(1,0,1,-66)
    listFrame.Position               = UDim2.fromOffset(0,66)
    listFrame.ScrollBarThickness     = 3
    listFrame.ScrollBarImageColor3   = CLR.accent
    listFrame.CanvasSize             = UDim2.new(0,0,0,0)
    listFrame.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    listFrame.Parent                 = frame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder   = Enum.SortOrder.LayoutOrder
    listLayout.Padding     = UDim.new(0,1)
    listLayout.Parent      = listFrame

    addPadding(listFrame, 3)
end

-- ── Créer / Mettre à jour une row ────────────────────────────
local function buildRow(player, i)
    local row = mkFrame({
        BackgroundColor3 = i % 2 == 0 and CLR.bgRow or CLR.bgRowAlt,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,-6,0,58),
        LayoutOrder      = i,
        Parent           = listFrame,
    })
    addCorner(row, 5)

    -- Indicateur de visibilité (point coloré gauche)
    local visDot = mkFrame({
        Name             = "VisDot",
        BackgroundColor3 = CLR.green,
        BorderSizePixel  = 0,
        Size             = UDim2.fromOffset(5, 5),
        Position         = UDim2.fromOffset(5, 8),
        Parent           = row,
    })
    addCorner(visDot, 3)

    -- Nom
    local nameLbl = mkLabel({
        Name           = "NameLbl",
        Text           = player.Name,
        TextSize       = 13,
        Font           = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size           = UDim2.new(1,-100,0,16),
        Position       = UDim2.fromOffset(14, 4),
        Parent         = row,
    })

    -- Distance
    local distLbl = mkLabel({
        Name           = "DistLbl",
        Text           = "??m",
        TextSize       = 11,
        TextColor3     = CLR.subtext,
        TextXAlignment = Enum.TextXAlignment.Right,
        Size           = UDim2.fromOffset(70, 14),
        Position       = UDim2.new(1,-74,0,5),
        Parent         = row,
    })

    -- Equipe
    local teamLbl = mkLabel({
        Name           = "TeamLbl",
        Text           = "No Team",
        TextSize       = 10,
        TextColor3     = CLR.subtext,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size           = UDim2.new(1,-80,0,12),
        Position       = UDim2.fromOffset(14, 22),
        Parent         = row,
    })

    -- Barre HP background
    local hpBg = mkFrame({
        Name             = "HpBg",
        BackgroundColor3 = Color3.fromRGB(35,35,40),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,-16,0,4),
        Position         = UDim2.fromOffset(8, 36),
        Parent           = row,
    })
    addCorner(hpBg, 2)

    -- Barre HP fill
    local hpBar = mkFrame({
        Name             = "HpBar",
        BackgroundColor3 = CLR.green,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1,0,1,0),
        Parent           = hpBg,
    })
    addCorner(hpBar, 2)

    -- Bouton Toggle ESP
    local espBtn = mkButton({
        Name    = "EspBtn",
        Text    = "👁 ESP ON",
        TextSize = 10,
        Size    = UDim2.fromOffset(75,18),
        Position = UDim2.fromOffset(8, 42),
        Color   = Color3.fromRGB(30,90,180),
        Parent  = row,
    }, function()
        if ESP_ref then
            local ents = ESP_ref.GetEntities()
            local ent  = ents[player]
            if ent then
                ent.disabled = not ent.disabled
                espBtn.Text             = ent.disabled and "👁 ESP OFF" or "👁 ESP ON"
                espBtn.BackgroundColor3 = ent.disabled and Color3.fromRGB(80,30,30) or Color3.fromRGB(30,90,180)
            end
        end
    end)
    addCorner(espBtn, 4)

    -- Bouton Spectate
    local specBtn = mkButton({
        Name    = "SpecBtn",
        Text    = "🎥 Spectate",
        TextSize = 10,
        Size    = UDim2.fromOffset(80,18),
        Position = UDim2.fromOffset(86, 42),
        Color   = Color3.fromRGB(100,70,0),
        Parent  = row,
    }, function()
        if spectateTarget == player then
            PlayerList.StopSpectate()
            specBtn.Text             = "🎥 Spectate"
            specBtn.BackgroundColor3 = Color3.fromRGB(100,70,0)
        else
            PlayerList.StartSpectate(player)
            -- reset tous les autres boutons
            for _, r in pairs(rows) do
                local sb = r.Frame and r.Frame:FindFirstChild("SpecBtn")
                if sb then
                    sb.Text             = "🎥 Spectate"
                    sb.BackgroundColor3 = Color3.fromRGB(100,70,0)
                end
            end
            specBtn.Text             = "⏹ Stop"
            specBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
        end
    end)
    addCorner(specBtn, 4)

    rows[player] = { Frame = row, VisDot=visDot, NameLbl=nameLbl,
                     DistLbl=distLbl, TeamLbl=teamLbl, HpBar=hpBar,
                     EspBtn=espBtn, SpecBtn=specBtn }
    return row
end

-- ── Update des données ────────────────────────────────────────
local function shouldShow(player)
    if filterMode == "Enemies" then
        return not Utils.SameTeam(player)
    elseif filterMode == "Allies" then
        return Utils.SameTeam(player)
    end
    return true
end

local function updateRows()
    if not visible or not listFrame then return end

    local playerList = Players:GetPlayers()
    local idx = 0

    -- Supprimer les rows de joueurs partis
    for p, rowData in pairs(rows) do
        if not p.Parent or p.Parent ~= Players then
            rowData.Frame:Destroy()
            rows[p] = nil
        end
    end

    for _, player in ipairs(playerList) do
        if player == LP then continue end
        if not shouldShow(player) then
            if rows[player] then rows[player].Frame.Visible = false end
            continue
        end

        idx = idx + 1

        -- Créer la row si elle n'existe pas
        if not rows[player] then buildRow(player, idx) end

        local rowData = rows[player]
        if not rowData then continue end

        rowData.Frame.Visible     = true
        rowData.Frame.LayoutOrder = idx

        local char = player.Character
        local root = char and Utils.GetRoot(char)

        -- Distance
        local dist = root and math.floor(Utils.GetDistance(root.Position)) or -1
        rowData.DistLbl.Text = dist >= 0 and (dist.."m") or "??"

        -- Equipe + couleur nom
        if player.Team then
            rowData.TeamLbl.Text      = player.Team.Name
            rowData.NameLbl.TextColor3 = player.Team.TeamColor.Color
        else
            rowData.TeamLbl.Text       = "No Team"
            rowData.NameLbl.TextColor3 = CLR.text
        end

        -- HP bar
        local hp = char and Utils.GetHealthPercent(char) or 0
        rowData.HpBar.Size             = UDim2.new(math.max(0, hp), 0, 1, 0)
        rowData.HpBar.BackgroundColor3 = Utils.HealthColor(hp)

        -- Visibilité
        local isVis = root and Utils.IsVisible(root.Position) or false
        rowData.VisDot.BackgroundColor3 = isVis and CLR.green or CLR.red
    end

    -- Mettre à jour le compteur
    local countLbl = frame and frame:FindFirstChild("Window", true)
    local header   = frame and frame:FindFirstChildWhichIsA("Frame")
    if header then
        local cl = header:FindFirstChild("CountLabel")
        if cl then cl.Text = idx.." joueurs" end
    end
end

-- ── Spectate ─────────────────────────────────────────────────
function PlayerList.StartSpectate(player)
    PlayerList.StopSpectate()
    spectateTarget = player

    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable

    spectateConn = RunService.RenderStepped:Connect(function()
        if not spectateTarget or not spectateTarget.Character then return end
        local root = Utils.GetRoot(spectateTarget.Character)
        local head = spectateTarget.Character:FindFirstChild("Head")
        if root then
            cam.CFrame = CFrame.new(root.Position + Vector3.new(0,2,0)) *
                         CFrame.Angles(0, math.pi, 0) *
                         CFrame.new(0,0,5)
        end
    end)
end

function PlayerList.StopSpectate()
    spectateTarget = nil
    if spectateConn then spectateConn:Disconnect(); spectateConn = nil end
    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
end

-- ── Show / Hide ───────────────────────────────────────────────
function PlayerList.Show()
    if visible then return end
    visible = true
    buildGUI()
    updateConn = RunService.Heartbeat:Connect(function()
        pcall(updateRows)
    end)
end

function PlayerList.Hide()
    visible = false
    if updateConn then updateConn:Disconnect(); updateConn = nil end
    PlayerList.StopSpectate()
    if gui then gui:Destroy(); gui = nil end
    frame = nil; listFrame = nil; rows = {}
end

function PlayerList.Toggle()
    if visible then PlayerList.Hide() else PlayerList.Show() end
end

function PlayerList.Cleanup()
    PlayerList.Hide()
end

-- ── Focus (legacy - maintenant c'est Spectate) ───────────────
function PlayerList.FocusPlayer(player)
    PlayerList.StartSpectate(player)
end

function PlayerList.Unfocus()
    PlayerList.StopSpectate()
end

function PlayerList.TogglePlayerESP(player)
    if not ESP_ref then return end
    local ents = ESP_ref.GetEntities()
    local ent  = ents[player]
    if ent then ent.disabled = not ent.disabled end
end

function PlayerList.GetData()
    local data = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        local root = char and Utils.GetRoot(char)
        table.insert(data, {
            player   = p,
            name     = p.Name,
            distance = root and math.floor(Utils.GetDistance(root.Position)) or -1,
            health   = char and Utils.GetHealthPercent(char) or 0,
            team     = p.Team and p.Team.Name or "No Team",
            visible  = root and Utils.IsVisible(root.Position) or false,
        })
    end
    return data
end

return PlayerList
