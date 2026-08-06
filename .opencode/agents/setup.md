# SKILL: SETUP & ONBOARDING (First Run)

**Goal:** Detect first-time usage and guide the user through initial APC configuration.
**Trigger:** Automatic (when config is missing) OR `/setup`
**Output:** `~/.config/apc/config.json` (Linux/macOS) or `%APPDATA%/apc/config.json` (Windows)

## ⛔ PRECONDITION
This skill runs BEFORE any other phase. No plugin work happens until setup is complete.

## 🚨 GUARDRAIL: ALL INPUT IS SETUP INPUT
While this skill is active, **EVERY message from the user is interpreted as input to the setup flow.** This includes greetings ("ciao", "hello", "ciao!"), questions, random text, or anything that might look like a plugin request.

- If the user says "ciao" → do NOT suggest `/dream` or any plugin phase. Respond with the next setup question.
- If the user says "create a plugin called X" → do NOT start `/dream`. Respond: "APC is not yet configured. Let's complete setup first. What folder name do you want for your plugins?"
- If the user asks "what can you do?" → respond: "APC needs initial configuration first. Let's set up your plugins folder. What folder name do you want?"
- If the user provides a folder name → proceed to Step 3.
- If the user provides anything that is NOT a valid folder name → ask again for a valid folder name.

**Do NOT exit this skill until `setup_complete=true`.** Do NOT hand off to `/dream`, `/plan`, `/impl`, `/design`, `/new`, or `/ship`. The only valid termination is: setup complete OR user explicitly says "cancel/abort setup" (in which case, stop and wait).

## STEP 1: DETECT FIRST RUN
Check if APC is already configured:

**macOS/Linux:**
```bash
bash scripts/apc-config.sh is-setup && echo "ALREADY_SETUP" || echo "NEEDS_SETUP"
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 is-setup
```

If `ALREADY_SETUP` (exit 0), APC is configured. Ask the user if they want to reconfigure. If yes, proceed. If no, STOP.

If `NEEDS_SETUP` (exit 1), proceed to Step 2.

## STEP 2: WELCOME & PLUGINS DIRECTORY PATH
Greet the user and ask for the **full path** where plugins will be stored:

> Benvenuto in APC (Audio Plugin Coder)! Prima di iniziare, configuro il tuo ambiente.
>
> In quale directory vuoi salvare i tuoi plugin?
> Specifica il percorso completo (es. `~/AudioPlugins`, `~/Projects/VST-PLUGINS/APC-Plugins`, `/mnt/data/Plugins`, `D:\MyPlugins`).
> La cartella verra creata se non esiste.

**ASK the user for a full directory path.** Do NOT proceed without an answer. Do NOT assume the home directory — the user may want plugins on another disk, a nested project folder, or any custom location.

Examples of valid answers:
- `AudioPlugins` → resolves to `~/AudioPlugins` (relative to home, shorthand allowed)
- `~/Projects/VST-PLUGINS/APC-Plugins` → absolute path with `~` expansion
- `/mnt/data/Plugins` → absolute POSIX path (different disk/mount)
- `D:\MyPlugins` → absolute Windows path (different drive)
- `Plugins/VST` → resolves to `~/Plugins/VST` (relative to home, nested path allowed)

> ⚠️ **DO NOT use folders inside the APC repo.** The plugins directory MUST be **outside** the APC repo (`audio-plugin-coder/`). Never suggest paths like `plugins/`, `examples/`, `audio-plugin-coder/plugins/`, or any subdirectory of the current working directory. If the user proposes a path inside the APC repo, STOP and ask for a different path. The APC repo contains tooling and reference examples only; user plugins live in their own separate directory.

## STEP 3: RESOLVE & VERIFY PATH
Resolve the full path from the user's answer:
- If the path starts with `~` → expand to `$HOME` (macOS/Linux) or `$env:USERPROFILE` (Windows)
- If the path is relative (no leading `/`, `~`, or drive letter) → resolve relative to `$HOME`/`$env:USERPROFILE`
- If the path is absolute → use as-is
- On Windows, convert forward slashes to backslashes for the stored value

Check if the directory already exists:
- **Does NOT exist** → Create it. Confirm: "Creata cartella `<full_path>`."
- **Already exists** → Ask: "La cartella `<full_path>` esiste gia. La uso o ne scegli un'altra?"
  - If "use it" → proceed
  - If "choose another" → go back to Step 2

## STEP 4: SAVE CONFIGURATION
Write the configuration using the helper:

**macOS/Linux:**
```bash
bash scripts/apc-config.sh set setup_complete true
bash scripts/apc-config.sh set setup_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
bash scripts/apc-config.sh set plugins_dir "<full_plugins_path>"
bash scripts/apc-config.sh set plugins_folder_name "<folder_name>"
bash scripts/apc-config.sh set tools_dir "$(pwd)"
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 set setup_complete true
powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 set setup_at (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 set plugins_dir "<full_plugins_path>"
powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 set plugins_folder_name "<folder_name>"
powershell -ExecutionPolicy Bypass -File .\scripts\apc-config.ps1 set tools_dir (Get-Location).Path
```

**Note:** `tools_dir` stores the path to the **APC repo** (where `_tools/JUCE`, `_tools/visage` and `include/` live). Plugins read it (as `APC_TOOLS_DIR`) to build standalone inside their own folder. JUCE itself is not part of the config — it is a Git submodule bundled with the APC repo at `_tools/JUCE`. If `tools_dir` is missing, the build scripts fall back to the repo that owns `scripts/`, so the key is optional. — it is a Git submodule bundled with the APC repo at `_tools/JUCE`. The build system (`CMakeLists.txt`) references it directly. No user input is needed for JUCE.

## STEP 4.5: INITIALIZE PLUGINS DIRECTORY README
Copy the plugins-directory README template into the user's plugins folder so they have on-disk documentation of the structure, build commands, and APC relationship.

**macOS/Linux:**
```bash
bash scripts/init-plugins-dir.sh
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init-plugins-dir.ps1
```

This is idempotent — it skips if `README.md` already exists (won't overwrite user customizations). The template substitutes the folder name and full path automatically. Confirm to the user: "Aggiunto `README.md` in `<plugins_dir>` con le istruzioni d'uso."

## STEP 5: CONFIRMATION
Verify the config was written:
```bash
bash scripts/apc-config.sh plugins-dir
```

Confirm to the user:

> Configurazione completata!
> - Plugin salvati in: `<plugins_dir>`
> - JUCE: submodule in `_tools/JUCE` (incluso nel repo)
>
> Ora puoi usare `/dream <NomePlugin>` per creare il tuo primo plugin.

## STEP 6: TERMINATION
STOP. Do not auto-start `/dream`.

---

## RECONFIGURE EXISTING SETUP
If the user runs `/setup` when already configured:
1. Show current config: `bash scripts/apc-config.sh get plugins_dir`
2. Ask: "Vuoi riconfigurare? (s/n)"
3. If yes, proceed from Step 2.
4. If no, STOP.
