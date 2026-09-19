# Changelog

All notable changes to this project are documented in this file.

## 0.1.1 - 2026-09-19

### Fixed

- Import the enabled Windows/WinINET proxy for the controller, including local Clash-compatible HTTP proxy settings.
- Keep the bridge process alive when Telegram is temporarily unreachable and retry with exponential backoff.
- Reduce repeated network-failure log noise while retaining the latest health error.
- Preserve queued completion events during an outage and deliver them after connectivity returns.
- Run service diagnostics through the same proxy-aware launcher as the scheduled task.

## 0.1.0 - 2026-09-19

### Added

- Telegram notifications for OpenCode session completion and failure.
- Paginated session browsing, project-path search, and current-session markers.
- Immediate prompts and per-session sequential queues with `/add` and `/batch`.
- Queue recovery, event deduplication, progress notifications, and completion summaries.
- Inline actions for selection, details, queue inspection, prompt help, and task stopping.
- `/health` diagnostics for Telegram, OpenCode, plugins, sessions, queues, and recent errors.
- Windows DPAPI protection and ACL-restricted runtime storage.
- Scheduled-task service management and a Chinese PowerShell management interface.
