#!/bin/bash
# workspaces.sh — Route workspaces to active monitors based on what's connected.
# Detects monitors by model name so connector changes (DP-2 vs DP-5) don't matter.
# Called at Hyprland startup and by monitor-watch.sh on hotplug events.

sleep 0.5  # let Hyprland settle before querying

MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)

ULTRAWIDE=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.model | test("C49RG9"; "i")) | .name' | head -1)
DELL=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.model | test("U2715H"; "i")) | .name' | head -1)
LAPTOP=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.name == "eDP-1") | .name' | head -1)

route() {
  local ws=$1 mon=$2
  # Set the default binding for future workspace creation
  hyprctl keyword workspace "$ws, monitor:$mon" >/dev/null
  # Also move the workspace if it already exists (e.g. on hotplug with open windows)
  hyprctl dispatch moveworkspacetomonitor "$ws $mon" >/dev/null 2>&1 || true
}

if [ -n "$ULTRAWIDE" ]; then
  for ws in 1 2 3 4 5; do route "$ws" "$ULTRAWIDE"; done
  route 16 "$ULTRAWIDE"  # gaming workspace always on primary

  if [ -n "$DELL" ]; then
    for ws in 11 12 13 14 15; do route "$ws" "$DELL"; done
    # laptop or ultrawide gets 6-10 when Dell is also present
    OTHER="${LAPTOP:-$ULTRAWIDE}"
    for ws in 6 7 8 9 10; do route "$ws" "$OTHER"; done
  elif [ -n "$LAPTOP" ]; then
    for ws in 6 7 8 9 10; do route "$ws" "$LAPTOP"; done
  else
    for ws in 6 7 8 9 10; do route "$ws" "$ULTRAWIDE"; done
  fi
else
  if [ -n "$LAPTOP" ] && [ -n "$DELL" ]; then
    for ws in 1 2 3 4 5; do route "$ws" "$LAPTOP"; done
    for ws in 6 7 8 9 10 11 12 13 14 15 16; do route "$ws" "$DELL"; done
  else
    ONLY="${LAPTOP:-$DELL}"
    [ -z "$ONLY" ] && ONLY=$(echo "$MONITORS_JSON" | jq -r '.[0].name')
    for ws in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do route "$ws" "$ONLY"; done
  fi
fi
