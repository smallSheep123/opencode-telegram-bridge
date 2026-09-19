[CmdletBinding()]
param(
    [ValidateSet('setup','start','stop','restart','status','logs','doctor','uninstall','install-plugin')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'
$scripts = Join-Path $PSScriptRoot 'scripts'
if ($Action -eq 'setup') {
    & (Join-Path $scripts 'install-plugin.ps1')
    & (Join-Path $scripts 'setup.ps1')
    & (Join-Path $scripts 'service.ps1') -Action install
} elseif ($Action -eq 'install-plugin') {
    & (Join-Path $scripts 'install-plugin.ps1')
} else {
    & (Join-Path $scripts 'service.ps1') -Action $Action
}

