-- Hyprland Lua config (0.57+).
-- See https://wiki.hypr.land/configuring/
-- Type stubs for editor completion: /usr/share/hypr/stubs/hl.meta.lua

require("modules.programs")
require("modules.env")
require("modules.monitors")
require("modules.autostart")
require("modules.decoration")
require("modules.animations")
require("modules.keybinds")
require("modules.windowrule")
require("modules.workspaces")

-- Ref https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

hl.config({
    general = {
        resize_on_border     = true,
        hover_icon_on_border = true,
    },

    -- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/ for more
    dwindle = {
        preserve_split = true, -- You probably want this
    },

    -- See https://wiki.hypr.land/configuring/layouts/master-layout/ for more
    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },

    -- Don't auto-switch the monitor into HDR mode when a fullscreen window
    -- (e.g. a video) requests HDR. Default is 1 (auto-switch).
    render = {
        cm_auto_hdr = 0,
    },

    -- NVIDIA hardware cursors don't account for monitor transforms — cursor clips early on
    -- rotated monitors. Software cursors fix this with no visible quality difference.
    cursor = {
        no_hardware_cursors = true,
    },

    ---------------
    ---- INPUT ----
    ---------------
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Laptop built-in keyboard only: Caps Lock acts as Escape.
-- External keyboards keep the global input settings above.
hl.device({
    name       = "at-translated-set-2-keyboard",
    kb_options = "caps:escape",
})

-- See https://wiki.hypr.land/configuring/core/gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
