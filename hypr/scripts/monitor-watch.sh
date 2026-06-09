#!/bin/bash
# monitor-watch.sh — Listen to Hyprland socket events and re-route workspaces
# whenever a monitor is connected or disconnected.
# Run via exec-once in hyprland.conf.

SOCKET="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
[ ! -S "$SOCKET" ] && SOCKET="/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

socat - "UNIX-CONNECT:${SOCKET}" | while IFS= read -r line; do
  case "$line" in
    monitoradded*|monitorremoved*)
      ~/.config/hypr/scripts/workspaces.sh
      ;;
  esac
done
