local Box = {}

function Box.Create(player)
    print("Box.Create() called for", player.Name)
end

function Box.Update(player)
    print("Box.Update() called for", player.Name)
end

return Box
