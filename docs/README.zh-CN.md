# OpenCode Telegram Bridge

[English](../README.md) · [架构说明](ARCHITECTURE.md) · [安全说明](../SECURITY.md)

这是一个运行在 Windows 本机的 OpenCode Desktop 与 Telegram 桥接服务。它会在每个 OpenCode 会话完成任务或执行失败时发送通知，并允许一个经过绑定的 Telegram 账号浏览会话、查看进度、继续发送指令以及运行串行指令队列。

## 主要功能

- 每个 OpenCode 会话完成或失败时发送 Telegram 通知。
- 会话列表分页、标题搜索和项目路径搜索。
- 每个会话拥有独立的串行队列，支持 `/add` 和多段 `/batch`。
- OpenCode 或桥接重启后自动恢复队列状态。
- 过滤重复完成事件，避免重复通知和重复推进。
- 队列通知显示序号、耗时、剩余数量和下一条指令摘要。
- 完成通知提供设为当前、查看详情、追加指令、查看队列和停止任务按钮。
- 同时校验 Telegram 私聊类型、用户 ID 和聊天 ID。
- Telegram Token 和 OpenCode Desktop 临时本机密码使用 Windows DPAPI 加密。
- 只访问回环地址，不创建入站端口，不依赖 VPS、VPN、反向代理或 webhook。

## 环境要求

- Windows 10 或 Windows 11。
- OpenCode Desktop。
- Node.js 20 或更新版本，并能通过 `node.exe` 启动。
- 通过 [@BotFather](https://t.me/BotFather) 创建的 Telegram Bot。

本项目依赖 OpenCode Desktop 的本机会话接口和全局插件目录。升级 OpenCode 后建议运行一次“自检”。

## 安装

1. 下载或克隆仓库。
2. 双击 `Bridge-Manager.cmd`。
3. 选择“首次配置并启动”。
4. 根据提示粘贴 BotFather 提供的 Token。
5. 给机器人发送 `/start`，回到配置窗口并确认检测到的 Telegram 账号。
6. 重启一次 OpenCode Desktop，让全局插件加载。
7. 给机器人发送 `/sessions`。

安装程序会：

- 把插件复制到 `%USERPROFILE%\.config\opencode\plugins\telegram-bridge.js`；
- 把加密配置保存到 `%USERPROFILE%\.config\opencode\telegram-bridge`；
- 将该目录权限限制为当前用户、SYSTEM 和本机管理员；
- 创建登录后自动运行的 `OpenCode Telegram Bridge` 计划任务。

## Telegram 命令

| 命令 | 作用 |
|---|---|
| `/sessions` | 显示第一页会话 |
| `/sessions 2` | 显示指定页 |
| `/find 关键词` | 搜索会话标题和项目目录 |
| `/use 1` | 选择当前页面第一个会话 |
| `/current` | 查看当前会话 |
| `/show` | 查看状态、改动、待办和最近回复 |
| `/send 内容` | 立即发送一条指令 |
| `/add 内容` | 向当前会话队列追加一条指令 |
| `/batch` | 按单独一行的 `---` 拆分并加入多条指令 |
| `/queue` | 查看正在执行和等待中的指令 |
| `/remove 2` | 删除第 2 条等待指令 |
| `/pause` | 暂停自动队列 |
| `/resume` | 恢复自动队列 |
| `/clearqueue` | 二次确认后清空等待队列 |
| `/stop` | 二次确认后停止当前任务 |
| `/health` | 查看 Telegram、OpenCode、插件、会话、队列和最近错误 |
| `/status` | 查看简要状态 |
| `/help` | 显示帮助 |

批量指令示例：

```text
/batch
检查失败的测试
---
修复根因并重新运行测试
---
写一份维护说明
```

每条指令完成后，机器人会先发送通知，再自动发送下一条。队列清空后还会单独发送“全部完成”。电脑端手动运行的任务也会通知，但不会误触发没有明确等待启动的旧队列。

## 管理和排错

双击 `Bridge-Manager.cmd` 使用交互式中文管理界面，也可以在 PowerShell 中运行：

```powershell
.\bridge.ps1 -Action status
.\bridge.ps1 -Action logs
.\bridge.ps1 -Action doctor
.\bridge.ps1 -Action restart
.\bridge.ps1 -Action install-plugin
.\bridge.ps1 -Action uninstall
```

OpenCode 升级后如果会话无法读取，可以先执行 `install-plugin`，重启 OpenCode Desktop，再运行 `doctor`。

`uninstall` 只删除自启任务，会保留配置、日志和插件。如果需要完全重置，再手动删除 `%USERPROFILE%\.config\opencode\telegram-bridge` 和插件文件。

## 开发测试

项目没有 npm 运行时依赖。

```powershell
npm test
npm run check
```

## 安全边界

- 仅绑定一个 Telegram 私聊账号。
- 只允许访问 `127.0.0.1`、`localhost` 和 `::1` 上的 OpenCode 服务。
- 不提供 Shell、PowerShell、任意文件读取或公网监听命令。
- `/stop` 和 `/clearqueue` 需要按钮二次确认。
- Token 和 OpenCode 临时密码均不以明文写入磁盘。

详细说明见 [SECURITY.md](../SECURITY.md)。

## 许可证

[MIT](../LICENSE)
