# AGENTS.md — Audio Plugin Coder (APC)

APC è un framework AI-first per sviluppare plugin audio (VST3/AU/LV2/CLAP) su JUCE.
Questo file è l'**entry point universale** per ogni coding agent. La single source of
truth di skill, rules e workflow vive in [`agents/`](agents/README.md).

## 🚪 FIRST RUN GATE (obbligatorio su OGNI messaggio)

Prima di rispondere a QUALSIASI messaggio (comando, saluto, domanda) verifica che APC sia configurato:

- **macOS/Linux:** `bash scripts/apc-config.sh is-setup`
- **Windows:** `powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 is-setup`

- **exit 0** → risolvi `${APC_PLUGINS_DIR}` con `bash scripts/apc-config.sh plugins-dir` (o `.ps1`) e procedi normalmente.
- **exit 1** → **STOP subito.** Non interpretare il messaggio come richiesta di plugin: esegui `/setup` (`agents/skills/setup/SKILL.md`). Fino a `setup_complete=true` ogni input utente è input di setup.

## 🌍 Fatti ambiente (verità unica)

- **APC_PLUGINS_DIR:** risolto a runtime da `~/.config/apc/config.json` (`%APPDATA%/apc/config.json` su Windows) via `scripts/apc-config.sh|.ps1 plugins-dir`. I plugin vivono **fuori dal repo**; `examples/` è riferimento read-only.
- **JUCE 9:** submodule `_tools/JUCE` (v9.0.0), risolto via `APC_TOOLS_DIR` (chiave `tools_dir` del config, iniettata dai build script). **Non** usare `~/JUCE` o installazioni esterne.
- **JUCE 8→9 breaking:** `Drawable` non eredita `Component` (usa `DrawableComponent`); `createFromSVG(XmlElement&)` rimosso (usa `createFromSVGFile/String`); multi-touch Windows richiede `usesWindowsMultiTouch()`; Linux usa EGL non GLX (installa `libegl-dev`).
- **Build:** SEMPRE `scripts/build-and-install.sh|.ps1 -PluginName <Name>` — mai `cmake`/`msbuild`/`xcodebuild` manuale, mai copie manuali di VST3/AU.
- **CMake plugin:** NON chiamare `juce_add_modules` (duplicate target error); flag WebView: `NEEDS_WEBVIEW2` (Windows) / `NEEDS_WEB_BROWSER` (Linux/macOS).
- **Gin:** submodule `_tools/Gin` pinnato (no tag upstream). Limitazioni vincolanti (C++20, API instabili, incompatibile UI Visage) in `agents/rules/gin-integration.md` — leggerle PRIMA di usarlo.
- **JIVE:** submodule `_tools/JIVE` pinnato + **patch JUCE 9 obbligatoria** (`patches/JIVE/`, applicata automaticamente da build-and-install). UI dichiarativa = terzo percorso UI (né Visage né WebView): limitazioni in `agents/rules/jive-integration.md` — leggerle PRIMA di usarlo.
- **OS protocol:** Bash/Zsh su macOS/Linux (script `.sh`), PowerShell su Windows (script `.ps1`). Mai mescolare le shell.

## 🗺️ Fasi (state machine su `status.json`)

`/dream` → `/plan` → `/design` → `/impl` → `/test` → `/ship` (+ `/status`, `/resume`, `/new`, `/setup`)

Ogni fase: leggi `${APC_PLUGINS_DIR}/[Name]/status.json` → verifica prerequisiti → esegui → aggiorna stato → **STOP** (mai auto-avviare la fase successiva).

## 📂 File chiave

| Percorso | Contenuto |
|---|---|
| `agents/rules/*.md` | Regole complete (dispatcher, naming, protocolli build) |
| `agents/skills/<nome>/SKILL.md` | 12 skill con frontmatter (`name` == nome cartella) |
| `agents/workflows/*.md` | Orchestrazioni di fase |
| `agents/troubleshooting/known-issues.yaml` | Cerca QUI prima di debuggare; auto-capture dopo 3 tentativi |
| `templates/` | Template plugin (visage, webview, ffgl, max-external) |

## 📏 Regole complete

Quando l'agente supporta il caricamento di file di regole, includi:

- `agents/rules/agent.md` — Master Dispatcher: phase gating, OS protocol, troubleshooting auto-capture
- `agents/rules/file-naming-conventions.md` — struttura e versioning dei progetti plugin
- `agents/rules/juce-build-protocols.md` — vincoli build JUCE 9/CMake/CI
- `agents/rules/gin-integration.md` — limitazioni e protocollo d'uso Gin ( submodule `_tools/Gin`)
- `agents/rules/jive-integration.md` — limitazioni, patch JUCE 9 e protocollo d'uso JIVE (submodule `_tools/JIVE`)
