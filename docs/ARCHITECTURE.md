# Architecture

## Components

```text
OpenCode Desktop
  └─ global plugin
       ├─ registers each local OpenCode instance
       └─ writes session.idle and session.error events

Local controller
  ├─ long-polls Telegram Bot API
  ├─ reads and retries local completion events
  ├─ calls only loopback OpenCode session APIs
  ├─ persists per-session queues and deduplication state
  └─ sends notifications and inline actions

Windows Task Scheduler
  └─ starts and restarts the controller for the logged-in user
```

The OpenCode plugin never reads the Telegram token. The controller never listens on a TCP port. The two components exchange instance registrations and completion events through an ACL-restricted local data directory.

## Local data

Runtime data is stored under:

```text
%USERPROFILE%\.config\opencode\telegram-bridge
├─ config.json
├─ state.json
├─ controller.lock
├─ instances\
├─ events\
└─ logs\
```

`config.json` contains the Telegram identity binding and a DPAPI-protected token. Instance files contain loopback connection metadata and a DPAPI-protected temporary OpenCode Desktop credential. `state.json` contains Telegram offsets, session selection, queues, recovery metadata, and processed event IDs.

## Queue lifecycle

1. `/add` or `/batch` appends one or more items to the selected session queue.
2. When the session is idle, the controller marks one item as dispatching and calls `prompt_async`.
3. The plugin writes a completion or error event.
4. The controller correlates the event with the active queue item by session ID and dispatch time.
5. It sends the notification, records the event ID and semantic fingerprint, then advances the queue.
6. On restart, the controller compares persisted in-flight items with pending events, session status, and recent OpenCode messages before deciding whether to wait, recover completion, or requeue.

Manual OpenCode work is reported separately. A manual completion starts a waiting queue only when that queue was explicitly armed while the session was busy.

## Trust boundaries

- Telegram is an external command transport. Every update is checked against private-chat type, user ID, and chat ID.
- OpenCode access is restricted to HTTP loopback hosts.
- The plugin and controller run as the interactive Windows user.
- Secrets are scoped to that Windows user through DPAPI and filesystem ACLs.
- The bridge does not expose a network server and does not execute arbitrary shell commands.
