---
description: "PHASE 2: Architecture - Define structure and UI framework"
---

# Plan Phase (Architecture)

**Prerequisites:**
```powershell
. "$PSScriptRoot\..\scripts\state-management.ps1"

$apcPluginsDir = "${APC_PLUGINS_DIR}"
if (Test-Path "$apcPluginsDir\$PluginName") { $pluginDir = "$apcPluginsDir\$PluginName" } else { $pluginDir = "plugins/$PluginName" }

if (-not (Test-PluginState -PluginPath $pluginDir -RequiredPhase "ideation" -RequiredFiles @(".ideas/creative-brief.md", ".ideas/parameter-spec.md"))) {
    Write-Error "Prerequisites not met. Complete /dream first."
    exit 1
}
```

**Execute Skill:**
Load and follow `.agent/skills/skill_planning/SKILL.md` exactly.

**CRITICAL UI Framework Decision:**
- Read user requirements
- If user has not explicitly chosen, ASK: "Use WebView2 (HTML/JS) or Visage (native C++)?"
- Determine: VISAGE (pure C++) or WEBVIEW (hybrid)
- Update status.json with framework selection
- Set complexity score (1-5)

**Success Criteria:**
- `status.json` updated with `ui_framework` = "visage" or "webview"
- Architecture document created
- Framework selection rationale documented

**After completion:**
Stop and inform user: "Plan phase complete. Framework selected: [X]. Use `/design [Name]` to continue."

