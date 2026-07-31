#!/usr/bin/env bash
# APC Master Builder (macOS)
# Configures, builds, and installs audio plugins using Xcode generator.
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
BUILD_DIR="$ROOT_PATH/build"
APC_PLUGINS_DIR="$HOME/Projects/VST-PLUGINS/ACP-Plugins"
if [ -d "$APC_PLUGINS_DIR/$PLUGIN_NAME" ]; then
    PLUGIN_DIR="$APC_PLUGINS_DIR/$PLUGIN_NAME"
else
    PLUGIN_DIR="$ROOT_PATH/plugins/$PLUGIN_NAME"
fi
STATUS_JSON="$PLUGIN_DIR/status.json"
BUILD_START_TIME="$(date +%s)"

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

# --- 1. CONFIGURE ---
echo "Configuring build..."
VISAGE_FLAG=""
if $USE_VISAGE; then
    VISAGE_FLAG="-DAPC_ENABLE_VISAGE:BOOL=ON"
fi

CONFIG_OUTPUT=""
CONFIG_OUTPUT=$(cmake -S "$ROOT_PATH" -B "$BUILD_DIR" \
    -G Xcode \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13 \
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
VST3_OUTPUT=$(cmake --build "$BUILD_DIR" --config Release --target "${PLUGIN_NAME}_VST3" 2>&1) || {
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
echo "Compiling AudioUnit..."
AU_OUTPUT=""
AU_OUTPUT=$(cmake --build "$BUILD_DIR" --config Release --target "${PLUGIN_NAME}_AU" 2>&1) || {
    echo "WARNING: AudioUnit build failed (non-fatal)" >&2
    echo "$AU_OUTPUT" >&2
}

# --- 4. BUILD STANDALONE ---
echo "Compiling Standalone..."
STANDALONE_OUTPUT=""
STANDALONE_OUTPUT=$(cmake --build "$BUILD_DIR" --config Release --target "${PLUGIN_NAME}_Standalone" 2>&1) || {
    echo "WARNING: Standalone build failed (non-fatal)" >&2
    echo "$STANDALONE_OUTPUT" >&2
}

# --- 5. INSTALL ---
if ! $NO_INSTALL; then
    echo "Installing plugins..."

    # Find and install VST3
    VST3_BUNDLE="$(find "$BUILD_DIR" -name "${PLUGIN_NAME}.vst3" -type d | head -1)"
    if [[ -n "$VST3_BUNDLE" ]]; then
        VST3_DEST="$HOME/Library/Audio/Plug-Ins/VST3/${PLUGIN_NAME}.vst3"
        if [[ -d "$VST3_DEST" ]]; then
            rm -rf "$VST3_DEST"
        fi
        cp -R "$VST3_BUNDLE" "$VST3_DEST"
        echo "INSTALLED VST3 to: $VST3_DEST"
    else
        echo "WARNING: VST3 bundle not found in build output"
    fi

    # Find and install AU
    AU_BUNDLE="$(find "$BUILD_DIR" -name "${PLUGIN_NAME}.component" -type d 2>/dev/null | head -1 || true)"
    if [[ -n "$AU_BUNDLE" ]]; then
        AU_DEST="$HOME/Library/Audio/Plug-Ins/Components/${PLUGIN_NAME}.component"
        if [[ -d "$AU_DEST" ]]; then
            rm -rf "$AU_DEST"
        fi
        cp -R "$AU_BUNDLE" "$AU_DEST"
        echo "INSTALLED AU to: $AU_DEST"
    fi

    # Report Standalone location
    STANDALONE_APP="$(find "$BUILD_DIR" -name "${PLUGIN_NAME}.app" -type d 2>/dev/null | head -1 || true)"
    if [[ -n "$STANDALONE_APP" ]]; then
        echo "STANDALONE built at: $STANDALONE_APP"
        echo "Tip: Copy to /Applications/ if desired."
    fi
fi

# --- 5.5. STAGE ARTIFACTS TO PLUGIN DIR (external plugins only) ---
STAGED_COUNT=0
if [[ "$PLUGIN_DIR" == "$APC_PLUGINS_DIR/"* ]]; then
    echo "Staging artifacts to plugin directory..."
    STAGE_DIR="$PLUGIN_DIR/build"
    rm -rf "$STAGE_DIR"
    mkdir -p "$STAGE_DIR/VST3" "$STAGE_DIR/AU" "$STAGE_DIR/Standalone"

    # VST3
    VST3_SRC="$(find "$BUILD_DIR" -path "*external/${PLUGIN_NAME}*artefacts/Release/VST3/${PLUGIN_NAME}.vst3" -type d 2>/dev/null | head -1 || true)"
    if [[ -n "$VST3_SRC" ]]; then
        cp -R "$VST3_SRC" "$STAGE_DIR/VST3/"
        STAGED_COUNT=$((STAGED_COUNT + 1))
        echo "STAGED VST3 → $STAGE_DIR/VST3/"
    fi

    # AU (macOS only)
    AU_SRC="$(find "$BUILD_DIR" -path "*external/${PLUGIN_NAME}*artefacts/Release/AU/${PLUGIN_NAME}.component" -type d 2>/dev/null | head -1 || true)"
    if [[ -n "$AU_SRC" ]]; then
        cp -R "$AU_SRC" "$STAGE_DIR/AU/"
        STAGED_COUNT=$((STAGED_COUNT + 1))
        echo "STAGED AU → $STAGE_DIR/AU/"
    fi

    # Standalone
    SA_SRC="$(find "$BUILD_DIR" -path "*external/${PLUGIN_NAME}*artefacts/Release/Standalone/${PLUGIN_NAME}.app" -type d 2>/dev/null | head -1 || true)"
    if [[ -n "$SA_SRC" ]]; then
        cp -R "$SA_SRC" "$STAGE_DIR/Standalone/"
        STAGED_COUNT=$((STAGED_COUNT + 1))
        echo "STAGED Standalone → $STAGE_DIR/Standalone/"
    fi

    # LV2 (Linux)
    LV2_SRC="$(find "$BUILD_DIR" -path "*external/${PLUGIN_NAME}*artefacts/Release/LV2/${PLUGIN_NAME}.lv2" -type d 2>/dev/null | head -1 || true)"
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
