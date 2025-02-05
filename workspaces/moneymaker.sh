#!/bin/bash

SESSION="MoneyMaker"

tmux has-session -t $SESSION &> /dev/null

if [ $? != 0 ]; then
	echo "Starting session $SESSION"
	DIRECTORY="~/workspace/moneymaker/"
	set -- $(stty size)

	tmux new-session -d -s $SESSION -x "$2" -y "$(($1 - 1))"

	tmux rename-window -t 1 'Backend'
	tmux send-keys -t 'Backend' "cd $DIRECTORY" C-m 'nvim .' C-m

	tmux new-window -t $SESSION:2 -n 'Run' -c ~/workspace/moneymaker/moneymaker-run/
	tmux send-keys -t 'Run' 'nvim .' C-m
	tmux split-window -h -t 'Run' -c ~/workspace/moneymaker/moneymaker-run/
	tmux resize-pane -x 35%
	tmux send-keys -t 'Run' 'make up' C-m 'docker ps' C-m

	tmux new-window -t $SESSION:3 -n 'React UI' -c ~/workspace/moneymaker/moneymaker-react-client/
	tmux send-keys -t 'React UI' 'nvim .' C-m
	tmux split-window -h -t 'React UI' -c ~/workspace/moneymaker/moneymaker-run/ 
	tmux resize-pane -x 25% 
	tmux send-keys -t 'React UI' 'kill -9 $(lsof -i:3000 -t) 2> /dev/null' C-m 'make start_react' C-m

	tmux select-window -t 'Backend'
fi

tmux attach -t $SESSION
