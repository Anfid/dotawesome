---------------------------------------------------------------------------
--- Util
-- Utility functions
--
-- @module cosy.util
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

local util = {}
util.math = {}
util.file = {}

--- Set wallpaper for screen s
-- @param screen
function util.set_wallpaper(s)
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

--- Toggle titlebar on or off depending on s. Creates titlebar if it doesn't exist
-- @param client Client to update titlebar state
function util.manage_titlebar(c)
    -- Fullscreen clients are considered floating. Return to prevent clients from shifting down in fullscreen mode
    if c.fullscreen then return end
    local show = c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating
    if show then
        if c.titlebar == nil then
            c:emit_signal("request::titlebars", "rules", {})
        end
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
    -- Prevents titlebar appearing off the screen
    awful.placement.no_offscreen(c)
end

--- Checks if client is floating and can be moved
-- @param client Client to test
-- @return bool
function util.client_free_floating(c)
    return (c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating)
        and not (c.fullscreen or c.maximized or c.maximized_vertical or c.maximized_horizontal)
end

--- Count table elements
-- @param table Table to count elements
-- @return number Amount of key-value pairs in the table
function util.table_count(table)
    local count = 0
    for _, v in pairs(table) do
        if v ~= nil then
            count = count + 1
        end
    end

    return count
end


function util.math.round(x) return x + 0.5 - (x + 0.5) % 1 end


function util.file.exists(command)
    local f = io.open(command)
    if f then f:close() end
    return f and true or false
end

function util.file.read(file)
    local file = io.open(file)
    if not file then return nil end
    local text = file:read('*all')
    file:close()
    return text
end

return util
