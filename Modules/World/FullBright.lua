local FullBright = {}
local Lighting = game:GetService("Lighting")
local enabled  = false
local original = {}
local disabledEffects = {}

function FullBright.Init(deps) end

function FullBright.Enable()
    if enabled then return end
    enabled = true
    original = {
        Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
        FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart,
        GlobalShadows=Lighting.GlobalShadows,
        Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
    }
    disabledEffects = {}
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect")
        or e:IsA("SunRaysEffect") or e:IsA("BloomEffect") then
            if e.Enabled then
                disabledEffects[e] = true
                e.Enabled = false
            end
        end
    end
    Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=100000
    Lighting.FogStart=0; Lighting.GlobalShadows=false
    Lighting.Ambient=Color3.fromRGB(178,178,178)
    Lighting.OutdoorAmbient=Color3.fromRGB(178,178,178)
end

function FullBright.Disable()
    if not enabled then return end
    enabled = false
    for k, v in pairs(original) do pcall(function() Lighting[k]=v end) end
    -- Restore only effects we disabled
    for e, _ in pairs(disabledEffects) do
        pcall(function() if e and e.Parent then e.Enabled=true end end)
    end
    disabledEffects = {}
end

function FullBright.Toggle()
    if enabled then FullBright.Disable() else FullBright.Enable() end
end
function FullBright.IsEnabled() return enabled end
return FullBright
