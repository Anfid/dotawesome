---------------------------------------------------------------------------
--- Cava desktop widget
--
-- @module cosy.widget.desktop
---------------------------------------------------------------------------

local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")
local posix = require("posix")

local cava = {}
cava.mt = {}

cava_global_val = {}

cava.defaults = {
    position = "left", -- TODO
    x = 0,
    y = 0,
    update_time = 0.05,
}

function cava.new(s, properties)
    local properties = gears.table.crush(cava.defaults, properties or {})

    local cava_widget = wibox.widget.base.make_widget()
    cava_widget.val = {}

    function cava_widget:fit(context, width, height) return width, height end

    function cava_widget:draw(context, cr, width, height)
        cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
        cr:set_line_width(0)

        for i = 1, #self.val do
            --settings
            local rec_width  = self.val[i] + 2
            local rec_height = (height - 10) / 50 - 5
            local top_left_x = 0
            local top_left_y = (i - 1) * (rec_height + 5) + 5
            --draw it
            cr:rectangle(top_left_x,top_left_y,rec_width,rec_height)
            cr:fill_preserve()
            cr:stroke()
        end
    end

    function cava_widget:update_val()
        local cava_fifo = posix.open("/tmp/cava", posix.O_RDONLY + posix.O_NONBLOCK)
        if cava_fifo then
            local cava_string = posix.read(cava_fifo, 4096)
            posix.close(cava_fifo)
            if cava_string then
                local cava_val = {}
                for match in cava_string:gmatch("[^;]+") do
                    table.insert(cava_val, match)
                end
                cava_global_val = cava_val
            end
        end

        if #cava_global_val ~= 0 then
            self.val = cava_global_val
            self:emit_signal("widget::updated")
        else
            self:emit_signal("widget::updated")
        end

        return true
    end

    local cava_box = wibox({
        screen = s,
        type = "desktop",
        visible = true,
        bg = "#00000000",
    })

    cava_box:geometry({
        x = s.geometry.x + properties.x,
        y = s.geometry.y + properties.y,
        width = 45,
        height = s.geometry.height,
    })

    cava_box:set_widget(cava_widget)

    cava_box.timer = gears.timer.start_new(properties.update_time, function() return cava_widget:update_val() end)

    return cava_box
end

function cava.mt:__call(...)
    return cava.new(...)
end

return setmetatable(cava, cava.mt)
