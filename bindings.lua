---------------------------------------------------------------------------
--- Bindings
-- Various keyboard and mouse bindings
--
-- @module bindings
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local menu = require("menu")

local global = require("global")
local audio = require("cosy.system.audio")

local client = _G.client
local awesome = _G.awesome

local modkey = global.modkey

local bindings = {
    modkey = modkey,
}

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

local function reload_color(c)
    beautiful.init("~/.config/awesome/themes/xresources/theme.lua")
    for s in _G.screen do
        _G.construct_panel(s)
    end
end
-- }}}

bindings.mouse = {
    global = gears.table.join(
        awful.button({ }, 3, function () menu.main:toggle() end),
        awful.button({ }, 4, awful.tag.viewnext),
        awful.button({ }, 5, awful.tag.viewprev)
    ),

    client = gears.table.join(
        awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
        awful.button({ modkey }, 1, awful.mouse.client.move),
        awful.button({ modkey }, 3, awful.mouse.client.resize)
    )
}

bindings.keyboard = {
    global = gears.table.join(
        awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
                  {description="show help", group="awesome"}),
        awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
                  {description = "view previous", group = "tag"}),
        awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
                  {description = "view next", group = "tag"}),
        awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
                  {description = "go back", group = "tag"}),

        awful.key({ modkey,           }, "e",
            function ()
                awful.client.focus.byidx( 1)
            end,
            {description = "focus next by index", group = "client"}),

        awful.key({ modkey,           }, "i",
            function ()
                awful.client.focus.byidx(-1)
            end,
            {description = "focus previous by index", group = "client"}),

        --awful.key({ modkey,           }, "w", function () menu.main:show() end,
                  --{description = "show main menu", group = "awesome"}),

        -- Standard program
        awful.key({ modkey,           }, "Return", function () awful.spawn(global.terminal) end,
                  {description = "open a terminal", group = "launcher"}),
        awful.key({ modkey, "Control" }, "r", awesome.restart,
                  {description = "reload awesome", group = "awesome"}),
        awful.key({ modkey, "Shift"   }, "q", awesome.quit,
                  {description = "quit awesome", group = "awesome"}),
        awful.key({ modkey,           }, "r", reload_color,
                  {description = "reload awesome colors",     group = "awesome"}),

        -- Layout manipulation
        awful.key({ modkey, "Shift"   }, "e", function () awful.client.swap.byidx(  1)    end,
                  {description = "swap with next client by index", group = "client"}),
        awful.key({ modkey, "Shift"   }, "i", function () awful.client.swap.byidx( -1)    end,
                  {description = "swap with previous client by index", group = "client"}),
        awful.key({ modkey,           }, "o", function () awful.screen.focus_relative( 1) end,
                  {description = "focus the next screen", group = "screen"}),
        awful.key({ modkey,           }, "n", function () awful.screen.focus_relative(-1) end,
                  {description = "focus the previous screen", group = "screen"}),
        awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
                  {description = "jump to urgent client", group = "client"}),
        awful.key({ modkey,           }, "Tab",
            function ()
                awful.client.focus.history.previous()
                if client.focus then
                    client.focus:raise()
                end
            end,
            {description = "go back", group = "client"}),

        awful.key({ modkey,           }, "period", function () awful.tag.incmwfact( 0.05)          end,
                  {description = "increase master width factor", group = "layout"}),
        awful.key({ modkey,           }, "comma",  function () awful.tag.incmwfact(-0.05)          end,
                  {description = "decrease master width factor", group = "layout"}),
        awful.key({ modkey, "Shift"   }, "comma",  function () awful.tag.incnmaster( 1, nil, true) end,
                  {description = "increase the number of master clients", group = "layout"}),
        awful.key({ modkey, "Shift"   }, "period", function () awful.tag.incnmaster(-1, nil, true) end,
                  {description = "decrease the number of master clients", group = "layout"}),
        awful.key({ modkey, "Control" }, "period", function () awful.tag.incncol( 1, nil, true)    end,
                  {description = "increase the number of columns", group = "layout"}),
        awful.key({ modkey, "Control" }, "comma",  function () awful.tag.incncol(-1, nil, true)    end,
                  {description = "decrease the number of columns", group = "layout"}),
        awful.key({ modkey,           }, "space",  function () awful.layout.inc( 1)                end,
                  {description = "select next", group = "layout"}),
        awful.key({ modkey, "Shift"   }, "space",  function () awful.layout.inc(-1)                end,
                  {description = "select previous", group = "layout"}),

        awful.key({ modkey, "Control" }, "k",
                  function ()
                      local c = awful.client.restore()
                      -- Focus restored client
                      if c then
                          client.focus = c
                          c:raise()
                      end
                  end,
                  {description = "restore minimized", group = "client"}),

        awful.key({ modkey }, "f", function() awful.spawn.with_shell(global.explorer_cmd) end,
                  {description = "open file explorer", group = "launcher"}),

        -- Rofi
        awful.key({ modkey }, "x", function()
                      awful.spawn("rofi -modi drun,run -show run -location 1 -xoffset " .. global.panel_size)
                  end,
                  {description = "run rofi launcher", group = "launcher"}),

        -- Vimwiki
        awful.key({ modkey, "Control" }, "w", function()
                      awful.spawn(global.editor_cmd .. " +VimwikiIndex")
                  end,
                  {description = "open vimwiki index page", group = "launcher"}),

        -- Screen lock
        awful.key({ "Control", "Mod1" }, "l",
                  function()
                      awful.spawn.with_shell("$HOME/.scripts/screen-lock.sh")
                  end,
                  {description = "lock screen", group = "awesome"}),

        -- Screenshot
        awful.key({}, "Print",
                  function()
                      local geo = awful.screen.focused().geometry
                      awful.spawn.with_shell("maim --geometry="..geo.width..'x'..geo.height..'+'..geo.x..'+'..geo.y.." $HOME/Pictures/Screenshots/$(date '+%Y-%0m-%0d-%0H:%M:%S:%3N').png")
                  end,
                  {description = "Take a screenshot of focused screen", group = "media"}),

        awful.key({ "Mod1" }, "Print",
                  function()
                      awful.spawn.with_shell("maim --window=".. client.focus.window or 'root' .." $HOME/Pictures/Screenshots/$(date '+%Y-%0m-%0d-%0H:%M:%S:%3N').png")
                  end,
                  {description = "Take a screenshot of focused window", group = "media"}),

        awful.key({ "Control" }, "Print",
                  function()
                      awful.spawn.with_shell("maim -s $HOME/Pictures/Screenshots/$(date +%Y-%0m-%0d-%0H:%M:%S:%3N.png)")
                  end,
                  {description = "Interactive screenshot", group = "media"}),

        awful.key({ modkey }, "Print",
                  function()
                      awful.spawn.with_shell("flameshot gui")
                  end,
                  {description = "Interactive screenshot to clipboard", group = "media"}),

        -- Media Keys
        awful.key({}, "XF86MonBrightnessUp",   function() awful.spawn("light -A 5") end,
                  {description = "increase brightness level", group = "media"}),
        awful.key({}, "XF86MonBrightnessDown", function() awful.spawn("light -U 5") end,
                  {description = "decrease brightness level", group = "media"}),

        awful.key({}, "XF86AudioRaiseVolume",  function() audio:volume_set("+2%")     end,
                  {description = "increase volume level",     group = "media"}),
        awful.key({}, "XF86AudioLowerVolume",  function() audio:volume_set("-2%")     end,
                  {description = "decrease volume level",     group = "media"}),
        awful.key({}, "XF86AudioMute",         function() audio:volume_mute("toggle") end,
                  {description = "mute volume",               group = "media"}),

        awful.key({}, "XF86AudioPlay",  function() awful.spawn("playerctl -p playerctld play-pause") end,
                  {description = "toggle pause",              group = "media"}),
        awful.key({}, "XF86AudioPause", function() awful.spawn("playerctl -p playerctld stop") end,
                  {description = "stop",                      group = "media"}),
        awful.key({}, "XF86AudioNext",  function() awful.spawn("playerctl -p playerctld next") end,
                  {description = "next soundtrack",           group = "media"}),
        awful.key({}, "XF86AudioPrev",  function() awful.spawn("playerctl -p playerctld previous") end,
                  {description = "previous soundtrack",       group = "media"})
    ),

    client = gears.table.join(
        awful.key({ modkey,           }, "w",
            function (c)
                c.fullscreen = not c.fullscreen
                c:raise()
            end,
            {description = "toggle fullscreen", group = "client"}),
        awful.key({ modkey,           }, "q",      function (c) c:kill()                         end,
                  {description = "close", group = "client"}),
        awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
                  {description = "toggle floating", group = "client"}),
        awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
                  {description = "move to master", group = "client"}),
        awful.key({ modkey,           }, "y",      function (c) c:move_to_screen()               end,
                  {description = "move to screen", group = "client"}),
        awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
                  {description = "toggle keep on top", group = "client"}),
        awful.key({ modkey,           }, "k",
            function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
            end ,
            {description = "minimize", group = "client"}),
        awful.key({ modkey,           }, "m",
            function (c)
                c.maximized = not c.maximized
                c:raise()
            end ,
            {description = "(un)maximize", group = "client"}),
        awful.key({ modkey, "Control" }, "m",
            function (c)
                c.maximized_vertical = not c.maximized_vertical
                c:raise()
            end ,
            {description = "(un)maximize vertically", group = "client"}),
        awful.key({ modkey, "Shift"   }, "m",
            function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c:raise()
            end ,
            {description = "(un)maximize horizontally", group = "client"})
    )
}

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    bindings.keyboard.global = gears.table.join(bindings.keyboard.global,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

bindings.taglist_mouse = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ bindings.modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ bindings.modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end)
                )

bindings.tasklist_mouse = gears.table.join(
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
                                              awful.client.focus.byidx(-1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(1)
                                          end))


return bindings
