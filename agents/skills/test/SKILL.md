---
name: test
description: "PHASE validation: Test - Run tests and validation on the plugin. Use when the user types /test [Name]. Build verification, parameter functionality, UI rendering, DAW compatibility, memory leaks."
---

# Test - Plugin Testing & Validation

**Trigger:** `/test [PluginName]`
**Phase:** Testing (can run after Implementation)
**Primary Skill:** `agents/skills/testing\SKILL.md`

---

## EXECUTION

When invoked, execute the complete workflow from:
**`agents/skills/testing\SKILL.md`**

## WORKFLOW GATES

See `agents/workflows/test.md` for:
- Prerequisites (requires completed Implementation phase)
- Test procedures
- Validation criteria

## PARAMETERS

- `PluginName` - Name of existing plugin to test

## OUTPUT

- Test results
- Validation report
- Updates `${APC_PLUGINS_DIR}/[Name]/status.json` with test status

## TEST TYPES

- Build validation
- Parameter range testing
- UI/DSP integration verification
- DAW compatibility check
