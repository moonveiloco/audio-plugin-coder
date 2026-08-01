#!/usr/bin/env bash
# ACP Config Manager (macOS/Linux)
# Reads/writes the global ACP configuration at ~/.config/acp/config.json
# This is the single source of truth for plugins_dir, juce_dir, and setup state.
#
# Usage:
#   bash scripts/acp-config.sh path          # print config file path
#   bash scripts/acp-config.sh get <key>     # get a value (empty if missing)
#   bash scripts/acp-config.sh set <key> <v> # set a value
#   bash scripts/acp-config.sh is-setup      # exit 0 if setup_complete=true, 1 otherwise
#   bash scripts/acp-config.sh plugins-dir   # print plugins_dir or empty
#   bash scripts/acp-config.sh juce-dir      # print juce_dir or empty
#   bash scripts/acp-config.sh init          # create default config if missing

set -euo pipefail

_acp_config_path() {
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/acp/config.json"
}

_acp_config_ensure_dir() {
    local dir
    dir="$(dirname "$(_acp_config_path)")"
    mkdir -p "$dir"
}

_acp_config_init() {
    local cfg
    cfg="$(_acp_config_path)"
    if [[ ! -f "$cfg" ]]; then
        _acp_config_ensure_dir
        cat > "$cfg" <<'JSON'
{
  "version": 1,
  "setup_complete": false,
  "setup_at": null,
  "plugins_dir": null,
  "plugins_folder_name": null,
  "juce_dir": null
}
JSON
        echo "Created default config at $cfg" >&2
    fi
}

_acp_config_get() {
    local key="$1"
    local cfg
    cfg="$(_acp_config_path)"
    if [[ ! -f "$cfg" ]]; then
        echo ""
        return 0
    fi
    if command -v jq &>/dev/null; then
        jq -r --arg k "$key" '.[$k] // empty' "$cfg" 2>/dev/null || echo ""
    else
        # Fallback: simple grep-based extraction (for systems without jq)
        python3 -c "
import json,sys
try:
    d=json.load(open('$cfg'))
    v=d.get('$key')
    print('' if v is None else v)
except: print('')
" 2>/dev/null || echo ""
    fi
}

_acp_config_set() {
    local key="$1"
    local val="$2"
    local cfg
    cfg="$(_acp_config_path)"
    if [[ ! -f "$cfg" ]]; then
        _acp_config_init
    fi
    if command -v jq &>/dev/null; then
        local tmp
        tmp="$(mktemp)"
        jq --arg k "$key" --arg v "$val" '.[$k] = $v' "$cfg" > "$tmp"
        mv "$tmp" "$cfg"
    else
        python3 -c "
import json
cfg='$cfg'
d=json.load(open(cfg))
d['$key']='$val'
json.dump(d,open(cfg,'w'),indent=2)
" 2>/dev/null
    fi
}

_acp_config_is_setup() {
    local val
    val="$(_acp_config_get setup_complete)"
    [[ "$val" == "true" ]]
}

case "${1:-help}" in
    path)
        _acp_config_path
        ;;
    get)
        if [[ $# -lt 2 ]]; then echo "Usage: $0 get <key>" >&2; exit 1; fi
        _acp_config_get "$2"
        ;;
    set)
        if [[ $# -lt 3 ]]; then echo "Usage: $0 set <key> <value>" >&2; exit 1; fi
        _acp_config_set "$2" "$3"
        ;;
    is-setup)
        if _acp_config_is_setup; then exit 0; else exit 1; fi
        ;;
    plugins-dir)
        _acp_config_get plugins_dir
        ;;
    juce-dir)
        _acp_config_get juce_dir
        ;;
    init)
        _acp_config_init
        ;;
    help|--help|-h)
        cat <<'USAGE'
ACP Config Manager

Commands:
  path           Print the config file path
  get <key>      Get a config value
  set <key> <v>  Set a config value
  is-setup       Exit 0 if setup_complete=true, else exit 1
  plugins-dir    Print plugins_dir (empty if not set)
  juce-dir       Print juce_dir (empty if not set)
  init           Create default config if missing
USAGE
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
