#!/bin/bash
# Toggle Kiro sidebar: show hidden, hide visible, or create new

agent_command=''

if [[ "$COMMON_PROFILE" == "WORK" ]]; then
	agent_command='kiro-cli chat --agent simba-default'
else
  agent_command='claude'
fi

if tmux list-windows -F "#W" | grep -q "^_hidden_$"; then
  tmux join-pane -h -s :_hidden_ -l 40%
else
  pane_count=$(tmux list-panes | wc -l)
  if [ "$pane_count" -gt 1 ]; then
    last_pane=$(tmux list-panes -F "#{pane_index}" | tail -1)
    tmux break-pane -d -n _hidden_ -s ":.$last_pane"
  else
    tmux split-window -h -l 40% -c "#{pane_current_path}" "bash -l -c $agent_command"
  fi
fi
