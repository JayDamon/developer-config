#!/bin/bash
# workspaces.sh — Route workspaces to active monitors based on what's connected.
# Called at Hyprland startup (exec in hyprland.conf) and by kanshi on profile switch.

sleep 0.5  # let Hyprland/kanshi settle before querying

MONITORS=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name')

has() { echo "$MONITORS" | grep -qx "$1"; }

route() {
  hyprctl keyword workspace "$1, monitor:$2" >/dev/null
}

if has "DP-2" && has "DP-3"; then
  # Desktop: ultrawide (DP-2) + vertical (DP-3)
  for ws in 1 2 3 4 5;  do route "$ws" "DP-2"; done
  for ws in 6 7 8 9 10; do route "$ws" "DP-3"; done

elif has "eDP-1"; then
  COUNT=$(echo "$MONITORS" | wc -l)
  if [ "$COUNT" -gt 1 ]; then
    # Laptop + external: external gets the main workspaces
    EXT=$(echo "$MONITORS" | grep -v "^eDP-1$" | head -1)
    for ws in 1 2 3 4 5 6 7; do route "$ws" "$EXT"; done
    for ws in 8 9 10;         do route "$ws" "eDP-1"; done
  else
    # Laptop only
    for ws in 1 2 3 4 5 6 7 8 9 10; do route "$ws" "eDP-1"; done
  fi

else
  # Unknown setup — route everything to the first available monitor
  FIRST=$(echo "$MONITORS" | head -1)
  for ws in 1 2 3 4 5 6 7 8 9 10; do route "$ws" "$FIRST"; done
fi
