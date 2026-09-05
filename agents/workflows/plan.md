---
description: "PHASE 2: Architecture - Define structure and UI framework"
---

> **OS Protocol:** Gli snippet sono PowerShell (Windows). Su **macOS/Linux** usa le
> controparti `scripts/*.sh` (es. `scripts/state-management.sh`, `scripts/apc-config.sh`,
> `scripts/build-and-install.sh`) con la stessa semantica. Non mescolare mai le shell.

# Plan Phase (Architecture)

**Prerequisites:**
```powershell
. "$PSScriptRoot\..\scripts\state-management.ps1"

$apcPluginsDir = "${APC_PLUGINS_DIR}"
if (Test-Path "$apcPluginsDir\$PluginName") { $pluginDir = "$apcPluginsDir\$PluginName" } else { Write-Error "Plugin '$PluginName' not found in APC_PLUGINS_DIR ($apcPluginsDir). Run /setup or create the plugin with /dream."; exit 1 }

if (-not (Test-PluginState -PluginPath $pluginDir -RequiredPhase "ideation" -RequiredFiles @(".ideas/creative-brief.md", ".ideas/parameter-spec.md"))) {
    Write-Error "Prerequisites not met. Complete /dream first."
    exit 1
}
```

**Execute Skill:**
Load and follow `agents/skills/plan/SKILL.md` exactly.

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
