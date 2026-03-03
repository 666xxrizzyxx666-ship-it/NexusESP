local Camera = workspace.CurrentCamera
local Box = {}

function Box.Create(player)
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Visible = false

    getgenv().ESP.Boxes[player] = box
end

function Box.Update(player)
    local box = getgenv().ESP.Boxes[player]
    if typeof(box) ~= "Drawing" then return end

    local char = player.Character
    if not char then
        box.Visible = false
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        box.Visible = false
        return
    end

    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        box.Visible = false
        return
    end

    box.Position = Vector2.new(pos.X - 25, pos.Y - 25)
    box.Size = Vector2.new(50, 50)
    box.Visible = true
end

getgenv().Box = Box
return Box
