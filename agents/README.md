# Agent Configuration (Single Source of Truth)

Questa cartella è l'**unica fonte di verità** per skill, rules, workflows, guide e
knowledge base di troubleshooting usati da tutti i coding agent supportati da APC.

Le cartelle nascoste (`.claude/`, `.kilocode/`) contengono **solo puntatori** a questi
file, generati da `scripts/sync-agent-pointers.sh|.ps1` partendo da `scripts/agent-homes.json`.

## Struttura

```
agents/
├── rules/                  # System constraints (caricate a session start)
│   ├── agent.md            # Master Dispatcher: FIRST RUN GATE, phase gating, OS protocol
│   ├── file-naming-conventions.md
│   ├── gin-integration.md        # FigBug/Gin submodule: limitazioni + protocollo d'uso
│   └── juce-build-protocols.md   # JUCE 9 = _tools/JUCE submodule via APC_TOOLS_DIR
├── skills/                 # 12 skill con frontmatter YAML (name == nome cartella)
├── workflows/              # Orchestrazioni delle fasi (/dream /plan /design /impl /test /ship ...)
├── guides/                 # Reference documentation (state management, documentation system)
└── troubleshooting/        # Knowledge base auto-apprendente
    ├── known-issues.yaml   # 14 issue note
    └── resolutions/        # Documenti di risoluzione
```

## Come caricano gli agent

| Agent | Rules | Skills | Workflows |
|---|---|---|---|
| Claude Code | `CLAUDE.md` → `@agents/rules/*.md` | `.claude/skills/<n>/SKILL.md` (puntatore) | `.claude/workflows/*.md` (puntatore) |
| opencode | `AGENTS.md` + `instructions[]` in `opencode.jsonc` | `.claude/skills/` (discovery nativa dei puntatori) | `.opencode/commands/*.md` (`/status` `/resume` `/new`) + agent stock `plan`/`build` |
| Kilo Code | `.kilocode/rules/*.md` (puntatore) | `.kilocode/skills/<n>/SKILL.md` (puntatore) | `.kilocode/workflows/*.md` (puntatore) |

## Aggiungere una nuova skill

1. Crea `agents/skills/<nome>/SKILL.md` con frontmatter:
   ```yaml
   ---
   name: <nome>          # DEVE coincidere col nome cartella (kebab-case)
   description: "..."    # 1-1024 char, includi i termini trigger
   ---
   ```
2. Aggiorna l'indice `agents/skills/README.md`
3. Rilancia `bash scripts/sync-agent-pointers.sh` per rigenerare i puntatori
4. Verifica con `bash scripts/validate-agent-config.sh`

## Aggiungere una nuova agent home (es. `.cursor/`, `.windsurf/`)

1. Aggiungi una entry a `scripts/agent-homes.json` dichiarando i path di
   discovery di rules/skills/workflows di quel tool
2. Estendi `scripts/sync-agent-pointers.sh|.ps1` se il tool richiede un formato puntatore diverso
3. Rilancia il sync e la validazione

## Convenzioni

- **JUCE**: il progetto usa **JUCE 9** dal submodule `_tools/JUCE`, risolto via
  `APC_TOOLS_DIR` (chiave `tools_dir` in `~/.config/apc/config.json`). Non usare `~/JUCE`.
- **Piattaforme**: ogni comando nelle rules/workflows esiste in versione
  Bash (macOS/Linux) e PowerShell (Windows). Mai mescolare shell.
- **Troubleshooting**: cercare sempre prima in `agents/troubleshooting/known-issues.yaml`;
  auto-capture dopo 3 tentativi falliti (vedi `rules/agent.md`).
- I documenti JUCE 8 in `troubleshooting/resolutions/` sono storici (banner HISTORICAL).
