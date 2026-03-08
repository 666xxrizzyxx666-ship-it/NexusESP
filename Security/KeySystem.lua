-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Security/KeySystem.lua
--   Rôle : Écran de validation de clé
--          Linkvertise integration
-- ══════════════════════════════════════════════════════

local KeySystem = {}

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local LP      = Players.LocalPlayer

local LINKVERTISE_URL = "https://linkvertise.com/VOTRE_ID/nexusesp-key"
local KEY_FILE        = "NexusESP/key.txt"
local BYPASS_USERID   = {
    -- Ajoute ton UserId ici pour bypasser le key system
    -- ex: [123456789] = true,
}

local gui = nil

-- ── Helpers UI ────────────────────────────────────────
local function C(r,g,b) return Color3.fromRGB(r,g,b) end

local function createGui()
    local sg = Instance.new("ScreenGui")
    sg.Name           = "NexusESP_Key"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local protectGui = getgenv().NexusESP and getgenv().NexusESP.ProtectGui
    if protectGui then protectGui(sg) end
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

    return sg
end

-- ── Sauvegarde / Lecture clé locale ───────────────────
local function saveKey(key)
    pcall(function()
        if not isfolder("NexusESP") then makefolder("NexusESP") end
        writefile(KEY_FILE, key)
    end)
end

local function loadSavedKey()
    local ok, key = pcall(readfile, KEY_FILE)
    if ok and key and key ~= "" then return key end
    return nil
end

-- ── Validation ────────────────────────────────────────
local function validate(key, callback)
    -- Owner bypass
    local userId = LP.UserId
    if BYPASS_USERID[userId] then
        callback(true, "owner")
        return
    end

    local Firebase = getgenv().NexusESP and getgenv().NexusESP.Firebase
    if not Firebase then
        -- Pas de Firebase → accepte tout (dev mode)
        callback(true, "dev")
        return
    end

    local result = Firebase.ValidateKey(key)
    if result.valid then
        saveKey(key)
        callback(true, result.tier)
    else
        callback(false, result.reason)
    end
end

-- ── UI ────────────────────────────────────────────────
function KeySystem.Show(callback)
    -- Check bypass owner
    if BYPASS_USERID[LP.UserId] then
        print("[KeySystem] Owner bypass ✓")
        callback(true)
        return
    end

    -- Essaie la clé sauvegardée
    local savedKey = loadSavedKey()
    if savedKey then
        validate(savedKey, function(valid, tier)
            if valid then
                print("[KeySystem] Clé sauvegardée valide ✓ (" .. tier .. ")")
                callback(true)
                return
            end
        end)
    end

    -- Affiche l'UI
    gui = createGui()

    -- Fond noir semi-transparent
    local overlay = Instance.new("Frame", gui)
    overlay.BackgroundColor3    = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel     = 0
    overlay.Size                = UDim2.fromScale(1,1)

    -- Fenêtre principale
    local win = Instance.new("Frame", gui)
    win.BackgroundColor3 = C(10,10,14)
    win.BorderSizePixel  = 0
    win.Size             = UDim2.fromOffset(420, 320)
    win.Position         = UDim2.fromScale(0.5, 0.5)
    win.AnchorPoint      = Vector2.new(0.5, 0.5)
    Instance.new("UICorner", win).CornerRadius = UDim.new(0,12)
    local ws = Instance.new("UIStroke", win)
    ws.Color = C(91,107,248); ws.Thickness = 1

    -- Header gradient
    local hdr = Instance.new("Frame", win)
    hdr.BackgroundColor3 = C(6,6,10)
    hdr.BorderSizePixel  = 0
    hdr.Size             = UDim2.new(1,0,0,60)
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,12)

    local acBar = Instance.new("Frame", hdr)
    acBar.BackgroundColor3 = C(91,107,248)
    acBar.BorderSizePixel  = 0
    acBar.Size             = UDim2.fromOffset(3,60)
    Instance.new("UICorner", acBar).CornerRadius = UDim.new(0,2)

    local logo = Instance.new("TextLabel", hdr)
    logo.Text               = "🔮  NexusESP"
    logo.Font               = Enum.Font.GothamBold
    logo.TextSize           = 20
    logo.TextColor3         = C(91,107,248)
    logo.BackgroundTransparency = 1
    logo.Size               = UDim2.new(1,0,0,32)
    logo.Position           = UDim2.fromOffset(16,6)
    logo.TextXAlignment     = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", hdr)
    sub.Text                = "Système d'accès sécurisé"
    sub.Font                = Enum.Font.Gotham
    sub.TextSize            = 11
    sub.TextColor3          = C(100,100,120)
    sub.BackgroundTransparency = 1
    sub.Size                = UDim2.new(1,0,0,18)
    sub.Position            = UDim2.fromOffset(16,36)
    sub.TextXAlignment      = Enum.TextXAlignment.Left

    -- Corps
    local body = Instance.new("Frame", win)
    body.BackgroundTransparency = 1
    body.BorderSizePixel        = 0
    body.Size    = UDim2.new(1,-32,0,220)
    body.Position = UDim2.fromOffset(16,70)

    -- Label
    local lbl = Instance.new("TextLabel", body)
    lbl.Text            = "Entre ta clé d'accès"
    lbl.Font            = Enum.Font.GothamMedium
    lbl.TextSize        = 13
    lbl.TextColor3      = C(220,220,230)
    lbl.BackgroundTransparency = 1
    lbl.Size            = UDim2.new(1,0,0,20)
    lbl.TextXAlignment  = Enum.TextXAlignment.Left

    -- Input
    local inputBg = Instance.new("Frame", body)
    inputBg.BackgroundColor3 = C(16,16,24)
    inputBg.BorderSizePixel  = 0
    inputBg.Size             = UDim2.new(1,0,0,40)
    inputBg.Position         = UDim2.fromOffset(0,26)
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0,8)
    local is = Instance.new("UIStroke", inputBg)
    is.Color = C(35,35,55); is.Thickness = 1

    local input = Instance.new("TextBox", inputBg)
    input.Text               = ""
    input.PlaceholderText    = "XXXX-XXXX-XXXX-XXXX"
    input.PlaceholderColor3  = C(60,60,80)
    input.Font               = Enum.Font.GothamMedium
    input.TextSize           = 14
    input.TextColor3         = C(220,220,230)
    input.BackgroundTransparency = 1
    input.BorderSizePixel    = 0
    input.Size               = UDim2.new(1,-16,1,0)
    input.Position           = UDim2.fromOffset(8,0)
    input.ClearTextOnFocus   = false

    -- Status label
    local status = Instance.new("TextLabel", body)
    status.Text             = ""
    status.Font             = Enum.Font.Gotham
    status.TextSize         = 11
    status.TextColor3       = C(248,113,113)
    status.BackgroundTransparency = 1
    status.Size             = UDim2.new(1,0,0,16)
    status.Position         = UDim2.fromOffset(0,72)
    status.TextXAlignment   = Enum.TextXAlignment.Left

    -- Bouton valider
    local validateBtn = Instance.new("TextButton", body)
    validateBtn.Text            = "✓  Valider la clé"
    validateBtn.Font            = Enum.Font.GothamBold
    validateBtn.TextSize        = 14
    validateBtn.TextColor3      = Color3.new(1,1,1)
    validateBtn.BackgroundColor3 = C(91,107,248)
    validateBtn.BorderSizePixel  = 0
    validateBtn.Size             = UDim2.new(1,0,0,42)
    validateBtn.Position         = UDim2.fromOffset(0,95)
    Instance.new("UICorner", validateBtn).CornerRadius = UDim.new(0,8)

    -- Bouton obtenir clé
    local getKeyBtn = Instance.new("TextButton", body)
    getKeyBtn.Text             = "🔑  Obtenir une clé gratuite"
    getKeyBtn.Font             = Enum.Font.GothamMedium
    getKeyBtn.TextSize         = 12
    getKeyBtn.TextColor3       = C(91,107,248)
    getKeyBtn.BackgroundColor3 = C(16,16,24)
    getKeyBtn.BorderSizePixel  = 0
    getKeyBtn.Size             = UDim2.new(1,0,0,36)
    getKeyBtn.Position         = UDim2.fromOffset(0,144)
    Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0,8)
    local gks = Instance.new("UIStroke", getKeyBtn)
    gks.Color = C(35,35,55); gks.Thickness = 1

    local discord = Instance.new("TextLabel", body)
    discord.Text            = "Discord : discord.gg/nexusesp"
    discord.Font            = Enum.Font.Gotham
    discord.TextSize        = 10
    discord.TextColor3      = C(70,70,90)
    discord.BackgroundTransparency = 1
    discord.Size            = UDim2.new(1,0,0,14)
    discord.Position        = UDim2.fromOffset(0,188)
    discord.TextXAlignment  = Enum.TextXAlignment.Center

    -- Actions
    local function tryValidate()
        local key = input.Text:gsub("%s", "")
        if key == "" then
            status.Text      = "⚠ Entre une clé"
            status.TextColor3 = C(251,191,36)
            return
        end
        status.Text      = "⏳ Vérification..."
        status.TextColor3 = C(148,163,184)
        validateBtn.Text  = "Vérification..."
        validateBtn.BackgroundColor3 = C(50,50,80)

        task.spawn(function()
            validate(key, function(valid, tierOrReason)
                if valid then
                    status.Text       = "✓ Clé valide ! (" .. tostring(tierOrReason) .. ")"
                    status.TextColor3 = C(74,222,128)
                    validateBtn.Text  = "✓ Accès accordé"
                    validateBtn.BackgroundColor3 = C(22,101,52)
                    task.wait(1)
                    if gui then gui:Destroy(); gui = nil end
                    callback(true)
                else
                    status.Text       = "✗ " .. tostring(tierOrReason)
                    status.TextColor3 = C(248,113,113)
                    validateBtn.Text  = "✓  Valider la clé"
                    validateBtn.BackgroundColor3 = C(91,107,248)
                end
            end)
        end)
    end

    validateBtn.MouseButton1Click:Connect(tryValidate)
    input.FocusLost:Connect(function(enter)
        if enter then tryValidate() end
    end)

    getKeyBtn.MouseButton1Click:Connect(function()
        setclipboard(LINKVERTISE_URL)
        status.Text       = "✓ Lien copié ! Ouvre-le dans ton navigateur"
        status.TextColor3 = C(74,222,128)
    end)

    -- Animation d'entrée
    win.Position = UDim2.fromScale(0.5, 0.6)
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    local TweenService = game:GetService("TweenService")
    TweenService:Create(win,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.fromScale(0.5, 0.5)}
    ):Play()
end

function KeySystem.Hide()
    if gui then gui:Destroy(); gui = nil end
end

-- ── Validate synchrone pour Main.lua ─────────────────
function KeySystem.Validate()
    -- Dev mode : Firebase absent → bypass automatique
    local ok, fb = pcall(function()
        return getgenv().NexusESP and getgenv().NexusESP.Firebase
    end)
    if not ok or not fb then
        print("[KeySystem] Dev mode — bypass ✓")
        return true
    end
    -- Owner bypass
    if BYPASS_USERID[LP.UserId] then
        print("[KeySystem] Owner bypass ✓")
        return true
    end
    -- Clé sauvegardée
    local savedKey = nil
    pcall(function() savedKey = readfile(KEY_FILE) end)
    if savedKey and savedKey ~= "" then
        local vok, result = pcall(function() return fb.ValidateKey(savedKey) end)
        if vok and result then
            print("[KeySystem] Clé valide ✓")
            return true
        end
    end
    -- Affiche l'écran sans bloquer
    task.spawn(function()
        KeySystem.Show(function() end)
    end)
    return true
end

return KeySystem
