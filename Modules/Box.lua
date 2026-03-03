--========================================================--
--  BOX MODULE (LINORIA VERSION)
--========================================================--

function CreateBox(player)
    if ESP.Boxes[player] then return end

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
    if not ESP.Box then return end

    local data = ESP.Boxes[player]
    if not data then
        CreateBox(player)
        data = ESP.Boxes[player]
    end

    local box = data.Main
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        box.Visible = false
        return
    end

    -- Camera globale définie dans Main.lua
    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        box.Visible = false
        return
    end

    local size = Vector2.new(60, 80)
    box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
    box.Size = size
    box.Color = ESP.BoxColor
    box.Visible = true
end
