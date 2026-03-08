-- ══════════════════════════════════════════════════════
--   Aurora v3.0.5 — Security/KeySystem.lua
-- ══════════════════════════════════════════════════════

local KeySystem = {}

local Players = game:GetService("Players")
local TweenS  = game:GetService("TweenService")
local LP      = Players.LocalPlayer

local LINKVERTISE_URL = "https://linkvertise.com/VOTRE_ID/aurora-key"
local KEY_FILE        = "Aurora/key.txt"
local BYPASS_USERID   = {}

local gui = nil

local function C(r,g,b) return Color3.fromRGB(r,g,b) end

local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0,10)
end

local function mkStroke(p, col, t)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C(91,107,248)
    s.Thickness = t or 1
    return s  -- FIX : retourne le stroke
end

local function saveKey(key)
    pcall(function()
        if not isfolder("Aurora") then makefolder("Aurora") end
        writefile(KEY_FILE, key)
    end)
end

local function loadKey()
    local ok, key = pcall(readfile, KEY_FILE)
    if ok and key and key ~= "" then return key end
    return nil
end

-- Validation — dev mode si Firebase absent
local function doValidate(key, callback)
    if not callback then return end
    -- Tout dans un pcall global pour ne jamais crasher
    local ok, err = pcall(function()
        local userId = LP and LP.UserId or 0
        if BYPASS_USERID[userId] then callback(true,"owner"); return end

        local Firebase = getgenv().NexusESP and getgenv().NexusESP.Firebase
        if not Firebase or type(Firebase.ValidateKey) ~= "function" then
            callback(true, "dev"); return
        end

        local ok3, result = pcall(Firebase.ValidateKey, Firebase, key)
        if ok3 and type(result) == "table" and result.valid then
            saveKey(key)
            callback(true, result.tier or "free")
        else
            callback(false, (type(result) == "table" and result.reason) or "Clé invalide")
        end
    end)
    if not ok then
        -- Erreur inattendue → dev bypass
        print("[Aurora/Key] Erreur validation : "..tostring(err))
        pcall(callback, true, "dev")
    end
end

-- ── UI ────────────────────────────────────────────────
function KeySystem.Show(callback)
    if gui then pcall(function() gui:Destroy() end) end

    gui = Instance.new("ScreenGui")
    gui.Name              = "Aurora_Key"
    gui.ResetOnSpawn      = false
    gui.IgnoreGuiInset    = true
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Global
    gui.DisplayOrder      = 9999
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Overlay sombre
    local overlay = Instance.new("Frame", gui)
    overlay.BackgroundColor3       = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.45
    overlay.BorderSizePixel        = 0
    overlay.Size                   = UDim2.fromScale(1,1)

    -- ── Fenêtre UNIQUE ────────────────────────────────
    -- Bordure via frame parente (évite le trait UIStroke)
    local winBorder = Instance.new("Frame", gui)
    winBorder.BackgroundColor3 = C(91,107,248)
    winBorder.BorderSizePixel  = 0
    winBorder.Size             = UDim2.fromOffset(402, 292)
    winBorder.Position         = UDim2.new(0.5,0,0.6,0)
    winBorder.AnchorPoint      = Vector2.new(0.5,0.5)
    mkCorner(winBorder, UDim.new(0,15))

    local win = Instance.new("Frame", winBorder)
    win.BackgroundColor3   = C(10,10,18)
    win.BorderSizePixel    = 0
    win.Size               = UDim2.fromOffset(400, 290)
    win.Position           = UDim2.fromOffset(1,1)
    win.ClipsDescendants   = true
    mkCorner(win, UDim.new(0,14))

    -- Gradient de fond (header intégré, pas de frame séparée)
    local grad = Instance.new("UIGradient", win)
    grad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C(18,16,34)),
        ColorSequenceKeypoint.new(0.35, C(12,12,20)),
        ColorSequenceKeypoint.new(1,   C(10,10,18)),
    })
    grad.Rotation = 90

    -- Icône maison (asset simple dispo partout)
    local logoImg = Instance.new("ImageLabel", win)
    logoImg.Image = "rbxassetid://4483345998"
    logoImg.BackgroundTransparency = 1
    logoImg.Size                   = UDim2.fromOffset(32,32)
    logoImg.Position               = UDim2.fromOffset(22,16)
    logoImg.ImageColor3 = C(91,107,248)
    logoImg.ImageTransparency = 1  -- cache si asset invalide

    -- Logo texte "A" fiable (fonctionne partout)
    local logoTxt = Instance.new("TextLabel", win)
    logoTxt.Text = "A"
    logoTxt.Font = Enum.Font.GothamBold
    logoTxt.TextSize = 22
    logoTxt.TextColor3 = Color3.new(1,1,1)
    logoTxt.BackgroundColor3 = C(91,107,248)
    logoTxt.BorderSizePixel = 0
    logoTxt.Size = UDim2.fromOffset(36,36)
    logoTxt.Position = UDim2.fromOffset(14,14)
    mkCorner(logoTxt, UDim.new(0,8))

    -- Titre "Aurora"
    local title = Instance.new("TextLabel", win)
    title.Text              = "Aurora"
    title.Font              = Enum.Font.GothamBold
    title.TextSize          = 22
    title.TextColor3        = C(91,107,248)
    title.BackgroundTransparency = 1
    title.Size              = UDim2.new(1,-80,0,30)
    title.Position          = UDim2.fromOffset(62,12)
    title.TextXAlignment    = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", win)
    sub.Text             = "Système d'accès sécurisé"
    sub.Font             = Enum.Font.Gotham
    sub.TextSize         = 12
    sub.TextColor3       = C(110,110,160)
    sub.BackgroundTransparency = 1
    sub.Size             = UDim2.new(1,-80,0,16)
    sub.Position         = UDim2.fromOffset(62,40)
    sub.TextXAlignment   = Enum.TextXAlignment.Left

    -- Séparateur fin
    local divider = Instance.new("Frame", win)
    divider.BackgroundColor3 = C(40,40,70)
    divider.BorderSizePixel  = 0
    divider.Size             = UDim2.new(1,-30,0,1)
    divider.Position         = UDim2.fromOffset(15,68)

    -- Label input
    local lbl = Instance.new("TextLabel", win)
    lbl.Text             = "Entre ta clé d'accès"
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextColor3       = C(180,180,210)
    lbl.BackgroundTransparency = 1
    lbl.Size             = UDim2.new(1,-40,0,18)
    lbl.Position         = UDim2.fromOffset(20,82)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left

    -- Input box
    local inputBg = Instance.new("Frame", win)
    inputBg.BackgroundColor3 = C(18,18,28)
    inputBg.BorderSizePixel  = 0
    inputBg.Size             = UDim2.new(1,-40,0,40)
    inputBg.Position         = UDim2.fromOffset(20,106)
    mkCorner(inputBg, UDim.new(0,8))
    local is = mkStroke(inputBg, C(50,50,90), 1)

    local input = Instance.new("TextBox", inputBg)
    input.PlaceholderText        = "XXXX-XXXX-XXXX-XXXX"
    input.PlaceholderColor3      = C(70,70,110)
    input.Text                   = ""
    input.Font                   = Enum.Font.Code
    input.TextSize               = 14
    input.TextColor3             = Color3.new(1,1,1)
    input.BackgroundTransparency = 1
    input.Size                   = UDim2.new(1,-20,1,0)
    input.Position               = UDim2.fromOffset(10,0)
    input.ClearTextOnFocus       = false

    input.Focused:Connect(function()
        if is then pcall(function() TweenS:Create(is, TweenInfo.new(0.15), {Color=C(91,107,248)}):Play() end) end
    end)
    input.FocusLost:Connect(function()
        if is then pcall(function() TweenS:Create(is, TweenInfo.new(0.15), {Color=C(50,50,90)}):Play() end) end
    end)

    -- Status
    local status = Instance.new("TextLabel", win)
    status.Text              = ""
    status.Font              = Enum.Font.Gotham
    status.TextSize          = 12
    status.TextColor3        = C(248,113,113)
    status.BackgroundTransparency = 1
    status.Size              = UDim2.new(1,-40,0,16)
    status.Position          = UDim2.fromOffset(20,150)
    status.TextXAlignment    = Enum.TextXAlignment.Left

    -- Bouton Valider
    local valBtn = Instance.new("TextButton", win)
    valBtn.BackgroundColor3 = C(91,107,248)
    valBtn.BorderSizePixel  = 0
    valBtn.Size             = UDim2.new(1,-40,0,38)
    valBtn.Position         = UDim2.fromOffset(20,172)
    valBtn.Text             = "✓  Valider la clé"
    valBtn.Font             = Enum.Font.GothamBold
    valBtn.TextSize         = 14
    valBtn.TextColor3       = Color3.new(1,1,1)
    valBtn.AutoButtonColor  = false
    mkCorner(valBtn, UDim.new(0,8))

    valBtn.MouseEnter:Connect(function()
        pcall(function() TweenS:Create(valBtn, TweenInfo.new(0.1), {BackgroundColor3=C(110,128,255)}):Play() end)
    end)
    valBtn.MouseLeave:Connect(function()
        pcall(function() TweenS:Create(valBtn, TweenInfo.new(0.1), {BackgroundColor3=C(91,107,248)}):Play() end)
    end)

    -- Bouton get key
    local getBtn = Instance.new("TextButton", win)
    getBtn.BackgroundTransparency = 1
    getBtn.BorderSizePixel  = 0
    getBtn.Size             = UDim2.new(1,-40,0,28)
    getBtn.Position         = UDim2.fromOffset(20,216)
    getBtn.Text             = "🔑  Obtenir une clé gratuite"
    getBtn.Font             = Enum.Font.Gotham
    getBtn.TextSize         = 13
    getBtn.TextColor3       = C(91,107,248)
    getBtn.AutoButtonColor  = false

    -- Discord
    local disc = Instance.new("TextLabel", win)
    disc.Text              = "discord.gg/aurora"
    disc.Font              = Enum.Font.Gotham
    disc.TextSize          = 11
    disc.TextColor3        = C(70,70,110)
    disc.BackgroundTransparency = 1
    disc.Size              = UDim2.new(1,0,0,14)
    disc.Position          = UDim2.fromOffset(0,268)
    disc.TextXAlignment    = Enum.TextXAlignment.Center

    -- ── Logique ───────────────────────────────────────
    local function tryValidate()
        local key = input.Text:gsub("%s","")
        if #key < 5 then
            status.TextColor3 = C(248,113,113)
            status.Text = "✗ Clé trop courte"
            return
        end
        valBtn.Text = "Vérification..."
        valBtn.BackgroundColor3 = C(60,70,160)
        status.Text = ""

        doValidate(key, function(valid, info)
            if valid then
                status.TextColor3 = C(74,222,128)
                status.Text = "✓ Accès autorisé !"
                valBtn.Text = "✓ Validé !"
                task.wait(1)
                KeySystem.Hide()
                if callback then pcall(callback, true) end
            else
                status.TextColor3 = C(248,113,113)
                status.Text = "✗ " .. tostring(info)
                valBtn.Text = "✓  Valider la clé"
                valBtn.BackgroundColor3 = C(91,107,248)
            end
        end)
    end

    valBtn.MouseButton1Click:Connect(tryValidate)
    input.FocusLost:Connect(function(enter)
        if enter then tryValidate() end
    end)

    getBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(LINKVERTISE_URL) end)
        status.TextColor3 = C(74,222,128)
        status.Text = "✓ Lien copié !"
    end)

    -- Animation entrée
    TweenS:Create(winBorder,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5,0,0.5,0)}
    ):Play()
end

function KeySystem.Hide()
    task.delay(0.2, function()
        if gui then gui:Destroy(); gui = nil end
    end)
end

function KeySystem.Validate()
    local ok2, Firebase = pcall(function()
        return getgenv().NexusESP and getgenv().NexusESP.Firebase or nil
    end)
    if not ok2 or not Firebase or not Firebase.ValidateKey then
        print("[Aurora] Dev mode — bypass ✓")
        return true
    end

    local userId = LP and LP.UserId or 0
    if BYPASS_USERID[userId] then return true end

    local savedKey = loadKey()
    if savedKey then
        local ok3, result = pcall(Firebase.ValidateKey, Firebase, savedKey)
        if ok3 and result and result.valid then return true end
    end

    task.spawn(function() KeySystem.Show(function() end) end)
    return true
end

return KeySystem
