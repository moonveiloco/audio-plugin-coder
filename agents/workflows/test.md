---
description: "Run tests on the plugin"
---

> **OS Protocol:** Gli snippet sono PowerShell (Windows). Su **macOS/Linux** usa le
> controparti `scripts/*.sh` (es. `scripts/state-management.sh`, `scripts/apc-config.sh`,
> `scripts/build-and-install.sh`) con la stessa semantica. Non mescolare mai le shell.

# Test Phase

**Prerequisites:**
```powershell
. "$PSScriptRoot\..\scripts\state-management.ps1"

$state = Get-PluginState -PluginPath "plugins\$PluginName"

if ($state.current_phase -ne "code_complete" -and $state.current_phase -ne "design_complete") {
    Write-Error "Implementation must be complete first."
    exit 1
}
```

**Execute Skill:**
Load and execute `agents/skills/testing\SKILL.md`

**Tests Run:**
- Build verification
- Parameter functionality
- UI rendering
- DAW compatibility
- Memory leaks

**Completion:**
```
✅ Tests complete!

Results: [Pass/Fail count]

Next step: /ship [Name] if all tests passed
```
