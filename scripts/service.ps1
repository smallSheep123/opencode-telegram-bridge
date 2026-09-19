[CmdletBinding()]
param(
    [ValidateSet('install','start','stop','restart','status','logs','doctor','uninstall')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'
$TaskName = 'OpenCode Telegram Bridge'
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Controller = Join-Path $Root 'app\controller.mjs'
$Runner = Join-Path $Root 'app\run-controller.ps1'
$DataRoot = "$env:USERPROFILE\.config\opencode\telegram-bridge"
$ConfigPath = Join-Path $DataRoot 'config.json'

function Get-BridgeTask { Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue }
function Stop-BridgeTask {
    if (-not (Get-BridgeTask)) { return }
    Stop-ScheduledTask $TaskName -ErrorAction SilentlyContinue
    $lockPath = Join-Path $DataRoot 'controller.lock'
    for ($i = 0; $i -lt 50; $i++) {
        $state = (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue).State
        if ($state -ne 'Running') { break }
        Start-Sleep -Milliseconds 100
    }
    # The task is stopped, so any remaining lock belongs to its terminated process.
    if ((Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue).State -ne 'Running') {
        Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
    }
}
function Show-Status {
    $task = Get-BridgeTask
    if (-not $task) {
        Write-Host "桥接：未安装；Telegram：$(if(Test-Path $ConfigPath){'已配置'}else{'未配置'})"
        return
    }
    $info = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host ("桥接：{0}；Telegram：{1}；上次结果：{2}；上次启动：{3}" -f $task.State, $(if(Test-Path $ConfigPath){'已配置'}else{'未配置'}), $info.LastTaskResult, $info.LastRunTime)
}

switch ($Action) {
    'install' {
        if (-not (Test-Path -LiteralPath $ConfigPath)) { throw 'Telegram 尚未初始化，请先运行首次配置。' }
        $node = (Get-Command node.exe -ErrorAction Stop).Source
        $powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
        $runnerArgs = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$Runner`" -Mode run -ControllerPath `"$Controller`" -NodePath `"$node`""
        $taskAction = New-ScheduledTaskAction -Execute $powershell -Argument $runnerArgs -WorkingDirectory $Root
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
        Register-ScheduledTask -TaskName $TaskName -Action $taskAction -Trigger $trigger -Principal $principal -Settings $settings -Description 'Secure local OpenCode to Telegram notification and session control bridge' -Force | Out-Null
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 2
        Show-Status
    }
    'start' { if(-not (Get-BridgeTask)){throw '桥接服务未安装。'}; Start-ScheduledTask $TaskName; Start-Sleep 1; Show-Status }
    'stop' { Stop-BridgeTask; Show-Status }
    'restart' { if(-not (Get-BridgeTask)){throw '桥接服务未安装。'}; Stop-BridgeTask; Start-ScheduledTask $TaskName; Start-Sleep 2; Show-Status }
    'status' { Show-Status }
    'logs' {
        $latest = Get-ChildItem -LiteralPath (Join-Path $DataRoot 'logs') -Filter 'bridge-*.log' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if($latest){Get-Content -LiteralPath $latest.FullName -Tail 120}else{Write-Host '暂无日志。'}
    }
    'doctor' {
        $node = (Get-Command node.exe -ErrorAction Stop).Source
        & $Runner -Mode self-test -ControllerPath $Controller -NodePath $node
        if(Test-Path $ConfigPath){& $Runner -Mode check -ControllerPath $Controller -NodePath $node}else{Write-Host 'NOT_CONFIGURED：程序自检通过，等待 Bot Token 初始化。'}
        $plugin = "$env:USERPROFILE\.config\opencode\plugins\telegram-bridge.js"
        Write-Host "PLUGIN=$(if(Test-Path $plugin){'OK'}else{'MISSING'})"
        Show-Status
    }
    'uninstall' {
        if(Get-BridgeTask){Stop-BridgeTask; Unregister-ScheduledTask $TaskName -Confirm:$false}
        Write-Host '桥接自启任务已卸载；配置、插件和日志均已保留。'
    }
}
