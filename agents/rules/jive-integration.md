# JIVE Integration Protocol (ImJimmi/JIVE)

**Libreria:** [ImJimmi/JIVE](https://github.com/ImJimmi/JIVE) — UI dichiarativa per JUCE ispirata al web: markup ValueTree/XML (stile HTML) + style sheets via `juce::var` (stile CSS).
**Posizione:** submodule `_tools/JIVE`, pinnato a `main` @ `89d5787` (2026-06-26).
**Licenza:** MIT. **Compatibilità:** compilato e testato contro JUCE 9 (`_tools/JUCE`) su Linux — build, link e runtime OK **con patch obbligatoria** (vedi sotto).

> **Nota sul pin:** il tag `v1.3.0` (2025-01-18) è **rotto contro JUCE 9** e il fix non è stato verificato su di esso. `main` è lo stable di facto del progetto (come `master` per Gin) e include 6 mesi di fix in più — è il commit pinnato.

---

## ✅ A cosa serve (perché è stato integrato)

| Modulo | Valore |
|---|---|
| `jive::jive_layouts` | UI dichiarativa: `jive::Interpreter{}.interpret(xmlString)` → albero di `GuiItem`; layout flexbox/grid via proprietà; `interpret(tree, AudioProcessor*)` per plugin |
| `jive::jive_style_sheets` | Style sheets CSS-like (`background-colour`, `font-size`, …) con `JIVE_GUI_ITEMS_HAVE_STYLE_SHEETS=1` |
| `jive::jive_components` / `jive_core` | Widget e core, tirati dentro dalle dipendenze dei moduli sopra |

---

## ⚠️ LIMITAZIONI NOTE (leggere PRIMA di scegliere JIVE)

Questi punti sono **vincolanti**, non suggestioni. Verificarli in fase `/plan` e annotare la decisione in `.ideas/architecture.md`.

| # | Limitazione | Impatto | Mitigazione obbligatoria |
|---|---|---|---|
| 1 | **Rotto contro JUCE 9 upstream** (sia `v1.3.0` che `main`): `Drawable::setTransformToFit` e `createFromSVG(XmlElement&)` rimossi in JUCE 9 | Compilazione fallisce in `jive_Image.cpp` e `jive_Drawable.cpp` | **Patch obbligatoria** `patches/JIVE/juce9-drawable-compat.patch`, applicata idempotentemente da `scripts/apply-submodule-patches.sh\|.ps1` e dall'hook in `build-and-install.sh\|.ps1`. Se una build fallisce con `setTransformToFit` / `createFromSVG is not a member` → patch non applicata: eseguire lo script |
| 2 | **Attività upstream ridotta** | Ultimo commit su `main` 2026-06-26 (solo manutenzione renovate); CI rossa (issue #196 aperta); branch `v2` = riscrittura, non stabile | Non aspettarsi fix rapidi upstream; ogni aggiornamento pin va testato con build reale |
| 3 | **Terzo percorso UI (non PATH A, non PATH B)** | JIVE sostituisce l'intero layer Component: incompatibile con Visage, concorrenziale con WebView | È una **decisione architetturale** da esplicitare in `/plan` (`ui_framework`): trattarla come percorso UI dedicato, mai mischiata alle altre due |
| 4 | **Integrazione plugin incompleta** | Issue #162 aperta (`interpret` non ritorna `AudioProcessorEditor`), #171 (demo-plugin richiede `juce_audio_plugin_client`) | Per plugin: usare `interpret(tree, pluginProcessor)` e verificare il titolo/owner dell'editor; testare in host DAW reale in fase `/test` |
| 5 | **Widget mancanti** | `TextEditor` (#59), `PopupMenu` (#60), alert windows (#63), tooltips stilizzati (#64), `Browser` (#62), `Video` (#61) | Se il plugin richiede questi widget, JIVE non è adatto (o servono componenti JUCE custom innestati — non documentato upstream) |
| 6 | **Interop con Gin non garantito** | I widget `gin_gui` sono `juce::Component` piani; l'embedding nell'albero dichiarativo JIVE non è supportato upstream | **Non combinare** UI Gin e UI JIVE nello stesso plugin. Solo layer non-UI (es. `gin_dsp`) sotto un'UI JIVE |

---

## 🔧 Protocollo d'uso (CMake)

Nel `CMakeLists.txt` del plugin, **dopo** il bootstrap JUCE:

```cmake
# JIVE (root: le opzioni runner/demo/example sono OFF di default, quindi sicuro)
add_subdirectory("${APC_TOOLS_DIR}/_tools/JIVE" "${CMAKE_BINARY_DIR}/_tools/JIVE")

target_link_libraries({PLUGIN_NAME} PRIVATE
    jive::jive_layouts
    jive::jive_style_sheets
)
target_compile_definitions({PLUGIN_NAME} PRIVATE
    JIVE_GUI_ITEMS_HAVE_STYLE_SHEETS=1
)
```

Uso runtime tipico (editor di plugin):

```cpp
item = jive::Interpreter{}.interpret(R"JIVE(
<Window width="480" height="320" display="flex"
        style='{"background": "#1a1a1a", "foreground": "#e8ecf1"}'>
    <Text text="Hello" font-size="18" justify="centred"/>
</Window>
)JIVE", processorPointer);
setContentNonOwned(item->getComponent().get(), true);   // item: std::unique_ptr<jive::GuiItem>, tenere vivo
```

### Sintassi markup verificata sul pin `89d5787` (⚠️ gli esempi upstream e i vecchi documenti usano proprietà non più valide)

| Regola | Dettaglio |
|---|---|
| **`display` obbligatoria** | Ogni elemento con figli da disporre DEVE avere `display="flex"|"grid"|"block"`: senza, i figli vengono **distrutti in silenzio** (`decorateWithHereditaryBehaviour` ritorna nullptr) |
| **Stili in `style` (JSON)** | Colori/font/bordi vivono nell'attributo `style='{"background": "#16181D", "font-size": 11}'` (stringa JSON → `jive::Object` via `parseJSON`); **NON** esistono attributi inline tipo `background-colour`/`colour` |
| **Colori** | `#RRGGBB` (o `rgb()`, nomi CSS). **NON** `0xAARRGGBB` (silenziosamente trasparente) |
| **Nomi style validi** | `background`, `foreground`, `border`, `border-radius`, `font-family`, `font-size`, `font-stretch`, `font-style`, `font-weight`, `letter-spacing`, `text-decoration` |
| **Nessun `Panel`** | Tipi validi: `Button, Checkbox, ComboBox, Component, Editor, Hyperlink, Image, Knob, Label, ProgressBar, Slider, Spinner, svg, Text, Window` — per un contenitore generico usare `Component` |
| **`gap` solo per grid** | `gap`/`grid-template-*` esistono solo con `display="grid"`; per flex usare padding/margini |
| **Slider** | `value`, `min`, `max`, `interval`, `orientation="vertical"|"horizontal"` |
| **ComboBox** | Figli `<Item text="..."/>` + attributo `selected="<indice>"` |
| **Flex items** | `flex-grow`, `flex-shrink`, `flex-basis`, `align-self` sui figli di un flex container |
| **Stile ereditato** | Il `style` del Window si propaga ai discendenti; selettori `#id` dentro lo `style` per targeting |

**Preview senza build del plugin:** usare il tool `jive-preview` (sezione sotto) — errore tipico senza questi vincoli: rendering vuoto/trasparente senza alcun warning.

## 🔍 Preview tool: `jive-preview` (APC)

Standalone GUI app in `tools/jive-preview/` (progetto CMake separato, bootstrap JUCE+JIVE da `APC_TOOLS_DIR`; **non** tocca la build dei plugin):

```bash
# Interactive con live-reload (aggiorna a ogni salvataggio del file):
bash scripts/preview-jive.sh <PluginName> [v<N>]

# Headless (render off-screen a PNG, ideale per CI e verifica agenti):
tools/jive-preview/build/jive-preview_artefacts/Release/jive-preview Design/v1-layout.xml --screenshot out.png
```

- Modalità default: interpreta il markup e apre una finestra host nativa (close→quit), live-reload con poll mtime ~500 ms.
- `--screenshot out.png`: **nessuna finestra** (immune dal tiling del WM), render deterministico alla size del markup.
- `--raw`: interpreta il markup *intatto* (jive gestisce la propria `Window`); utile per debug, ma la chiusura via titlebar non esce (limitazione upstream `closeButtonPressed`).
- Il tool riscrive la root `<Window>` → `<Component>` e fornisce la finestra host: evita il window-in-window e dà chiusura pulita.
- Load fallito durante il live-reload → mantiene l'ultima UI valida e logga su stderr.

**Build standalone (cache in `tools/jive-preview/build/`, non influisce sui plugin):**
```bash
cmake -S tools/jive-preview -B tools/jive-preview/build -DAPC_TOOLS_DIR="$(pwd)" -DCMAKE_BUILD_TYPE=Release
cmake --build tools/jive-preview/build --config Release --target jive-preview
```

**Limitazione nota (Hyprland/tiling):** le finestre JUCE sotto tiling WM vengono ridimensionate dal WM ignorando la size richiesta — per il preview interattivo affiancare/floattare la finestra; per verifiche deterministiche usare `--screenshot`.

**Nota runners upstream:** `JIVE_BUILD_DEMO_RUNNER`/`JIVE_BUILD_TEST_RUNNER` non sono utilizzabili dentro un progetto che include già JUCE (il demo-runner tenta CPM con un secondo JUCE) — da qui il tool dedicato.

**Nota `--fresh`:** `build-and-install.sh|.ps1` configura con `--fresh`, quindi la working tree del submodule deve essere **già patchata** quando parte la configure — è esattamente ciò che fa l'hook (idempotente) inserito prima della configure.

---

## 🩹 Protocollo patch (JUCE 9 compat)

**Fresh clone:**

```bash
git submodule update --init --recursive
bash scripts/apply-submodule-patches.sh        # .ps1 su Windows
```

In genere **non serve**: `build-and-install.sh|.ps1` applica le patch da solo a ogni build.

**Contenuto della patch** (`patches/JIVE/juce9-drawable-compat.patch`, 3 file, ~10 righe):
- `jive_Image.cpp/.h`: `dynamic_cast<juce::Drawable*>` → `juce::DrawableComponent*`; `createSVG()` usa `juce::OwningDrawableComponent::createFromSVGString()`; cast di auto-size aggiornati
- `jive_Drawable.cpp`: `createFromSVG(XmlElement&)` → `createFromSVGString(xmlElement.toString())`

**Conflitto patch** (`ERROR: ... does not apply`): il pin è cambiato a monte e i file patchati sono stati toccati → rigenerare la patch (vedi protocollo di aggiornamento).

---

## 🔄 Protocollo di aggiornamento del pin

1. Leggere i changelog/commit upstream tra il pin attuale e il nuovo target.
2. `cd _tools/JIVE && git fetch && git checkout <commit> && cd ../..`
3. `bash scripts/apply-submodule-patches.sh JIVE` — se fallisce, i file patchati sono cambiati: valutare/riportare la patch su nuova base.
4. Build + test di un plugin con UI JIVE prima di considerare l'aggiornamento valido.
5. `git add _tools/JIVE && git commit` (eventualmente con patch rigenerata).

## 🪦 Protocollo di dismissione patch (quando upstream fixa JUCE 9)

1. Aggiornare il pin al commit upstream che include il fix.
2. Cancellare `patches/JIVE/juce9-drawable-compat.patch`.
3. `git submodule update --force _tools/JIVE` (working tree pulita) + build di verifica.
4. Aggiornare questo file (rimuovere la sezione patch) e la riga "pinnato a" in cima.
