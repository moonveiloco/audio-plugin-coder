# Gin Integration Protocol (FigBug/Gin)

**Libreria:** [FigBug/Gin](https://github.com/FigBug/Gin) — "a few extras for JUCE" (parametri con modulazione, ModMatrix, componenti UI synth, DSP).
**Posizione:** submodule `_tools/Gin`, pinnato (Gin **non pubblica tag/release** — `master` è il canale stable; il pin al commit garantisce riproducibilità).
**Licenza:** BSD-3-Clause. **Prerequisiti:** C++20, CMake 3.15+. **Compatibilità:** CI di Gin testa contro `develop` di JUCE (9.x).

---

## ✅ A cosa serve (perché è stato integrato)

| Modulo | Valore |
|---|---|
| `gin_plugin` | `gin::Processor`, parametri con modulazione/smoothing, ModMatrix, patch browser |
| `gin_dsp` | Wavetable oscillators band-limited, `BandLimitedLookupTables`, DelayLine, AudioFifo, Perlin noise |
| `gin_gui` / `gin_graphics` | Knob, ADSR, LFO, MSEG editor, layout JSON (solo UI JUCE-native) |
| `gin` (core) | Utilities comuni richieste dagli altri moduli |

Linkare **solo i moduli necessari** — gli altri 9 (`gin_3d`, `gin_controllers`, `gin_location`, `gin_metadata`, `gin_network`, `gin_simd`, `gin_svg`, `gin_webp`, …) aggiungono dipendenze e tempi di build.

---

## ⚠️ LIMITAZIONI NOTE (leggere PRIMA di scegliere Gin)

Questi punti sono **vincolanti**, non suggestioni. Verificarli in fase `/plan` e annotare la decisione in `.ideas/architecture.md`.

| # | Limitazione | Impatto | Mitigazione obbligatoria |
|---|---|---|---|
| 1 | **Richiede C++20** | I template APC non impostano `CMAKE_CXX_STANDARD` | Aggiungere `set(CMAKE_CXX_STANDARD 20)` nel CMake del plugin prima di aggiungere Gin |
| 2 | **API instabili** | Breaking changes frequenti (es. `textFunction` → `ConversionFunction`, wavetable +6 dB) — vedi `BREAKING_CHANGES.md` nel repo Gin | **Mai** aggiornare il pin senza leggere `_tools/Gin/BREAKING_CHANGES.md`; mai passare a `master` mobile |
| 3 | **`gin::Processor` diverge dal pattern APC** | Vuole essere base class al posto di `juce::AudioProcessor` dei template | Decisione architetturale da esplicitare in `/plan`; non mescolare `gin::Processor` e parametri JUCE vanilla nello stesso plugin |
| 4 | **Widget gin = `juce::Component`** | **Inutilizzabili sul percorso Visage (PATH A)**: il protocollo Visage vieta componenti JUCE per la UI | Su PATH A usare solo `gin_dsp` + parametri `gin_plugin` come layer backend; UI resta 100% Visage |
| 5 | **Moduli con dipendenze piattaforma** | `gin_network`→curl, `gin_location`→mappe, `gin_webp`→codec | Non linkarli se non necessari; su Linux verificare le dipendenze di sistema prima del build |
| 6 | **Tempo di build / binario** | I moduli Gin compilano per intero | Linkare il set minimo (di solito `gin_plugin` + `gin_dsp`) |

---

## 🔧 Protocollo d'uso (CMake)

Nel `CMakeLists.txt` del plugin, **dopo** il bootstrap JUCE:

```cmake
# Gin (dopo add_subdirectory di JUCE)
set(CMAKE_CXX_STANDARD 20)
add_subdirectory("${APC_TOOLS_DIR}/_tools/Gin/modules" "${CMAKE_BINARY_DIR}/_tools/Gin/modules")

target_link_libraries({PLUGIN_NAME} PRIVATE
    gin          # core
    gin_plugin   # parametri + ModMatrix
    # gin_dsp / gin_gui solo se effettivamente usati
)
```

**Regole hard:**

1. Aggiungere **SOLO** `${APC_TOOLS_DIR}/_tools/Gin/modules` — **MAI** la root di Gin (aggiungerebbe esempi/unit test e si aspetta un checkout `juce/` locale inesistente).
2. Il `juce_add_module()` dei moduli gin è eseguito dal CMake **di Gin** (una sola volta) — rispetta la regola APC "mai `juce_add_modules` manuale nel plugin": nessun duplicate target.
3. Usare il pattern out-of-tree con binary dir esplicita (come per JUCE nel template).

---

## 🔄 Protocollo di aggiornamento del pin

1. Leggere `_tools/Gin/BREAKING_CHANGES.md` upstream e valutare l'impatto sui plugin esistenti.
2. `cd _tools/Gin && git fetch && git checkout <commit> && cd ../..`
3. `git add _tools/Gin && git commit -m "chore(tools): update Gin pin to <sha>"`
4. Build + test di un plugin che usa Gin (`scripts/build-and-install.sh <Name>`) prima di considerare l'aggiornamento valido.
5. Aggiornare la riga "pinnato a" in cima a questo file.
