-- ============================================================
--  PlayerList.lua — Liste avancée des joueurs avec infos temps réel
--  Distance | Équipe | Santé | Visibilité | Position
--  Bouton Focus | Toggle visualisation individuelle
--  Rendu via Drawing (overlay) ou via l'UI Linoria
-- ============================================================

local PlayerList = {}
PlayerList.__index = PlayerList

-- ── Services ─────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

-- ── Dépendances ──────────────────────────────────────────────
local Utils
local Config
local ESP_ref   -- référence à l'ESP pour toggle/focus

function PlayerList.SetDependencies(utils, config, esp)
    Utils   = utils
    Config  = config
    ESP_ref = esp
end

-- ── État interne ─────────────────────────────────────────────
local playerData   = {}   -- cache des données joueurs
local listDrawings = {}   -- drawings de la liste overlay
local listConn     = nil
local visible      = false
local focusedPlayer = nil

-- Paramètres visuels de la liste overlay
local LIST_X       = 10
local LIST_Y       = 10
local ROW_HEIGHT   = 16
local FONT_SIZE    = 12
local LIST_WIDTH   = 280
local MAX_PLAYERS  = 16

-- ── Couleurs helpers ─────────────────────────────────────────
local function teamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(200, 200, 200)
end

-- ── Mise à jour du cache ─────────────────────────────────────
local function refreshPlayerData()
    playerData = {}
    local lp = Players.LocalPlayer

    for _, player in ipairs(Players:GetPlayers()) do
        if player == lp then continue end

        local char = player.Character
        local root = char and Utils.GetRoot(char)

        local data = {
            player   = player,
            name     = player.Name,
            distance = root and math.floor(Utils.GetDistance(root.Position)) or -1,
            team     = player.Team and player.Team.Name or "No Team",
            health   = char and Utils.GetHealthPercent(char) or 0,
            visible  = root and Utils.IsVisible(root.Position) or false,
            position = root and root.Position or Vector3.new(0, 0, 0),
            espOn    = not (ESP_ref and ESP_ref.GetEntities()["__disabled__" .. player.Name]),
        }

        if ESP_ref then
            local info = pcall(function()
                return ESP_ref.GetPlayerInfo(player)
            end)
        end

        table.insert(playerData, data)
    end

    -- Trier par distance
    table.sort(playerData, function(a, b)
        if a.distance == -1 then return false end
        if b.distance == -1 then return true end
        return a.distance < b.distance
    end)
end

-- ── Créer les drawings de la liste ───────────────────────────
local function createListDrawings(count)
    -- Nettoyer les anciens
    for _, d in pairs(listDrawings) do
        Utils.RemoveDrawing(d)
    end
    listDrawings = {}

    -- Background
    listDrawings.bg = Utils.NewDrawing("Square", {
        Position     = Vector2.new(LIST_X - 4, LIST_Y - 4),
        Size         = Vector2.new(LIST_WIDTH + 8, count * ROW_HEIGHT + 26),
        Filled       = true,
        Color        = Color3.fromRGB(15, 15, 15),
        Transparency = 0.3,
        Visible      = true,
    })

    -- Titre
    listDrawings.title = Utils.NewDrawing("Text", {
        Text     = "  ── Player List ──",
        Size     = 13,
        Position = Vector2.new(LIST_X, LIST_Y + 2),
        Color    = Color3.fromRGB(0, 170, 255),
        Outline  = true,
        Visible  = true,
    })

    -- Header
    listDrawings.header = Utils.NewDrawing("Text", {
        Text     = "  Name                  Dist   HP    Team       Vis",
        Size     = FONT_SIZE - 1,
        Position = Vector2.new(LIST_X, LIST_Y + ROW_HEIGHT + 2),
        Color    = Color3.fromRGB(150, 150, 150),
        Outline  = true,
        Visible  = true,
    })

    -- Lignes joueurs
    for i = 1, math.min(count, MAX_PLAYERS) do
        listDrawings["row_bg_" .. i] = Utils.NewDrawing("Square", {
            Filled       = true,
            Color        = Color3.fromRGB(30, 30, 30),
            Transparency = 0.5,
            Visible      = false,
        })

        listDrawings["row_" .. i] = Utils.NewDrawing("Text", {
            Size    = FONT_SIZE,
            Outline = true,
            Visible = false,
        })

        -- Barre de santé mini
        listDrawings["hp_bg_" .. i] = Utils.NewDrawing("Square", {
            Filled  = true,
            Color   = Color3.fromRGB(40, 40, 40),
            Visible = false,
        })

        listDrawings["hp_bar_" .. i] = Utils.NewDrawing("Square", {
            Filled  = true,
            Color   = Color3.fromRGB(0, 255, 0),
            Visible = false,
        })

        -- Indicateur de visibilité
        listDrawings["vis_" .. i] = Utils.NewDrawing("Square", {
            Filled  = true,
            Visible = false,
        })

        -- Indicateur focus
        listDrawings["focus_" .. i] = Utils.NewDrawing("Square", {
            Filled  = false,
            Color   = Color3.fromRGB(255, 200, 0),
            Visible = false,
        })
    end
end

-- ── Render de la liste ────────────────────────────────────────
local function renderList()
    if not visible then return end
    if not Config or not Config.Current.PlayerList.Enabled then return end

    refreshPlayerData()

    local count = math.min(#playerData, MAX_PLAYERS)
    local startY = LIST_Y + ROW_HEIGHT * 2 + 4

    -- Redimensionner le bg
    if listDrawings.bg then
        listDrawings.bg.Size = Vector2.new(LIST_WIDTH + 8, count * ROW_HEIGHT + 26)
    end

    for i = 1, MAX_PLAYERS do
        local data = playerData[i]

        local rowBg   = listDrawings["row_bg_" .. i]
        local row     = listDrawings["row_" .. i]
        local hpBg    = listDrawings["hp_bg_" .. i]
        local hpBar   = listDrawings["hp_bar_" .. i]
        local visInd  = listDrawings["vis_" .. i]
        local focusInd = listDrawings["focus_" .. i]

        if not row then continue end

        if not data then
            if rowBg    then rowBg.Visible    = false end
            if row      then row.Visible      = false end
            if hpBg     then hpBg.Visible     = false end
            if hpBar    then hpBar.Visible    = false end
            if visInd   then visInd.Visible   = false end
            if focusInd then focusInd.Visible = false end
            continue
        end

        local rowY = startY + (i - 1) * ROW_HEIGHT

        -- Fond de la ligne
        if rowBg then
            local isFocused = focusedPlayer == data.player
            rowBg.Position     = Vector2.new(LIST_X - 2, rowY - 1)
            rowBg.Size         = Vector2.new(LIST_WIDTH + 4, ROW_HEIGHT)
            rowBg.Color        = isFocused and Color3.fromRGB(0, 60, 120) or Color3.fromRGB(25, 25, 25)
            rowBg.Transparency = isFocused and 0.2 or 0.6
            rowBg.Visible      = true
        end

        -- Texte de la ligne
        if row then
            local cfg      = Config.Current.PlayerList
            local nameStr  = Utils.Truncate(data.name, 16)
            local distStr  = data.distance >= 0 and (data.distance .. "m") or "??"
            local teamStr  = cfg.ShowTeam    and Utils.Truncate(data.team, 10) or ""

            local line = string.format("%-17s %5s", nameStr, distStr)
            if cfg.ShowTeam then
                line = line .. string.format("  %-10s", teamStr)
            end

            row.Text     = line
            row.Position = Vector2.new(LIST_X + 2, rowY)
            row.Color    = teamColor(data.player)
            row.Visible  = true
        end

        -- Mini HP bar
        local cfg2 = Config.Current.PlayerList
        if cfg2.ShowHealth then
            local hpW  = 40
            local hpX  = LIST_X + LIST_WIDTH - hpW - 20
            local hpY  = rowY + 3
            local hpH  = ROW_HEIGHT - 6

            if hpBg then
                hpBg.Position = Vector2.new(hpX, hpY)
                hpBg.Size     = Vector2.new(hpW, hpH)
                hpBg.Visible  = true
            end

            if hpBar then
                local fillW = math.max(1, math.floor(hpW * data.health))
                hpBar.Position = Vector2.new(hpX, hpY)
                hpBar.Size     = Vector2.new(fillW, hpH)
                hpBar.Color    = Utils.HealthColor(data.health)
                hpBar.Visible  = true
            end
        else
            if hpBg  then hpBg.Visible  = false end
            if hpBar then hpBar.Visible = false end
        end

        -- Indicateur de visibilité
        if cfg2.ShowVisible then
            if visInd then
                visInd.Position     = Vector2.new(LIST_X + LIST_WIDTH - 10, rowY + 4)
                visInd.Size         = Vector2.new(6, 6)
                visInd.Color        = data.visible
                                      and Color3.fromRGB(0, 255, 100)
                                      or  Color3.fromRGB(255, 60, 60)
                visInd.Visible      = true
            end
        else
            if visInd then visInd.Visible = false end
        end

        -- Indicateur focus
        if focusInd then
            if focusedPlayer == data.player then
                focusInd.Position  = Vector2.new(LIST_X - 2, rowY - 1)
                focusInd.Size      = Vector2.new(LIST_WIDTH + 4, ROW_HEIGHT)
                focusInd.Thickness = 1
                focusInd.Visible   = true
            else
                focusInd.Visible = false
            end
        end
    end
end

-- ── API Publique ─────────────────────────────────────────────

function PlayerList.Show()
    visible = true
    createListDrawings(MAX_PLAYERS)
    listConn = RunService.RenderStepped:Connect(renderList)
    Utils.Log("PlayerList activée")
end

function PlayerList.Hide()
    visible = false
    if listConn then
        listConn:Disconnect()
        listConn = nil
    end
    for _, d in pairs(listDrawings) do
        Utils.RemoveDrawing(d)
    end
    listDrawings = {}
    Utils.Log("PlayerList masquée")
end

function PlayerList.Toggle()
    if visible then
        PlayerList.Hide()
    else
        PlayerList.Show()
    end
end

-- Retourne la liste de données courante (pour l'UI Linoria)
function PlayerList.GetData()
    refreshPlayerData()
    return playerData
end

-- Focus un joueur (caméra CFrame)
function PlayerList.FocusPlayer(player)
    focusedPlayer = player
    if not player then return end

    local char = player.Character
    local root = char and Utils.GetRoot(char)
    if not root then return end

    -- Déplacer la caméra pour regarder le joueur
    local camera = Workspace.CurrentCamera
    local camPos = root.Position + Vector3.new(0, 3, 10)
    camera.CFrame = CFrame.new(camPos, root.Position)

    Utils.Log("Focus sur " .. player.Name)
end

function PlayerList.Unfocus()
    focusedPlayer = nil
end

-- Toggle les visualisations ESP d'un joueur
function PlayerList.TogglePlayerESP(player)
    if not ESP_ref then return end
    local ents = ESP_ref.GetEntities()
    local ent  = ents[player]
    if ent then
        ent.disabled = not ent.disabled
        Utils.Log(player.Name .. " ESP: " .. (ent.disabled and "OFF" or "ON"))
    end
end

function PlayerList.IsPlayerESPEnabled(player)
    if not ESP_ref then return true end
    local ents = ESP_ref.GetEntities()
    local ent  = ents[player]
    return ent and not ent.disabled or true
end

function PlayerList.Cleanup()
    PlayerList.Hide()
end

return PlayerList
