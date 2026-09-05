---
description: "Resume plugin development from current state"
---

> **OS Protocol:** Gli snippet sono PowerShell (Windows). Su **macOS/Linux** usa le
> controparti `scripts/*.sh` (es. `scripts/state-management.sh`, `scripts/apc-config.sh`,
> `scripts/build-and-install.sh`) con la stessa semantica. Non mescolare mai le shell.

# Resume Development
```powershell
. "$PSScriptRoot\..\scripts\state-management.ps1"

$apcPluginsDir = "${APC_PLUGINS_DIR}"
if (Test-Path "$apcPluginsDir\$PluginName") {
    $pluginPath = "$apcPluginsDir\$PluginName"
} else {
    $pluginPath = "plugins\$PluginName"
}
$state = Get-PluginState -PluginPath $pluginPath

Write-Host "Resuming plugin: $($state.plugin_name)" -ForegroundColor Cyan
Write-Host "Current phase: $($state.current_phase)"
Write-Host ""

# Suggest next command
$nextCommand = switch ($state.current_phase) {
    "ideation" { "/plan $($state.plugin_name)" }
    "plan_complete" { "/design $($state.plugin_name)" }
    "design_complete" { "/impl $($state.plugin_name)" }
    "code_complete" { "/ship $($state.plugin_name)" }
    "ship_complete" { "Plugin is complete!" }
    default { "/status $($state.plugin_name)" }
}

Write-Host "Next command: $nextCommand" -ForegroundColor Green

# Show any errors
if ($state.error_recovery.error_log.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Errors found:" -ForegroundColor Yellow
    $state.error_recovery.error_log | ForEach-Object {
        Write-Host "  - $_"
    }
}
```