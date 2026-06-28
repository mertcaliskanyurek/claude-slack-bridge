const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const { App } = require('@slack/bolt');
const { exec } = require('child_process');

const args = process.argv.slice(2);
const sessionIndex = args.indexOf('--session');
const TMUX_SESSION = (sessionIndex !== -1 && args[sessionIndex + 1]) || "gsd-session";

console.log(`Using Tmux Session: ${TMUX_SESSION}`);

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,    // xoxb-...
  appToken: process.env.SLACK_APP_TOKEN, // xapp-...
  socketMode: true
});

app.command('/claude', async ({ command, ack, say }) => {
  await ack();
  const message = command.text;
  let pasteCmd = '';

  if (message.startsWith('enter')) {
    exec(`tmux send-keys -t ${TMUX_SESSION}.1 C-m`, (enterErr) => {
      if (enterErr) console.error("Enter key failed");
    });
    return;
  }

  if (message.startsWith('select')) {
    const selection = message.slice(7);
    exec(`tmux send-keys -t ${TMUX_SESSION}.1 C-c "${selection}"`, (selectErr) => {
      if (selectErr) console.error("Selection command failed");
    });
    return;
  }
  
  if(message.startsWith('exec')) {
    const command = message.slice(5);
    pasteCmd = `tmux send-keys -t ${TMUX_SESSION}.1 C-c "${command}"`;
  } else {
    pasteCmd = `tmux send-keys -t ${TMUX_SESSION}.1 C-c "/p \\"${message}\\""`;
  }

  // 3. The "Double Tap" Execution
  exec(pasteCmd, (err) => {
    if (err) return say(`❌ Paste Error: ${err.message}`);

    // We wait 200ms for the terminal to "digest" the long string
    setTimeout(() => {
      exec(`tmux send-keys -t ${TMUX_SESSION}.1 C-m`, (enterErr) => {
        if (enterErr) console.error("Enter key failed");
      });
    }, 200);

    say(`🤖 *Claude is processing:* "${message}"`);
  });
});

(async () => {
  await app.start();
  console.log('⚡️ Claude GSD Bridge is live in Socket Mode!');
})();
