local ESP = {}

ESP.Enabled = false
ESP.Boxes = {}

function ESP:UpdateAll()
    if not self.Enabled then return end

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then

            if not self.Boxes[player] then
                getgenv().Box.Create(player)
                self.Boxes[player] = true
            end

            getgenv().Box.Update(player)
        end
    end
end

return ESP
