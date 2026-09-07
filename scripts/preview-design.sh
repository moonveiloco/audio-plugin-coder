#!/usr/bin/env bash
# APC GUI Preview (macOS / Linux)
# Builds and launches the Standalone target for instant GUI preview.
#
# Usage: bash scripts/preview-design.sh <PluginName>

set -euo pipefail

# --- PARSE ARGUMENTS ---
PLUGIN_NAME="${1:-}"
if [[ -z "$PLUGIN_NAME" ]]; then
    echo "Usage: $0 <PluginName>" >&2
    exit 1
fi

# --- OS DETECTION ---
OS_NAME="$(uname -s)"
case "$OS_NAME" in
    Darwin|Linux) ;;
    *)
        echo "ERROR: Unsupported OS '$OS_NAME' (expected macOS or Linux)." >&2
        exit 1
        ;;
esac

# --- PATH RESOLUTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_PATH/build"
APC_PLUGINS_DIR="$(bash "$SCRIPT_DIR/apc-config.sh" plugins-dir)" || { echo "Run /setup first." >&2; exit 1; }
PLUGIN_DIR="$APC_PLUGINS_DIR/$PLUGIN_NAME"
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Error: Plugin '$PLUGIN_NAME' not found in APC_PLUGINS_DIR ($APC_PLUGINS_DIR)." >&2
    echo "       Run /setup or check that the plugin was created with /dream." >&2
    exit 1
fi
STATUS_JSON="$PLUGIN_DIR/status.json"

# --- DETECT FRAMEWORK ---
USE_VISAGE=false
FRAMEWORK_NAME="webview"
if [[ -f "$STATUS_JSON" ]]; then
    if command -v jq &>/dev/null; then
        fw="$(jq -r '.ui_framework // "pending"' "$STATUS_JSON" 2>/dev/null || echo "pending")"
    else
        # Fallback for systems without jq (mirrors apc-config.sh behaviour)
        fw="$(python3 -c "
import json
try:
    print(json.load(open('$STATUS_JSON')).get('ui_framework') or 'pending')
except Exception:
    print('pending')
" 2>/dev/null || echo "pending")"
    fi
    if [[ "$fw" == "visage" ]]; then
        USE_VISAGE=true
        FRAMEWORK_NAME="visage"
    fi
fi

echo "--- APC PREVIEW: $PLUGIN_NAME ---"
echo "Framework: $FRAMEWORK_NAME"

# --- LINUX: FRAMEWORK GATE ---
if [[ "$OS_NAME" == "Linux" ]] && ! $USE_VISAGE; then
    echo "ERROR: preview-design.sh on Linux only supports Visage plugins (ui_framework: \"$FRAMEWORK_NAME\")." >&2
    echo "       - JIVE:    bash scripts/preview-jive.sh $PLUGIN_NAME" >&2
    echo "       - WebView: open $PLUGIN_DIR/Design/index.html in a browser" >&2
    exit 1
fi

# --- LINUX: DEPENDENCY PREFLIGHT (hard-fail) ---
if [[ "$OS_NAME" == "Linux" ]]; then
    echo "Preflight: checking EGL / Vulkan..."
    have_lib() {
        if command -v pkg-config &>/dev/null && pkg-config --exists "$1" 2>/dev/null; then
            return 0
        fi
        ldconfig -p 2>/dev/null | grep -qi "$2"
    }
    MISSING=()
    have_lib egl libEGL.so || MISSING+=("EGL runtime (required by JUCE 9 on Linux)")
    have_lib vulkan libvulkan.so || MISSING+=("Vulkan runtime (Visage Linux renderer)")
    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo "ERROR: missing dependencies for Visage preview on Linux:" >&2
        for m in "${MISSING[@]}"; do echo "  - $m" >&2; done
        echo "Install (Arch):   sudo pacman -S libvulkan vulkan-headers" >&2
        echo "Install (Debian): sudo apt install libegl-dev libvulkan-dev" >&2
        exit 1
    fi
fi

# --- 1. CONFIGURE ---
echo "Configuring..."
VISAGE_FLAG=""
if $USE_VISAGE; then
    VISAGE_FLAG="-DAPC_ENABLE_VISAGE:BOOL=ON"
fi

if [[ "$OS_NAME" == "Darwin" ]]; then
    cmake -S "$ROOT_PATH" -B "$BUILD_DIR" \
        -G Xcode \
        -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13 \
        --fresh \
        $VISAGE_FLAG
else
    cmake -S "$ROOT_PATH" -B "$BUILD_DIR" \
        -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        --fresh \
        $VISAGE_FLAG
fi

# Verify Visage flag in cache if applicable
if $USE_VISAGE && [[ -f "$BUILD_DIR/CMakeCache.txt" ]]; then
    if ! grep -q "APC_ENABLE_VISAGE:BOOL=ON" "$BUILD_DIR/CMakeCache.txt"; then
        echo "ERROR: APC_ENABLE_VISAGE is OFF in CMakeCache.txt. Reconfigure with -DAPC_ENABLE_VISAGE=ON." >&2
        exit 1
    fi
fi

# --- 2. BUILD STANDALONE ---
echo "Compiling Standalone..."
if [[ "$OS_NAME" == "Darwin" ]]; then
    cmake --build "$BUILD_DIR" --config Release --target "${PLUGIN_NAME}_Standalone"
else
    cmake --build "$BUILD_DIR" --target "${PLUGIN_NAME}_Standalone" -j"$(nproc)"
fi

# --- 3. LAUNCH ---
if [[ "$OS_NAME" == "Darwin" ]]; then
    STANDALONE_APP="$(find "$BUILD_DIR" -name "${PLUGIN_NAME}.app" -type d 2>/dev/null | head -1 || true)"

    if [[ -n "$STANDALONE_APP" ]]; then
        echo "Launching..."
        open -W "$STANDALONE_APP"
        EXIT_CODE=$?
        if [[ $EXIT_CODE -ne 0 ]]; then
            echo "WARNING: CRASH DETECTED (exit code $EXIT_CODE). Check Console.app for crash logs."
        fi
    else
        echo "ERROR: Standalone .app not found." >&2
        exit 1
    fi
else
    # -ipath (GNU find): standalone binary is named PRODUCT_NAME, which may
    # differ in case from the plugin/target name on case-sensitive filesystems.
    STANDALONE_BIN="$(find "$BUILD_DIR" -ipath "*artefacts/Release/Standalone/${PLUGIN_NAME}" -type f -executable 2>/dev/null | head -1 || true)"

    if [[ -n "$STANDALONE_BIN" ]]; then
        echo "Launching: $STANDALONE_BIN"
        set +e
        "$STANDALONE_BIN"
        EXIT_CODE=$?
        set -e
        if [[ $EXIT_CODE -ne 0 ]]; then
            echo "WARNING: CRASH DETECTED (exit code $EXIT_CODE). Check: coredumpctl list | tail" >&2
        fi
    else
        echo "ERROR: Standalone executable not found under $BUILD_DIR." >&2
        exit 1
    fi
fi
