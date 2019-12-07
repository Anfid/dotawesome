---------------------------------------------------------------------------
--- Cava desktop widget
--
-- @module cosy.widget.desktop
---------------------------------------------------------------------------

local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")
local posix = require("posix")

local round = require("cosy.util").math.round

local tostring = tostring

-- Constants, depend on cava configuration
local cava_max = 1000
local cava_bars = 50

local cava = {}
cava.mt = {}

_G.cava_global_val = {}

cava.defaults = {
    position = "top",
    size = 45,
    zero_size = 2,
    spacing = 5,
    update_time = 0.04,
}

-- Throws exception
local function parse_fifo()
    local cava_fifo = assert(posix.open("/tmp/cava", posix.O_RDONLY + posix.O_NONBLOCK), "Could not open /tmp/cava")
    -- Buffer has to be big enough to read all accumulated output asap. This will prevent slow updating cava
    -- from displaying outdated values
    local bufsize = 4096
    local cava_string = posix.read(cava_fifo, bufsize)
    posix.close(cava_fifo)

    local cava_val = {}
    for match in cava_string:match("[%d;]+\n$"):gmatch("(%d+);") do
        table.insert(cava_val, match)
    end

    -- Assert prevents blinking. Sometimes because of simultaneous access to fifo incomplete string may be received.
    -- This way it may freeze a little sometimes, but it won't blink
    assert(#cava_val == cava_bars, "Expected length of the table is 50. Actual result: " .. tostring(#cava_val))

    return cava_val
end

local function update_global_val()
    local success, result = pcall(parse_fifo)

    if success then
        _G.cava_global_val = result
    end
end

local function draw_top(cava_widget, context, cr, width, height)
    local w = width / cava_bars - cava_widget.spacing  -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(pos, 0  )
        cr:line_to(pos, val)
    end

    cr:stroke()
end

local function draw_left(cava_widget, context, cr, width, height)
    local w = height / cava_bars - cava_widget.spacing -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(0,   pos)
        cr:line_to(val, pos)
    end

    cr:stroke()
end

local function draw_bottom(cava_widget, context, cr, width, height)
    local w = width / cava_bars - cava_widget.spacing  -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(pos, height      )
        cr:line_to(pos, height - val)
    end

    cr:stroke()
end

local function draw_right(cava_widget, context, cr, width, height)
    local w = height / cava_bars - cava_widget.spacing -- block width
    local d = w + cava_widget.spacing           -- block distance

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(w)

    for i = 1, #cava_widget.val do
        local val = cava_widget.val[i] + cava_widget.zero_size
        local pos = d * i - d / 2

        cr:move_to(width,       pos)
        cr:line_to(width - val, pos)
    end

    cr:stroke()
end

-- TODO: Document properties
-- update_time - how often widget is redrawn. For single widget 0.05 works best. However, if more than one widget is
-- used, it is better to set to 0.01. Widgets sometimes interrupt each other's reading of fifo and faster redraw rate
-- compensates lag frames
function cava.new(s, properties)
    local properties = gears.table.join(cava.defaults, properties or {})
    local cava_widget = gears.table.join(properties, wibox.widget.base.make_widget())
    cava_widget.val = {}

    -- Assigning draw function prevents multiple string comparison in performance critical code
    if     cava_widget.position == "top" then
        cava_widget.draw = draw_top
        properties.w = s.geometry.width
        properties.h = properties.size
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = 0 end
    elseif cava_widget.position == "left" then
        cava_widget.draw = draw_left
        properties.w = properties.size
        properties.h = s.geometry.height
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = 0 end
    elseif cava_widget.position == "bottom" then
        cava_widget.draw = draw_bottom
        properties.w = s.geometry.width
        properties.h = properties.size
        if not properties.x then properties.x = 0 end
        if not properties.y then properties.y = s.geometry.height - properties.size end
    elseif cava_widget.position == "right" then
        cava_widget.draw = draw_right
        properties.w = properties.size
        properties.h = s.geometry.height
        if not properties.x then properties.x = s.geometry.width - properties.size end
        if not properties.y then properties.y = 0 end
    else
        error("Wrong cava widget position")
    end

    for i = 1, cava_bars do
        cava_widget.val[i] = 0
    end

    function cava_widget:fit(context, width, height) return width, height end

    function cava_widget:update_val()
        update_global_val()

        local cava_val = _G.cava_global_val

        assert(#cava_val == cava_bars, "Global cava buffer has wrong amount of values")

        -- Adjust values to fit into the desired size
        local cava_val_fit = {}
        local cava_changed = false
        for i = 1, #cava_val do
            cava_val_fit[i] = round(cava_val[i] * (self.size - self.zero_size) / cava_max)
            if self.val[i] ~= cava_val_fit[i] then
                cava_changed = true
            end
        end

        -- Prevent unnecessary redraw
        if cava_changed then
            self.val = cava_val_fit
            self:emit_signal("widget::updated")
        end
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
        width  = properties.w,
        height = properties.h,
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
