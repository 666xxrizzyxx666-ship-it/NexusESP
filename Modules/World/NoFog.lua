local NoFog = {}
local Lighting = game:GetService("Lighting")
local enabled = false
local original = {}

function NoFog.Init(deps) end

function NoFog.Enable()
    if enabled then return end
    enabled = true
    original = {FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart}
    Lighting.FogEnd   = 100000
    Lighting.FogStart = 99999
end

function NoFog.Disable()
    if not enabled then return end
    enabled = false
    Lighting.FogEnd   = original.FogEnd   or 100000
    Lighting.FogStart = original.FogStart or 0
end

function NoFog.Toggle()
    if enabled then NoFog.Disable() else NoFog.Enable() end
end
function NoFog.IsEnabled() return enabled end
return NoFog
