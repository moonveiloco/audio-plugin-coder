---
description: "Check current plugin state and progress"
---

> **OS Protocol:** Gli snippet sono PowerShell (Windows). Su **macOS/Linux** usa le
> controparti `scripts/*.sh` (es. `scripts/state-management.sh`, `scripts/apc-config.sh`,
> `scripts/build-and-install.sh`) con la stessa semantica. Non mescolare mai le shell.

# Status Check
```powershell
. "$PSScriptRoot\..\scripts\state-management.ps1"

$state = Get-PluginState -PluginPath "plugins\$PluginName"

Write-Host "=== Plugin Status ===" -ForegroundColor Cyan
Write-Host "Name: $($state.plugin_name)"
Write-Host "Version: $($state.version)"
Write-Host "Current Phase: $($state.current_phase)"
Write-Host "UI Framework: $($state.ui_framework)"
Write-Host "Complexity: $($state.complexity_score)/10"
Write-Host ""

Write-Host "=== Completed Phases ===" -ForegroundColor Green
$state.phase_history | ForEach-Object {
    Write-Host "✓ $($_.phase) - $($_.completed_at)"
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Yellow
switch ($state.current_phase) {
    "ideation" { Write-Host "/plan [Name]" }
    "plan_complete" { Write-Host "/design [Name]" }
    "design_complete" { Write-Host "/impl [Name]" }
    "code_complete" { Write-Host "/ship [Name]" }
    "ship_complete" { Write-Host "Plugin complete! 🎉" }
}
```