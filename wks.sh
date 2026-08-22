#!/bin/bash
# wks.sh — Open a tmux workspace with SSH windows to all dev machines.
# Auto-detects home vs away by probing local hosts; use -r to force away mode.
#
# Home:  squall  cloud
# Away:  squallr cloudr

SESSION="wks"

# Window names stay consistent regardless of home/away
# NAMES=(squall cloud biggs wedge)
# LOCAL_HOSTS=(squall cloud biggs wedge)
# REMOTE_HOSTS=(squallr cloudr biggsr wedger)
NAMES=(squall cloud cid)
LOCAL_HOSTS=(squall cloud cid)
REMOTE_HOSTS=(squallr cloudr cidr)

# ─── Flags ───────────────────────────────────────────────────────────────────
force_remote=false
while getopts ":r" opt; do
  case "$opt" in
    r) force_remote=true ;;
  esac
done

# ─── Home/Away Detection ─────────────────────────────────────────────────────
if $force_remote; then
  HOSTS=("${REMOTE_HOSTS[@]}")
  echo "Away mode — using remote hostnames"
elif timeout 3 ssh -o ConnectTimeout=3 "${LOCAL_HOSTS[0]}" true 2>/dev/null; then
  HOSTS=("${LOCAL_HOSTS[@]}")
  echo "Home mode — using local hostnames"
else
  HOSTS=("${REMOTE_HOSTS[@]}")
  echo "Away mode — using remote hostnames (auto-detected)"
fi

# ─── Attach if session already exists ────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux attach-session -t "$SESSION"
  exit 0
fi

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
  ssh -t "${host}" 'bash -l ~/workplace/developer-config/wks-remote.sh'
  echo ""
  echo "[${name}] Connection closed. Press Enter to reconnect or Ctrl+C to exit."
  read
done
EOF
  echo "$script"
}

# ─── Create session ───────────────────────────────────────────────────────────
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
