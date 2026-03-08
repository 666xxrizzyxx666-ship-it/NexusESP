-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.3 — Security/KeySystem.lua
--   Rôle : Écran de validation de clé (Linkvertise)
-- ══════════════════════════════════════════════════════

local KeySystem = {}

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TweenS  = game:GetService("TweenService")
local LP      = Players.LocalPlayer

local LINKVERTISE_URL = "https://linkvertise.com/VOTRE_ID/nexusesp-key"
local KEY_FILE        = "NexusESP/key.txt"
local BYPASS_USERID   = {
    -- [TON_USER_ID] = true,
}

local gui = nil

local function C(r,g,b) return Color3.fromRGB(r,g,b) end
local function corner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=r or UDim.new(0,8); return c end
local function stroke(p,col,t) local s=Instance.new("UIStroke",p); s.Color=col; s.Thickness=t or 1; return s end

-- ── Save / Load key ───────────────────────────────────
local function saveKey(key)
    pcall(function()
        if not isfolder("NexusESP") then makefolder("NexusESP") end
        writefile(KEY_FILE, key)
    end)
end

local function loadKey()
    local ok, key = pcall(readfile, KEY_FILE)
    if ok and key and key ~= "" then return key end
    return nil
end

-- ── Validation ────────────────────────────────────────
local function validate(key, callback)
    if not callback then return end

    local userId = LP and LP.UserId or 0
    if BYPASS_USERID[userId] then
        callback(true, "owner")
        return
    end

    -- Dev mode : Firebase absent ou pas configuré → accepte tout
    local Firebase = getgenv().NexusESP and getgenv().NexusESP.Firebase
    if not Firebase or not Firebase.ValidateKey then
        callback(true, "dev")
        return
    end

    local ok, result = pcall(function()
        return Firebase.ValidateKey(key)
    end)

    if ok and result and result.valid then
        saveKey(key)
        callback(true, result.tier or "free")
    else
        callback(false, (ok and result and result.reason) or "Clé invalide")
    end
end

-- ── UI ────────────────────────────────────────────────
function KeySystem.Show(callback)
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name              = "NexusESP_Key"
    gui.ResetOnSpawn      = false
    gui.IgnoreGuiInset    = true
    gui.ZIndexBehavior    = Enum.ZIndexBehavior.Global
    gui.DisplayOrder      = 9999
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    -- Overlay
    local overlay = Instance.new("Frame", gui)
    overlay.BackgroundColor3       = Color3.new(0,0,0)
    overlay.BackgroundTransparency = 0.45
    overlay.BorderSizePixel        = 0
    overlay.Size                   = UDim2.fromScale(1,1)

    -- Fenêtre
    local win = Instance.new("Frame", gui)
    win.BackgroundColor3 = C(10,10,16)
    win.BorderSizePixel  = 0
    win.Size             = UDim2.fromOffset(420, 300)
    win.Position         = UDim2.fromScale(0.5, 0.5)
    win.AnchorPoint      = Vector2.new(0.5, 0.5)
    win.ClipsDescendants = true   -- ← FIX trait en haut à droite
    corner(win, UDim.new(0,14))
    stroke(win, C(91,107,248), 1)

    -- Header (sans UICorner propre — win.ClipsDescendants gère)
    local hdr = Instance.new("Frame", win)
    hdr.BackgroundColor3 = C(14,14,22)
    hdr.BorderSizePixel  = 0
    hdr.Size             = UDim2.new(1,0,0,68)

    -- Barre accent gauche
    local acBar = Instance.new("Frame", hdr)
    acBar.BackgroundColor3 = C(91,107,248)
    acBar.BorderSizePixel  = 0
    acBar.Size             = UDim2.fromOffset(3,68)
    corner(acBar, UDim.new(0,2))

    -- Logo image (remplace l'emoji)
    local logoImg = Instance.new("ImageLabel", hdr)
    logoImg.Image                  = "rbxassetid://7733960981"  -- icône shield/orb violet
    logoImg.BackgroundTransparency = 1
    logoImg.Size                   = UDim2.fromOffset(36,36)
    logoImg.Position               = UDim2.new(0,14,0.5,-18)
    logoImg.ImageColor3            = C(91,107,248)

    -- Titre
    local title = Instance.new("TextLabel", hdr)
    title.Text              = "NexusESP"
    title.Font              = Enum.Font.GothamBold
    title.TextSize          = 20
    title.TextColor3        = C(91,107,248)
    title.BackgroundTransparency = 1
    title.Size              = UDim2.new(1,-60,0,28)
    title.Position          = UDim2.fromOffset(56,8)
    title.TextXAlignment    = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", hdr)
    sub.Text             = "Système d'accès sécurisé"
    sub.Font             = Enum.Font.Gotham
    sub.TextSize         = 12
    sub.TextColor3       = C(120,120,160)
    sub.BackgroundTransparency = 1
    sub.Size             = UDim2.new(1,-60,0,18)
    sub.Position         = UDim2.fromOffset(56,34)
    sub.TextXAlignment   = Enum.TextXAlignment.Left

    -- Corps
    local body = Instance.new("Frame", win)
    body.BackgroundTransparency = 1
    body.Size    = UDim2.new(1,-40,0,200)
    body.Position = UDim2.fromOffset(20,76)

    -- Label "Entre ta clé"
    local lbl = Instance.new("TextLabel", body)
    lbl.Text             = "Entre ta clé d'accès"
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextColor3       = C(200,200,220)
    lbl.BackgroundTransparency = 1
    lbl.Size             = UDim2.new(1,0,0,18)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left

    -- Input
    local inputBg = Instance.new("Frame", body)
    inputBg.BackgroundColor3 = C(20,20,30)
    inputBg.BorderSizePixel  = 0
    inputBg.Size             = UDim2.new(1,0,0,40)
    inputBg.Position         = UDim2.fromOffset(0,24)
    corner(inputBg, UDim.new(0,8))
    local is = stroke(inputBg, C(50,50,80), 1)

    local input = Instance.new("TextBox", inputBg)
    input.PlaceholderText        = "XXXX-XXXX-XXXX-XXXX"
    input.PlaceholderColor3      = C(80,80,110)
    input.Text                   = ""
    input.Font                   = Enum.Font.Code
    input.TextSize               = 14
    input.TextColor3             = C(255,255,255)
    input.BackgroundTransparency = 1
    input.Size                   = UDim2.new(1,-20,1,0)
    input.Position               = UDim2.fromOffset(10,0)
    input.ClearTextOnFocus       = false

    -- Focus glow
    input.Focused:Connect(function()
        TweenS:Create(is, TweenInfo.new(0.15), {Color=C(91,107,248)}):Play()
    end)
    input.FocusLost:Connect(function()
        TweenS:Create(is, TweenInfo.new(0.15), {Color=C(50,50,80)}):Play()
    end)

    -- Status
    local status = Instance.new("TextLabel", body)
    status.Text              = ""
    status.Font              = Enum.Font.Gotham
    status.TextSize          = 12
    status.TextColor3        = C(248,113,113)
    status.BackgroundTransparency = 1
    status.Size              = UDim2.new(1,0,0,16)
    status.Position          = UDim2.fromOffset(0,70)
    status.TextXAlignment    = Enum.TextXAlignment.Left

    -- Bouton Valider
    local valBtn = Instance.new("TextButton", body)
    valBtn.BackgroundColor3 = C(91,107,248)
    valBtn.BorderSizePixel  = 0
    valBtn.Size             = UDim2.new(1,0,0,38)
    valBtn.Position         = UDim2.fromOffset(0,92)
    valBtn.Text             = "✓  Valider la clé"
    valBtn.Font             = Enum.Font.GothamBold
    valBtn.TextSize         = 14
    valBtn.TextColor3       = Color3.new(1,1,1)
    valBtn.AutoButtonColor  = false
    corner(valBtn, UDim.new(0,8))

    valBtn.MouseEnter:Connect(function()
        TweenS:Create(valBtn, TweenInfo.new(0.1), {BackgroundColor3=C(110,128,255)}):Play()
    end)
    valBtn.MouseLeave:Connect(function()
        TweenS:Create(valBtn, TweenInfo.new(0.1), {BackgroundColor3=C(91,107,248)}):Play()
    end)

    -- Bouton Get Key
    local getBtn = Instance.new("TextButton", body)
    getBtn.BackgroundTransparency = 1
    getBtn.BorderSizePixel  = 0
    getBtn.Size             = UDim2.new(1,0,0,30)
    getBtn.Position         = UDim2.fromOffset(0,136)
    getBtn.Text             = "🔑  Obtenir une clé gratuite"
    getBtn.Font             = Enum.Font.Gotham
    getBtn.TextSize         = 13
    getBtn.TextColor3       = C(91,107,248)
    getBtn.AutoButtonColor  = false

    -- Discord
    local disc = Instance.new("TextLabel", body)
    disc.Text              = "Discord : discord.gg/nexusesp"
    disc.Font              = Enum.Font.Gotham
    disc.TextSize          = 11
    disc.TextColor3        = C(80,80,110)
    disc.BackgroundTransparency = 1
    disc.Size              = UDim2.new(1,0,0,16)
    disc.Position          = UDim2.fromOffset(0,172)
    disc.TextXAlignment    = Enum.TextXAlignment.Center

    -- ── Logique ───────────────────────────────────────
    local function tryValidate()
        local key = input.Text:gsub("%s","")
        if #key < 5 then
            status.TextColor3 = C(248,113,113)
            status.Text = "✗ Clé trop courte"
            return
        end
        valBtn.Text = "Validation..."
        valBtn.BackgroundColor3 = C(60,70,160)
        status.Text = ""

        validate(key, function(valid, info)
            if valid then
                status.TextColor3 = C(74,222,128)
                status.Text = "✓ Accès autorisé — bienvenue !"
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
        setclipboard(LINKVERTISE_URL)
        status.TextColor3 = C(74,222,128)
        status.Text = "✓ Lien copié ! Ouvre-le dans ton navigateur"
    end)

    -- Animation entrée
    win.Position = UDim2.new(0.5,0,0.6,0)
    TweenS:Create(win,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.fromScale(0.5,0.5)}
    ):Play()
end

function KeySystem.Hide()
    if gui then
        TweenS:Create(gui:FindFirstChild("Frame"),
            TweenInfo.new(0.2),
            {BackgroundTransparency = 1}
        )
        task.delay(0.2, function()
            if gui then gui:Destroy(); gui = nil end
        end)
    end
end

-- ── Validate (appelé par Main.lua) ───────────────────
function KeySystem.Validate()
    -- Dev mode : Firebase absent → bypass automatique
    local Firebase = getgenv().NexusESP and getgenv().NexusESP.Firebase
    if not Firebase then
        print("[KeySystem] Dev mode — bypass ✓")
        return true
    end

    local userId = LP and LP.UserId or 0
    if BYPASS_USERID[userId] then
        print("[KeySystem] Owner bypass ✓")
        return true
    end

    local savedKey = loadKey()
    if savedKey then
        local ok, result = pcall(function()
            return Firebase.ValidateKey(savedKey)
        end)
        if ok and result and result.valid then
            print("[KeySystem] Clé sauvegardée valide ✓")
            return true
        end
    end

    -- Affiche l'écran sans bloquer le chargement
    task.spawn(function()
        KeySystem.Show(function() end)
    end)
    return true
end

return KeySystem
