#!/bin/bash

SESSION="BudgetPlanner"

tmux has-session -t $SESSION &> /dev/null

if [ $? != 0 ]; then
	echo "Starting session $SESSION"
	DIRECTORY="~/workspace/budget-planner/"
	set -- $(stty size)

	tmux new-session -d -s $SESSION -x "$2" -y "$(($1 - 1))"

#	tmux rename-window -t 1 'Backend'
#	tmux send-keys -t 'Backend' "cd $DIRECTORY" C-m 'nvim .' C-m

#	tmux new-window -t $SESSION:2 -n 'Run' -c ~/workspace/moneymaker/moneymaker-run/
#	tmux send-keys -t 'Run' 'nvim .' C-m
#	tmux split-window -h -t 'Run' -c ~/workspace/moneymaker/moneymaker-run/
#	tmux resize-pane -x 35%
#	tmux send-keys -t 'Run' 'make up' C-m 'docker ps' C-m

	tmux rename-window -t 1 'UI'
	tmux send-keys -t 'UI' "cd $DIRECTORY" C-m 'nvim .' C-m

	tmux split-window -h -t 'UI' -c ~/workspace/budget-planner/
	tmux resize-pane -x 50% 
	tmux send-keys -t 'UI' 'kill -9 $(lsof -i:3000 -t) 2> /dev/null' C-m 'npm start' C-m

	tmux select-window -t 'UI'
	tmux select-pane -t 0
fi

tmux attach -t $SESSION
