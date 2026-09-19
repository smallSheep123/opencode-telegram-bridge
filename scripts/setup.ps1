[CmdletBinding()]
param(
    [string]$DataRoot = "$env:USERPROFILE\.config\opencode\telegram-bridge"
)

$ErrorActionPreference = 'Stop'
$ConfigPath = Join-Path $DataRoot 'config.json'
$StatePath = Join-Path $DataRoot 'state.json'

function Read-SecretText([string]$Prompt) {
    $secure = Read-Host $Prompt -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Invoke-Telegram([string]$Token, [string]$Method, [hashtable]$Body = @{}) {
    try {
        # Windows PowerShell 5 may encode a JSON string with the active ANSI code page.
        # Supplying explicit UTF-8 bytes prevents Chinese text from becoming question marks.
        $json = $Body | ConvertTo-Json -Depth 8 -Compress
        $utf8Body = [Text.Encoding]::UTF8.GetBytes($json)
        $result = Invoke-RestMethod -Uri "https://api.telegram.org/bot$Token/$Method" -Method Post -ContentType 'application/json; charset=utf-8' -Body $utf8Body -TimeoutSec 40
        if (-not $result.ok) { throw 'Telegram returned ok=false' }
        return $result.result
    } catch {
        throw "Telegram $Method 调用失败。请检查 Token 和网络连接。"
    }
}

function Lock-DataRoot([string]$Path) {
    $account = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $directories = @((Get-Item -LiteralPath $Path)) + @(Get-ChildItem -LiteralPath $Path -Recurse -Directory -Force)
    foreach ($directory in $directories) {
        & icacls.exe $directory.FullName /inheritance:r /grant:r "${account}:(OI)(CI)F" 'NT AUTHORITY\SYSTEM:(OI)(CI)F' 'BUILTIN\Administrators:(OI)(CI)F' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "无法收紧目录权限：$($directory.FullName)" }
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force)) {
        & icacls.exe $file.FullName /inheritance:r /grant:r "${account}:F" 'NT AUTHORITY\SYSTEM:F' 'BUILTIN\Administrators:F' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "无法收紧文件权限：$($file.FullName)" }
    }
}

Write-Host ''
Write-Host 'OpenCode Telegram Bridge 初始化' -ForegroundColor Cyan
Write-Host '这里只需要 BotFather 提供的 Telegram Bot Token。它会用当前 Windows 用户的 DPAPI 加密保存。'
Write-Host ''

$token = Read-SecretText '粘贴 Bot Token'
if ($token -notmatch '^\d{8,12}:[A-Za-z0-9_-]{20,}$') { throw 'Bot Token 格式不正确。' }
$me = Invoke-Telegram $token 'getMe'
Write-Host ("机器人验证成功：@{0}" -f $me.username) -ForegroundColor Green

$webhook = Invoke-Telegram $token 'getWebhookInfo'
if ($webhook.url) {
    Write-Host ("这个机器人当前配置了 webhook：{0}" -f $webhook.url) -ForegroundColor Yellow
    $remove = Read-Host '长轮询桥接不能与 webhook 同时使用。输入 Y 删除旧 webhook'
    if ($remove -notmatch '^(?i)y(es)?$') { throw '已取消，未修改 webhook。' }
    [void](Invoke-Telegram $token 'deleteWebhook' @{ drop_pending_updates = $false })
}

Write-Host ''
Write-Host ("请在 Telegram 中打开 @{0}，发送 /start，然后回到这里按回车。" -f $me.username) -ForegroundColor Yellow
[void](Read-Host)
$updates = @(Invoke-Telegram $token 'getUpdates' @{ timeout = 2; allowed_updates = @('message') })
$private = @($updates | Where-Object { $_.message -and $_.message.chat.type -eq 'private' } | Sort-Object update_id -Descending)
if ($private.Count -eq 0) { throw '没有读取到私聊消息。请给机器人发送 /start 后重新运行。' }

$selected = $private[0]
$from = $selected.message.from
$chat = $selected.message.chat
$display = if ($from.username) { "@$($from.username)" } else { (@($from.first_name, $from.last_name) | Where-Object { $_ }) -join ' ' }
Write-Host ("将绑定 Telegram 用户 {0}（user_id={1}, chat_id={2}）" -f $display, $from.id, $chat.id)
$yes = Read-Host '输入 Y 确认'
if ($yes -notmatch '^(?i)y(es)?$') { throw '已取消，未保存配置。' }

New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null
foreach ($name in @('instances','events','logs')) { New-Item -ItemType Directory -Path (Join-Path $DataRoot $name) -Force | Out-Null }
$protectedToken = ConvertFrom-SecureString (ConvertTo-SecureString $token -AsPlainText -Force)
$config = [ordered]@{
    version = 1
    botUsername = [string]$me.username
    botTokenProtected = $protectedToken
    allowedUserId = [string]$from.id
    allowedChatId = [string]$chat.id
    maxSessions = 10
    sessionPageSize = 6
    queueLimit = 20
    configuredAt = (Get-Date).ToString('o')
}
$maxUpdate = ($updates | Measure-Object -Property update_id -Maximum).Maximum
$state = [ordered]@{
    updateOffset = if ($null -eq $maxUpdate) { 0 } else { [long]$maxUpdate + 1 }
    selected = $null
    sessionMap = @()
}
$config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
$state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $StatePath -Encoding UTF8
Lock-DataRoot $DataRoot

$commands = @(
    @{ command='sessions'; description='列出最近的 OpenCode 会话' },
    @{ command='find'; description='按标题或项目目录搜索会话' },
    @{ command='current'; description='查看当前选择的会话' },
    @{ command='show'; description='查看当前会话进展' },
    @{ command='send'; description='向当前会话继续发送指令' },
    @{ command='add'; description='向当前会话队列追加一条指令' },
    @{ command='batch'; description='按 --- 分隔并依次执行多条指令' },
    @{ command='queue'; description='查看当前会话的自动队列' },
    @{ command='pause'; description='暂停当前会话的自动队列' },
    @{ command='resume'; description='恢复当前会话的自动队列' },
    @{ command='clearqueue'; description='清空等待中的队列任务' },
    @{ command='stop'; description='停止当前会话的运行' },
    @{ command='status'; description='查看桥接状态' },
    @{ command='health'; description='查看完整健康状态' },
    @{ command='help'; description='显示帮助' }
)
[void](Invoke-Telegram $token 'setMyCommands' @{ commands = $commands })
[void](Invoke-Telegram $token 'sendMessage' @{ chat_id=[string]$chat.id; text='OpenCode Telegram Bridge 已完成安全绑定，服务启动后发送 /sessions。' })
$token = $null
Write-Host ''
Write-Host "配置完成：$ConfigPath" -ForegroundColor Green
