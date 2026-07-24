---
description: "Resume plugin development from current state"
---

# Resume Development

Riprende lo sviluppo del plugin dalla fase corrente.

## Esecuzione
Leggi `plugins/[Name]/status.json` e determina il prossimo comando:

| Fase | Comando |
|------|---------|
| ideation | `/plan [Name]` |
| plan_complete | `/design [Name]` |
| design_complete | `/impl [Name]` |
| code_complete | `/ship [Name]` |
| ship_complete | Plugin già completato |

Mostra errori presenti in `error_recovery.error_log`.
