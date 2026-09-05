#!/usr/bin/env bash
# APC Submodule Patch Applicator (macOS / Linux)
# Idempotently applies patches from patches/<SubModuleName>/*.patch onto the
# matching submodule working tree at _tools/<SubModuleName>.
#
# Generic: works for any submodule that has a patches/<name>/ directory.
#
# Usage:
#   bash scripts/apply-submodule-patches.sh              # apply all
#   bash scripts/apply-submodule-patches.sh JIVE         # apply one submodule's patches

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCHES_DIR="$ROOT_PATH/patches"

if [[ ! -d "$PATCHES_DIR" ]]; then
    echo "No patches/ directory — nothing to apply."
    exit 0
fi

TARGETS=()
if [[ $# -gt 0 ]]; then
    TARGETS=("$1")
else
    shopt -s nullglob
    for d in "$PATCHES_DIR"/*/; do
        TARGETS+=("$(basename "$d")")
    done
    shopt -u nullglob
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo "No patch sets found in $PATCHES_DIR — nothing to apply."
    exit 0
fi

APPLIED=0
SKIPPED=0
MISSING=0

for name in "${TARGETS[@]}"; do
    SUBMODULE="$ROOT_PATH/_tools/$name"

    if [[ ! -e "$SUBMODULE/.git" ]]; then
        echo "SKIP: _tools/$name not initialised (run: git submodule update --init _tools/$name)"
        MISSING=$((MISSING + 1))
        continue
    fi

    shopt -s nullglob
    PATCH_LIST=("$PATCHES_DIR/$name"/*.patch)
    shopt -u nullglob

    for patch in "${PATCH_LIST[@]}"; do
        base="$(basename "$patch")"
        if git -C "$SUBMODULE" apply --reverse --check --quiet "$patch" 2>/dev/null; then
            echo "SKIP: $name/$base already applied"
            SKIPPED=$((SKIPPED + 1))
        elif git -C "$SUBMODULE" apply --check --quiet "$patch" 2>/dev/null; then
            git -C "$SUBMODULE" apply "$patch"
            echo "APPLIED: $name/$base"
            APPLIED=$((APPLIED + 1))
        else
            echo "ERROR: $name/$base does not apply — _tools/$name changed upstream." >&2
            echo "       Re-generate the patch or update the pin. See agents/rules/*.md for the protocol." >&2
            exit 1
        fi
    done
done

echo "Submodule patches: $APPLIED applied, $SKIPPED already applied, $MISSING submodules missing."
