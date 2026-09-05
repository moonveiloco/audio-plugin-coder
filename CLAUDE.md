@AGENTS.md

## Claude Code — regole complete (import eager)

@agents/rules/agent.md

@agents/rules/file-naming-conventions.md

@agents/rules/juce-build-protocols.md

## Note Claude Code

- Le skill sono in `.claude/skills/<nome>/SKILL.md` (puntatori generati a
  `agents/skills/`); i workflow di fase in `.claude/workflows/`.
- Per rigenerare i puntatori dopo modifiche a `agents/`: `bash scripts/sync-agent-pointers.sh`
- Verifica configurazione: `bash scripts/validate-agent-config.sh`
