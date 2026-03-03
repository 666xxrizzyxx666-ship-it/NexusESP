--========================================================--
--  BOX MODULE — VERSION STABLE
--========================================================--

function CreateBox(player)
    if ESP.Boxes[player] then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = ESP.BoxColor
    box.Visible = false

    ESP.Boxes[player] = { Box = box }
end

function UpdateBox(player, char)
    local data = ESP.Boxes[player]
    if not data then
        CreateBox(player)
        data = ESP.Boxes[player]
    end

    local box = data.Box

    if not ESP.Box then
        box.Visible = false
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")

    if not hrp or not hum then
        box.Visible = false
        return
    end

    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        box.Visible = false
        return
    end

    -- Taille dynamique basée sur la distance
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    local scale = math.clamp(2000 / distance, 20, 300)

    box.Size = Vector2.new(scale * 0.6, scale)
    box.Position = Vector2.new(pos.X - box.Size.X / 2, pos.Y - box.Size.Y / 2)
    box.Color = ESP.BoxColor
    box.Visible = true
end
