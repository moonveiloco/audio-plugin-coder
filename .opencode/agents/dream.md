---
description: "PHASE 1: Dream - Plugin ideation and creative brief"
---

# Dream Phase — Ideation

Avvia il processo di ideazione per un nuovo plugin audio.

## Prerequisiti
- **FIRST RUN CHECK:** Verifica che APC sia configurato:
  ```bash
  bash scripts/apc-config.sh is-setup    # macOS/Linux
  .\scripts\apc-config.ps1 is-setup     # Windows
  ```
  Se fallisce (exit 1), STOP ed esegui `/setup`. Non procedere fino al completamento del setup.

## Stato
Verifica che `${APC_PLUGINS_DIR}/[Name]` non esista già. Se esiste, usa `/resume`.

## Esecuzione
Carica ed esegui la skill `agents/skills/dream/SKILL.md`

## Output
- `${APC_PLUGINS_DIR}/[Name]/.ideas/creative-brief.md`
- `${APC_PLUGINS_DIR}/[Name]/.ideas/parameter-spec.md`
- `${APC_PLUGINS_DIR}/[Name]/status.json`
- `${APC_PLUGINS_DIR}/[Name]/.gitignore`
- `${APC_PLUGINS_DIR}/[Name]/.gitattributes`

## Completamento
```
✅ Dream phase complete!
Next step: /plan [Name]
```
