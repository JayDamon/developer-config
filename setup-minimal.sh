#!/bin/bash
# setup-minimal.sh — Minimal setup for machines that only get the minimal sync
# (wks-remote.sh + tmux), e.g. Raspberry Pi k8s nodes. Non-interactive; safe
# to rerun on every sync. Install the packages first with: install.sh -m

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

if ! command -v tmux &>/dev/null; then
  echo "tmux not installed — run install.sh -m (or sync-remotes.sh -r). Skipping."
  exit 0
fi

# These machines are reached through wks (outer tmux), so default to Ctrl+B
# unless a prefix was already chosen on this machine.
bash "$DOTFILES/tmux/setup-tmux.sh" "^B"

# Install TPM plugins (resurrect, continuum, …) by cloning them directly.
# TPM's own install_plugins needs a running tmux server, which these headless
# machines usually don't have during setup.
grep -oE "^set -g @plugin '[^']+'" ~/.tmux.conf | sed -E "s/.*'(.+)'/\1/" | while read -r plugin; do
  dir=~/.tmux/plugins/"${plugin##*/}"
  if [ ! -d "$dir" ]; then
    echo "Installing tmux plugin $plugin..."
    git clone -q "https://github.com/$plugin" "$dir"
  fi
done

echo "Minimal setup done."
