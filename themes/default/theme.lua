---------------------
--  Gruvbox theme  --
---------------------

local theme_dir = require("gears.filesystem").get_configuration_dir() .. "themes/default/"
local dpi = require("beautiful.xresources").apply_dpi

local global = require("global")

-- {{{ Main
local theme = {}
theme.wallpaper = "~/Pictures/Wallpapers/LoneWolf.png"
-- }}}

-- {{{ Styles
theme.font_family   = "Iosevka"
theme.font          = theme.font_family.." 12"
theme.taglist_font  = theme.font_family.." 15"

-- {{{ Colors
theme.fg_normal  = "#a89984"
theme.fg_focus   = "#ebdbb2"
theme.fg_urgent  = "#cc241d"
theme.bg_normal  = "#282828"
theme.bg_focus   = "#141414"
theme.bg_urgent  = "#282828"
theme.bg_systray = theme.bg_normal

theme.color_green  = "#98971a"
theme.color_yellow = "#d79921"
theme.color_red    = "#cc241d"
-- }}}

-- {{{ Borders
theme.useless_gap   = dpi(0)
theme.border_width  = dpi(0)
theme.border_normal = "#282828"
theme.border_focus  = "#98971a"
theme.border_marked = "#d79921"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#3c3c3c"
theme.titlebar_bg_normal = "#3c3c3c"
-- }}}

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- titlebar_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- Example:
--theme.taglist_bg_focus = "#CC9393"
-- }}}

-- {{{ Widgets
-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.fg_widget        = "#AECF96"
--theme.fg_center_widget = "#88A175"
--theme.fg_end_widget    = "#FF5656"
--theme.bg_widget        = "#494B4F"
--theme.border_widget    = "#3F3F3F"
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = "#d3869b"
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

if global.dynamic_theme then
    -- TODO: read color file and update colors, if dynamic_theme is enabled
    local success, xres = pcall(require, "colors")
    -- XXX: Work in progress temporary plug
    -- This will be removed as soon as color extraction program is finished
    success = true
    xres = {
        wallpaper = "~/Pictures/Wallpapers/LoneWolf.png",
        foreground = "#e67979",
        background = "#221a26",
        cursorColor = "#e67979",

        -- black
        color0 = "#070508",
        color8 = "#221a26",

        -- red
        color1 = "#cf392a",
        color9 = "#df6357",

        -- green
        color2 = "#c8410c",
        color10 = "#f35a1f",

        -- yellow
        color3 = "#9d244d",
        color11 = "#cf2f65",

        -- blue
        color4 = "#992d51",
        color12 = "#c73c6a",

        -- magenta
        color5 = "#95324a",
        color13 = "#c14362",

        -- cyan
        color6 = "#a02b36",
        color14 = "#cb3d4a",

        -- white
        color7 = "#eac8cf",
        color15 = "#fbf4f5",
    }
    if success then
        theme.wallpaper = xres.wallpaper

        theme.fg_normal  = xres.foreground -- foreground
        theme.fg_focus   = xres.color7 -- white
        theme.fg_urgent  = xres.color1 -- red
        theme.bg_normal  = xres.color0 -- black
        theme.bg_focus   = xres.color8 -- black bright
        theme.bg_urgent  = xres.color8 -- black bright
        theme.bg_systray = theme.bg_normal

        --theme.border_normal = -- undecided
        --theme.border_focus  = -- undecided
        --theme.border_marked = -- undecided

        theme.titlebar_bg_focus  = xres.background
        theme.titlebar_bg_normal = xres.color0
    end
end

-- {{{ Menu
-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = dpi(25)
theme.menu_width  = dpi(150)
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = theme_dir .. "taglist/squarefz.png"
theme.taglist_squares_unsel = theme_dir .. "taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
theme.awesome_icon           = theme_dir .. "awesome-icon.png"
theme.menu_submenu_icon      = theme_dir .. "submenu.png"
-- }}}

-- {{{ Layout
theme.layout_tile       = theme_dir .. "layouts/tile.png"
theme.layout_tileleft   = theme_dir .. "layouts/tileleft.png"
theme.layout_tilebottom = theme_dir .. "layouts/tilebottom.png"
theme.layout_tiletop    = theme_dir .. "layouts/tiletop.png"
theme.layout_fairv      = theme_dir .. "layouts/fairv.png"
theme.layout_fairh      = theme_dir .. "layouts/fairh.png"
theme.layout_spiral     = theme_dir .. "layouts/spiral.png"
theme.layout_dwindle    = theme_dir .. "layouts/dwindle.png"
theme.layout_max        = theme_dir .. "layouts/max.png"
theme.layout_fullscreen = theme_dir .. "layouts/fullscreen.png"
theme.layout_magnifier  = theme_dir .. "layouts/magnifier.png"
theme.layout_popup      = theme_dir .. "layouts/magnifier.png"
theme.layout_floating   = theme_dir .. "layouts/floating.png"
theme.layout_cornernw   = theme_dir .. "layouts/cornernw.png"
theme.layout_cornerne   = theme_dir .. "layouts/cornerne.png"
theme.layout_cornersw   = theme_dir .. "layouts/cornersw.png"
theme.layout_cornerse   = theme_dir .. "layouts/cornerse.png"
-- }}}

-- {{{ Titlebar
theme.titlebar_close_button_focus  = theme_dir .. "titlebar/close_focus.png"
theme.titlebar_close_button_normal = theme_dir .. "titlebar/close_normal.png"

theme.titlebar_minimize_button_normal = theme_dir .. "titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = theme_dir .. "titlebar/minimize_focus.png"

theme.titlebar_ontop_button_focus_active  = theme_dir .. "titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = theme_dir .. "titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = theme_dir .. "titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = theme_dir .. "titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = theme_dir .. "titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = theme_dir .. "titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = theme_dir .. "titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = theme_dir .. "titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = theme_dir .. "titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = theme_dir .. "titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = theme_dir .. "titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = theme_dir .. "titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = theme_dir .. "titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = theme_dir .. "titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = theme_dir .. "titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme_dir .. "titlebar/maximized_normal_inactive.png"
-- }}}
-- }}}

return theme
