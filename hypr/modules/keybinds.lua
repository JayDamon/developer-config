---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/configuring/core/binds/
local programs = require("modules.programs")
local mainMod  = "SUPER" -- Sets "Windows" key as main modifier

local function key(combo)
    return mainMod .. " + " .. combo
end

local exec = hl.dsp.exec_cmd

hl.bind(key("SHIFT + Delete"), exec("hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff'"))
hl.bind(key("SHIFT + R"),      exec("hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl reboot'"))
hl.bind(key("Z"),              exec("systemctl suspend"))

hl.bind(key("C"),         exec(programs.terminal))
hl.bind(key("Return"),    exec(programs.terminal))
hl.bind(key("Q"),         hl.dsp.window.close())
hl.bind(key("SHIFT + Q"), hl.dsp.window.kill())
hl.bind(key("Escape"),    exec("hyprlock --config ~/.config/hypr/hyprlock.conf"))
hl.bind(key("E"),         exec("hyprlock"))
hl.bind(key("V"),         hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("SPACE"),     exec(programs.menu))
hl.bind(key("P"),         hl.dsp.window.pseudo())       -- dwindle
hl.bind(key("U"),         hl.dsp.layout("togglesplit")) -- dwindle

-- Set audio device
hl.bind(key("T"),         exec("wpctl set-default 73"))
hl.bind(key("SHIFT + T"), exec("wpctl set-default 85"))

-- Move focus (arrows and vim keys) / swap windows (with SHIFT)
local directions = {
    { arrow = "left",  vim = "H", dir = "left"  },
    { arrow = "right", vim = "L", dir = "right" },
    { arrow = "up",    vim = "K", dir = "up"    },
    { arrow = "down",  vim = "J", dir = "down"  },
}
for _, d in ipairs(directions) do
    hl.bind(key(d.arrow),               hl.dsp.focus({ direction = d.dir }))
    hl.bind(key(d.vim),                 hl.dsp.focus({ direction = d.dir }))
    hl.bind(key("SHIFT + " .. d.arrow), hl.dsp.window.move({ direction = d.dir }))
    hl.bind(key("SHIFT + " .. d.vim),   hl.dsp.window.move({ direction = d.dir }))
    -- Move the active window into a neighbouring group
    hl.bind(key("CTRL + " .. d.vim),    hl.dsp.window.move({ into_group = d.dir }))
end

-- Screenshot
hl.bind(key("Print"),    exec("hyprshot -m window"))
hl.bind("Print",         exec("hyprshot -m output"))
hl.bind("SHIFT + Print", exec("hyprshot -m region"))

-- Workspaces — 1-5 ultrawide, 6-0 laptop, CTRL+6-0 Dell.
-- SHIFT moves the active window instead of switching.
for i = 1, 10 do
    local k = tostring(i % 10) -- 10 maps to key 0
    hl.bind(key(k),               hl.dsp.focus({ workspace = i }))
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i }))
end
for i = 11, 15 do
    local k = tostring((i - 5) % 10) -- 11..15 map to keys 6..9, 0
    hl.bind(key("CTRL + " .. k),         hl.dsp.focus({ workspace = i }))
    hl.bind(key("CTRL + SHIFT + " .. k), hl.dsp.window.move({ workspace = i }))
end

-- Gaming workspace (Moonlight) — 16 avoids collision with Dell workspaces 11-15
hl.bind(key("F"),         hl.dsp.focus({ workspace = 16 }))
hl.bind(key("SHIFT + F"), exec("~/.config/hypr/scripts/playgame.sh"))

-- Special workspace (scratchpad)
hl.bind(key("S"),         hl.dsp.workspace.toggle_special("magic"))
hl.bind(key("SHIFT + S"), hl.dsp.window.move({ workspace = "special:magic" }))

-- Groups (stacks)
hl.bind(key("A"),            hl.dsp.group.toggle())
hl.bind(key("bracketright"), hl.dsp.group.next())
hl.bind(key("bracketleft"),  hl.dsp.group.prev())
hl.bind(key("G"),            hl.dsp.window.move({ out_of_group = true }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
local lockedRepeat = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lockedRepeat)
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      lockedRepeat)
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     lockedRepeat)
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   lockedRepeat)
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+"),                  lockedRepeat)
hl.bind("XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-"),                  lockedRepeat)

-- Requires playerctl
hl.bind("XF86AudioNext",  exec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })

-- Application launchers
hl.bind(key("B"),         exec("brave"))
hl.bind(key("SHIFT + B"), exec("brave --incognito"))
hl.bind(key("SHIFT + V"), exec("flatpak run org.videolan.VLC --no-one-instance")) -- forced new instance
