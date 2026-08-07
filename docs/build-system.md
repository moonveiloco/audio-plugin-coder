# Build System Documentation

Complete guide to the APC build system, including CMake configuration, PowerShell scripts, and cross-platform considerations.

## Overview

APC uses a CMake-based build system with JUCE 9 as the audio plugin framework. The build process is orchestrated through PowerShell scripts to ensure consistency and proper error handling.

**Key Principles:**
- Never run cmake/msbuild directly - always use scripts
- Build each plugin from its own folder (`cmake -S <PluginDir> -B <PluginDir>/build`), never from the repo root
- Use PowerShell 7+ on Windows
- Build artifacts live **inside the plugin folder** at `<plugins_dir>/[PluginName]/build/`
- Plugins locate the APC repo through the `tools_dir` config key (used as `APC_TOOLS_DIR` in their CMakeLists); scripts fall back to the repo owning `scripts/`

---

## Build Architecture

### Directory Structure

```
audio-plugin-coder/                # APC repo (= tools_dir)
├── CMakeLists.txt                 # Repo-level CMake (optional/root convenience)
├── _tools/
│   └── JUCE/
│       └── CMakeLists.txt         # JUCE framework (Git submodule)
├── include/                       # Shared headers (VisageJuceHost.h, ...)
├── examples/                      # Read-only reference plugins (CloudWash, gnarly2, ...)
└── scripts/                       # Build/install/config helpers

~/AudioPlugins/[PluginName]/       # A plugin created via /new (external to repo)
├── CMakeLists.txt                 # Self-contained: bootstraps APC_TOOLS_DIR + JUCE
└── build/                         # Build artifacts (generated)
    ├── CMakeCache.txt
    ├── VST3/                      # Staged installable artifacts
    │   └── [PluginName].vst3/
    └── [PluginName]_artefacts/
        └── Release/
            ├── [PluginName].vst3/
            ├── [PluginName].exe
            └── [PluginName].lib
```

### Build Flow

```
┌─────────────────┐
│  build-and-     │
│  install.ps1    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  CMake Configure│◀── Creates build files
│  (cmake -S -B)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Build VST3     │◀── Compiles VST3 plugin
│  (cmake --build)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Build          │◀── Compiles standalone
│  Standalone     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Install VST3   │◀── Copies to Program Files
│  (cmake --inst) │
└─────────────────┘
```

---

## Root CMakeLists.txt

The root [`CMakeLists.txt`](CMakeLists.txt) configures the global build environment:

```cmake
cmake_minimum_required(VERSION 3.22)
project(AudioPluginCoder VERSION 0.1.0 LANGUAGES C CXX)

# C++ Standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add JUCE as subdirectory
add_subdirectory(_tools/JUCE)

# Enable all plugin formats by default
set(FORMATS VST3 Standalone)

# Include all plugin directories (external APC_PLUGINS_DIR + env var fallback)
file(GLOB PLUGIN_DIRS "$ENV{APC_PLUGINS_DIR}/*")
foreach(plugin_dir ${PLUGIN_DIRS})
    if(IS_DIRECTORY ${plugin_dir})
        add_subdirectory(${plugin_dir} ${CMAKE_BINARY_DIR}/external/$(get_filename_component(${plugin_dir} NAME)))
    endif()
endforeach()
```

**Key Points:**
- JUCE is added as a subdirectory (not called via `find_package`)
- Discovers plugins in `APC_PLUGINS_DIR` (configured via `/setup`, external to the repo)
- Sets global C++20 standard
- **MUST declare `LANGUAGES C CXX`** — JUCE needs C for Sheenbidi (text rendering) and juceaide (build tool). Without C, `CMAKE_C_COMPILE_OBJECT` will be undefined at generate time

---

## Plugin CMakeLists.txt

Each plugin has its own CMake configuration:

### Basic Structure

```cmake
# Plugin name
set(PLUGIN_NAME MyPlugin)

# JUCE plugin definition
juce_add_plugin(${PLUGIN_NAME}
    COMPANY_NAME "APC"
    PLUGIN_MANUFACTURER_CODE Apco
    PLUGIN_CODE MyPl
    FORMATS ${FORMATS}
    PRODUCT_NAME "My Plugin"
    NEEDS_WEBVIEW2 TRUE              # For WebView plugins
)

# Source files
target_sources(${PLUGIN_NAME}
    PRIVATE
        Source/PluginProcessor.cpp
        Source/PluginEditor.cpp
)

# Include directories
target_include_directories(${PLUGIN_NAME}
    PRIVATE
        Source
)

# Link libraries
target_link_libraries(${PLUGIN_NAME}
    PRIVATE
        juce::juce_audio_utils
        juce::juce_dsp
        juce::juce_gui_extra         # Required for WebView
)

# Compile definitions
target_compile_definitions(${PLUGIN_NAME}
    PUBLIC
        JUCE_WEB_BROWSER=1
        JUCE_USE_WIN_WEBVIEW2_WITH_STATIC_LINKING=1
)
```

### WebView Plugin Configuration

Additional configuration for WebView plugins:

```cmake
# Embed web UI files
juce_add_binary_data(${PLUGIN_NAME}_WebUI
    SOURCES
        Source/ui/public/index.html
        Source/ui/public/js/index.js
        Source/ui/public/js/juce/index.js
)

# Link binary data
target_link_libraries(${PLUGIN_NAME}
    PRIVATE
        ${PLUGIN_NAME}_WebUI
        juce::juce_gui_extra
)

# WebView2 definitions
target_compile_definitions(${PLUGIN_NAME}
    PUBLIC
        JUCE_WEB_BROWSER=1
        JUCE_USE_WIN_WEBVIEW2_WITH_STATIC_LINKING=1
)
```

### **CRITICAL: Platform-Specific WebView Requirements**

JUCE 9 has **two separate flags** for WebView plugins:

| Platform | Flag | Purpose |
|----------|------|---------|
| Windows | `NEEDS_WEBVIEW2 TRUE` | Static-links WebView2 SDK |
| **Linux** | **`NEEDS_WEB_BROWSER TRUE`** | Links webkit2gtk + GTK, adds include paths |
| macOS | (neither) | Uses WKWebView (system framework) |

**Linux plugins MUST set both flags:**

```cmake
elseif(UNIX)
    set(PLUGIN_FORMATS VST3 LV2 Standalone)
    set(NEEDS_WEBVIEW2 FALSE)
    set(NEEDS_WEB_BROWSER TRUE)  # REQUIRED for Linux WebView
    set(WEBVIEW_BACKEND "WebKitGTK")
endif()

juce_add_plugin(${PLUGIN_NAME}
    ...
    NEEDS_WEBVIEW2 ${NEEDS_WEBVIEW2}
    NEEDS_WEB_BROWSER ${NEEDS_WEB_BROWSER}  # MUST pass this to juce_add_plugin
)
```

**Without `NEEDS_WEB_BROWSER TRUE` on Linux:** Compiler will get `JUCE_WEB_BROWSER=1` but never receive `-I/usr/include/gtk-3.0` → `gtk/gtk.h: No such file or directory` → build fails.

### Format-Specific Settings

```cmake
# VST3 settings
if("VST3" IN_LIST FORMATS)
    set_target_properties(${PLUGIN_NAME}_VST3 PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/vst3"
    )
endif()

# Standalone settings
if("Standalone" IN_LIST FORMATS)
    set_target_properties(${PLUGIN_NAME}_Standalone PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/standalone"
    )
endif()
```

---

## Build Scripts

### build-and-install.ps1 / build-and-install.sh

The main build scripts ([`build-and-install.ps1`](scripts/build-and-install.ps1) / [`build-and-install.sh`](scripts/build-and-install.sh)) build each plugin **inside its own folder**. Simplified logic (Windows):

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$PluginName,
    [switch]$NoInstall,
    [switch]$SkipTests,
    [switch]$Strict
)

$PluginsDir = & "$PSScriptRoot\apc-config.ps1" plugins-dir
$PluginDir  = Join-Path $PluginsDir $PluginName
$BuildDir   = Join-Path $PluginDir "build"

# APC repo (hosts _tools/JUCE, _tools/visage, include/) — fallback to script owner
$ApcToolsDir = & "$PSScriptRoot\apc-config.ps1" tools-dir
if (-not $ApcToolsDir) { $ApcToolsDir = (Resolve-Path "$PSScriptRoot\..").Path }

# Target name is the lowercase plugin name (juce_add_plugin produces <name>_VST3)
$CmakeTarget = ... # parsed lowercase from CMakeLists.txt juce_add_plugin(...)

# Configure from the plugin folder, telling it where APC lives
cmake -S $PluginDir -B $BuildDir -DAPC_TOOLS_DIR="$ApcToolsDir" -G "Visual Studio 17 2022" -A x64

# Build
cmake --build $BuildDir --config Release --target "${CmakeTarget}_VST3"
cmake --build $BuildDir --config Release --target "${CmakeTarget}_Standalone"

# Stage into $BuildDir/VST3 and $BuildDir/Standalone (unless -NoInstall)
# Run pluginval tests (unless -SkipTests)
Write-Host "Build complete!" -ForegroundColor Green
```

**Usage:**
```powershell
# Full build and install
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-install.ps1 -PluginName MyPlugin

# macOS / Linux
bash scripts/build-and-install.sh MyPlugin

# Build only (no install)
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-install.ps1 -PluginName MyPlugin -NoInstall

# Skip validation tests
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-install.ps1 -PluginName MyPlugin -SkipTests
```

### validate-webview-setup.ps1

Validates WebView plugin configuration:

```powershell
param([Parameter(Mandatory=$true)][string]$PluginName)

$PluginPath = "$env:APC_PLUGINS_DIR/$PluginName"
$Checks = @{
    CMakeListsExists = Test-Path "$PluginPath/CMakeLists.txt"
    BinaryDataTarget = $false
    WebView2Enabled = $false
    CorrectDefinitions = $false
}

# Check CMakeLists.txt content
$CMakeContent = Get-Content "$PluginPath/CMakeLists.txt" -Raw

$Checks.BinaryDataTarget = $CMakeContent -match "juce_add_binary_data"
$Checks.WebView2Enabled = $CMakeContent -match "NEEDS_WEBVIEW2 TRUE"
$Checks.CorrectDefinitions = $CMakeContent -match "JUCE_WEB_BROWSER=1"

# Report results
$Checks.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value) { "✅" } else { "❌" }
    Write-Host "$status $($_.Key)"
}

# Return overall result
$allPassed = $Checks.Values -notcontains $false
exit ($allPassed ? 0 : 1)
```

### validate-webview-member-order.ps1

Validates critical member declaration order:

```powershell
param([Parameter(Mandatory=$true)][string]$PluginName)

$HeaderPath = "$env:APC_PLUGINS_DIR/$PluginName/Source/PluginEditor.h"
$Content = Get-Content $HeaderPath -Raw

# Check for correct order pattern
$relayPattern = 'WebSliderRelay.*\{[^}]+\}'
$webViewPattern = 'unique_ptr.*WebBrowserComponent'
$attachmentPattern = 'WebSliderParameterAttachment'

$relayPos = $Content | Select-String $relayPattern | Select-Object -First 1
$webViewPos = $Content | Select-String $webViewPattern | Select-Object -First 1
$attachmentPos = $Content | Select-String $attachmentPattern | Select-Object -First 1

if ($relayPos -and $webViewPos -and $attachmentPos) {
    if ($relayPos.Index -lt $webViewPos.Index -and 
        $webViewPos.Index -lt $attachmentPos.Index) {
        Write-Host "✅ Member order correct: Relays → WebView → Attachments" -ForegroundColor Green
        exit 0
    }
}

Write-Host "❌ Member order incorrect! Must be: Relays → WebView → Attachments" -ForegroundColor Red
exit 1
```

---

## Build Targets

### Available Targets

| Target | Description | Output |
|--------|-------------|--------|
| `[Name]_VST3` | VST3 plugin | `.vst3` bundle |
| `[Name]_Standalone` | Standalone app | `.exe` |
| `[Name]_AU` | Audio Unit (macOS) | `.component` |
| `[Name]_LV2` | LV2 plugin (Linux) | `.lv2` bundle |
| `[Name]_All` | All formats | Multiple |

### Target Dependencies

```
[Name]_All
├── [Name]_VST3
│   └── [Name]_SharedCode
├── [Name]_Standalone
│   └── [Name]_SharedCode
└── [Name]_AU (macOS only)
    └── [Name]_SharedCode
```

---

## Build Configuration

### Debug vs Release

**Debug Build:** *(from the plugin folder, pointing at the APC repo via `APC_TOOLS_DIR`)*
```powershell
cmake -S "$PluginDir" -B "$PluginDir\build" -DAPC_TOOLS_DIR="<apc_repo_path>" -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Debug
cmake --build "$PluginDir\build" --config Debug --target myplugin_VST3
```

**Release Build:**
```powershell
cmake -S "$PluginDir" -B "$PluginDir\build" -DAPC_TOOLS_DIR="<apc_repo_path>" -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
cmake --build "$PluginDir\build" --config Release --target myplugin_VST3
```

### Compiler Flags

**Global Settings (Root CMakeLists.txt):**
```cmake
# MSVC specific
if(MSVC)
    add_compile_options(/W4 /WX-)  # High warnings, don't treat as errors
    add_compile_options(/MP)        # Multi-processor compilation
endif()

# macOS/Linux
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()
```

**Plugin-Specific:**
```cmake
# Optimization for release
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(${PLUGIN_NAME} PRIVATE /O2)
endif()
```

---

## Installation

### VST3 Installation Path

Windows:
```
C:\Program Files\Common Files\VST3\
```

macOS:
```
/Library/Audio/Plug-Ins/VST3/
~/Library/Audio/Plug-Ins/VST3/
```

Linux:
```
/usr/lib/vst3/
~/.vst3/
```

### CMake Install Configuration

```cmake
# VST3 installation
install(TARGETS ${PLUGIN_NAME}_VST3
    LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/VST3"
    COMPONENT ${PLUGIN_NAME}_VST3
)

# Standalone installation
install(TARGETS ${PLUGIN_NAME}_Standalone
    RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/bin"
    COMPONENT ${PLUGIN_NAME}_Standalone
)
```

---

## Cross-Platform Builds

### Windows (Local)

**Requirements:**
- Visual Studio 2022
- CMake 3.22+
- Windows SDK

**Build:**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-install.ps1 -PluginName MyPlugin
```

### macOS (GitHub Actions)

**Requirements:**
- Xcode
- CMake

**GitHub Actions:**
```yaml
build-macos:
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive
    - name: Configure
      run: cmake -S . -B build -G Xcode -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
    - name: Build
      run: cmake --build build --config Release --target MyPlugin_VST3
```

### Linux (GitHub Actions)

**Requirements:**
- GCC/Clang
- CMake 3.22+
- Development libraries (complete list below)
- **xvfb** (for LV2/Standalone builds on headless CI)

**Complete Linux Dependencies:**
```bash
cmake libasound2-dev libfreetype6-dev libgl1-mesa-dev libx11-dev
libxcomposite-dev libxcursor-dev libxext-dev libxinerama-dev libxrandr-dev
libwebkit2gtk-4.1-dev libjack-jackd2-dev xvfb
```

**GitHub Actions:**
```yaml
build-linux:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive
    - name: Install deps
      run: |
        sudo apt-get update
        sudo apt-get install -y cmake libasound2-dev libfreetype6-dev \
          libgl1-mesa-dev libx11-dev libxcomposite-dev libxcursor-dev \
          libxext-dev libxinerama-dev libxrandr-dev libwebkit2gtk-4.1-dev \
          libjack-jackd2-dev xvfb
    - name: Configure
      run: cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    - name: Build VST3
      run: cmake --build build --target MyPlugin_VST3
    - name: Build LV2
      run: xvfb-run cmake --build build --target MyPlugin_LV2
    - name: Build Standalone
      run: xvfb-run cmake --build build --target MyPlugin_Standalone
```

**Why xvfb?** LV2 and Standalone builds run JUCE's manifest helper post-link, which loads the plugin to extract metadata. WebView plugins init GTK, requiring a display. `xvfb-run` provides a virtual framebuffer on headless CI. VST3 doesn't need it (no post-link subprocess).

---

## Troubleshooting

### "CMake not found"

**Solution:** Install CMake 3.22+ from https://cmake.org/download/

### "JUCE not found"

**Solution:** Initialize submodules:
```powershell
git submodule update --init --recursive
```

### "Visual Studio not found"

**Solution:** Install Visual Studio 2022 with C++ development tools

### "Permission denied when installing"

**Cause:** Windows requires admin to write to Program Files

**Solutions:**
1. Run PowerShell as Administrator
2. Use `-NoInstall` flag and manually copy
3. Change install prefix in CMake

### "Duplicate target error"

**Cause:** Plugin CMakeLists.txt calls `juce_add_modules`

**Solution:** Remove `juce_add_modules` - JUCE is already included at root level

### "WebView2 not found"

**Cause:** WebView2 Runtime not installed

**Solution:** Install WebView2 Runtime (usually pre-installed on Windows 11)

---

## Best Practices

### 1. Always Use Scripts

```powershell
# Good
.\scripts\build-and-install.ps1 -PluginName MyPlugin

# Bad
cmake -S . -B build  # Don't run directly
```

### 2. Build from Root

```powershell
# Good (from audio-plugin-coder/)
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-install.ps1 -PluginName MyPlugin

# Bad (from plugin directory)
cd "$env:APC_PLUGINS_DIR/MyPlugin"  # Don't do this — run from audio-plugin-coder/ root
```

### 3. Clean Builds

When switching configurations:
```powershell
Remove-Item -Recurse -Force build/
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-install.ps1 -PluginName MyPlugin
```

### 4. Parallel Compilation

CMake automatically uses parallel compilation on Windows with `/MP` flag.

### 5. Incremental Builds

CMake only rebuilds changed files. Keep build directory for faster rebuilds.

---

## Advanced Configuration

### Custom JUCE Modules

```cmake
# Add custom JUCE module
add_subdirectory(ThirdParty/CustomModule)

target_link_libraries(${PLUGIN_NAME}
    PRIVATE
        juce::juce_audio_utils
        CustomModule
)
```

### Precompiled Headers

```cmake
target_precompile_headers(${PLUGIN_NAME}
    PRIVATE
        <juce_audio_processors/juce_audio_processors.h>
        <juce_dsp/juce_dsp.h>
)
```

### Unity Builds

```cmake
set_target_properties(${PLUGIN_NAME} PROPERTIES
    UNITY_BUILD ON
    UNITY_BUILD_BATCH_SIZE 8
)
```

---

## Related Documentation

- [Project Structure](PROJECT_STRUCTURE.md) - Directory layout
- [WebView Framework](webview-framework.md) - WebView-specific build info
- [GitHub Actions](github-actions.md) - CI/CD builds
- [Troubleshooting](troubleshooting-guide.md) - Build issues