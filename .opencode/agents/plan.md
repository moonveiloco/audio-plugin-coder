---
description: "PHASE 2: Plan - Architecture definition and UI framework selection"
---

# Plan Phase — Architecture

Definisce l'architettura DSP e seleziona il framework UI.

## Prerequisiti
- Dream phase completata
- `${APC_PLUGINS_DIR}/[Name]/.ideas/creative-brief.md` e `parameter-spec.md` esistenti

## Esecuzione
Carica la skill `.claude/skills/plan/SKILL.md`

## Decisione Critica
Determina e imposta `ui_framework` in status.json:
- **visage**: C++ puro (Visage)
- **webview**: HTML/Canvas (WebView)

Chiedi all'utente se non ha già scelto.

## Output
- `${APC_PLUGINS_DIR}/[Name]/.ideas/architecture.md`
- `${APC_PLUGINS_DIR}/[Name]/.ideas/plan.md`
- `status.json` aggiornato con framework e complexity_score

## Completamento
```
✅ Plan phase complete! Framework: [Visage/WebView]
Next step: /design [Name]
```
