local Name = {}
local function T() local t=Drawing.new("Text") t.Visible=false t.Outline=true t.Center=true t.Font=Drawing.Fonts.Plex t.Size=13 return t end
function Name.Create() return {text=T()} end
function Name.Update(d, bb, name, col)
    if not d or not bb then return end
    d.text.Text     = name
    d.text.Color    = col or Color3.new(1,1,1)
    d.text.Position = Vector2.new(bb.cx, bb.y - 16)
    d.text.Visible  = true
end
function Name.Hide(d) if d and d.text then d.text.Visible=false end end
function Name.Remove(d) if d and d.text then pcall(function() d.text:Remove() end) end end
return Name
