#!/usr/bin/env bash
# APC JIVE Preview (Linux/macOS)
# Builds (cached) and launches jive-preview on a plugin's JIVE layout markup.
#
# Usage:
#   bash scripts/preview-jive.sh <PluginName> [version]   # e.g. v2 (default: latest)
#
# Optional flags forwarded to the tool:
#   APC_JIVE_PREVIEW_ARGS="--width 800 --height 500" bash scripts/preview-jive.sh <Name>
#
# NOTE: this script is strictly opt-in. It is only meant for plugins whose
# ui_framework is "jive"; every other framework keeps its own preview path
# (Visage -> preview-design.sh, WebView -> browser). Nothing here modifies
# the build system or any other plugin.

set -euo pipefail

# --- PARSE ARGUMENTS ---
PLUGIN_NAME="${1:-}"
VERSION="${2:-}"
if [[ -z "$PLUGIN_NAME" ]]; then
    echo "Usage: $0 <PluginName> [version]" >&2
    exit 1
fi

# --- PATH RESOLUTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
APC_PLUGINS_DIR="$(bash "$SCRIPT_DIR/apc-config.sh" plugins-dir)" || { echo "Run /setup first." >&2; exit 1; }
PLUGIN_DIR="$APC_PLUGINS_DIR/$PLUGIN_NAME"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Error: Plugin '$PLUGIN_NAME' not found in APC_PLUGINS_DIR ($APC_PLUGINS_DIR)." >&2
    echo "       Run /setup or create the plugin with /dream." >&2
    exit 1
fi

# --- NON-BINDING GUARD: only act on JIVE plugins ---
if command -v jq &>/dev/null && [ -f "$PLUGIN_DIR/status.json" ]; then
    FRAMEWORK="$(jq -r '.ui_framework // "pending"' "$PLUGIN_DIR/status.json" 2>/dev/null || echo "pending")"
    if [ "$FRAMEWORK" != "jive" ]; then
        echo "Plugin '$PLUGIN_NAME' has ui_framework='$FRAMEWORK': not a JIVE plugin." >&2
        echo "preview-jive is opt-in and does nothing for other frameworks." >&2
        case "$FRAMEWORK" in
            visage)  echo "Hint: use preview-design.sh for Visage plugins." >&2 ;;
            webview) echo "Hint: open Design/index.html in a browser for WebView plugins." >&2 ;;
        esac
        exit 1
    fi
fi

# --- LOCATE LAYOUT MARKUP ---
if [ -n "$VERSION" ]; then
    LAYOUT="$PLUGIN_DIR/Design/${VERSION}-layout.xml"
else
    LAYOUT="$(ls -1v "$PLUGIN_DIR"/Design/v*-layout.xml 2>/dev/null | tail -1 || true)"
fi

if [ -z "${LAYOUT:-}" ] || [ ! -f "$LAYOUT" ]; then
    echo "Error: no JIVE layout markup found for '$PLUGIN_NAME'." >&2
    echo "       Expected Design/v<N>-layout.xml (created by the /design phase)." >&2
    exit 1
fi
echo "--- APC JIVE PREVIEW: $PLUGIN_NAME ---"
echo "Layout: $LAYOUT"

# --- BUILD (cached; build dir lives inside the tool, not the repo root) ---
BUILD_DIR="$ROOT_PATH/_tools/jive-preview/build"
NEEDS_CONFIGURE=0
[ ! -f "$BUILD_DIR/CMakeCache.txt" ] && NEEDS_CONFIGURE=1
if [ "$NEEDS_CONFIGURE" -eq 0 ]; then
    NEWEST_SOURCE="$(find "$ROOT_PATH/_tools/jive-preview/CMakeLists.txt" "$ROOT_PATH/_tools/jive-preview/Source" -type f -newer "$BUILD_DIR/CMakeCache.txt" 2>/dev/null | head -1 || true)"
    [ -n "$NEWEST_SOURCE" ] && NEEDS_CONFIGURE=1
fi

if [ "$NEEDS_CONFIGURE" -eq 1 ]; then
    echo "Configuring jive-preview..."
    cmake -S "$ROOT_PATH/_tools/jive-preview" -B "$BUILD_DIR" \
        -DAPC_TOOLS_DIR="$ROOT_PATH" \
        -DCMAKE_BUILD_TYPE=Release
fi

echo "Building jive-preview..."
cmake --build "$BUILD_DIR" --config Release --target jive-preview

# --- LAUNCH ---
BIN="$(find "$BUILD_DIR" -name "jive-preview" -type f -perm -u+x 2>/dev/null | sort | tail -1 || true)"

if [ -z "$BIN" ]; then
    echo "Error: jive-preview binary not found under $BUILD_DIR." >&2
    exit 1
fi

echo "Launching (close the window or press Ctrl+C here to stop)..."
exec "$BIN" "$LAYOUT" ${APC_JIVE_PREVIEW_ARGS:-}
