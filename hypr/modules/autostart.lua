-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/
-- Commands inside the "hyprland.start" handler run once at login (old exec-once).
-- Top-level hl.exec_cmd calls run on every config load/reload (old exec).

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("sleep 1 && waybar")
    hl.exec_cmd("/usr/lib/pam_kwallet_init")

    -- Monitor layout management — kanshi detects which monitors are connected and
    -- activates the matching profile from ~/.config/kanshi/config.
    hl.exec_cmd("kanshi")

    -- Kill all RGB on login
    hl.exec_cmd("sleep 3 && ~/.config/hypr/scripts/kill-rgb.sh")
end)

hl.exec_cmd([[gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"]])

-- Workspace routing per connected monitor (and hotplug handling) lives in workspaces.lua.
