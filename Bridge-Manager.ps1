[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'OpenCode Telegram Bridge Manager'

function Write-Banner {
    Clear-Host
    Write-Host '========================================================' -ForegroundColor DarkCyan
    Write-Host '          OpenCode Telegram 桥接管理中心' -ForegroundColor Cyan
    Write-Host '========================================================' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host '  1' -NoNewline -ForegroundColor Yellow; Write-Host '  首次配置并启动'
    Write-Host '  2' -NoNewline -ForegroundColor Yellow; Write-Host '  启动桥接'
    Write-Host '  3' -NoNewline -ForegroundColor Yellow; Write-Host '  停止桥接'
    Write-Host '  4' -NoNewline -ForegroundColor Yellow; Write-Host '  重启桥接'
    Write-Host '  5' -NoNewline -ForegroundColor Yellow; Write-Host '  查看状态'
    Write-Host '  6' -NoNewline -ForegroundColor Yellow; Write-Host '  查看日志'
    Write-Host '  7' -NoNewline -ForegroundColor Yellow; Write-Host '  运行自检'
    Write-Host '  8' -NoNewline -ForegroundColor Yellow; Write-Host '  重新安装 OpenCode 插件'
    Write-Host '  9' -NoNewline -ForegroundColor Yellow; Write-Host '  卸载自启任务（保留配置）'
    Write-Host '  0' -NoNewline -ForegroundColor Yellow; Write-Host '  退出'
    Write-Host ''
    Write-Host '--------------------------------------------------------' -ForegroundColor DarkGray
}

$actions = @{
    '1' = 'setup'
    '2' = 'start'
    '3' = 'stop'
    '4' = 'restart'
    '5' = 'status'
    '6' = 'logs'
    '7' = 'doctor'
    '8' = 'install-plugin'
    '9' = 'uninstall'
}

while ($true) {
    Write-Banner
    $choice = Read-Host '请选择'
    if ($choice -eq '0') { break }
    if (-not $actions.ContainsKey($choice)) {
        Write-Host ''
        Write-Host '输入无效，请选择 0 到 9。' -ForegroundColor Red
        Start-Sleep -Seconds 1
        continue
    }

    Write-Host ''
    try {
        & (Join-Path $PSScriptRoot 'bridge.ps1') -Action $actions[$choice]
        Write-Host ''
        Write-Host '操作完成。' -ForegroundColor Green
    } catch {
        Write-Host ''
        Write-Host ('操作失败：' + $_.Exception.Message) -ForegroundColor Red
    }
    Write-Host ''
    [void](Read-Host '按回车键返回主菜单')
}

