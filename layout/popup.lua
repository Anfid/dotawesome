---------------------------------------------------------------------------
--- Popup layout
--
-- @module layout.popup
-- @alias popup
---------------------------------------------------------------------------

local popup = {}

--- Popup layout.
popup.name = "popup"

function popup.arrange(p)
    -- Fullscreen?
    local area
    if fs then
        area = p.geometry
    else
        area = p.workarea
    end

    for _, c in pairs(p.clients) do
        local g = {
            x = area.x,
            y = area.y,
            width = area.width,
            height = area.height
        }
        p.geometries[c] = g
    end
end

return popup
