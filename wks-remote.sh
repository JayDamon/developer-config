#!/bin/bash
# wks-remote.sh — Attach to or create a tmux session named after this machine.
# Invoked by wks.sh on the local machine via SSH.

SESSION=$(hostname -s)

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux attach-session -t "$SESSION"
else
  tmux new-session -s "$SESSION"
fi
