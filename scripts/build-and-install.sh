#!/usr/bin/env bash
# APC Master Builder (macOS / Linux)
# Configures, builds, and installs audio plugins.
# macOS: Xcode generator. Linux: "Unix Makefiles" generator.
#
# Usage: bash scripts/build-and-install.sh <PluginName> [--no-install] [--skip-tests]

set -euo pipefail

# --- PARSE ARGUMENTS ---
PLUGIN_NAME=""
NO_INSTALL=false
SKIP_TESTS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-install) NO_INSTALL=true; shift ;;
        --skip-tests) SKIP_TESTS=true; shift ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) PLUGIN_NAME="$1"; shift ;;
    esac
done

if [[ -z "$PLUGIN_NAME" ]]; then
    echo "Usage: $0 <PluginName> [--no-install] [--skip-tests]" >&2
    exit 1
fi

# --- PATH RESOLUTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
APC_PLUGINS_DIR="$(bash "$SCRIPT_DIR/apc-config.sh" plugins-dir)" || { echo "Run /setup first." >&2; exit 1; }
PLUGIN_DIR="$APC_PLUGINS_DIR/$PLUGIN_NAME"
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Error: Plugin '$PLUGIN_NAME' not found in APC_PLUGINS_DIR ($APC_PLUGINS_DIR)." >&2
    echo "       Run /setup or check that the plugin was created with /dream." >&2
    exit 1
fi
# Build dir lives INSIDE the plugin directory (self-contained per-plugin builds)
BUILD_DIR="$PLUGIN_DIR/build"
# APC_TOOLS_DIR: the APC repo root holding _tools/JUCE, _tools/visage, include/.
# Read from config (tools_dir), falling back to the repo owning scripts/.
APC_TOOLS_DIR="$(bash "$SCRIPT_DIR/apc-config.sh" tools-dir 2>/dev/null || true)"
if [[ -z "$APC_TOOLS_DIR" ]]; then
    APC_TOOLS_DIR="$ROOT_PATH"
fi
STATUS_JSON="$PLUGIN_DIR/status.json"
BUILD_START_TIME="$(date +%s)"

# --- PLATFORM DETECTION ---
OS_NAME="$(uname -s)"
IS_LINUX=false
IS_MACOS=false
if [[ "$OS_NAME" == "Darwin" ]]; then
    IS_MACOS=true
elif [[ "$OS_NAME" == "Linux" ]]; then
    IS_LINUX=true
fi

# CMake target name: derive from the plugin's juce_add_plugin(...) call.
# Templates use the lowercase plugin name, so CMake targets are lowercase.
CMAKE_TARGET="$(grep -oE 'juce_add_plugin\([A-Za-z0-9_]+' "$PLUGIN_DIR/CMakeLists.txt" 2>/dev/null | head -1 | sed 's/juce_add_plugin(//')"
if [[ -z "$CMAKE_TARGET" ]]; then
    CMAKE_TARGET="${PLUGIN_NAME,,}"
fi

# --- IMPORT MODULES ---
# shellcheck source=state-management.sh
. "$SCRIPT_DIR/state-management.sh"
# shellcheck source=error-detection.sh
. "$SCRIPT_DIR/error-detection.sh"

# --- DETECT FRAMEWORK ---
USE_VISAGE=false
if [[ -f "$STATUS_JSON" ]] && command -v jq &>/dev/null; then
    fw="$(jq -r '.ui_framework // "pending"' "$STATUS_JSON" 2>/dev/null || echo "pending")"
    if [[ "$fw" == "visage" ]]; then
        USE_VISAGE=true
    fi
fi

echo "--- APC BUILDER: $PLUGIN_NAME ---"
if $USE_VISAGE; then
    echo "Framework: visage"
fi

# --- VALIDATE PREREQUISITES ---
if [[ -f "$STATUS_JSON" ]] && command -v jq &>/dev/null; then
    current_phase="$(jq -r '.current_phase // ""' "$STATUS_JSON" 2>/dev/null || echo "")"
    if [[ "$current_phase" != "code" && "$current_phase" != "ship" && "$current_phase" != "complete" ]] && ! $SKIP_TESTS; then
        echo "WARNING: Plugin implementation not marked as complete. Use --skip-tests to override."
    fi
fi

# --- APPLY SUBMODULE PATCHES (e.g. JIVE JUCE 9 compat) ---
# Idempotent: safe to run on every build. See agents/rules/jive-integration.md.
bash "$SCRIPT_DIR/apply-submodule-patches.sh"

# --- 1. CONFIGURE ---
echo "Configuring build..."
VISAGE_FLAG=""
if $USE_VISAGE; then
    VISAGE_FLAG="-DAPC_ENABLE_VISAGE:BOOL=ON"
fi

CMAKE_GEN_ARGS=()
CMAKE_CONFIG_TYPE=""
if $IS_MACOS; then
    CMAKE_GEN_ARGS=(-G Xcode -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13)
else
    CMAKE_GEN_ARGS=(-G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release)
fi

CONFIG_OUTPUT=""
CONFIG_OUTPUT=$(cmake -S "$PLUGIN_DIR" -B "$BUILD_DIR" \
    "${CMAKE_GEN_ARGS[@]}" \
    -DAPC_TOOLS_DIR="$APC_TOOLS_DIR" \
    --fresh \
    $VISAGE_FLAG 2>&1) || {
    echo "ERROR: CMake configuration failed" >&2
    echo "$CONFIG_OUTPUT" >&2

    if command -v jq &>/dev/null; then
        errors="$(parse_build_errors "$CONFIG_OUTPUT")"
        error_count="$(echo "$errors" | jq 'length')"
        if (( error_count > 0 )); then
            known="$(find_known_issue "$errors" 2>/dev/null || true)"
            if [[ -n "$known" ]]; then
                echo "Known issue detected: $(echo "$known" | jq -r '.title')"
            else
                new_issue_from_error "$errors" "$CONFIG_OUTPUT" 2>/dev/null || true
            fi
        fi
    fi
    exit 1
}

# --- 2. BUILD VST3 ---
echo "Compiling VST3..."
VST3_OUTPUT=""
VST3_OUTPUT=$(cmake --build "$BUILD_DIR" --config Release --target "${CMAKE_TARGET}_VST3" 2>&1) || {
    echo "ERROR: VST3 build failed" >&2
    echo "$VST3_OUTPUT" >&2

    if command -v jq &>/dev/null; then
        errors="$(parse_build_errors "$VST3_OUTPUT")"
        error_count="$(echo "$errors" | jq 'length')"
        if (( error_count > 0 )); then
            known="$(find_known_issue "$errors" 2>/dev/null || true)"
            if [[ -n "$known" ]]; then
                echo "Known issue detected: $(echo "$known" | jq -r '.title')"
            else
                new_issue_from_error "$errors" "$VST3_OUTPUT" 2>/dev/null || true
            fi
        fi
    fi
    exit 1
}

# --- 3. BUILD AU (AudioUnit) ---
if $IS_MACOS; then
    echo "Compiling AudioUnit..."
    AU_OUTPUT=""
    AU_OUTPUT=$(cmake --build "$BUILD_DIR" --config Release --target "${CMAKE_TARGET}_AU" 2>&1) || {
        echo "WARNING: AudioUnit build failed (non-fatal)" >&2
        echo "$AU_OUTPUT" >&2
    }
else
    echo "Skipping AudioUnit (macOS only)"
fi

# --- 4. BUILD STANDALONE ---
echo "Compiling Standalone..."
STANDALONE_OUTPUT=""
STANDALONE_OUTPUT=$(cmake --build "$BUILD_DIR" --config Release --target "${CMAKE_TARGET}_Standalone" 2>&1) || {
    echo "WARNING: Standalone build failed (non-fatal)" >&2
    echo "$STANDALONE_OUTPUT" >&2
}

# --- 5. INSTALL ---
if ! $NO_INSTALL; then
    echo "Installing plugins..."

    # Find and install VST3
    # -iname: JUCE names artifacts after PRODUCT_NAME, which may differ in
    # case from the plugin/target name on case-sensitive filesystems.
    VST3_BUNDLE="$(find "$BUILD_DIR" -iname "${PLUGIN_NAME}.vst3" -type d | head -1)"
    if [[ -n "$VST3_BUNDLE" ]]; then
        # Preserve the found bundle's actual name (never rename on install:
        # DAWs identify VST3 by bundle name matching the module description).
        VST3_ARTIFACT_NAME="$(basename "$VST3_BUNDLE")"
        if $IS_MACOS; then
            VST3_DEST="$HOME/Library/Audio/Plug-Ins/VST3/${VST3_ARTIFACT_NAME}"
        else
            VST3_DEST="$HOME/.vst3/${VST3_ARTIFACT_NAME}"
        fi
        if [[ -d "$VST3_DEST" ]]; then
            rm -rf "$VST3_DEST"
        fi
        mkdir -p "$(dirname "$VST3_DEST")"
        cp -R "$VST3_BUNDLE" "$VST3_DEST"
        echo "INSTALLED VST3 to: $VST3_DEST"
    else
        echo "WARNING: VST3 bundle not found in build output"
    fi

    if $IS_MACOS; then
        # Find and install AU
        AU_BUNDLE="$(find "$BUILD_DIR" -iname "${PLUGIN_NAME}.component" -type d 2>/dev/null | head -1 || true)"
        if [[ -n "$AU_BUNDLE" ]]; then
            AU_DEST="$HOME/Library/Audio/Plug-Ins/Components/$(basename "$AU_BUNDLE")"
            if [[ -d "$AU_DEST" ]]; then
                rm -rf "$AU_DEST"
            fi
            cp -R "$AU_BUNDLE" "$AU_DEST"
            echo "INSTALLED AU to: $AU_DEST"
        fi

        # Report Standalone location
        STANDALONE_APP="$(find "$BUILD_DIR" -iname "${PLUGIN_NAME}.app" -type d 2>/dev/null | head -1 || true)"
        if [[ -n "$STANDALONE_APP" ]]; then
            echo "STANDALONE built at: $STANDALONE_APP"
            echo "Tip: Copy to /Applications/ if desired."
        fi
    fi
fi

# --- 5.5. STAGE ARTIFACTS IN PLUGIN DIR ---
# Build output already lives in $PLUGIN_DIR/build (per-plugin builds).
# Organize the JUCE <name>_artefacts/Release bundles into VST3/AU/Standalone/LV2
# subfolders so tooling (build_artifacts_json) can enumerate them.
STAGED_COUNT=0
echo "Staging artifacts in plugin build dir..."
STAGE_DIR="$PLUGIN_DIR/build"
rm -rf "$STAGE_DIR/VST3" "$STAGE_DIR/AU" "$STAGE_DIR/Standalone" "$STAGE_DIR/LV2"
mkdir -p "$STAGE_DIR/VST3" "$STAGE_DIR/AU" "$STAGE_DIR/Standalone"

# VST3 (-iname: artifact named after PRODUCT_NAME, see install section)
VST3_SRC="$(find "$BUILD_DIR" -iname "${PLUGIN_NAME}.vst3" -type d 2>/dev/null | head -1 || true)"
if [[ -n "$VST3_SRC" ]]; then
    cp -R "$VST3_SRC" "$STAGE_DIR/VST3/"
    STAGED_COUNT=$((STAGED_COUNT + 1))
    echo "STAGED VST3 → $STAGE_DIR/VST3/"
fi

# AU (macOS only)
if $IS_MACOS; then
    AU_SRC="$(find "$BUILD_DIR" -iname "${PLUGIN_NAME}.component" -type d 2>/dev/null | head -1 || true)"
    if [[ -n "$AU_SRC" ]]; then
        cp -R "$AU_SRC" "$STAGE_DIR/AU/"
        STAGED_COUNT=$((STAGED_COUNT + 1))
        echo "STAGED AU → $STAGE_DIR/AU/"
    fi
fi

# Standalone (macOS: .app bundle; Linux: executable ELF)
SA_SRC=""
if $IS_MACOS; then
    SA_SRC="$(find "$BUILD_DIR" -iname "${PLUGIN_NAME}.app" -type d 2>/dev/null | head -1 || true)"
else
    # -ipath (GNU find): path context is REQUIRED here — the VST3 bundle
    # contains an executable named after PRODUCT_NAME too; -iname alone
    # could match it instead of the Standalone ELF.
    SA_SRC="$(find "$BUILD_DIR" -ipath "*artefacts/Release/Standalone/${PLUGIN_NAME}" -type f -executable 2>/dev/null | head -1 || true)"
fi
if [[ -n "$SA_SRC" ]]; then
    cp -R "$SA_SRC" "$STAGE_DIR/Standalone/"
    STAGED_COUNT=$((STAGED_COUNT + 1))
    echo "STAGED Standalone → $STAGE_DIR/Standalone/"
fi

# LV2 (Linux)
LV2_SRC="$(find "$BUILD_DIR" -iname "${PLUGIN_NAME}.lv2" -type d 2>/dev/null | head -1 || true)"
if [[ -n "$LV2_SRC" ]]; then
    mkdir -p "$STAGE_DIR/LV2"
    cp -R "$LV2_SRC" "$STAGE_DIR/LV2/"
    STAGED_COUNT=$((STAGED_COUNT + 1))
    echo "STAGED LV2 → $STAGE_DIR/LV2/"
fi

# Remove empty format dirs to keep things tidy
for d in "$STAGE_DIR"/*/; do
    rmdir "$d" 2>/dev/null || true
done

if [[ $STAGED_COUNT -eq 0 ]]; then
    echo "WARNING: no artifacts staged (no matching bundles found in build cache)"
fi

# --- 6. UPDATE BUILD STATUS ---
BUILD_END="$(date +%s)"
BUILD_DURATION=$((BUILD_END - BUILD_START_TIME))

if command -v jq &>/dev/null && [[ -f "$STATUS_JSON" ]]; then
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # Detect JUCE version + compiler (best-effort)
    JUCE_VER="$(detect_juce_version "$BUILD_DIR" 2>/dev/null || echo unknown)"
    COMPILER_VER="$(${CXX:-c++} --version 2>/dev/null | head -1 || echo unknown)"

    # Build artifacts array (only for staged external plugins)
    ARTIFACTS_JSON="[]"
    if [[ "$PLUGIN_DIR" == "$APC_PLUGINS_DIR/"* ]] && [[ -d "$PLUGIN_DIR/build" ]]; then
        ARTIFACTS_JSON="$(build_artifacts_json "$PLUGIN_DIR/build")"
    fi

    # Determine build type string from staged formats (or fallback to "VST3")
    BUILD_TYPE="VST3"
    if [[ "$PLUGIN_DIR" == "$APC_PLUGINS_DIR/"* ]] && [[ -d "$PLUGIN_DIR/build" ]]; then
        BUILD_TYPE=""
        for fmt_dir in "$PLUGIN_DIR/build"/*/; do
            fmt="$(basename "$fmt_dir")"
            [[ -z "$BUILD_TYPE" ]] && BUILD_TYPE="$fmt" || BUILD_TYPE="${BUILD_TYPE}+${fmt}"
        done
        [[ -z "$BUILD_TYPE" ]] && BUILD_TYPE="VST3"
    fi

    # Determine overall status: we got here → VST3 succeeded. AU/Standalone warnings are non-fatal → "success" still.
    BUILD_STATUS="success"

    jq --arg ts "$timestamp" \
       --arg status "$BUILD_STATUS" \
       --arg dur "$BUILD_DURATION" \
       --arg btype "$BUILD_TYPE" \
       --arg juce "$JUCE_VER" \
       --arg comp "$COMPILER_VER" \
       --argjson arts "$ARTIFACTS_JSON" \
       '.build_info = {
           last_build_at: $ts,
           last_build_status: $status,
           last_build_duration_sec: ($dur|tonumber),
           last_build_type: $btype,
           artifacts: $arts,
           juce_version: $juce,
           compiler: $comp
       } | .last_modified = $ts
       | .validation.build_completed = true' \
       "$STATUS_JSON" > "$STATUS_JSON.tmp" && mv "$STATUS_JSON.tmp" "$STATUS_JSON"

    echo "Build status updated in $STATUS_JSON"
elif [[ -f "$STATUS_JSON" ]]; then
    # jq not available: fall back to legacy 2-field update
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    update_plugin_state "$PLUGIN_DIR" \
        "validation.build_completed=true" \
        "validation.build_timestamp=$timestamp" \
        2>/dev/null || true
fi

echo "Build process complete!"
