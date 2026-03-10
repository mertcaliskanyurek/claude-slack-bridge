#!/usr/bin/env bash

# Default values
SESSION="tmux-session"
CHANNEL="C0AJCQPUNNM"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --session) SESSION="$2"; shift ;;
        --channel) CHANNEL="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "Sending update for session: $SESSION to channel: $CHANNEL"

# 2. Load .env
ENV_PATH="$(dirname "$0")/.env"
if [ -f "$ENV_PATH" ]; then
    # Load variables and export them
    set -a
    source "$ENV_PATH"
    set +a
else
    echo "❌ Error: .env file not found at $ENV_PATH"
    exit 1
fi

if [ -z "$SLACK_BOT_TOKEN" ]; then
    echo "❌ Error: SLACK_BOT_TOKEN not found in .env"
    exit 1
fi

# 3. Capture the last 20 lines of Claude's output
# We use .0 to target the first pane (where Claude resides)
CONTEXT=$(tmux capture-pane -pt "$SESSION.0" -S -20)

# 4. Use jq to build the JSON safely
PAYLOAD=$(jq -n \
  --arg msg "✅ *Claude is waiting for your input*" \
  --arg ctx "$CONTEXT" \
  --arg channel "$CHANNEL" \
  '{channel: $channel, text: ($msg + "\n```\n" + $ctx + "\n```")}')

# 6. Send Message to Slack
curl -s -X POST "https://slack.com/api/chat.postMessage" \
     -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "$PAYLOAD"