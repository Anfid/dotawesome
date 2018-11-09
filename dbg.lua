---------------------------------------------------------------------------
--- Debugging utilities
--
-- Module with various debugging utilities for Awesome WM
--
-- @module dbg
---------------------------------------------------------------------------
local gears = require("gears")
local naughty = require("naughty")

local dbg = {}

function dbg.notify(var, title)
    local title = title or "Debug"
    naughty.notify({
            preset = naughty.config.presets.normal,
            title = title,
            text = gears.debug.dump_return(var),
        })
end

function dbg.notify_err(var, title)
    local title = title or "Error"
    naughty.notify({
            preset = naughty.config.presets.critical,
            title = title,
            text = gears.debug.dump_return(var),
        })
end

return dbg
