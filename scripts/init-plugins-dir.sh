#!/usr/bin/env bash
# APC Plugins Directory Initializer (macOS/Linux)
#
# Copies the plugins-directory README template into the configured APC_PLUGINS_DIR.
# Idempotent: skips if README.md already exists (does not overwrite user customizations).
#
# Usage: bash scripts/init-plugins-dir.sh
#        bash scripts/init-plugins-dir.sh --force   # overwrite existing README

set -euo pipefail

# --- PARSE ARGUMENTS ---
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        -h|--help)
            echo "Usage: $0 [--force]"
            echo "  Copies templates/plugins-dir-readme.md into APC_PLUGINS_DIR/README.md."
            echo "  --force: overwrite an existing README.md."
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

# --- PATH RESOLUTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$ROOT_PATH/templates/plugins-dir-readme.md"

# --- RESOLVE APC_PLUGINS_DIR ---
APC_PLUGINS_DIR="$(bash "$SCRIPT_DIR/apc-config.sh" plugins-dir)" || {
    echo "Error: APC_PLUGINS_DIR not configured. Run /setup first." >&2
    exit 1
}

# --- VALIDATE PLUGINS DIR EXISTS ---
if [ ! -d "$APC_PLUGINS_DIR" ]; then
    echo "Error: Plugins directory does not exist: $APC_PLUGINS_DIR" >&2
    echo "       Run /setup first (it creates the directory)." >&2
    exit 1
fi

# --- VALIDATE TEMPLATE EXISTS ---
if [ ! -f "$TEMPLATE" ]; then
    echo "Error: README template not found: $TEMPLATE" >&2
    exit 1
fi

# --- CHECK EXISTING README ---
TARGET="$APC_PLUGINS_DIR/README.md"
if [ -f "$TARGET" ] && [ "$FORCE" != "true" ]; then
    echo "README.md already exists at $TARGET (skipping)."
    echo "Use --force to overwrite."
    exit 0
fi

# --- COMPUTE PLACEHOLDERS ---
DIR_NAME="$(basename "$APC_PLUGINS_DIR")"
REPO_URL="https://github.com/noizefield/audio-plugin-coder"

# --- COPY + SUBSTITUTE ---
# Escape replacements for sed (path may contain & or /)
ESC_PATH="$(printf '%s' "$APC_PLUGINS_DIR" | sed 's/[&/\]/\\&/g')"

sed \
    -e "s|{{PLUGINS_DIR_NAME}}|${DIR_NAME}|g" \
    -e "s|{{PLUGINS_DIR_PATH}}|${ESC_PATH}|g" \
    -e "s|{{APC_REPO_URL}}|${REPO_URL}|g" \
    "$TEMPLATE" > "$TARGET"

echo "Created README.md at $TARGET"
