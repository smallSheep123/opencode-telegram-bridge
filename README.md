# OpenCode Telegram Bridge

[简体中文](docs/README.zh-CN.md) · [Architecture](docs/ARCHITECTURE.md) · [Security](SECURITY.md)

A local, Windows-first bridge between OpenCode Desktop and Telegram. It sends completion notifications for every OpenCode session and lets one authorized Telegram account browse sessions, inspect progress, send prompts, and run sequential prompt queues.

## Highlights

- Completion and error notifications for every OpenCode session.
- Paginated session browser with title and project-path search.
- Per-session sequential queues with `/add` and multiline `/batch` input.
- Queue recovery after bridge or OpenCode restarts.
- Duplicate completion suppression and queue-safe event correlation.
- Queue progress notifications with position, duration, remaining work, and next prompt.
- One-user private-chat authorization using Telegram user and chat IDs.
- Windows DPAPI protection for the Telegram token and OpenCode's temporary local credential.
- Loopback-only OpenCode access. The bridge opens no inbound port.
- No VPS, VPN, reverse proxy, webhook, or third-party relay required.

## Requirements

- Windows 10 or Windows 11.
- OpenCode Desktop.
- Node.js 20 or newer available as `node.exe`.
- A Telegram bot created with [@BotFather](https://t.me/BotFather).

The current release is designed for OpenCode Desktop's local session API and global plugin directory. OpenCode updates may change these interfaces; run the included doctor command after upgrading OpenCode.

## Installation

1. Download or clone this repository.
2. Double-click `Bridge-Manager.cmd`.
3. Choose option `1` (`首次配置并启动`, first-time setup and start).
4. Paste the BotFather token when prompted.
5. Send `/start` to the bot, return to the setup window, and confirm the detected Telegram account.
6. Restart OpenCode Desktop once so the global plugin is loaded.
7. Send `/sessions` to the bot.

The setup process:

- copies the OpenCode plugin to `%USERPROFILE%\.config\opencode\plugins\telegram-bridge.js`;
- stores encrypted configuration under `%USERPROFILE%\.config\opencode\telegram-bridge`;
- restricts that directory to the current user, SYSTEM, and local administrators;
- registers the **OpenCode Telegram Bridge** scheduled task for logon startup.

## Telegram commands

| Command | Purpose |
|---|---|
| `/sessions` | Show the first page of sessions |
| `/sessions 2` | Show a specific session page |
| `/find keyword` | Search session titles and project paths |
| `/use 1` | Select an item from the current page |
| `/current` | Show the selected session |
| `/show` | Show status, worktree summary, todos, and the latest reply |
| `/send prompt` | Send one prompt immediately |
| `/add prompt` | Append one prompt to the selected session queue |
| `/batch` | Add multiple prompts separated by a line containing `---` |
| `/queue` | Show the active and waiting queue |
| `/remove 2` | Remove a waiting queue item |
| `/pause` | Pause automatic queue progression |
| `/resume` | Resume automatic queue progression |
| `/clearqueue` | Clear waiting items after confirmation |
| `/stop` | Stop the active session task after confirmation |
| `/health` | Show Telegram, OpenCode, plugin, session, queue, and error health |
| `/status` | Show a compact bridge status |
| `/help` | Show command help |

Batch example:

```text
/batch
Inspect the failing tests
---
Fix the root cause and rerun the tests
---
Write a short maintenance note
```

Each prompt starts only after the previous prompt reaches a completion event. The bot sends a completion message before starting the next item and sends a separate message when the queue is empty.

## Management

Run `Bridge-Manager.cmd` for the interactive PowerShell manager, or use:

```powershell
.\bridge.ps1 -Action status
.\bridge.ps1 -Action logs
.\bridge.ps1 -Action doctor
.\bridge.ps1 -Action restart
.\bridge.ps1 -Action install-plugin
.\bridge.ps1 -Action uninstall
```

`uninstall` removes the scheduled task and keeps configuration, logs, and the OpenCode plugin. Remove those files manually only if you want a full reset.

## Development

The project has no runtime npm dependencies.

```powershell
npm test
npm run check
```

`npm test` validates command parsing, batch splitting, event fingerprints, loopback restrictions, DPAPI credential protection, plugin registration, and completion event creation.

## Security model

The bot accepts commands only when all three checks match the initial setup: private chat type, Telegram user ID, and Telegram chat ID. The controller accepts only loopback HTTP URLs for OpenCode. Bot tokens and OpenCode's temporary Desktop credential are protected with Windows DPAPI for the current user.

See [SECURITY.md](SECURITY.md) for boundaries and reporting guidance.

## License

[MIT](LICENSE)
