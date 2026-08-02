---
description: "Complete plugin development from idea to shipped product"
---

# New Plugin - Full Workflow

**This workflow guides you through all phases with user confirmation at each step.**

**Usage:** `/new [PluginName]`

---

## 🚪 PREREQUISITE: FIRST RUN CHECK
Before starting, verify APC is configured:

**macOS/Linux:**
```bash
bash scripts/apc-config.sh is-setup
```
**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 is-setup
```

If the check **fails** (exit 1), STOP and execute `/setup` instead. Do not proceed until setup is complete.

---

## Phase 1: Dream 💭
Execute `/dream [PluginName]`

**STOP** - Review creative brief and parameters
**Continue?** User must approve before proceeding

---

## Phase 2: Plan 📋
Execute `/plan [PluginName]`

**CRITICAL:** UI framework selection happens here
**Ask user:** "Use WebView2 (HTML/JS) or Visage (native C++)?"
**STOP** - Review architecture and framework choice
**Continue?** User must approve before proceeding

---

## Phase 3: Design 🎨
Based on framework selected:
- **Visage:** Execute Visage design workflow
- **WebView:** Execute WebView design workflow

**STOP** - Preview and approve design
**Continue?** User must approve before proceeding

---

## Phase 4: Implementation 💻
Execute `/impl [PluginName]`

**Build and test** - Verify plugin loads and works
**STOP** - Test in DAW
**Continue?** User must approve before proceeding

---

## Phase 5: Ship 🚀
Execute `/ship [PluginName]`

**COMPLETE** - Plugin is packaged and ready!

---

**Note:** You can exit at any phase and resume later with `/resume [PluginName]`

**Emergency:** If something breaks, use `/status [PluginName]` to check state
