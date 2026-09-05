#!/usr/bin/env bash
# sync-agent-pointers.sh — rigenera le case nascoste degli agent partendo da agents/
# (single source of truth). Le case contengono SOLO puntatori: mai modificare i file
# puntatore a mano — modifica agents/ e rilancia questo script.
#
# Usage:
#   bash scripts/sync-agent-pointers.sh            # rigenera i puntatori
#   bash scripts/sync-agent-pointers.sh --dry-run  # mostra cosa farebbe, non scrive
#
# Configurazione case: scripts/agent-homes.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$SCRIPT_DIR/agent-homes.json"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERRORE: manifest non trovato: $MANIFEST" >&2
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
    print(f"ERRORE: cartella canonica mancante: {canonical}", file=sys.stderr)
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
                f"# Skill: {name} (puntatore)\n\n"
                f"Carica ed esegui **esattamente** `agents/skills/{s}/SKILL.md` "
                f"(single source of truth). Non improvisare il contenuto della skill.\n"
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
                f"Carica ed esegui **esattamente** `agents/workflows/{wf}` "
                f"(single source of truth). Non improvisare il contenuto del workflow.\n"
            )
            print(f"  workflow: {home['dir']}/workflows/{wf}")
            if not dry:
                write(os.path.join(wdir, wf), body)

    if home.get("rules"):
        rdir = os.path.join(hdir, "rules")
        wipe(rdir)
        for rf in rules:
            body = (
                f"# {rf} (puntatore)\n\n"
                f"**Single source of truth:** leggi e segui `agents/rules/{rf}` "
                f"prima di procedere con qualsiasi operazione.\n"
            )
            print(f"  rule: {home['dir']}/rules/{rf}")
            if not dry:
                write(os.path.join(rdir, rf), body)

print("DRY RUN (nessun file scritto)" if dry else "OK")
PYEOF
