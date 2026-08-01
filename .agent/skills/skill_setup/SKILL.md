# SKILL: SETUP & ONBOARDING (First Run)

**Goal:** Detect first-time usage and guide the user through initial ACP configuration.
**Trigger:** Automatic (when config is missing) OR `/setup`
**Output:** `~/.config/acp/config.json` (Linux/macOS) or `%APPDATA%/acp/config.json` (Windows)

## ⛔ PRECONDITION
This skill runs BEFORE any other phase. No plugin work happens until setup is complete.

## STEP 1: DETECT FIRST RUN
Check if ACP is already configured:

**macOS/Linux:**
```bash
bash scripts/acp-config.sh is-setup && echo "ALREADY_SETUP" || echo "NEEDS_SETUP"
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\acp-config.ps1 is-setup
```

If `ALREADY_SETUP` (exit 0), ACP is configured. Ask the user if they want to reconfigure. If yes, proceed. If no, STOP.

If `NEEDS_SETUP` (exit 1), proceed to Step 2.

## STEP 2: WELCOME & FOLDER NAME
Greet the user:

> Benvenuto in ACP (Audio Plugin Coder)! Prima di iniziare, configuro il tuo ambiente.
>
> Come vuoi chiamare la cartella dove salvare i tuoi plugin?
> (Suggerito: `AudioPlugins` — verra creata nella tua home directory)

**ASK the user for the folder name.** Do NOT proceed without an answer.

Examples of valid answers:
- `AudioPlugins` → resolves to `~/AudioPlugins`
- `MieiSynth` → resolves to `~/MieiSynth`
- `Plugins/VST` → resolves to `~/Plugins/VST` (nested path allowed)

## STEP 3: RESOLVE & VERIFY PATH
Resolve the full path from the user's answer:
- On macOS/Linux: `$HOME/<folder_name>`
- On Windows: `$env:USERPROFILE\<folder_name>`

Check if the directory already exists:
- **Does NOT exist** → Create it. Confirm: "Creata cartella `<full_path>`."
- **Already exists** → Ask: "La cartella `<full_path>` esiste gia. La uso o ne scegli un'altra?"
  - If "use it" → proceed
  - If "choose another" → go back to Step 2

## STEP 4: JUCE PATH
Ask the user where JUCE is installed:

> Dove e installato JUCE? (Suggerito: `~/JUCE`)

**ASK the user.** Accept the default or a custom path. Verify the path exists (or warn if it doesn't, but allow proceeding).

## STEP 5: SAVE CONFIGURATION
Write the configuration using the helper:

**macOS/Linux:**
```bash
bash scripts/acp-config.sh set setup_complete true
bash scripts/acp-config.sh set setup_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
bash scripts/acp-config.sh set plugins_dir "<full_plugins_path>"
bash scripts/acp-config.sh set plugins_folder_name "<folder_name>"
bash scripts/acp-config.sh set juce_dir "<juce_path>"
```

**Windows:**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\acp-config.ps1 set setup_complete true
powershell -ExecutionPolicy Bypass -File .\scripts\acp-config.ps1 set setup_at (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
powershell -ExecutionPolicy Bypass -File .\scripts\acp-config.ps1 set plugins_dir "<full_plugins_path>"
powershell -ExecutionPolicy Bypass -File .\scripts\acp-config.ps1 set plugins_folder_name "<folder_name>"
powershell -ExecutionPolicy Bypass -File .\scripts\acp-config.ps1 set juce_dir "<juce_path>"
```

## STEP 6: CONFIRMATION
Verify the config was written:
```bash
bash scripts/acp-config.sh plugins-dir
bash scripts/acp-config.sh juce-dir
```

Confirm to the user:

> Configurazione completata!
> - Plugin salvati in: `<plugins_dir>`
> - JUCE: `<juce_dir>`
>
> Ora puoi usare `/dream <NomePlugin>` per creare il tuo primo plugin.

## STEP 7: TERMINATION
STOP. Do not auto-start `/dream`.

---

## RECONFIGURE EXISTING SETUP
If the user runs `/setup` when already configured:
1. Show current config: `bash scripts/acp-config.sh get plugins_dir`
2. Ask: "Vuoi riconfigurare? (s/n)"
3. If yes, proceed from Step 2.
4. If no, STOP.
