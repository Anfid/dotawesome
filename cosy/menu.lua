---------------------------------------------------------------------------
--- Menu
-- Definitions for awful.menu
--
-- @module cosy.menu
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local global = require("global")

local awesome = _G.awesome

local menu = {}

local launcher_power = {
   { "Shutdown", "shutdown 0"},
   { "Reboot",   "shutdown -r 0" },
}

local launcher_awesome = {
   { "Restart",     awesome.restart },
   { "Edit config", global.editor_cmd .. " " .. awesome.conffile },
   { "Quit",        function() awesome.quit() end},
}

menu.main = awful.menu({
    items = {
        { "Power",    launcher_power,   beautiful.awesome_icon },
        { "Awesome",  launcher_awesome, beautiful.awesome_icon },
        { "Terminal", global.terminal },
    }
})

return menu
