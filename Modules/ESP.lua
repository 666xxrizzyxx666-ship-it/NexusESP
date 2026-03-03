local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESP = getgenv().ESP or {
    Enabled = false,
    Color = Color3.fromRGB(255, 0, 0),
    Boxes = {},

    HealthBar = false,
    HealthColor = Color3.fromRGB(0, 255, 0),
    HealthPosition = "Left",
    HealthBars = {}
}

function ESP:UpdateAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then

            -- BOX
            if self.Enabled then
                if not self.Boxes[player] then
                    require(script.Parent.Box).Create(player)
                end
                require(script.Parent.Box).Update(player)
            else
                if self.Boxes[player] then
                    self.Boxes[player].Visible = false
                end
            end

            -- HEALTH
            if self.HealthBar then
                if not self.HealthBars[player] then
                    require(script.Parent.Health).Create(player)
                end
                require(script.Parent.Health).Update(player)
            else
                local hb = self.HealthBars[player]
                if hb then
                    hb.bg.Visible = false
                    hb.bar.Visible = false
                end
            end
        end
    end
end

getgenv().ESP = ESP
return ESP
