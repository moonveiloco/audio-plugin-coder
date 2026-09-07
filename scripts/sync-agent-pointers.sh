#!/usr/bin/env bash
# sync-agent-pointers.sh — regenerates the agent hidden homes from agents/
# (single source of truth). The homes contain ONLY pointers: never edit the
# pointer files by hand — edit agents/ and re-run this script.
#
# Usage:
#   bash scripts/sync-agent-pointers.sh            # regenerates the pointers
#   bash scripts/sync-agent-pointers.sh --dry-run  # shows what it would do, without writing
#
# Home configuration: scripts/agent-homes.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$SCRIPT_DIR/agent-homes.json"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: manifest not found: $MANIFEST" >&2
    exit 1
fi

python3 - "$ROOT" "$MANIFEST" "$DRY_RUN" <<'PYEOF'
import json
import os
import re
import shutil
import sys

root, manifest_path, dry = sys.argv[1], sys.argv[2], sys.argv[3] == "1"

with open(manifest_path, encoding="utf-8") as f:
    manifest = json.load(f)

canonical = os.path.join(root, manifest["canonical_dir"])
if not os.path.isdir(canonical):
    print(f"ERROR: canonical folder missing: {canonical}", file=sys.stderr)
    sys.exit(1)


def read_frontmatter(path):
    with open(path, encoding="utf-8") as f:
        txt = f.read()
    m = re.match(r"^---\n(.*?)\n---\n", txt, re.DOTALL)
    fields = {}
    if m:
        for line in m.group(1).splitlines():
            mm = re.match(r"^(\w+):\s*(.*)$", line)
            if mm:
                fields[mm.group(1)] = mm.group(2).strip().strip('"')
    return fields


def yaml_quote(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def wipe(path):
    if os.path.isdir(path):
        shutil.rmtree(path)


def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


skills_dir = os.path.join(canonical, "skills")
skills = sorted(
    d for d in os.listdir(skills_dir)
    if os.path.isfile(os.path.join(skills_dir, d, "SKILL.md"))
)
workflows = sorted(
    f for f in os.listdir(os.path.join(canonical, "workflows")) if f.endswith(".md")
)
rules = sorted(
    f for f in os.listdir(os.path.join(canonical, "rules")) if f.endswith(".md")
)

for home in manifest["homes"]:
    hdir = os.path.join(root, home["dir"])
    print(f"== {home['dir']} ==")

    if home.get("skills"):
        sdir = os.path.join(hdir, "skills")
        wipe(sdir)
        for s in skills:
            fm = read_frontmatter(os.path.join(skills_dir, s, "SKILL.md"))
            name = fm.get("name", s)
            desc = fm.get("description", "")
            body = (
                f"---\nname: {name}\ndescription: {yaml_quote(desc)}\n---\n\n"
                f"# Skill: {name} (pointer)\n\n"
                f"Load and run **exactly** `agents/skills/{s}/SKILL.md` "
                f"(single source of truth). Do not improvise the skill content.\n"
            )
            print(f"  skill: {home['dir']}/skills/{s}/SKILL.md")
            if not dry:
                write(os.path.join(sdir, s, "SKILL.md"), body)

    if home.get("workflows"):
        wdir = os.path.join(hdir, "workflows")
        wipe(wdir)
        for wf in workflows:
            fm = read_frontmatter(os.path.join(canonical, "workflows", wf))
            desc = fm.get("description", "")
            body = (
                f"---\ndescription: {yaml_quote(desc)}\n---\n\n"
                f"Load and run **exactly** `agents/workflows/{wf}` "
                f"(single source of truth). Do not improvise the workflow content.\n"
            )
            print(f"  workflow: {home['dir']}/workflows/{wf}")
            if not dry:
                write(os.path.join(wdir, wf), body)

    if home.get("rules"):
        rdir = os.path.join(hdir, "rules")
        wipe(rdir)
        for rf in rules:
            body = (
                f"# {rf} (pointer)\n\n"
                f"**Single source of truth:** read and follow `agents/rules/{rf}` "
                f"before proceeding with any operation.\n"
            )
            print(f"  rule: {home['dir']}/rules/{rf}")
            if not dry:
                write(os.path.join(rdir, rf), body)

print("DRY RUN (no file written)" if dry else "OK")
PYEOF
