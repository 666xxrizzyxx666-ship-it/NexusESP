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

            if self.Enabled then
                if not self.Boxes[player] then
                    getgenv().Box.Create(player)
                end
                getgenv().Box.Update(player)
            else
                if self.Boxes[player] then
                    self.Boxes[player].Visible = false
                end
            end

            if self.HealthBar then
                if not self.HealthBars[player] then
                    getgenv().Health.Create(player)
                end
                getgenv().Health.Update(player)
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
