# {{PLUGINS_DIR_NAME}}

External plugin projects for the [Audio Plugin Coder (APC)]({{APC_REPO_URL}}) toolchain.

This directory holds your plugin projects. It lives **outside** the APC repo and is configured via `/setup`.

## Structure

```
{{PLUGINS_DIR_NAME}}/
├── README.md               # This file
├── MyPlugin/               # Each plugin is its own directory
│   ├── .git/               # Optional: independent Git repository
│   ├── .gitignore          # Per-plugin ignores (from template)
│   ├── .gitattributes      # Line endings + binary handling
│   ├── .ideas/             # Creative brief, parameter spec, architecture
│   ├── Source/             # C++ source (PluginProcessor, PluginEditor)
│   ├── Design/             # UI design assets
│   ├── CMakeLists.txt      # Plugin build config
│   ├── status.json         # Phase + build tracking
│   └── build/              # Final artifacts (gitignored)
│       ├── VST3/
│       ├── AU/
│       └── Standalone/
└── AnotherPlugin/
    └── ...
```

## Creating a New Plugin

From the APC repository root, use the APC workflow (recommended):

```
# In your AI agent, type:
/new MyPlugin
```

The agent creates the plugin directory here, populates `.ideas/`, `status.json`, `Source/`, `Design/`, and the git templates (`.gitignore`, `.gitattributes`).

To make the plugin its own Git repository:

```bash
cd "{{PLUGINS_DIR_PATH}}/MyPlugin"
git init
git add .
git commit -m "feat: initial MyPlugin scaffold"
```

## Building a Plugin

From the APC repository root:

```bash
# macOS / Linux
bash scripts/build-and-install.sh MyPlugin

# Windows
powershell scripts/build-and-install.ps1 MyPlugin
```

The build system:
1. Compiles in the shared APC build cache (`audio-plugin-coder/build/`)
2. Copies final artifacts (VST3, AU, Standalone) to `MyPlugin/build/`
3. Installs to system plugin folders (`~/Library/Audio/Plug-Ins/...`)
4. Updates `MyPlugin/status.json` with build metadata

## Relationship with APC

```
audio-plugin-coder/        ← Toolchain: CMake, scripts, JUCE, agent configs
{{PLUGINS_DIR_NAME}}/      ← Your plugins: source code, design, status
```

APC provides the build system and AI workflows. This directory holds your plugin projects. Reference example plugins ship inside the APC repo in `examples/` (read-only — not for new plugin creation).

## Per-Plugin Build Status

Each plugin's `status.json` contains a `build_info` block populated automatically after each build:

```json
"build_info": {
  "last_build_at": "2026-07-29T14:32:18Z",
  "last_build_status": "success",
  "last_build_duration_sec": 47,
  "last_build_type": "VST3+AU+Standalone",
  "artifacts": [
    {"format": "VST3", "path": "build/VST3/MyPlugin.vst3", "size_bytes": 8400000}
  ],
  "juce_version": "JUCE 9.0.0",
  "compiler": "Apple clang 15.0.0"
}
```

Check build status with:

```bash
jq '.build_info' "{{PLUGINS_DIR_PATH}}/MyPlugin/status.json"
```
