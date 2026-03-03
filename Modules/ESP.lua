local ESP = {}

ESP.Enabled = false
ESP.Boxes = {}

function ESP:HideAll()
    for player, box in pairs(self.Boxes) do
        if typeof(box) == "Drawing" then
            box.Visible = false
        end
    end
end

function ESP:UpdateAll()
    if not self.Enabled then
        self:HideAll()
        return
    end

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then

            if not self.Boxes[player] then
                getgenv().Box.Create(player)
            end

            getgenv().Box.Update(player)
        end
    end
end

getgenv().ESP = ESP
return ESP
