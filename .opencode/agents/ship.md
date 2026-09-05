---
description: "PHASE 5: Ship - Cross-platform packaging and distribution"
---

# Ship Phase — Packaging

Crea installer professionali multipiattaforma.

## Prerequisiti
- Implementation completata
- Plugin funzionante
- Tests superati

## Esecuzione
Carica `agents/skills/ship/SKILL.md`

## Workflow
1. **Rileva ambiente**: Identifica OS e build locali
2. **Selezione piattaforme**: Chiedi all'utente quali piattaforme includere
3. **Build locale**: Crea installer per piattaforma corrente
4. **GitHub Actions**: Trigger build cross-platform
5. **Scarica artefatti**: Crea installer per altre piattaforme
6. **Licenza**: Genera EULA
7. **Finalizza**: Crea distribuzione ZIP

## Output
```
dist/{PluginName}-v{version}.zip
├── {PluginName}-{version}-Windows-Setup.exe
├── {PluginName}-{version}-macOS.dmg
├── {PluginName}-{version}-macOS.pkg
├── {PluginName}-{version}-Linux.AppImage
├── {PluginName}-{version}.deb
└── LICENSE.txt
```

## Completamento
```
🎉 PLUGIN SHIPPED SUCCESSFULLY!
```
