local Box = {}

function Box.Create(player)
    print("[BOX] Create for:", player.Name)
end

function Box.Update(player)
    print("[BOX] Update for:", player.Name)
end

getgenv().Box = Box
return Box
