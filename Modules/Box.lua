-- Modules/Box.lua

function CreateBox(player)
    if player == game.Players.LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = ESP.BoxColor
    box.Visible = false

    ESP.Boxes[player] = {
        Main = box
    }
end

function UpdateBox(player, char)
    local data = ESP.Boxes[player]
    if not data then
        CreateBox(player)
        data = ESP.Boxes[player]
    end

    local box = data.Main

    if not ESP.Box then
        box.Visible = false
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        box.Visible = false
        return
    end

    local Camera = workspace.CurrentCamera
    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        box.Visible = false
        return
    end

    local size = Vector2.new(60, 80)
    box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
    box.Size = size
    box.Visible = true
end
