# SKILL: IDEATION & DREAMING

**Goal:** Define the plugin concept and initialize the project state.
**Trigger:** `/dream [Name]`
**Output Location:** `${APC_PLUGINS_DIR}/[Name]/`

## 🚪 PREREQUISITE: FIRST RUN CHECK
Prima di iniziare, verifica che ACP sia configurato:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\acp-config.ps1 is-setup
```
Se il check fallisce (exit 1), STOP ed esegui `/setup`. Non procedere fino al completamento del setup.

Se il check passa, risolvi la directory:
```powershell
$ApcPluginsDir = & .\scripts\acp-config.ps1 plugins-dir
```

## ⛔ OUTPUT RESTRICTIONS (MANDATORY)
*   **NO C++ Code.**
*   **NO Build Scripts.**
*   **NO CMake configurations.**

## STEP 1: THE INTERVIEW
**Do NOT generate files yet.**
If the user prompt is vague, ask 3 clarifying questions:
1.  **Sonic Goal:** What is the character? (e.g., "Dirty Tape Delay", "Clean EQ")
2.  **Controls:** What are the top 3 parameters?
3.  **Vibe:** Visual aesthetic?

**STOP and WAIT for the user's response.**

## STEP 2: CONCEPT GENERATION
*Only after the user answers, generate these files:*

### 1. `${APC_PLUGINS_DIR}/[Name]/.ideas/creative-brief.md`
The vision statement.
*   **Hook:** Marketing pitch.
*   **Description:** Detailed behavior.

### 2. `${APC_PLUGINS_DIR}/[Name]/.ideas/parameter-spec.md`
The definitive list of controls.
| ID | Name | Type | Range | Default | Unit |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `gain` | Gain | Float | 0.0 - 1.0 | 0.5 | dB |

### 3. `${APC_PLUGINS_DIR}/[Name]/status.json` (ROOT)
Initialize the project tracking file in the plugin root using the standardized schema.

**Use the state management system:**
```powershell
# Import state management
. "$PSScriptRoot\..\scripts\state-management.ps1"

# Initialize state
New-PluginState -PluginName "[Name]" -PluginPath "plugins\[Name]"
```

**Schema structure:**
```json
{
  "plugin_name": "[Name]",
  "version": "v0.0.0",
  "current_phase": "ideation",
  "ui_framework": "pending",
  "complexity_score": 0,
  "created_at": "2026-01-04T20:20:00Z",
  "last_modified": "2026-01-04T20:20:00Z",
  "phase_history": [],
  "validation": {
    "creative_brief_exists": true,
    "parameter_spec_exists": true,
    "architecture_defined": false,
    "ui_framework_selected": false,
    "design_complete": false,
    "code_complete": false,
    "tests_passed": false,
    "ship_ready": false
  },
  "framework_selection": {
    "decision": "pending",
    "rationale": "",
    "implementation_strategy": "pending"
  },
  "error_recovery": {
    "last_backup": null,
    "rollback_available": false,
    "error_log": []
  }
}
```

### 4. Copy Git Templates
Copy the git templates into the new plugin directory so it is ready for `git init`:
```bash
cp templates/plugin-gitignore.template      ${APC_PLUGINS_DIR}/[Name]/.gitignore
cp templates/plugin-gitattributes.template  ${APC_PLUGINS_DIR}/[Name]/.gitattributes
```
These provide line-ending normalization (LF for source, CRLF for `.ps1`/`.bat`), binary handling for VST3/AU/artifacts, and standard ignores for `build/`, `dist/`, IDE, and OS files.

**Update state after completion:**
```powershell
# Use standardized phase completion function
Complete-Phase -PluginPath "plugins\[Name]" -Phase "ideation" -Updates @{
  "validation.creative_brief_exists" = $true
  "validation.parameter_spec_exists" = $true
}
```

## STEP 3: TERMINATION
1. Confirm files are created.
2. STOP.
3. Ask: "Concept defined. Type /plan [Name] to architecture the DSP and UI."