#!/usr/bin/env bash
# validate-agent-config.sh — contract test per la configurazione agent-agnostic di APC.
#
# Verifica che:
#   1. agents/ esista con la struttura attesa
#   2. ogni SKILL.md abbia frontmatter name + description
#   3. name == nome cartella (eccezione documentata: skill_design_webview)
#   4. nessun nome skill duplicato (canonica vs gusci)
#   5. ogni puntatore nei gusci risolva a un file canonico esistente
#   6. niente riferimenti a macchine (R:\, _VST_Development, C:\Users\<utente>)
#   7. niente riferimenti JUCE stanti (~/JUCE, JUCE_DIR, "JUCE 8" fuori dai doc HISTORICAL)
#   8. AGENTS.md / CLAUDE.md / opencode.jsonc esistano e i loro import risolvano
#   9. .gitignore non escluda agents/, AGENTS.md, CLAUDE.md
#  10. le case nel manifest (scripts/agent-homes.json) esistano
#
# Usage: bash scripts/validate-agent-config.sh   (exit 0 = OK, 1 = violazioni)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

python3 - "$ROOT" <<'PYEOF'
import json
import os
import re
import sys

root = sys.argv[1]
errors = []
warnings = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def rel(p):
    return os.path.relpath(p, root)


# ---------- 1. struttura canonica ----------
canonical = os.path.join(root, "agents")
for sub in ("rules", "skills", "workflows", "guides", "troubleshooting"):
    if not os.path.isdir(os.path.join(canonical, sub)):
        err(f"agents/{sub}/ mancante")

# ---------- 2/3. frontmatter skill ----------
skills_dir = os.path.join(canonical, "skills")
skill_folders = sorted(
    d for d in os.listdir(skills_dir)
    if os.path.isfile(os.path.join(skills_dir, d, "SKILL.md"))
) if os.path.isdir(skills_dir) else []

NAME_EXCEPTIONS = {"skill_design_webview"}  # name: juce-webview-windows (zero churn, documentato)

names = []
for s in skill_folders:
    p = os.path.join(skills_dir, s, "SKILL.md")
    txt = open(p, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n", txt, re.DOTALL)
    if not m:
        err(f"{rel(p)}: frontmatter mancante")
        continue
    fields = dict(re.findall(r"^(\w+):\s*(.*)$", m.group(1), re.MULTILINE))
    if "name" not in fields or "description" not in fields:
        err(f"{rel(p)}: frontmatter incompleto (richiesti name + description)")
        continue
    name = fields["name"].strip().strip('"')
    names.append((name, s))
    if name != s and s not in NAME_EXCEPTIONS:
        err(f"{rel(p)}: name '{name}' != nome cartella '{s}'")

# ---------- 4. duplicati ----------
seen = {}
for name, s in names:
    seen.setdefault(name, []).append(s)
for name, folders in seen.items():
    if len(folders) > 1:
        err(f"nome skill duplicato '{name}' in: {', '.join(folders)}")

# nomi nei gusci: uniqueness per scope di discovery (canonica esclusa:
# nessun tool la scopre direttamente, vi si accede solo via puntatori/import)
SCOPE_OPENCODE = [".opencode/skills", ".claude/skills"]  # opencode scopre entrambe
home_scope = {".claude/skills": SCOPE_OPENCODE, ".kilocode/skills": [".kilocode/skills"], ".opencode/skills": SCOPE_OPENCODE}
for scope_home, scope_dirs in home_scope.items():
    base = os.path.join(root, scope_home)
    if not os.path.isdir(base):
        continue
    scope_names = {}
    for d in sorted(os.listdir(base)):
        sp = os.path.join(base, d, "SKILL.md")
        if not os.path.isfile(sp):
            continue
        txt2 = open(sp, encoding="utf-8").read()
        m = re.search(r"^name:\s*(\S+)", txt2, re.MULTILINE)
        if m:
            scope_names.setdefault(m.group(1).strip().strip('"'), []).append(f"{scope_home}/{d}")
    for name, locs in scope_names.items():
        if len(locs) > 1:
            err(f"nome skill duplicato in {scope_home}: '{name}' in {', '.join(locs)}")

# ---------- 5. puntatori risolti ----------
AGENT_REF = re.compile(r"agents/(?:skills/[\w.-]+/SKILL\.md|workflows/[\w.-]+\.md|rules/[\w.-]+\.md|troubleshooting/[\w./-]+|guides/[\w.-]+\.md)")
home_dirs = [".claude", ".kilocode"]
pointer_count = 0
for home in home_dirs:
    if not os.path.isdir(os.path.join(root, home)):
        continue
    for sub in ("skills", "workflows", "rules"):
        base = os.path.join(root, home, sub)
        if not os.path.isdir(base):
            continue
        for dirpath, _, files in os.walk(base):
            for fn in files:
                if not fn.endswith(".md"):
                    continue
                p = os.path.join(dirpath, fn)
                txt = open(p, encoding="utf-8").read()
                refs = AGENT_REF.findall(txt)
                if not refs:
                    err(f"{rel(p)}: puntatore senza riferimento a agents/")
                    continue
                pointer_count += 1
                for r in refs:
                    if not os.path.exists(os.path.join(root, r)):
                        err(f"{rel(p)}: target inesistente agents/{r}")

# ---------- 6/7. riferimenti stanti ----------
config_files = []
for base in ("agents", ".claude", ".kilocode", ".opencode", "scripts"):
    for dirpath, _, files in os.walk(os.path.join(root, base)):
        if "node_modules" in dirpath:
            continue
        for fn in files:
            if fn.endswith((".md", ".yaml", ".yml", ".json", ".jsonc")):
                config_files.append(os.path.join(dirpath, fn))
for extra in ("AGENTS.md", "CLAUDE.md", "opencode.jsonc"):
    p = os.path.join(root, extra)
    if os.path.isfile(p):
        config_files.append(p)

MACHINE_PATTERNS = [r"R:\\", r"_VST_Development", r"C:\\Users\\"]
NEGATION = re.compile(r"(non\b|never|not\b|mai|vietato|forbidden)", re.IGNORECASE)
JUCE8_OK_FILE = re.compile(r"troubleshooting/resolutions/.*juce8|troubleshooting/resolutions/.*juce-8")
JUCE8_OK_LINE = re.compile(r"JUCE 8(→|\+)|Da JUCE 8|since JUCE 8|JUCE 7→8", re.IGNORECASE)
JUCE8_OK_LINE2 = re.compile(r"(storico|storici|historical)", re.IGNORECASE)

for p in config_files:
    txt = open(p, encoding="utf-8", errors="replace").read()
    r = rel(p)
    for pat in MACHINE_PATTERNS:
        if re.search(pat, txt):
            err(f"{r}: riferimento macchina '{pat}'")
    if re.search(r"JUCE_DIR\s*[=:]", txt) and "agents/rules/juce-build-protocols.md" not in r:
        err(f"{r}: assegnazione JUCE_DIR stantia")
    hist = bool(JUCE8_OK_FILE.search(r)) and "HISTORICAL" in txt[:400]
    for i, line in enumerate(txt.splitlines(), 1):
        if "~/JUCE" in line and not NEGATION.search(line):
            err(f"{r}:{i}: riferimento '~/JUCE' senza negazione")
        if "JUCE 8" in line and not hist and not JUCE8_OK_LINE.search(line) and not JUCE8_OK_LINE2.search(line):
            err(f"{r}:{i}: 'JUCE 8' attivo fuori dai documenti HISTORICAL -> {line.strip()[:80]}")

# ---------- 8. entry points ----------
for f in ("AGENTS.md", "CLAUDE.md", "opencode.jsonc", "scripts/agent-homes.json"):
    if not os.path.isfile(os.path.join(root, f)):
        err(f"{f} mancante")

claude_md = os.path.join(root, "CLAUDE.md")
if os.path.isfile(claude_md):
    txt = open(claude_md, encoding="utf-8").read()
    for imp in re.findall(r"^@(\S+)", txt, re.MULTILINE):
        if not imp.startswith("~") and not os.path.exists(os.path.join(root, imp)):
            err(f"CLAUDE.md: import @{imp} inesistente")

oc = os.path.join(root, "opencode.jsonc")
if os.path.isfile(oc):
    txt = open(oc, encoding="utf-8").read()
    txt_nc = re.sub(r"(?<!:)//[^\n]*", "", txt)
    try:
        cfg = json.loads(txt_nc)
        for inst in cfg.get("instructions", []):
            if not os.path.exists(os.path.join(root, inst)):
                err(f"opencode.jsonc: instruction '{inst}' inesistente")
        if "skills" in cfg:
            warn("opencode.jsonc contiene ancora 'skills.paths' (rimuoverla: la discovery nativa di .claude/skills evita duplicati)")
    except json.JSONDecodeError as e:
        err(f"opencode.jsonc: JSON non valido ({e})")

# ---------- 9. .gitignore ----------
gi = os.path.join(root, ".gitignore")
if os.path.isfile(gi):
    for i, line in enumerate(open(gi, encoding="utf-8"), 1):
        s = line.strip()
        if s in ("agents", "agents/", "/agents", "AGENTS.md", "CLAUDE.md", "/AGENTS.md", "/CLAUDE.md"):
            err(f".gitignore:{i}: esclude '{s}'")
else:
    warn(".gitignore mancante")

# ---------- 10. manifest ----------
mf = os.path.join(root, "scripts", "agent-homes.json")
if os.path.isfile(mf):
    try:
        manifest = json.load(open(mf, encoding="utf-8"))
        if not os.path.isdir(os.path.join(root, manifest.get("canonical_dir", ""))):
            err(f"manifest: canonical_dir '{manifest.get('canonical_dir')}' inesistente")
        for h in manifest.get("homes", []):
            if not os.path.isdir(os.path.join(root, h.get("dir", ""))):
                err(f"manifest: home '{h.get('dir')}' inesistente")
    except json.JSONDecodeError as e:
        err(f"agent-homes.json: JSON non valido ({e})")

# ---------- report ----------
print(f"Puntatori verificati: {pointer_count}")
print(f"Skill canoniche: {len(skill_folders)}")
if warnings:
    print("\nWARNING:")
    for w in warnings:
        print(f"  ⚠ {w}")
if errors:
    print(f"\nFAIL ({len(errors)} violazioni):")
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)
print("\nOK — configurazione agent valida")
PYEOF
