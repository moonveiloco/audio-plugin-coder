---
description: "Complete plugin development from idea to shipped product"
---
## 🚪 PREREQUISITE: FIRST RUN CHECK
Verifica che ACP sia configurato prima di iniziare:
```bash
bash scripts/acp-config.sh is-setup    # macOS/Linux
.\scripts\acp-config.ps1 is-setup     # Windows
```
Se fallisce, esegui `/setup` prima di continuare.


# New Plugin — Full Workflow

Guida il plugin attraverso tutte le 5 fasi con conferma utente a ogni step.

## Fasi
1. **Dream** 💭 — Ideazione → `/dream [Name]`
2. **Plan** 📋 — Architettura → `/plan [Name]`
3. **Design** 🎨 — UI → `/design [Name]`
4. **Impl** 💻 — Codice → `/impl [Name]`
5. **Ship** 🚀 — Packaging → `/ship [Name]`

Ogni fase richiede approvazione utente prima di procedere alla successiva.

Puoi uscire in qualsiasi fase e riprendere con `/resume [Name]`.
