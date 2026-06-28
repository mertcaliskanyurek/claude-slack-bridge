#!/bin/bash
# Default values
SESSION="tmux-session"
PROJECT_PATH="ProjectPath"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) SESSION="$2"; shift ;;
        --project) PROJECT_PATH="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "Starting session: $SESSION"
echo "Project Path: $PROJECT_PATH"

# Start session
tmux new-session -d -s $SESSION

# Create Panes
tmux split-window -h -t $SESSION     # Split for Bridge


# 1. Start the Bridge Server
tmux send-keys -t $SESSION.0 "node scripts/slack_bridge.js --session $SESSION" C-m

# 2. Start Claude (Auto-approve mode)
tmux send-keys -t $SESSION.1 "cd $PROJECT_PATH && claude --dangerously-skip-permissions" C-m

# Final View
tmux attach-session -t $SESSION