local Camera = workspace.CurrentCamera
local ESP = require(script.Parent.ESP)

local Health = {}

function Health.Create(player)
    local bg = Drawing.new("Square")
    bg.Filled = true
    bg.Color = Color3.fromRGB(40, 40, 40)
    bg.Visible = false

    local bar = Drawing.new("Square")
    bar.Filled = true
    bar.Color = ESP.HealthColor
    bar.Visible = false

    ESP.HealthBars[player] = {bg = bg, bar = bar}
end

function Health.Update(player)
    local hb = ESP.HealthBars[player]
    if not hb then return end

    local box = ESP.Boxes[player]
    if not box or not box.Visible then
        hb.bg.Visible = false
        hb.bar.Visible = false
        return
    end

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local health = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

    local pos = box.Position
    local size = box.Size

    if ESP.HealthPosition == "Left" then
        hb.bg.Position = Vector2.new(pos.X - 6, pos.Y)
        hb.bg.Size = Vector2.new(4, size.Y)

        hb.bar.Position = Vector2.new(pos.X - 6, pos.Y + size.Y * (1 - health))
        hb.bar.Size = Vector2.new(4, size.Y * health)

    elseif ESP.HealthPosition == "Right" then
        hb.bg.Position = Vector2.new(pos.X + size.X + 2, pos.Y)
        hb.bg.Size = Vector2.new(4, size.Y)

        hb.bar.Position = Vector2.new(pos.X + size.X + 2, pos.Y + size.Y * (1 - health))
        hb.bar.Size = Vector2.new(4, size.Y * health)
    end

    hb.bg.Visible = true
    hb.bar.Visible = true
    hb.bar.Color = ESP.HealthColor
end

return Health
