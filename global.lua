---------------------------------------------------------------------------
--- Global
-- Awesome global settings
--
-- @module global
---------------------------------------------------------------------------

local global = {
    dynamic_theme   = false,
    modkey          = "Mod4",
    panel_size      = 45,
    panel_position  = "left",
    terminal        = "kitty",
    editor          = os.getenv("EDITOR") or "vim",
    explorer        = "ranger",
}

global.editor_cmd   = global.terminal .. " -e " .. global.editor
global.explorer_cmd = global.terminal .. " -e " .. global.explorer


return global
