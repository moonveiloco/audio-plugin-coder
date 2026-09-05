# APC Skills Index

Catalogo delle skill disponibili in `agents/skills/`. Ogni skill è una cartella
con `SKILL.md` (il loader li rileva in flat, un livello sotto `skills/`).

## Skill di fase (workflow APC)

| Skill | Trigger | Scopo |
|-------|---------|-------|
| [`dream`](dream/SKILL.md) | `/dream [Name]` | Ideazione, creative brief |
| [`plan`](plan/SKILL.md) | `/plan [Name]` | Architettura e pianificazione |
| [`design`](design/SKILL.md) | `design UI for [plugin]` | Visual interface (frontmatter `skill_design`) |
| [`impl`](impl/SKILL.md) | — (fase 4) | Implementazione DSP (+ integrationi WebView) |
| [`test`](test/SKILL.md) | `/test [Name]` | Validazione (delega a `testing`) |
| [`ship`](ship/SKILL.md) | `/ship [Name]` | Packaging cross-platform |
| [`debug`](debug/SKILL.md) | — | Debug autonomo in VSCode (frontmatter `skill_debug`) |
| [`setup`](setup/SKILL.md) | — | Setup/onboarding primo avvio |

## Skill di dominio

| Skill | Scopo |
|-------|-------|
| [`skill_design_webview`](skill_design_webview/SKILL.md) | Guide WebView: KNOWN-ISSUES, WEBVIEW-PRODUCTION-GUIDE |
| [`testing`](testing/SKILL.md) | Procedura di testing/validazione |
| [`troubleshooting`](troubleshooting/SKILL.md) | Risoluzione problemi nota-based (known-issues.yaml) |

## Skill fix (correzioni incrementali)

Skill di soluzione ottenute risolvendo bug reali durante lo sviluppo. `fix_*`
raggruppa per problema. L'agent deve caricarli quando il sintomo corrisponde
(trigger nella `description` del frontmatter).

| Skill | Problema risolto | Sintomi / trigger |
|-------|------------------|-------------------|
| [`fix_windowsize`](fix_windowsize/SKILL.md) | UI WebView con X giusta ma Y corta (scroll verticale) sotto scaling frazionario Wayland/REAPER | WebView, app, altezza, scroll verticale, dpr, fractional HiDPI, scaling |

## Come aggiungere una nuova skill `fix_*`

1. Crea la cartella `agents/skills/fix_<nome>/` con `SKILL.md`.
2. Il `name:` nel frontmatter DEVE coincidere col nome cartella (`fix_windowsize`).
3. Scrivi la `description` con **termini trigger** (parole chiave con cui l'agent
   riconosce il problema e carica la skill).
4. Se è un fix emerso durante `impl`, aggiungi una riga nella sezione
   TROUBLESHOOTING di `impl/SKILL.md`.
5. Aggiungi una riga in questa tabella `## Skill fix`.
