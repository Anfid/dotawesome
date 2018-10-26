-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
awesome.set_preferred_icon_size(35)

-- Theme handling library
local beautiful = require("beautiful")
beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/default/theme.lua")

-- Widget and layout library
local wibox = require("wibox")

-- Notification library
local naughty = require("naughty")
naughty.config.defaults['icon_size'] = 64

-- User library
local cosy = require("cosy")
local global = require("global")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
floatgeoms = {}

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.max,
    cosy.layout.popup,
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

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- Keyboard map indicator and switcher
keyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ cosy.bindings.modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ cosy.bindings.modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.layoutbox = awful.widget.layoutbox(s)
    s.layoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.taglist = awful.widget.taglist(s, awful.widget.taglist.filter.noempty, taglist_buttons, {align = "center"}, nil, wibox.layout.fixed.vertical())

    -- Create a tasklist widget
    s.tasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons, {align = "center", disable_task_name = true}, nil, wibox.layout.fixed.vertical())

    -- Create the wibox
    s.wibox = awful.wibar { screen = s, position = "left", width = 35 }

    -- Add widgets to the wibox
    s.wibox:setup {
        layout = wibox.layout.align.vertical,
        { -- Left widgets
            layout = wibox.layout.fixed.vertical,
            cosy.widget.launcher,
            s.taglist,
            cosy.widget.promptbox,
        },
        s.tasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.vertical,
            keyboardlayout,
            wibox.widget.systray(),
            cosy.widget.textclock,
            s.layoutbox,
        },
    }
end)
-- }}}

-- {{{ Set bindings
root.buttons(cosy.bindings.mouse.global)
root.keys(cosy.bindings.keyboard.global)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = cosy.bindings.keyboard.client,
                     buttons = cosy.bindings.mouse.client,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = true }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Functions
-- Toggle titlebar on or off depending on s. Creates titlebar if it doesn't exist
local function manage_titlebar(c)
    show = c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating
    if show then
        if c.titlebar == nil then
            c:emit_signal("request::titlebars", "rules", {})
        end
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
end

local function getn(table)
    local count = 0
    for _, v in pairs(table) do
        if v ~= nil then
            count = count + 1
        end
    end

    return count
end
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    if not awesome.startup then awful.client.setslave(c) end

    -- Set floating if slave window is created on popup layout
    -- TODO: Consider if more elegant solution is possible
    if awful.layout.get(c.screen) == cosy.layout.popup
        and getn(c.first_tag:clients()) > 1 then
        c.floating = true
        awful.placement.bottom(c)
    end

    -- Save floating client geometry
    if c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating then
        floatgeoms[c.window] = c:geometry()
    end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- FIXME: Exclude titlebar from geometry
client.connect_signal("property::floating", function(c)
    local floating = c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating
    if floating then
        c:geometry(floatgeoms[c.window])
    end
    manage_titlebar(c)
    awful.placement.no_offscreen(c)
end)

tag.connect_signal("property::layout", function(t)
    for _, c in pairs(t:clients()) do
        local floating = c.floating or t.layout == awful.layout.suit.floating
        if floating then
            c:geometry(floatgeoms[c.window])
        end
        manage_titlebar(c)
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("property::geometry", function(c)
    local floating = c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating
    if floating then
        floatgeoms[c.window] = c:geometry()
    end
end)

client.connect_signal("unmanage", function(c) floatgeoms[c.window] = nil end)

client.connect_signal("manage", function(c)
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
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
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

-- {{{ Startup application
awful.spawn.with_shell("~/.config/awesome/startup.sh")
-- }}}
