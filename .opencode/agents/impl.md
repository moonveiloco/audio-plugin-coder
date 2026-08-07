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

## CMake / JUCE
- JUCE è un submodule APC in `_tools/JUCE` (JUCE 8.0.12). **Non** usare `~/JUCE` o JUCE 9.
- I template plugin sono self-contained: bootstrap `APC_TOOLS_DIR` + `add_subdirectory(${APC_TOOLS_DIR}/_tools/JUCE)`.
- Non passare `JUCE_DIR` come env var — il build script inietta `APC_TOOLS_DIR` (chiave config `tools_dir`).
- `juce_add_plugin` flags: `NEEDS_WEBVIEW2` (Windows), `NEEDS_WEB_BROWSER` (Linux/macOS).
- JUCE 8 ha rimosso `JuceHeader.h` auto-generato: i template chiamano `juce_generate_juce_header()` esplicitamente.

## Output
- Plugin compilato in `<plugins_dir>/[Name]/build/` (per-plugin, non nella root del repo)
- `status.json` → `code_complete`

## Completamento
```
✅ Implementation complete!
Next step: /ship [Name] (o /test [Name])
```
