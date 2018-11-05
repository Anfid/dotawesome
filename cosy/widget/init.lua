---------------------------------------------------------------------------
--- Widget module for cosy
--
-- @module cosy.widget
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local menu = require("cosy.menu")
local wibox = require("wibox")

local widget = {
    desktop = require("cosy.widget.desktop")
}

-- Launcher menu
widget.launcher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = menu.main,
})

-- Textclock
widget.textclock = {}
widget.textclock.widget = wibox.widget.textclock("<span font=\"Iosevka 10\">%a\n%H:%M\n%d.%m</span>")
widget.textclock.tooltip = awful.tooltip({
    objects = { widget.textclock.widget },
    timer_function = function()
        return os.date("%d of %B %Y\n%A")
    end
})
widget.textclock.widget:set_align("center")
widget.textclock.tooltip.textbox:set_align("center")

-- Promptbox
widget.promptbox = awful.widget.prompt()

function load_panel(s)
    -- Create a promptbox for each screen
    s.promptbox = awful.widget.prompt()
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
            widget.launcher,
            s.taglist,
            s.mypromptbox,
        },
        s.tasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.vertical,
            keyboardlayout,
            wibox.widget.systray(),
            textclock,
            s.mylayoutbox,
        },
    }
end

return widget
