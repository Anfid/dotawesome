---------------------------------------------------------------------------
--- System info desktop widget
--
-- @module cosy.widget.desktop
---------------------------------------------------------------------------
local d = require("dbg")

local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")
local sysinfo = require("cosy.sysinfo")

local dpi = beautiful.xresources.apply_dpi
local pi = math.pi
local floor = math.floor

local stat = {
    arcs = {}
}
stat.mt = {}

stat.defaults = {
    bg_color = gears.color(beautiful.fg_normal.."40"),
    fg_color = gears.color(beautiful.fg_normal.."a0"),
}

stat.defaults.rings = {
    --[[
        * name        - type of the stat to display.
                        See https://github.com/brndnmtthws/conky/wiki/Configuration-Variables for various possible
                        options
        * arg         - argument to the stat type, see link above
        * max         - maximum value of the ring
        * bg_color    - color of the base ring
        * bg_alpha    - alpha value of the base ring
        * fg_color    - color of the indicator part of the ring
        * fg_alpha    - alpha value of the indicator part of the ring
        * x           - x coordinate of the ring centre
        * y           - y coordinate of the ring centre
        * radius      - radius of the ring
        * thickness   - thickness of the ring, centred around the radius
        * start_angle - start angle of the ring, in degrees, clockwise from top. Value can be either positive or
                        negative
        * end_angle   - end angle of the ring, in degrees, clockwise from top. Value can be either positive or negative,
                        but must be larger than start_angle.
    ]]--
    {
        name='time',
        arg='%S',
        max=60,
        bg_color=0xffffff,
        bg_alpha=0.1,
        fg_color=0xffffff,
        fg_alpha=0.6,
        x=160, y=155,
        radius=65,
        thickness=4,
        start_angle=0,
        end_angle=360
    },
    {
        name='cpu',
        arg='cpu1',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=75,
        thickness=5,
        start_angle=93,
        end_angle=208
    },
    {
        name='cpu',
        arg='cpu2',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=81,
        thickness=5,
        start_angle=93,
        end_angle=208
    },
    {
        name='cpu',
        arg='cpu3',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=87,
        thickness=5,
        start_angle=93,
        end_angle=208
    },
    {
        name='cpu',
        arg='cpu4',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=93,
        thickness=5,
        start_angle=93,
        end_angle=208
    },
    {
        name='memperc',
        arg='',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=84,
        thickness=22.5,
        start_angle=212,
        end_angle=329
    },
    {
        name='battery_percent',
        arg='BAT1',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=84,
        thickness=22.5,
        start_angle=-27,
        end_angle=88
    },
    {
        name='cpu', -- dummy (used for arc)
        arg='',
        max=1,
        bg_color=0xd5dcde,
        bg_alpha=0.7,
        fg_color=0xd5dcde,
        fg_alpha=0,
        x=162, y=155,
        radius=118,
        thickness=2,
        start_angle=75,
        end_angle=105
    },
    {
        name='cpu', -- dummy (used for arc)
        arg='',
        max=1,
        bg_color=0xffffff,
        bg_alpha=0.7,
        fg_color=0xffffff,
        fg_alpha=0,
        x=266, y=155,
        radius=308,
        thickness=2,
        start_angle=84,
        end_angle=96
    },
    {
        name='fs_used_perc',
        arg='/',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=105,
        thickness=5,
        start_angle=-120,
        end_angle=-1.5
    },
    {
        name='fs_used_perc',
        arg='/home',
        max=100,
        bg_color=0xffffff,
        bg_alpha=0.2,
        fg_color=0xffffff,
        fg_alpha=0.5,
        x=160, y=155,
        radius=105,
        thickness=5,
        start_angle=1.5,
        end_angle=120
    },
}

local function setup_arcs(self, cr)
    self.arcs = {}
    local bg_color = stat.defaults.bg_color
    local fg_color = stat.defaults.fg_color
    -- TODO: replace const width with configurable
    local width = dpi(24)

    local x = dpi(160)
    local y = dpi(100)
    local angle_start = 3 * (pi / 180)
    local angle_end = 118 * (pi / 180)

    local cores = sysinfo.cpu.cores
    local w
    if 3 * cores > width then
        w = 2
        width = 3 * cores
    else
        w = floor(width / cores) - 1
    end

    -- CPU
    for i = 1, sysinfo.cpu.cores do
        local r = 75 + ((w + 1) * (i - 1))
        local val = sysinfo.cpu.load[i]

        local bg_arc = {
            x = x,
            y = y,
            r = r,
            w = w,
            angle_start = angle_start,
            angle_end = angle_end,
            color = bg_color,
        }

        local fg_arc = {
            x = x,
            y = y,
            r = r,
            w = w,
            angle_start = angle_start,
            angle_end = angle_start + val * (angle_end - angle_start),
            color = fg_color,
        }

        table.insert(self.arcs, bg_arc)
        table.insert(self.arcs, fg_arc)
    end

    -- RAM
    do
        local r = 75 + width / 2
        local w = width
        local angle_end = 239 * (pi / 180)
        local angle_start = 122 * (pi / 180)
        local val = (sysinfo.mem.total - sysinfo.mem.available) / sysinfo.mem.total

        local bg_arc = {
            x = x,
            y = y,
            r = r,
            w = w,
            angle_start = angle_start,
            angle_end = angle_end,
            color = bg_color,
        }

        local fg_arc = {
            x = x,
            y = y,
            r = r,
            w = w,
            angle_start = angle_start,
            angle_end = angle_start + val * (angle_end - angle_start),
            color = fg_color,
        }

        table.insert(self.arcs, bg_arc)
        table.insert(self.arcs, fg_arc)
    end
end

local function draw_arcs(self, cr)
    for i, arc in pairs(self.arcs) do
        cr:set_source(arc.color)
        cr:set_line_width(arc.w)
        cr:new_sub_path()
        cr:arc(arc.x, arc.y, arc.r, arc.angle_start, arc.angle_end)
        cr:stroke()
    end
end

local function draw(self, context, cr, width, height)
    self:setup_arcs(cr)
    self:draw_arcs(cr)
end

-- TODO: Document properties
-- update_time - how often widget is redrawn. For single widget 0.05 works best. However, if more than one widget is
-- used, it is better to set to 0.01. Widgets sometimes interrupt each other's reading of fifo and faster redraw rate
-- compensates lag frames
function stat.new(s, properties)
    local properties = gears.table.join(stat.defaults, properties or {})
    local stat_widget = gears.table.join(properties, wibox.widget.base.make_widget())

    properties.w = s.geometry.width
    properties.h = s.geometry.height

    if not properties.x then properties.x = 0 end
    if not properties.y then properties.y = 0 end

    function stat_widget:fit(context, width, height) return width, height end
    stat_widget.setup_arcs = setup_arcs
    stat_widget.draw_arcs = draw_arcs
    stat_widget.draw = draw

    local stat_box = wibox({
        screen = s,
        type = "desktop",
        visible = true,
        bg = "#00000000",
    })

    stat_box:geometry({
        x = s.geometry.x + properties.x,
        y = s.geometry.y + properties.y,
        width  = properties.w,
        height = properties.h,
    })

    stat_box:set_widget(stat_widget)

    stat_widget:emit_signal("widget::updated")

    sysinfo.connect_signal("cpu::updated", function() stat_widget:emit_signal("widget::updated") end)

    return stat_box
end

function stat.mt:__call(...)
    return stat.new(...)
end

return setmetatable(stat, stat.mt)
