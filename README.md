# Claude Automation Integration

This project provides a set of scripts to seamlessly connect **Claude Code** to **Slack**, allowing you to completely automate and interact with the Claude CLI remotely via Slack commands and notifications.

## Overview

The automation tool spins up a `tmux` session with two panes:
1. **Slack Bridge (`scripts/slack_bridge.js`)**: A Node.js bot running in Socket Mode that listens for the `/claude` slash command on Slack and passes your prompts directly to Claude.
2. **Claude Code CLI**: Running in your target project directory with auto-approve mode enabled (`--dangerously-skip-permissions`). !! BE CAREFUL WITH THIS FLAG !! It allows Claude to make changes to your project without your explicit approval. If you run claude on your personal machine, do not use this flag. Use it only on your work machine where you have a backup of your project and only dev enviorement.

Once Claude completes a task or needs intervention, the included hooks script (`notify_channel.sh`) captures the latest terminal output and sends a notification right back to your designated Slack channel.

## Prerequisites

- **Tools**: `tmux`, `jq`, `curl`
- **Node.js**: Required to run the Slack bridge (`@slack/bolt` and `dotenv`).
- **Claude Code CLI**: Properly installed and authenticated.
- **Slack App**:
  - Socket Mode enabled.
  - Slack slash command `/claude` configured.
  - Scopes to post messages to channels.

## Setup & Configuration

### 1. Environment Variables (.env)

In the root of the `ClaudeAutomation` directory, configure your `.env` file with your Slack API tokens:

```env
SLACK_BOT_TOKEN="xoxb-your-bot-token"
SLACK_APP_TOKEN="xapp-your-app-token"
```

### 2. Install Node Dependencies

Make sure to install the required Node.js dependencies for the slack bridge:
```bash
npm install @slack/bolt dotenv
```

### 3. Project Configuration (Very Important)

To enable Claude to automatically notify your Slack channel when it finishes doing work or stops, you **must** configure webhooks in your target project.

In the project where you will run Claude, create or edit the file `.claude/settings.local.json` and insert the following hooks configuration:

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/ClaudeAutomation/notify_channel.sh --session session_name --channel channel_id"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/ClaudeAutomation/notify_channel.sh --session session_name --channel channel_id"
          }
        ]
      }
    ]
  }
}
```
*Note: Make sure to replace `session_name` with the exact name of your tmux session, and `channel_id` with the actual ID of your targeted Slack channel (e.g. `C0123456789`).*

## Usage

### 1. Starting the Automation Session

To spin up the bridge and Claude together, use the startup script:

```bash
./start_tmux_session.sh --name "session_name" --project "/path/to/your/project"
```
- `--name`: The name for your tmux session. Ensure this matches what you used in the hooks settings!
- `--project`: The absolute path to the directory that Claude should work in.

*This script will launch the tmux session in the background and attach you to it.*

### 2. Interacting with Claude via Slack

Once running, you can orchestrate tasks directly from Slack:

- Just go to Slack and type:
  ```
  /claude "Refactor the authentication logic in src/auth.js"
  ```
- The bridge will pick up the command, inject it into Claude's tmux pane, and execute it. 
- You do not need to hit approve because the session runs with `--dangerously-skip-permissions`.
- When Claude halts (due to completion or an error), the hook will trigger `notify_channel.sh`, taking the last 20 lines of the terminal context and posting it straight into your Slack channel so you know what happened.

## Architecture & Files

- `start_tmux_session.sh`: Uses `tmux` to split the screen and spin up Node (`slack_bridge.js`) and Claude CLI parallelly.
- `notify_channel.sh`: Fetches the last 20 lines of Claude's terminal view (`tmux capture-pane`) and posts a formatted message to Slack using `curl` and `jq`.
- `scripts/slack_bridge.js`: Uses `@slack/bolt` in socket mode. Escapes your input and injects the payload by sending keystrokes directly into the `tmux` pane.
