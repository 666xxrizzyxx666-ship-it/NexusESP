local Health = {}
local function L() local l=Drawing.new("Line") l.Visible=false l.ZIndex=2 l.Outline=false return l end
local function getCol(pct)
    if pct>0.6 then return Color3.fromRGB(74,222,128)
    elseif pct>0.3 then return Color3.fromRGB(251,191,36)
    else return Color3.fromRGB(248,113,113) end
end
function Health.Create() return {bg=L(), bar=L()} end
function Health.Update(d, bb, hp, maxHp, pos)
    if not d or not bb then return end
    local pct = maxHp>0 and math.clamp(hp/maxHp,0,1) or 0
    local col = getCol(pct)
    local x,y,w,h = bb.x, bb.y, bb.width, bb.height
    local off = 4

    if pos == "Gauche" or pos == "Left" then
        d.bg.From=Vector2.new(x-off, y)        d.bg.To=Vector2.new(x-off, y+h)
        d.bar.From=Vector2.new(x-off, y+h)     d.bar.To=Vector2.new(x-off, y+h-(h*pct))
    elseif pos == "Droite" or pos == "Right" then
        d.bg.From=Vector2.new(x+w+off, y)      d.bg.To=Vector2.new(x+w+off, y+h)
        d.bar.From=Vector2.new(x+w+off, y+h)   d.bar.To=Vector2.new(x+w+off, y+h-(h*pct))
    elseif pos == "Dessous" then
        d.bg.From=Vector2.new(x, y+h+off)      d.bg.To=Vector2.new(x+w, y+h+off)
        d.bar.From=Vector2.new(x, y+h+off)     d.bar.To=Vector2.new(x+(w*pct), y+h+off)
    else -- Dessus
        d.bg.From=Vector2.new(x, y-off)        d.bg.To=Vector2.new(x+w, y-off)
        d.bar.From=Vector2.new(x, y-off)       d.bar.To=Vector2.new(x+(w*pct), y-off)
    end

    d.bg.Color=Color3.fromRGB(20,20,20)  d.bg.Thickness=3   d.bg.Visible=true
    d.bar.Color=col                       d.bar.Thickness=3  d.bar.Visible=true
end
function Health.Hide(d) if not d then return end d.bg.Visible=false d.bar.Visible=false end
function Health.Remove(d) if not d then return end pcall(function() d.bg:Remove() end) pcall(function() d.bar:Remove() end) end
return Health
