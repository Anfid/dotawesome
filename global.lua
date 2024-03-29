---------------------------------------------------------------------------
--- Global
-- Awesome global settings
--
-- @module global
---------------------------------------------------------------------------

local dpi = require("beautiful.xresources").apply_dpi

local global = {
    dynamic_theme   = false,
    modkey          = "Mod4",
    panel_size      = dpi(50),
    panel_position  = "left",
    terminal        = "kitty --single-instance",
    editor          = os.getenv("EDITOR") or "vim",
    explorer        = "ranger",
}

global.editor_cmd   = global.terminal .. " -e " .. global.editor
global.explorer_cmd = global.terminal .. " -e " .. global.explorer


return global
