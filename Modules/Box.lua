local Camera = workspace.CurrentCamera
local ESP = require(script.Parent.ESP)

local Box = {}

function Box.Create(player)
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = ESP.Color
    box.Visible = false

    ESP.Boxes[player] = box
end

function Box.Update(player)
    local box = ESP.Boxes[player]
    if not box then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then box.Visible = false return end

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local size = part.Size / 2
            local corners = {
                part.Position + Vector3.new(-size.X, -size.Y, -size.Z),
                part.Position + Vector3.new(size.X, -size.Y, -size.Z),
                part.Position + Vector3.new(-size.X, size.Y, -size.Z),
                part.Position + Vector3.new(size.X, size.Y, -size.Z),
                part.Position + Vector3.new(-size.X, -size.Y, size.Z),
                part.Position + Vector3.new(size.X, -size.Y, size.Z),
                part.Position + Vector3.new(-size.X, size.Y, size.Z),
                part.Position + Vector3.new(size.X, size.Y, size.Z),
            }

            for _, corner in ipairs(corners) do
                local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
                if onScreen then
                    minX = math.min(minX, screenPos.X)
                    minY = math.min(minY, screenPos.Y)
                    maxX = math.max(maxX, screenPos.X)
                    maxY = math.max(maxY, screenPos.Y)
                end
            end
        end
    end

    if minX < maxX and minY < maxY then
        box.Position = Vector2.new(minX - 4, minY - 4)
        box.Size = Vector2.new((maxX - minX) + 8, (maxY - minY) + 8)
        box.Color = ESP.Color
        box.Visible = true
    else
        box.Visible = false
    end
end

return Box
