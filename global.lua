---------------------------------------------------------------------------
--- Global
-- Awesome global settings
--
-- @module global
---------------------------------------------------------------------------

local global = {}

global.modkey = "Mod4"
global.terminal = "kitty"
global.editor = os.getenv("EDITOR") or "vim"
global.editor_cmd = global.terminal .. " -e " .. global.editor

return global
