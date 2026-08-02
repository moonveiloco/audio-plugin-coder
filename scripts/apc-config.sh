#!/usr/bin/env bash
# APC Config Manager (macOS/Linux)
# Reads/writes the global APC configuration at ~/.config/apc/config.json
# This is the single source of truth for plugins_dir and setup state.
#
# Usage:
#   bash scripts/apc-config.sh path          # print config file path
#   bash scripts/apc-config.sh get <key>     # get a value (empty if missing)
#   bash scripts/apc-config.sh set <key> <v> # set a value
#   bash scripts/apc-config.sh is-setup      # exit 0 if setup_complete=true, 1 otherwise
#   bash scripts/apc-config.sh plugins-dir   # print plugins_dir (exit 1 if unset)
#   bash scripts/apc-config.sh init          # create default config if missing

set -euo pipefail

_apc_config_path() {
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/apc/config.json"
}

_apc_config_ensure_dir() {
    local dir
    dir="$(dirname "$(_apc_config_path)")"
    mkdir -p "$dir"
}

_apc_config_init() {
    local cfg
    cfg="$(_apc_config_path)"
    if [[ ! -f "$cfg" ]]; then
        _apc_config_ensure_dir
        cat > "$cfg" <<'JSON'
{
  "version": 1,
  "setup_complete": false,
  "setup_at": null,
  "plugins_dir": null,
  "plugins_folder_name": null
}
JSON
        echo "Created default config at $cfg" >&2
    fi
}

_apc_config_get() {
    local key="$1"
    local cfg
    cfg="$(_apc_config_path)"
    if [[ ! -f "$cfg" ]]; then
        echo ""
        return 0
    fi
    if command -v jq &>/dev/null; then
        jq -r --arg k "$key" 'if has($k) and (.[$k] != null) then .[$k] else empty end' "$cfg" 2>/dev/null || echo ""
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

_apc_config_set() {
    local key="$1"
    local val="$2"
    local cfg
    cfg="$(_apc_config_path)"
    if [[ ! -f "$cfg" ]]; then
        _apc_config_init
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

_apc_config_is_setup() {
    local val
    val="$(_apc_config_get setup_complete)"
    [[ "$val" == "true" ]]
}

case "${1:-help}" in
    path)
        _apc_config_path
        ;;
    get)
        if [[ $# -lt 2 ]]; then echo "Usage: $0 get <key>" >&2; exit 1; fi
        _apc_config_get "$2"
        ;;
    set)
        if [[ $# -lt 3 ]]; then echo "Usage: $0 set <key> <value>" >&2; exit 1; fi
        _apc_config_set "$2" "$3"
        ;;
    is-setup)
        if _apc_config_is_setup; then exit 0; else exit 1; fi
        ;;
    plugins-dir)
        v="$(_apc_config_get plugins_dir)"
        if [[ -z "$v" ]]; then
            echo "APC not configured: plugins_dir is null. Run /setup first." >&2
            exit 1
        fi
        echo "$v"
        ;;
    init)
        _apc_config_init
        ;;
    help|--help|-h)
        cat <<'USAGE'
APC Config Manager

Commands:
  path           Print the config file path
  get <key>      Get a config value
  set <key> <v>  Set a config value
  is-setup       Exit 0 if setup_complete=true, else exit 1
  plugins-dir    Print plugins_dir (exit 1 + stderr if unset)
  init           Create default config if missing
USAGE
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
