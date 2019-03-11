---------------------------------------------------------------------------
--- Volume panel widget
--
-- @module cosy.widget.panel
---------------------------------------------------------------------------

local awesome = _G.awesome
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local dbg = require("dbg")

local get_volume_cmd = "\\\
    SINK=$( pactl list short sinks \\\
    | sed -e 's,^\\([0-9][0-9]*\\)[^0-9].*,\\1,' | head -n 1 ); \\\
    pactl list sinks | grep '^[[:space:]]Volume:' \\\
    | head -n $(( $SINK + 1 )) | tail -n 1 | sed -e 's,.* \\([0-9][0-9]*\\)%.*,\\1,'"

local volume = {}
volume.mt = {}

volume.defaults = {
    timeout = 3,
    orientation = "vertical",
    size = 100,
    bar_width = 3,
    indicator_width = 2,
    indicator_offset = 5,
}

local function draw_vertical(widget, context, cr, width, height)
    if widget.vol >= 100 then
        cr:set_source(gears.color(beautiful.color_red .. "a0"))
    elseif widget.vol >= 75 then
        cr:set_source(gears.color(beautiful.color_yellow .. "a0"))
    else
        cr:set_source(gears.color(beautiful.color_green .. "a0"))
    end
    cr:set_line_width(widget.bar_width)

    local x = width / 2
    local val = height - (widget.vol <= 100 and widget.vol or 100) * (widget.size / 100)

    local off = widget.offset

    cr:move_to(x, height + off)
    cr:line_to(x, val + off)
    cr:stroke()

    cr:set_source(gears.color(beautiful.bg_focus .. "a0"))
    cr:move_to(x, val + off)
    cr:line_to(x, 0 + off)
    cr:stroke()

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(widget.indicator_width)
    local i = widget.bar_width / 2 + widget.indicator_offset
    cr:move_to(x - i, val + off)
    cr:line_to(x + i, val + off)
    cr:stroke()
end

local function draw_horizontal(widget, context, cr, width, height)
    if widget.vol >= 100 then
        cr:set_source(gears.color(beautiful.color_red .. "a0"))
    elseif widget.vol >= 75 then
        cr:set_source(gears.color(beautiful.color_yellow .. "a0"))
    else
        cr:set_source(gears.color(beautiful.color_green .. "a0"))
    end
    cr:set_line_width(widget.bar_width)

    local y = height / 2
    local val = width - (widget.vol <= 100 and widget.vol or 100) * (widget.size / 100)

    local off = widget.offset

    cr:move_to(width + off, y)
    cr:line_to(val + off, y)
    cr:stroke()

    cr:set_source(gears.color(beautiful.bg_focus .. "a0"))
    cr:move_to(val + off, y)
    cr:line_to(0 + off, y)
    cr:stroke()

    cr:set_source(gears.color(beautiful.fg_normal .. "a0"))
    cr:set_line_width(widget.indicator_width)
    local i = widget.bar_width / 2 + widget.indicator_offset
    cr:move_to(val + off, x - i)
    cr:line_to(val + off, x + i)
    cr:stroke()
end

local function fit_vertical(widget, context, width, height)
    return width, widget.size
end

local function fit_horizontal(widget, context, width, height)
    return widget.size, height
end

function volume.new(properties)
    local properties = gears.table.join(volume.defaults, properties or {})
    local volume_widget = gears.table.join(properties, wibox.widget.base.make_widget())
    volume_widget.vol = 0
    volume_widget.shown = false
    volume_widget.offset = 0

    if volume_widget.orientation == "vertical" then
        volume_widget.draw = draw_vertical
        volume_widget.fit = fit_vertical
    elseif volume_widget.orientation == "horizontal" then
        volume_widget.draw = draw_horizontal
        volume_widget.fit = fit_horizontal
    else
        error("Wrong volume widget orientation")
    end

    function volume_widget:update()
        local handle = io.popen(get_volume_cmd)
        local vol = handle:read("*n")
        handle:close()

        if vol ~= nil then
            self.vol = vol
        else
            self.vol = 0
        end

        volume_widget.shown = true
        self.animation_timer:again()
        self.timeout:again()

        volume_widget:emit_signal("widget::updated")
    end

    volume_widget.timeout = gears.timer.start_new(
        volume_widget.timeout,
        function()
            volume_widget.shown = false
            volume_widget.animation_timer:again()
            return false
        end)

    volume_widget.animation_timer = gears.timer.start_new(
        0.005,
        function()
            if volume_widget.shown and volume_widget.offset ~= 0 then
                volume_widget.offset = volume_widget.offset - 2
                volume_widget:emit_signal("widget::updated")
                return true
            elseif not volume_widget.shown and volume_widget.offset ~= volume_widget.size then
                volume_widget.offset = volume_widget.offset + 1
                volume_widget:emit_signal("widget::updated")
                return true
            else
                return false
            end
        end)

    volume_widget:update()

    awesome.connect_signal("volume::level", function() volume_widget:update() end)

    return volume_widget
end

function volume.mt:__call(...)
    return volume.new(...)
end

return setmetatable(volume, volume.mt)
