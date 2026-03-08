-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — UI/Theme.lua
--   📁 Dossier : UI/
--   Rôle : Couleurs, fonts, tailles — tout centralisé
-- ══════════════════════════════════════════════════════

local Theme = {}

local function C(r,g,b,a)
    local c = Color3.fromRGB(r,g,b)
    if a then return {Color=c, Alpha=a} end
    return c
end

-- ── Palette principale ────────────────────────────────
Theme.Colors = {
    -- Fonds
    Background   = C(8,   8,  12),   -- fond principal
    Surface      = C(12,  12, 18),   -- cartes / groupes
    SurfaceHover = C(16,  16, 24),   -- hover sur surface
    SurfaceAlt   = C(20,  20, 30),   -- inputs, items

    -- Bordures
    Border       = C(30,  30, 50),
    BorderHover  = C(60,  60, 90),
    BorderActive = C(91, 107,248),

    -- Accent violet/bleu électrique
    Accent       = C(91, 107,248),
    AccentHover  = C(110,125,255),
    AccentPress  = C(70,  85,220),
    AccentDark   = C(30,  35, 90),
    AccentGlow   = C(91, 107,248),

    -- Texte
    Text         = C(220,220,235),
    TextSub      = C(100,100,125),
    TextMuted    = C(55,  55, 75),
    TextOnAccent = C(255,255,255),

    -- États
    Success      = C(74, 222,128),
    SuccessDark  = C(20,  83, 45),
    Warning      = C(251,191, 36),
    WarningDark  = C(92,  70,  0),
    Danger       = C(248,113,113),
    DangerDark   = C(127, 29, 29),
    Info         = C(56, 189,248),

    -- Health bar
    HealthHigh   = C(74, 222,128),
    HealthMid    = C(251,191, 36),
    HealthLow    = C(248,113,113),

    -- Transparent
    Overlay      = C(0,0,0),       -- utiliser avec alpha
    White        = C(255,255,255),
    Black        = C(0,  0,  0),
}

-- ── Transparences ─────────────────────────────────────
Theme.Alpha = {
    Overlay     = 0.5,
    Surface     = 0.0,
    SurfaceAlt  = 0.0,
    Hover       = 0.1,
    Disabled    = 0.5,
    Scrollbar   = 0.7,
}

-- ── Fonts ─────────────────────────────────────────────
Theme.Fonts = {
    Bold     = Enum.Font.GothamBold,
    Medium   = Enum.Font.GothamMedium,
    Regular  = Enum.Font.Gotham,
    Mono     = Enum.Font.RobotoMono,
}

-- ── Tailles de texte ──────────────────────────────────
Theme.TextSize = {
    Title    = 16,
    Subtitle = 13,
    Body     = 12,
    Small    = 11,
    Tiny     = 10,
    Logo     = 20,
}

-- ── Rayons de coins ───────────────────────────────────
Theme.Radius = {
    Window  = UDim.new(0, 12),
    Card    = UDim.new(0, 10),
    Input   = UDim.new(0, 8),
    Button  = UDim.new(0, 8),
    Toggle  = UDim.new(1, 0),
    Tag     = UDim.new(0, 4),
    Small   = UDim.new(0, 6),
}

-- ── Padding ───────────────────────────────────────────
Theme.Padding = {
    Window  = 12,
    Card    = 10,
    Item    = 8,
    Small   = 6,
}

-- ── Tailles de bordure ────────────────────────────────
Theme.Stroke = {
    Window  = 1,
    Card    = 1,
    Input   = 1,
    Focus   = 1.5,
}

-- ── Animations ────────────────────────────────────────
Theme.Anim = {
    Fast    = 0.12,
    Normal  = 0.20,
    Slow    = 0.35,
    Spring  = TweenInfo.new(0.20, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    Smooth  = TweenInfo.new(0.18, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out),
    Linear  = TweenInfo.new(0.12, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    Bounce  = TweenInfo.new(0.30, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
}

-- ── Tailles UI ────────────────────────────────────────
Theme.Size = {
    SidebarWidth  = 46,
    WindowWidth   = 650,
    WindowHeight  = 480,
    HeaderHeight  = 50,
    TabBarHeight  = 38,
    ItemHeight    = 34,
    ToggleWidth   = 36,
    ToggleHeight  = 20,
    SliderHeight  = 4,
    SliderKnob    = 14,
    CardPadding   = 10,
}

-- ── Fonction utilitaire : applique un thème custom ────
function Theme.Apply(custom)
    if not custom then return end
    if custom.Accent then
        local c = custom.Accent
        Theme.Colors.Accent      = Color3.fromRGB(c.R, c.G, c.B)
        Theme.Colors.AccentHover = Color3.fromRGB(
            math.min(c.R+20,255),
            math.min(c.G+20,255),
            math.min(c.B+20,255)
        )
        Theme.Colors.AccentDark  = Color3.fromRGB(
            math.floor(c.R*0.3),
            math.floor(c.G*0.3),
            math.floor(c.B*0.3)
        )
    end
end

return Theme
