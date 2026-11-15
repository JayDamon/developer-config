------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
-- kanshi (started in autostart.lua) handles per-profile monitor layout automatically.
-- These rules are fallbacks — Hyprland ignores rules for disconnected outputs.
-- Use desc: matching so these work regardless of which port a monitor is plugged into.
hl.monitor({
    output   = "desc:Samsung Electric Company C49RG9x H1AK500000",
    mode     = "5120x1440@59.98",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output    = "desc:Dell Inc. DELL U2715H 0x30505353",
    mode      = "2560x1440@59.95",
    position  = "5120x0",
    scale     = 1,
    transform = 3,
})

-- Laptop built-in (3840x2400 → 1920x1200 logical)
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 2,
})

-- Catch-all for any other
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
