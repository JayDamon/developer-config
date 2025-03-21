#!/bin/bash

SESSION="httpserver"

tmux has-session -t $SESSION &> /dev/null

if [ $? != 0 ]; then

	echo "Starting session $SESSION"
	DIRECTORY="~/workspace/http-server/"
	set -- $(stty size)

	tmux new-session -d -s $SESSION -x "$2" -y "$(($1 - 1))"

	tmux rename-window -t 1 -n 'httpserver' -c 
	tmux send-keys -t 'httpserver' "cd ~/workspace/http-server/server/" C-m 'nvim .' C-m
	tmux split-window -h -t 'httpserver' -c ~/workspace/http-server/client/
	tmux send-keys -t 'httpserver' 'nvim .' C-m

	tmux select-pane -L

fi

tmux attach -t $SESSION
