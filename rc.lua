-- Capture variables
local awesome = _G.awesome
local client = _G.client
local root = _G.root
local tag = _G.tag
local screen = _G.screen

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Theme handling library
local beautiful = require("beautiful")
beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/default/theme.lua")
local dpi = require("beautiful.xresources").apply_dpi

-- Widget and layout library
local wibox = require("wibox")

-- Notification library
local naughty = require("naughty")
naughty.config.defaults['icon_size'] = 64

-- User library
local cosy = require("cosy")
local global = require("global")
local rules = require("rules")
local bindings = require("bindings")
local layout = require("layout")

awesome.set_preferred_icon_size(global.panel_size)

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Errors during startup",
            text = awesome.startup_errors,
        })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
                preset = naughty.config.presets.critical,
                title = "An error occured",
                text = tostring(err),
            })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
local floatgeoms = {}

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.max,
    layout.popup,
    awful.layout.suit.tile.left,
    awful.layout.suit.fair,
    awful.layout.suit.floating,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", cosy.util.set_wallpaper)

-- Keyboard map indicator and switcher
local keyboardlayout = awful.widget.keyboardlayout()

function _G.construct_panel(s)
    s.cava = cosy.widget.desktop.cava(
        s,
        {
            bars = 100,
            enable_interpolation = true,
            size = global.panel_size,
            position = global.panel_position,
            update_time = (screen:count() > 1) and 0.01 or 0.05
        })

    s.stat = cosy.widget.desktop.stat(s, {})

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.layoutbox = awful.widget.layoutbox(s)
    s.layoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))

    local focus_gradient = gears.color.create_linear_pattern({
            type = "linear",
            from = {0, 0},
            to = {global.panel_size, 0},
            stops = { {0, beautiful.bg_focus.."f0"}, {1, "#00000000"} }
        })

    -- Create a taglist widget
    s.taglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.noempty,
        buttons = bindings.taglist_mouse,
        style = {
            align = "center",
            bg_normal = beautiful.bg_normal .. "a0",
            bg_focus = focus_gradient,
            bg_urgent = beautiful.bg_urgent .. "00",
        },
        layout = wibox.layout.fixed.vertical()
    }

    -- Create a tasklist widget
    s.tasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = bindings.tasklist_mouse,
        style = {
            align = "center",
            disable_task_name = true,
            bg_normal = "#00000000",
            bg_focus = focus_gradient,
            bg_urgent = beautiful.bg_urgent .. "00",
        },
        layout = wibox.layout.fixed.vertical()
    }

    s.systray = wibox.widget.systray()

    -- remove old panel
    if s.panel then s.panel:remove() end

    -- create new panel
    s.panel = awful.wibar {
        screen = s,
        position = global.panel_position,
        width = global.panel_size,
        bg = beautiful.bg_normal .. "a0", -- bg with alpha
    }

    -- Add widgets to the wibox
    s.panel:setup {
        layout = wibox.layout.align.vertical,
        { -- Left widgets
            layout = wibox.layout.fixed.vertical,
            s.taglist,
        },
        s.tasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.vertical,
            cosy.widget.panel.volume({
                indicator_width = dpi(2),
                indicator_offset = dpi(5),
            }),
            cosy.widget.panel.battery({}),
            keyboardlayout,
            s.systray,
            cosy.widget.textclock,
            s.layoutbox,
        },
    }
end

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    cosy.util.set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    _G.construct_panel(s)
end)

-- {{{ Set bindings
root.buttons(bindings.mouse.global)
root.keys(bindings.keyboard.global)
-- }}}

awful.rules.rules = rules

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    if not awesome.startup then awful.client.setslave(c) end

    -- Set floating if slave window is created on popup layout
    -- TODO: Consider if more elegant solution is possible
    if awful.layout.get(c.screen) == layout.popup
        and cosy.util.table_count(c.first_tag:clients()) > 1
    then
        c.floating = true
        awful.placement.no_offscreen(c)
    end

    -- Save floating client geometry
    if cosy.util.client_free_floating(c) then
        floatgeoms[c.window] = c:geometry()
    end

    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position
    then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- FIXME: Exclude titlebar from geometry
-- XXX: There seems to be a weird behavior with property::floating signal. It is not sent when maximized and fullscreen
-- property changes of clients originally created on other than floating tag layouts and sent otherwise
client.connect_signal("property::floating", function(c)
    if cosy.util.client_free_floating(c) then
        c:geometry(floatgeoms[c.window])
    end
    cosy.util.manage_titlebar(c)
end)

tag.connect_signal("property::layout", function(t)
    for _, c in pairs(t:clients()) do
        if cosy.util.client_free_floating(c) then
            c:geometry(floatgeoms[c.window])
        end
        cosy.util.manage_titlebar(c)
    end
end)

client.connect_signal("property::geometry", function(c)
    if cosy.util.client_free_floating(c) then
        floatgeoms[c.window] = c:geometry()
    end
end)

client.connect_signal("unmanage", function(c)
    floatgeoms[c.window] = nil
    awful.client.focus.byidx(-1)
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.minimizebutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }

    -- Hide titlebar if client is not floating
    local l = awful.layout.get(c.screen)
    if not (c.floating or l == awful.layout.suit.floating) then
        awful.titlebar.hide(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Startup applications
awful.spawn.spawn("setxkbmap -layout us,ru -variant colemak, -option 'grp:toggle'")
awful.spawn.once("picom --experimental-backends")
awful.spawn.once("nm-applet")
awful.spawn.once("telegram-desktop")
-- }}}
