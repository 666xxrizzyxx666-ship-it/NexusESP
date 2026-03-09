local Distance = {}
local function T() local t=Drawing.new("Text") t.Visible=false t.Outline=true t.Center=true t.Font=Drawing.Fonts.Plex t.Size=11 return t end
function Distance.Create() return {text=T()} end
function Distance.Update(d, bb, dist)
    if not d or not bb then return end
    d.text.Text     = dist.."m"
    d.text.Color    = Color3.fromRGB(180,180,180)
    d.text.Position = Vector2.new(bb.cx, bb.y + bb.height + 3)
    d.text.Visible  = true
end
function Distance.Hide(d) if d and d.text then d.text.Visible=false end end
function Distance.Remove(d) if d and d.text then pcall(function() d.text:Remove() end) end end
return Distance
