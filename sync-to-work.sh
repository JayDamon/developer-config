#!/bin/bash
# Sync shared config FROM developer-config TO Jaydamo-dotfiles
# Run from the developer-config repo root
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/workplace/Jaydamo-dotfiles"

if [ ! -d "$DEST" ]; then
  echo "Error: $DEST not found"
  exit 1
fi

echo "Syncing: developer-config → Jaydamo-dotfiles"

# Shared directories
for dir in nvim tmux shell git; do
  rsync -av --delete \
    --exclude='.shell_work' \
    --exclude='.shell_home' \
    "$SRC/$dir/" "$DEST/$dir/"
done

# Top-level shared files
cp "$SRC/install.sh" "$DEST/install.sh"

echo "Done. Review changes in $DEST with 'git diff'"
