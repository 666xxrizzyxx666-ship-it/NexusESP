-- Aurora — Tracers.lua v3.1 — Lines uniquement (pas de Circle)
local Tracers = {}
local Camera = workspace.CurrentCamera

local function L()
    local l = Drawing.new("Line")
    l.Visible=false l.ZIndex=1 l.Outline=false
    return l
end

function Tracers.Create()
    -- 4 lignes : principale + 2 pour flèche + 1 pour point (petit trait)
    return { main=L(), a1=L(), a2=L(), dot1=L(), dot2=L() }
end

function Tracers.Update(d, bb, col, style)
    if not d or not bb then return end
    local vp = Camera.ViewportSize
    local fx, fy = vp.X/2, vp.Y
    local tx, ty = bb.cx, bb.y + bb.height
    local c = col or Color3.new(1,1,1)
    style = style or "Ligne"

    -- Reset tout
    d.main.Visible=false d.a1.Visible=false
    d.a2.Visible=false d.dot1.Visible=false d.dot2.Visible=false

    if style == "Ligne" then
        d.main.From=Vector2.new(fx,fy) d.main.To=Vector2.new(tx,ty)
        d.main.Color=c d.main.Thickness=1 d.main.Visible=true

    elseif style == "Flèche" then
        d.main.From=Vector2.new(fx,fy) d.main.To=Vector2.new(tx,ty)
        d.main.Color=c d.main.Thickness=1 d.main.Visible=true

        local dx, dy = tx-fx, ty-fy
        local len = math.sqrt(dx*dx + dy*dy)
        if len > 20 then
            local ux, uy = dx/len, dy/len
            -- perpendiculaire
            local px, py = -uy, ux
            local as = 12 -- taille flèche
            -- côté gauche
            d.a1.From=Vector2.new(tx, ty)
            d.a1.To=Vector2.new(tx - ux*as + px*(as*0.5), ty - uy*as + py*(as*0.5))
            d.a1.Color=c d.a1.Thickness=1 d.a1.Visible=true
            -- côté droit
            d.a2.From=Vector2.new(tx, ty)
            d.a2.To=Vector2.new(tx - ux*as - px*(as*0.5), ty - uy*as - py*(as*0.5))
            d.a2.Color=c d.a2.Thickness=1 d.a2.Visible=true
        end

    elseif style == "Point" then
        -- Ligne en pointillés simulés : 3 segments avec gaps
        local dx, dy = tx-fx, ty-fy
        local len = math.sqrt(dx*dx+dy*dy)
        if len > 0 then
            local ux, uy = dx/len, dy/len
            -- Segment 1 : 0% → 40%
            d.main.From=Vector2.new(fx, fy)
            d.main.To=Vector2.new(fx+ux*len*0.4, fy+uy*len*0.4)
            d.main.Color=c d.main.Thickness=1 d.main.Visible=true
            -- Segment 2 : 55% → 80%
            d.a1.From=Vector2.new(fx+ux*len*0.55, fy+uy*len*0.55)
            d.a1.To=Vector2.new(fx+ux*len*0.80, fy+uy*len*0.80)
            d.a1.Color=c d.a1.Thickness=1 d.a1.Visible=true
            -- Segment 3 : 88% → 100%
            d.a2.From=Vector2.new(fx+ux*len*0.88, fy+uy*len*0.88)
            d.a2.To=Vector2.new(tx, ty)
            d.a2.Color=c d.a2.Thickness=1 d.a2.Visible=true
            -- Croix au bout (point)
            d.dot1.From=Vector2.new(tx-4, ty-4) d.dot1.To=Vector2.new(tx+4, ty+4)
            d.dot1.Color=c d.dot1.Thickness=2 d.dot1.Visible=true
            d.dot2.From=Vector2.new(tx+4, ty-4) d.dot2.To=Vector2.new(tx-4, ty+4)
            d.dot2.Color=c d.dot2.Thickness=2 d.dot2.Visible=true
        end
    end
end

function Tracers.Hide(d)
    if not d then return end
    d.main.Visible=false d.a1.Visible=false
    d.a2.Visible=false d.dot1.Visible=false d.dot2.Visible=false
end

function Tracers.Remove(d)
    if not d then return end
    for _, l in pairs(d) do pcall(function() l:Remove() end) end
end

return Tracers
