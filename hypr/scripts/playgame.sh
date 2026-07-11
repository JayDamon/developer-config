#!/bin/bash
# playgame.sh — Wake gaming PC, ensure Desktop Mode, and launch Moonlight.
# Mapped to $mainMod SHIFT, F in keybinds.conf.

MOONLIGHT_CONF="$HOME/.config/Moonlight Game Streaming Project/Moonlight.conf"
BAZZITE="gaming"
SSH_OPTS="-o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5"

# Set stream resolution and bitrate based on which monitor is active
ULTRAWIDE=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.model | test("C49RG9"; "i")) | .name' | head -1)

if [ -n "$ULTRAWIDE" ]; then
  W=5120; H=1440; BITRATE=150000   # 32:9 native via virtual display on gaming PC
  VIDEOCFG=4                       # Force AV1 Codec
  VIDEODEC=1                       # Force Hardware Decoding
  VSYNC=true                       # Maintain uniform frame pacing on 60Hz display
	HDR=true
else
  W=1920; H=1080; BITRATE=20000    # laptop screen
  VIDEOCFG=0                       # Auto Codec
  VIDEODEC=1                       # Force Hardware Decoding
  VSYNC=true                       # Laptop display sync
	HDR=true
fi

sed -i "s/^width=.*/width=$W/"         "$MOONLIGHT_CONF"
sed -i "s/^height=.*/height=$H/"       "$MOONLIGHT_CONF"
sed -i "s/^bitrate=.*/bitrate=$BITRATE/" "$MOONLIGHT_CONF"
sed -i "s/^videocfg=.*/videocfg=$VIDEOCFG/" "$MOONLIGHT_CONF"
sed -i "s/^videodec=.*/videodec=$VIDEODEC/" "$MOONLIGHT_CONF"
sed -i "s/^vsync=.*/vsync=$VSYNC/"       "$MOONLIGHT_CONF"
sed -i "s/^hdr=.*/hdr=$HDR/"             "$MOONLIGHT_CONF"

# Wake gaming PC
ssh -n $SSH_OPTS router "ether-wake -i br0 10:FF:E0:B8:1F:AD"

# Wait for Bazzite to accept SSH connections
until ssh -n $SSH_OPTS $BAZZITE "true" 2>/dev/null; do
  sleep 2
done

# # If gamescope is running, Bazzite is in Game Mode — switch to Desktop Mode
# if ssh -n $SSH_OPTS $BAZZITE "pgrep gamescope" &>/dev/null; then
#   ssh -n $SSH_OPTS $BAZZITE "steamos-session-select desktop"
#   # Session restarts — wait for SSH to come back, then wait for Sunshine to be ready
#   sleep 3
#   until ssh -n $SSH_OPTS $BAZZITE "true" 2>/dev/null; do
#     sleep 2
#   done
#   until ssh -n $SSH_OPTS $BAZZITE "pgrep sunshine" &>/dev/null; do
#     sleep 2
#   done
# fi
#
# # Set virtual display resolution, then restart Sunshine so it re-detects cleanly
# ssh -n $SSH_OPTS $BAZZITE "kscreen-doctor output.DP-1.mode.5120x1440@60" 2>/dev/null
# ssh -n $SSH_OPTS $BAZZITE "systemctl --user restart app-dev.lizardbyte.app.Sunshine.service"
# until ssh -n $SSH_OPTS $BAZZITE "pgrep sunshine" &>/dev/null; do
#   sleep 2
# done
#
# # Ensure Steam is running on Bazzite (window rule keeps it on the TV)
# ssh -n $SSH_OPTS $BAZZITE "pgrep steam &>/dev/null || systemd-run --user --no-block -- steam"

moonlight &
hyprctl dispatch workspace 16
