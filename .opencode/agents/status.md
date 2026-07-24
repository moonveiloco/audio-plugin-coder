---
description: "Check current plugin state and progress"
---

# Status Check

Mostra lo stato corrente del plugin e suggerisce il prossimo passo.

## Esecuzione
Leggi `plugins/[Name]/status.json` e mostra:
- Nome e versione
- Fase corrente
- UI framework
- Complexity score
- Cronologia fasi completate
- Prossimo passo suggerito

## Fasi e prossimi comandi
| Fase | Next Step |
|------|-----------|
| ideation | `/plan [Name]` |
| plan_complete | `/design [Name]` |
| design_complete | `/impl [Name]` |
| code_complete | `/ship [Name]` |
| ship_complete | Plugin completo! 🎉 |
