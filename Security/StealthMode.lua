-- ══════════════════════════════════════════════════════
--   NexusESP v3.0.0 — Security/StealthMode.lua
--   📁 Dossier : Security/
--   Rôle : Mode furtif — masque les traces d'utilisation
--          Anti-screenshot + Anti-détection
-- ══════════════════════════════════════════════════════

local StealthMode = {}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local enabled     = false
local adminNearby = false

-- ── Anti screenshot ───────────────────────────────────
local function hookScreenshot()
    -- Détecte les captures d'écran via CoreGui
    pcall(function()
        local cg = game:GetService("CoreGui")
        cg.ScreenshotHud:GetPropertyChangedSignal("Visible"):Connect(function()
            if cg.ScreenshotHud.Visible and enabled then
                -- Cache l'UI brièvement
                task.spawn(function()
                    local nexusGui = cg:FindFirstChild("NexusESP_Main")
                    if nexusGui then
                        nexusGui.Enabled = false
                        task.wait(0.5)
                        nexusGui.Enabled = true
                    end
                end)
            end
        end)
    end)
end

-- ── Comportement naturel ─────────────────────────────
local idleTimer   = 0
local idleActions = {
    function()
        -- Regarde autour aléatoirement
        local cam = workspace.CurrentCamera
        local rx  = (math.random() - 0.5) * 0.3
        local ry  = (math.random() - 0.5) * 0.3
        cam.CFrame = cam.CFrame * CFrame.Angles(rx, ry, 0)
    end,
    function()
        -- Jump aléatoire
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end,
    function()
        -- Chat message aléatoire (optionnel)
        -- game:GetService("Chat"):Chat(LP.Character and LP.Character:FindFirstChild("Head"), "gg")
    end,
}

-- ── Détecte la présence d'admins ─────────────────────
local AdminDetector = nil

local function checkAdminProximity()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    if not AdminDetector then return false end
    local detected = AdminDetector.GetDetected()

    for userId, name in pairs(detected) do
        local admin = Players:GetPlayerByUserId(userId)
        if admin and admin.Character then
            local ar = admin.Character:FindFirstChild("HumanoidRootPart")
            if ar and (root.Position - ar.Position).Magnitude < 100 then
                return true
            end
        end
    end
    return false
end

-- ── Loop stealth ──────────────────────────────────────
local conn = nil

function StealthMode.Enable()
    if enabled then return end
    enabled = true

    hookScreenshot()

    conn = RunService.Heartbeat:Connect(function(dt)
        if not enabled then return end

        -- Vérifie admin toutes les 5s
        idleTimer = idleTimer + dt
        if idleTimer >= 5 then
            idleTimer  = 0
            adminNearby = checkAdminProximity()

            if adminNearby then
                print("[StealthMode] ⚠ Admin proche — réduction activité")
                -- Notifie le PanicKey
                local nexus = getgenv().NexusESP
                if nexus and nexus.PanicKey then
                    nexus.PanicKey.Panic()
                end
            end
        end
    end)

    print("[StealthMode] Activé ✓")
end

function StealthMode.Disable()
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
    print("[StealthMode] Désactivé")
end

function StealthMode.Init(deps)
    AdminDetector = deps.AdminDetector
    print("[StealthMode] Initialisé ✓")
end

function StealthMode.IsAdminNearby() return adminNearby end
function StealthMode.IsEnabled()     return enabled end
function StealthMode.Toggle()
    if enabled then StealthMode.Disable() else StealthMode.Enable() end
end

return StealthMode
