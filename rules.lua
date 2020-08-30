---------------------------------------------------------------------------
--- Rules
--
-- Awesome tag settings
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local bindings = require("bindings")

local screen = _G.screen

-- Rules to apply to new clients (through the "manage" signal).
local rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = bindings.keyboard.client,
            buttons = bindings.mouse.client,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
        }
    },

    -- Floating clients
    {
        rule_any = {
            instance = {
                "DTA",  -- Firefox addon DownThemAll
                "copyq",  -- Includes session name in class
            },

            class = {
                "Arandr",
                "Gpick",
                "Kruler",
                "MessageWin",  -- kalarm
                "Sxiv",
                "Wpa_gui",
                "pinentry",
                "veromix",
                "xtightvncviewer",
            },

            name = {
                "Event Tester",  -- xev
            },

            role = {
                "AlarmWindow",  -- Thunderbird's calendar
                "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools
            }
        },
        properties = { floating = true }
    },

    -- Fullscreen clients
    {
        rule_any = {
            class = {
                "awesome-xephyr",
            },
        },
        properties = {
            --fullscreen = true,
        }
    },

    -- Add titlebars to normal clients and dialogs
    {
        rule_any = {
            type = { "normal", "dialog" }
        },
        properties = { titlebars_enabled = true }
    },

    -- Assign default tags
    {
        rule_any = {
            class = { "Waterfox", "Firefox", "qutebrowser" }
        },
        properties = { screen = 1, tag = "1" }
    },

    {
        rule_any = {
            class = { "TelegramDesktop", "Slack" }
        },
        properties = { screen = screen.count()>1 and 2 or 1, tag = screen.count() > 1 and "1" or "4" }
    },
}

return rules
