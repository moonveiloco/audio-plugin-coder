---
description: "Autonomous debugging and fault isolation"
---

# Debug Phase

Debugging autonomo con VS Code.

## Prerequisiti
- Implementation completata (`code_complete`) o test falliti (`test_failed`)

## Esecuzione
Carica la skill `.claude/skills/debug/SKILL.md`

## Responsabilità
- Ispezione full codebase
- Identificazione path ad alto rischio
- Inserimento breakpoint
- Generazione/update `.vscode/launch.json`
- Esecuzione sotto debugger
- Cattura diagnostica runtime

## Output
```json
{
  "workspaceMap": {},
  "debugConfig": {},
  "breakpoints": [],
  "errors": [],
  "suspectedRootCauses": [],
  "confidence": 0.0
}
```

## Completamento
```
🐞 Debugging complete!
Root cause identified: [Yes/No]
Failure reproducible: [Yes/No]
```
