---------------------------------------------------------------------------
--- Cava desktop widget
--
-- @module cosy.widget.desktop
---------------------------------------------------------------------------

local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")
local posix = require("posix")
local global = require("global")

-- Constant, depends on cava configuration
local cava_max = 1000

local cava = {}
cava.mt = {}

_G.cava_global_val = {}

cava.defaults = {
    position = "left", -- TODO
    size = global.panel_size,
    zero_size = 2,
    x = 0,
    y = 0,
    update_time = 0.05,
}

local function round(x) return x + 0.5 - (x + 0.5) % 1 end

-- Throws exception
local function parse_fifo()
    local cava_fifo = assert(posix.open("/tmp/cava", posix.O_RDONLY + posix.O_NONBLOCK), "Could not open /tmp/cava")
    -- Buffer has to be big enough to read all accumulated output asap. This will prevent slow updating cava
    -- from displaying outdated values
    local bufsize = 4096
    local cava_string = posix.read(cava_fifo, bufsize)
    posix.close(cava_fifo)

    local cava_val = {}
    for match in cava_string:match("[^\n]+"):gmatch("[^;]+") do
        table.insert(cava_val, match)
    end

    -- Assert prevents blinking. Sometimes because of simultaneous access to fifo incomplete string may be received.
    -- This way it may freeze a little sometimes, but it won't blink
    assert(#cava_val == 50, "Expected length of the table is 50. Actual result: " .. tostring(#cava_val))

    return cava_val
end

local function update_global_val()
    local parse_success, parse_result = pcall(parse_fifo)

    -- Do not return in case of failure. Value can be updated by other widget
    if parse_success then
        _G.cava_global_val = parse_result
    end
end

function cava.new(s, properties)
    local properties = gears.table.crush(cava.defaults, properties or {})

    local cava_widget = wibox.widget.base.make_widget()
    cava_widget.size = properties.size
    cava_widget.zero_size = properties.zero_size
    cava_widget.val = {}
    for i = 1, 50 do
        cava_widget.val[i] = 0
    end

    function cava_widget:fit(context, width, height) return width, height end

    function cava_widget:draw(context, cr, width, height)
        cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
        cr:set_line_width(0)

        for i = 1, #self.val do
            local rect = {}
            rect.w = self.val[i] + self.zero_size
            rect.h = (height - 10) / 50 - 5
            rect.x = 0
            rect.y = (i - 1) * (rect.h + 5) + 5

            cr:rectangle(rect.x, rect.y, rect.w, rect.h)
            cr:fill_preserve()
            cr:stroke()
        end
    end

    function cava_widget:update_val()
        update_global_val()

        local cava_val = _G.cava_global_val

        assert(#cava_val == 50, "Global cava buffer has wrong amount of values")

        -- Adjust values to fit into the desired size
        for i = 1, 50 do
            self.val[i] = round(cava_val[i] * (self.size - self.zero_size) / cava_max)
        end

        self:emit_signal("widget::updated")
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
        width = properties.size,
        height = s.geometry.height,
    })

    cava_box:set_widget(cava_widget)

    cava_widget:emit_signal("widget::updated")
    cava_widget.timer = gears.timer.start_new(
        properties.update_time,
        function()
            pcall(cava_widget.update_val, cava_widget)
            return true -- Ignore errors
        end)

    return cava_box
end

function cava.mt:__call(...)
    return cava.new(...)
end

return setmetatable(cava, cava.mt)
