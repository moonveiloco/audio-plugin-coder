---
description: "PHASE 4: Implementation - DSP and UI code"
---

# Implementation Phase — Code

Implementa DSP e UI basandoti sui design approvati.

## Prerequisiti
- Design phase completata
- `${APC_PLUGINS_DIR}/[Name]/Source/` con template iniziali

## Esecuzione
Carica `.claude/skills/impl/SKILL.md`

## Key Steps
1. Conversione design → codice framework-specifico (WebView HTML/JS o Visage C++)
2. Approvazione utente UI
3. Implementazione DSP
4. Integrazione parametri → UI
5. Build e verifica

## CMake JUCE 9
`juce_add_plugin` flags invariati: `NEEDS_WEBVIEW2`, `NEEDS_WEB_BROWSER`.
Non chiamare `juce_add_modules`.
`JUCE_DIR = ~/JUCE` (JUCE 9) — leggere da env var.

## Output
- Plugin compilato in `build/`
- `status.json` → `code_complete`

## Completamento
```
✅ Implementation complete!
Next step: /ship [Name] (o /test [Name])
```
