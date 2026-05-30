#!/bin/bash
# sync-remotes.sh — Rsync developer-config to remote machines over SSH.
# Reads ~/.ssh/config for hosts ending in 'r' (e.g. cloudr, biggsr).
# Saves chosen targets and reuses them on subsequent runs.
# Usage: ./sync-remotes.sh              — sync to saved targets (asks on first run)
#        ./sync-remotes.sh -r           — sync then run install.sh -r on each machine
#        ./sync-remotes.sh -R           — re-ask and update saved targets
#        ./sync-remotes.sh -c h1 h2     — sync to specific hosts
#        ./sync-remotes.sh -r -c h1 h2  — sync + install on specific hosts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_CONFIG="$HOME/.ssh/config"
TARGETS_FILE="$HOME/.config/sync-remotes-targets"

# ─── Flags ───────────────────────────────────────────────────────────────────
reconfigure=false
run_install=false
custom_targets=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) run_install=true; shift ;;
    -R) reconfigure=true; shift ;;
    -c) shift
        while [[ $# -gt 0 && "$1" != -* ]]; do
          custom_targets+=("$1")
          shift
        done
        ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ─── Parse SSH config ─────────────────────────────────────────────────────────
if [ ! -f "$SSH_CONFIG" ]; then
  echo "No SSH config found at $SSH_CONFIG"
  exit 1
fi

REMOTES=$(grep "^Host " "$SSH_CONFIG" \
  | sed 's/^Host //' \
  | tr ' ' '\n' \
  | grep -v '[*?]' \
  | grep 'r$' \
  | sort -u)

if [ -z "$REMOTES" ]; then
  echo "No hosts ending in 'r' found in $SSH_CONFIG"
  exit 0
fi

mapfile -t REMOTE_ARRAY <<< "$REMOTES"

# ─── Target Selection ─────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
echo " Sync developer-config to remote machines"
echo "════════════════════════════════════════════"
echo ""

# All hosts in SSH config (used to validate -c targets)
ALL_HOSTS=$(grep "^Host " "$SSH_CONFIG" \
  | sed 's/^Host //' \
  | tr ' ' '\n' \
  | grep -v '[*?]' \
  | sort -u)

TARGETS=()

if [ ${#custom_targets[@]} -gt 0 ]; then
  # Validate each specified host against SSH config
  for host in "${custom_targets[@]}"; do
    if echo "$ALL_HOSTS" | grep -qx "$host"; then
      TARGETS+=("$host")
    else
      echo "  Warning: '$host' not found in SSH config, skipping."
    fi
  done

  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "No valid hosts in provided list. Exiting."
    exit 0
  fi

  echo "Using specified targets: ${TARGETS[*]}"

elif [ -f "$TARGETS_FILE" ] && ! $reconfigure; then
  # Load saved targets, silently skip any that no longer exist in SSH config
  while IFS= read -r host; do
    if echo "$REMOTES" | grep -qx "$host"; then
      TARGETS+=("$host")
    else
      echo "  Warning: saved host '$host' not found in SSH config, skipping."
    fi
  done < "$TARGETS_FILE"

  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "No valid saved targets. Run with -r to reconfigure."
    exit 0
  fi

  echo "Using saved targets: ${TARGETS[*]}"
  echo "(Run with -r to change.)"
else
  # Ask for each discovered host and save the result
  for host in "${REMOTE_ARRAY[@]}"; do
    read -rp "  Sync to '$host'? (y/n): " ans
    [[ "$ans" == "y" ]] && TARGETS+=("$host")
  done

  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo ""
    echo "No hosts selected. Exiting."
    exit 0
  fi

  mkdir -p "$(dirname "$TARGETS_FILE")"
  printf '%s\n' "${TARGETS[@]}" > "$TARGETS_FILE"
  echo ""
  echo "Saved targets to $TARGETS_FILE"
fi

# ─── Sync ────────────────────────────────────────────────────────────────────
echo ""
for host in "${TARGETS[@]}"; do
  echo "────────────────────────────────────────────"
  echo "Syncing to $host..."

  if ! timeout 5 ssh -o ConnectTimeout=5 "$host" true 2>/dev/null; then
    echo "  Skipping $host — could not connect (offline or sleeping)."
    continue
  fi

  ssh "$host" 'mkdir -p ~/workplace/developer-config'

  rsync -az --delete \
    --exclude='.git' \
    "$SCRIPT_DIR/" \
    "$host:~/workplace/developer-config/"

  if $run_install; then
    echo "Running install.sh -r on $host..."
    ssh -t "$host" 'bash ~/workplace/developer-config/install.sh -r'
  fi

  echo "Done: $host"
done

echo ""
echo "════════════════════════════════════════════"
echo " Sync complete."
echo "════════════════════════════════════════════"
