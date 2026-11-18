#!/bin/bash
# wks.sh — Open a tmux workspace with SSH windows to dev machines.
#
# Usage:
#   wks              — default workspace "wks" (squall cloud cid); remote tmux
#                      sessions are named after each machine's hostname.
#   wks <name>       — workspace/profile <name>. Local tmux session and the
#                      tmux session on every remote machine are named <name>.
#                      If wks-profiles/<name> doesn't exist yet, you're asked
#                      which machines to include and the profile is saved.
#   -r               — force away mode (use the "<host>r" SSH configs).
#
# Each machine is probed individually: if its local SSH config is reachable it
# is used, otherwise its remote "<host>r" variant is used.

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/wks-profiles"

ALL_MACHINES=(squall gaming cloud biggs wedge bastion cid)
DEFAULT_MACHINES=(squall cloud cid)

# ─── Args ────────────────────────────────────────────────────────────────────
force_remote=false
profile=""
for arg in "$@"; do
  case "$arg" in
    -r) force_remote=true ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown option: $arg"; exit 1 ;;
    *)
      if [[ -n "$profile" ]]; then
        echo "Only one workspace name may be given."; exit 1
      fi
      profile="$arg"
      ;;
  esac
done

if [[ -n "$profile" && ! "$profile" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Invalid name '$profile' — use letters, numbers, '-' or '_'."
  exit 1
fi

# ─── Resolve session name + machines ────────────────────────────────────────
if [[ -z "$profile" ]]; then
  SESSION="wks"
  REMOTE_SESSION=""          # empty → remote uses its hostname
  NAMES=("${DEFAULT_MACHINES[@]}")
else
  SESSION="$profile"
  REMOTE_SESSION="$profile"
fi

# Attach straight away if the local session is already running.
if tmux has-session -t "=$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "=$SESSION"
fi

is_known_machine() {
  local m
  for m in "${ALL_MACHINES[@]}"; do [[ "$m" == "$1" ]] && return 0; done
  return 1
}

if [[ -n "$profile" ]]; then
  profile_file="$PROFILE_DIR/$profile"
  if [[ -f "$profile_file" ]]; then
    # One machine per line (spaces also accepted); '#' starts a comment.
    read -r -a NAMES <<< "$(sed 's/#.*//' "$profile_file" | tr '\n' ' ')"
    if [[ ${#NAMES[@]} -eq 0 ]]; then
      echo "Profile '$profile' ($profile_file) lists no machines."; exit 1
    fi
    echo "Loaded profile '$profile': ${NAMES[*]}"
  else
    echo "No profile named '$profile' yet. Available machines:"
    for i in "${!ALL_MACHINES[@]}"; do
      printf "  %d) %s\n" "$((i + 1))" "${ALL_MACHINES[$i]}"
    done
    while true; do
      read -r -p "Machines for '$profile' (space separated names or numbers): " -a picks
      NAMES=()
      bad=""
      for p in "${picks[@]}"; do
        if [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= ${#ALL_MACHINES[@]} )); then
          p="${ALL_MACHINES[$((p - 1))]}"
        fi
        if is_known_machine "$p"; then
          [[ " ${NAMES[*]} " == *" $p "* ]] || NAMES+=("$p")
        else
          bad+=" $p"
        fi
      done
      if [[ -n "$bad" ]]; then
        echo "Unknown machine(s):$bad"
      elif [[ ${#NAMES[@]} -eq 0 ]]; then
        echo "Pick at least one machine."
      else
        break
      fi
    done
    mkdir -p "$PROFILE_DIR"
    printf "%s\n" "${NAMES[@]}" > "$profile_file"
    echo "Saved profile '$profile' → $profile_file"
  fi
fi

# ─── Home/Away detection (per machine, in parallel) ──────────────────────────
PROBE_TMP="$(mktemp -d /tmp/wks-probe-XXXX)"
if ! $force_remote; then
  for name in "${NAMES[@]}"; do
    (
      if timeout 4 ssh -o ConnectTimeout=3 -o BatchMode=yes "$name" true 2>/dev/null; then
        touch "$PROBE_TMP/$name"
      fi
    ) &
  done
  wait
fi

HOSTS=()
for name in "${NAMES[@]}"; do
  if [[ -e "$PROBE_TMP/$name" ]]; then
    HOSTS+=("$name");  echo "  $name → local"
  else
    HOSTS+=("${name}r"); echo "  $name → remote (${name}r)"
  fi
done
rm -rf "$PROBE_TMP"

# ─── Build per-window scripts ────────────────────────────────────────────────
# Write each window's loop to a temp script to avoid nested quoting issues.
# The scripts are deleted after tmux attaches (bash has already read them in).
WKS_TMP="$(mktemp -d /tmp/wks-XXXX)"

make_window_script() {
  local host="$1" name="$2"
  local script="$WKS_TMP/${name}.sh"
  cat > "$script" << EOF
#!/bin/bash
while true; do
  ssh -t "${host}" 'bash -l ~/workplace/developer-config/wks-remote.sh ${REMOTE_SESSION}'
  echo ""
  echo "[${name}] Connection closed. Press Enter to reconnect or Ctrl+C to exit."
  read
done
EOF
  echo "$script"
}

# ─── Create session ──────────────────────────────────────────────────────────
script=$(make_window_script "${HOSTS[0]}" "${NAMES[0]}")
tmux new-session -d -s "$SESSION" -n "${NAMES[0]}" "bash $script"

for i in "${!NAMES[@]}"; do
  [[ $i -eq 0 ]] && continue
  script=$(make_window_script "${HOSTS[$i]}" "${NAMES[$i]}")
  tmux new-window -t "${SESSION}:" -n "${NAMES[$i]}" "bash $script"
done

tmux new-window -t "${SESSION}:" -n "local" -c "$PWD"

tmux select-window -t "${SESSION}:${NAMES[0]}"
tmux attach-session -t "$SESSION"

rm -rf "$WKS_TMP"
