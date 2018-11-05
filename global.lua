---------------------------------------------------------------------------
--- Global
-- Awesome global settings
--
-- @module global
---------------------------------------------------------------------------

local global = {
    modkey      = "Mod4",
    panel_size  = 45,
    terminal    = "kitty",
    editor      = os.getenv("EDITOR") or "vim",
    explorer    = "ranger",
}

global.editor_cmd   = global.terminal .. " -e " .. global.editor
global.explorer_cmd = global.terminal .. " -e " .. global.explorer


return global
