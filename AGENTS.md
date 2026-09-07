# AGENTS.md — Audio Plugin Coder (APC)

APC is an AI-first framework for developing audio plugins (VST3/AU/LV2/CLAP) on JUCE.
This file is the **universal entry point** for every coding agent. The single source of
truth for skills, rules and workflows lives in [`agents/`](agents/README.md).

## 🚪 FIRST RUN GATE (mandatory on EVERY message)

Before answering ANY message (command, greeting, question) check that APC is configured:

- **macOS/Linux:** `bash scripts/apc-config.sh is-setup`
- **Windows:** `powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 is-setup`

- **exit 0** → resolve `${APC_PLUGINS_DIR}` with `bash scripts/apc-config.sh plugins-dir` (or `.ps1`) and proceed normally.
- **exit 1** → **STOP immediately.** Do NOT interpret the message as a plugin request: run `/setup` (`agents/skills/setup/SKILL.md`). Until `setup_complete=true` every user input is setup input.

## 🌍 Environment facts (single truth)

- **APC_PLUGINS_DIR:** resolved at runtime from `~/.config/apc/config.json` (`%APPDATA%/apc/config.json` on Windows) via `scripts/apc-config.sh|.ps1 plugins-dir`. The plugins live **outside the repo**; `examples/` is a read-only reference.
- **JUCE 9:** submodule `_tools/JUCE` (v7.0.0), resolved via `APC_TOOLS_DIR` (key `tools_dir` of the config, injected by the build scripts). **Do not** use `~/JUCE` or external installs.
- **JUCE 8→9 breaking:** `Drawable` no longer inherits `Component` (use `DrawableComponent`); `createFromSVG(XmlElement&)` removed (use `createFromSVGFile`/`Document`); Windows multi-touch requires `usesWindowsMultiTouch()`; Linux uses EGL not GLX (install `libegl-dev`).
- **Build:** ALWAYS `scripts/build-and-install.sh|.ps1 -PluginName <Name>` — never manual `cmake`/`msbuild`/`xcodebuild`, never manual copies of VST3/AU.
- **CMake plugin:** do NOT call `juce_add_modules` (duplicate target error); WebView flags: `NEEDS_WEBVIEW2` (Windows) / `NEEDS_WEB_BROWSER` (Linux/macOS).
- **Gin:** pinned submodule `_tools/Gin` (no upstream tag). Binding limitations (C++20, unstable APIs, Visage-incompatible UI) in `agents/rules/gin-integration.md` — read them BEFORE using it.
- **JIVE:** pinned submodule `_tools/JIVE` + **mandatory JUCE 9 patch** (`patches/JIVE/`, applied automatically by build-and-install). Declarative UI = third UI path (neither Visage nor WebView): limitations in `agents/rules/jive-integration.md` — read them BEFORE using it.
- **OS protocol:** Bash/Csh on macOS/Linux (`.sh` scripts), PowerShell on Windows (`.ps1` scripts). Never mix shells.

## 🗺️ Phases (state machine on `status.json`)

`/dream` → `/plan` → `/design` → `/impl` → `/test` → `/ship` (+ `/status`, `/resume`, `/new`, `/setup`)

Each phase: read `${APC_PLUGINS_DIR}/[Name]/status.json` → check prerequisites → execute → update state → **STOP** (never auto-start the next phase).

## 📂 Key files

| Path | Content |
|---|---|
| `agents/rules/*.md` | Complete rules (dispatcher, naming, build protocols) |
| `agents/skills/<name>/SKILL.md` | 12 skills with frontmatter (`name` == folder name) |
| `agents/workflows/*.md` | Phase orchestrations |
| `agents/troubleshooting/known-issues.yaml` | Search HERE before debugging; auto-capture after 3 attempts |
| `templates/` | Plugin templates (visage, webview, ffgl, max-external) |

## 📏 Full rules

When the agent supports loading rule files, include:

- `agents/rules/agent.md` — Master Dispatcher: phase gating, OS protocol, troubleshooting auto-capture
- `agents/rules/file-naming-conventions.md` — structure and versioning of plugin projects
- `agents/rules/juce-build-protocols.md` — JUCE 9/CMake/CI build constraints
- `agents/rules/gin-integration.md` — Gin limitations and usage protocol (submodule `_tools/Gin`)
- `agents/rules/jive-integration.md` — limitations, JUCE 9 patch and JIVE usage protocol (submodule `_tools/JIVE`)