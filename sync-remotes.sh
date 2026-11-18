#!/bin/bash
# sync-remotes.sh — Rsync developer-config to remote machines over SSH.
# Reads ~/.ssh/config for hosts ending in 'r' (e.g. cloudr, biggsr).
# Saves chosen targets (and each one's sync mode) and reuses them on later runs.
#
# Sync modes:
#   full    — the whole repo (minus .git)
#   minimal — only wks-remote.sh, tmux/ and the install scripts;
#             setup-minimal.sh runs after every minimal sync to regenerate
#             ~/.tmux.conf
#
# Usage: ./sync-remotes.sh                 — sync to all saved targets (asks on first run)
#        ./sync-remotes.sh wedger cidr     — sync only these hosts ("wedge" also works)
#        ./sync-remotes.sh -r              — full: also run install.sh -r
#                                            minimal: also run install.sh -m
#                                            (installs tmux/git/vim)
#        ./sync-remotes.sh -r wedger       — sync + install on just wedger
#        ./sync-remotes.sh -R              — re-ask and update saved targets
#
# Named hosts use their saved mode. Hosts that aren't saved default to full;
# pass -m to sync them (or override saved ones) as minimal. -c is accepted
# before the host list for backwards compatibility.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_CONFIG="$HOME/.ssh/config"
TARGETS_FILE="$HOME/.config/sync-remotes-targets"

# ─── Flags ───────────────────────────────────────────────────────────────────
reconfigure=false
run_install=false
custom_minimal=false
custom_targets=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) run_install=true; shift ;;
    -R) reconfigure=true; shift ;;
    -m) custom_minimal=true; shift ;;
    -c) shift ;;   # optional; hosts can be given without it
    -*) echo "Unknown option: $1"; exit 1 ;;
    *)  custom_targets+=("$1"); shift ;;
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
MODES=()

if $custom_minimal && [ ${#custom_targets[@]} -eq 0 ]; then
  echo "-m only applies when hosts are named (saved targets carry their own mode)."
  exit 1
fi

# Saved mode for a host, or empty if it isn't in the targets file.
saved_mode() {
  [ -f "$TARGETS_FILE" ] || return 0
  awk -v h="$1" '$1 == h { print ($2 == "" ? "full" : $2); exit }' "$TARGETS_FILE"
}

if [ ${#custom_targets[@]} -gt 0 ]; then
  for name in "${custom_targets[@]}"; do
    # A bare machine name ("wedge") maps to its remote variant ("wedger").
    if echo "$ALL_HOSTS" | grep -qx "${name}r"; then
      host="${name}r"
    elif echo "$ALL_HOSTS" | grep -qx "$name"; then
      host="$name"
    else
      echo "  Warning: '$name' not found in SSH config, skipping."
      continue
    fi
    [[ " ${TARGETS[*]} " == *" $host "* ]] && continue

    mode="$(saved_mode "$host")"
    if $custom_minimal; then
      mode=minimal
    elif [ -z "$mode" ]; then
      mode=full
      echo "  Note: '$host' isn't a saved target — using full (pass -m for minimal)."
    fi
    TARGETS+=("$host")
    MODES+=("$mode")
  done

  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "No valid hosts in provided list. Exiting."
    exit 0
  fi

  echo "Using specified targets:"
  for i in "${!TARGETS[@]}"; do
    printf "  %-10s %s\n" "${TARGETS[$i]}" "${MODES[$i]}"
  done

elif [ -f "$TARGETS_FILE" ] && ! $reconfigure; then
  # Load saved targets ("host [full|minimal]"; no mode = full),
  # skipping any that no longer exist in SSH config
  while read -r host mode; do
    [ -z "$host" ] && continue
    if echo "$REMOTES" | grep -qx "$host"; then
      TARGETS+=("$host")
      MODES+=("${mode:-full}")
    else
      echo "  Warning: saved host '$host' not found in SSH config, skipping."
    fi
  done < "$TARGETS_FILE"

  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "No valid saved targets. Run with -R to reconfigure."
    exit 0
  fi

  echo "Using saved targets:"
  for i in "${!TARGETS[@]}"; do
    printf "  %-10s %s\n" "${TARGETS[$i]}" "${MODES[$i]}"
  done
  echo "(Run with -R to change.)"
else
  # Ask for each discovered host and save the result
  for host in "${REMOTE_ARRAY[@]}"; do
    read -rp "  Sync to '$host'? (f)ull / (m)inimal / (n)o: " ans
    case "$ans" in
      f|full|y) TARGETS+=("$host"); MODES+=(full) ;;
      m|minimal) TARGETS+=("$host"); MODES+=(minimal) ;;
    esac
  done

  if [ ${#TARGETS[@]} -eq 0 ]; then
    echo ""
    echo "No hosts selected. Exiting."
    exit 0
  fi

  mkdir -p "$(dirname "$TARGETS_FILE")"
  for i in "${!TARGETS[@]}"; do
    echo "${TARGETS[$i]} ${MODES[$i]}"
  done > "$TARGETS_FILE"
  echo ""
  echo "Saved targets to $TARGETS_FILE"
fi

# ─── Sync ────────────────────────────────────────────────────────────────────
# A failure on one host is reported and the loop moves on to the next host.
failed=()
skipped=()
fail() { echo "  ✗ $1 failed on $host — continuing with the next host."; failed+=("$host ($1)"); }

echo ""
for i in "${!TARGETS[@]}"; do
  host="${TARGETS[$i]}"
  mode="${MODES[$i]}"
  echo "────────────────────────────────────────────"
  echo "Syncing to $host ($mode)..."

  if ! timeout 5 ssh -o ConnectTimeout=5 "$host" true 2>/dev/null; then
    echo "  Skipping $host — could not connect (offline or sleeping)."
    skipped+=("$host")
    continue
  fi

  ssh "$host" 'mkdir -p ~/workplace/developer-config' || { fail "mkdir"; continue; }

  if [ "$mode" = minimal ]; then
    # Only the pieces needed for wks sessions + tmux. Excluded paths are
    # never deleted, so a host that used to get a full sync keeps its old files.
    rsync -az --delete \
      --include='/wks-remote.sh' \
      --include='/install.sh' \
      --include='/install-software.sh' \
      --include='/setup-minimal.sh' \
      --include='/tmux/***' \
      --exclude='*' \
      "$SCRIPT_DIR/" \
      "$host:~/workplace/developer-config/" || { fail "rsync"; continue; }

    if $run_install; then
      echo "Running install.sh -m on $host..."
      ssh -t "$host" 'bash ~/workplace/developer-config/install.sh -m' || { fail "install.sh -m"; continue; }
    else
      ssh "$host" 'bash ~/workplace/developer-config/setup-minimal.sh' || { fail "setup-minimal.sh"; continue; }
    fi
  else
    rsync -az --delete \
      --exclude='.git' \
      "$SCRIPT_DIR/" \
      "$host:~/workplace/developer-config/" || { fail "rsync"; continue; }

    if $run_install; then
      echo "Running install.sh -r on $host..."
      ssh -t "$host" 'bash ~/workplace/developer-config/install.sh -r' || { fail "install.sh -r"; continue; }
    fi
  fi

  echo "Done: $host"
done

echo ""
echo "════════════════════════════════════════════"
echo " Sync complete."
echo "════════════════════════════════════════════"
[ ${#skipped[@]} -gt 0 ] && echo " Skipped (unreachable): ${skipped[*]}"
if [ ${#failed[@]} -gt 0 ]; then
  echo " Failed:"
  printf '   %s\n' "${failed[@]}"
  exit 1
fi
exit 0
