---
description: "PHASE 1: Ideation - Create creative brief and parameter spec"
---

# Dream Phase

**Prerequisites:**
- None (entry point)

**State Check:**
```powershell
# Check if plugin already exists
if (Test-Path "$env:USERPROFILE\Projects\VST-PLUGINS\ACP-Plugins\$PluginName") {
    Write-Warning "Plugin already exists. Use /resume to continue existing plugin."
    exit 1
}
if (Test-Path "plugins\$PluginName") {
    Write-Warning "Legacy plugin exists. Use /resume to continue existing plugin."
    exit 1
}
```

**Execute Skill:**
Load and execute `...agent\skills\skill_ideation\SKILL.md`

**Validation:**
- Verify `~/Projects/VST-PLUGINS/ACP-Plugins/[Name]/status.json` exists
- Verify `current_phase` = "ideation"
- Verify creative brief and parameter spec exist

**Completion:**
Stop and inform user:
```
✅ Dream phase complete!

Files created:
- ~/Projects/VST-PLUGINS/ACP-Plugins/[Name]/.ideas/creative-brief.md
- ~/Projects/VST-PLUGINS/ACP-Plugins/[Name]/.ideas/parameter-spec.md
- ~/Projects/VST-PLUGINS/ACP-Plugins/[Name]/status.json

Next step: /plan [Name]
```

---
description: "PHASE 2: Architecture - Define structure and select UI framework"
---

# Plan Phase

**Prerequisites:**
```powershell
. "$PSScriptRoot\..\scripts\state-management.ps1"

$apcPluginsDir = "$env:USERPROFILE\Projects\VST-PLUGINS\ACP-Plugins"
if (Test-Path "$apcPluginsDir\$PluginName") { $pluginDir = "$apcPluginsDir\$PluginName" } else { $pluginDir = "plugins/$PluginName" }

if (-not (Test-PluginState -PluginPath $pluginDir -RequiredPhase "ideation" -RequiredFiles @(".ideas/creative-brief.md", ".ideas/parameter-spec.md"))) {
    Write-Error "Prerequisites not met. Complete /dream first."
    exit 1
}
```

**Execute Skill:**
Load and execute `...agent\skills\skill_planning\SKILL.md`

**Critical Decision Point:**
This phase MUST determine and set `ui_framework` in status.json:
- "visage" for pure C++ (Visage)
- "webview" for hybrid HTML/Canvas

**Validation:**
- Verify `ui_framework` is NOT "pending"
- Verify architecture.md exists
- Verify complexity_score is set

**Completion:**
```
✅ Plan phase complete!

Framework selected: [Visage/WebView]
Complexity score: [N]/5

Files created:
- ~/Projects/VST-PLUGINS/ACP-Plugins/[Name]/.ideas/architecture.md
- ~/Projects/VST-PLUGINS/ACP-Plugins/[Name]/.ideas/plan.md

Next step: /design [Name]
```

