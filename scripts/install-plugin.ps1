[CmdletBinding()]
param(
    [string]$Source = "$PSScriptRoot\..\opencode-plugin\telegram-bridge.js",
    [string]$Destination = "$env:USERPROFILE\.config\opencode\plugins\telegram-bridge.js"
)

$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $Destination
New-Item -ItemType Directory -Path $dir -Force | Out-Null
Copy-Item -LiteralPath $Source -Destination $Destination -Force
Write-Host "OpenCode 插件已安装：$Destination"
Write-Host '已经运行的 OpenCode 需要重启一次才能加载插件。'

