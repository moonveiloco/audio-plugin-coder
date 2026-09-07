# Gin Integration Protocol (FigBug/Gin)

**Library:** [FigBug/Gin](https://github.com/FigBug/Gin) — "a few extras for JUCE" (parameters with modulation, ModMatrix, synth UI components, DSP).
**Location:** submodule `_tools/Gin`, pinned (Gin **publishes no tags/releases** — `master` is the stable channel; pinning to a commit guarantees reproducibility).
**License:** BSD-3-Clause. **Prerequisites:** C++20, CMake 3.15+. **Compatibility:** Gin's CI tests against JUCE `develop` (9.x).

---

## ✅ What it is for (why it was integrated)

| Module | Value |
|---|---|
| `gin_plugin` | `gin::Processor`, parameters with modulation/smoothing, ModMatrix, patch browser |
| `gin_dsp` | Band-limited wavetable oscillators, `BandLimitedLookupTables`, DelayLine, AudioFifo, Perlin noise |
| `gin_gui` / `gin_graphics` | Knob, ADSR, LFO, MSEG editor, JSON layout (JUCE-native UI only) |
| `gin` (core) | Common utilities required by the other modules |

Link **only the modules you need** — the other 9 (`gin_3d`, `gin_controllers`, `gin_location`, `gin_metadata`, `gin_network`, `gin_simd`, `gin_svg`, `gin_webp`, …) add dependencies and build time.

---

## ⚠️ KNOWN LIMITATIONS (read BEFORE choosing Gin)

These points are **binding**, not suggestions. Verify them during `/plan` and record the decision in `.ideas/architecture.md`.

| # | Limitation | Impact | Mandatory mitigation |
|---|---|---|---|
| 1 | **Requires C++20** | The APC templates do not set `CMAKE_CXX_STANDARD` | Add `set(CMAKE_CXX_STANDARD 20)` to the plugin CMake before adding Gin |
| 2 | **Unstable API** | Frequent breaking changes (e.g. `textFunction` → `ConversionFunction`, wavetable +6 dB) — see `BREAKING_CHANGES.md` in the Gin repo | **Never** update the pin without reading `_tools/Gin/BREAKING_CHANGES.md`; never switch to a moving `master` |
| 3 | **`gin::Processor` diverges from the APC pattern** | It wants to be the base class instead of the templates' `juce::AudioProcessor` | Architectural decision to be made explicit in `/plan`; do not mix `gin::Processor` and vanilla JUCE parameters in the same plugin |
| 4 | **Gin widgets = `juce::Component`** | **Unusable on the Visage path (PATH A)**: the Visage protocol forbids JUCE components for the UI | On PATH A use only `gin_dsp` + `gin_plugin` parameters as a backend layer; the UI stays 100% Visage |
| 5 | **Modules with platform dependencies** | `gin_network`→curl, `gin_location`→maps, `gin_webp`→codec | Do not link them unless needed; on Linux verify the system dependencies before building |
| 6 | **Build time / binary size** | The Gin modules compile in full | Link the minimal set (usually `gin_plugin` + `gin_dsp`) |

---

## 🔧 Usage protocol (CMake)

In the plugin `CMakeLists.txt` **after** the JUCE bootstrap:

```cmake
# Gin (after add_subdirectory of JUCE)
set(CMAKE_CXX_STANDARD 20)
add_subdirectory("${APC_TOOLS_DIR}/_tools/Gin/modules" "${CMAKE_BINARY_DIR}/_tools/Gin/modules")

target_link_libraries({PLUGIN_NAME} PRIVATE
    gin          # core
    gin_plugin   # parameters + ModMatrix
    # gin_dsp / gin_gui only if actually used
)
```

**Hard rules:**

1. Add **ONLY** `${APC_TOOLS_DIR}/_tools/Gin/modules` — **NEVER** the Gin root (it would add examples/unit tests and expects a local `juce/` checkout that doesn't exist).
2. The `juce_add_module()` of the gin modules is executed by the **Gin** CMake (once) — it respects the APC rule "never manual `juce_add_modules` in the plugin": no duplicate targets.
3. Use the out-of-tree pattern with an explicit binary dir (as for JUCE in the template).

---

## 🔄 Pin update protocol

1. Read the upstream `_tools/Gin/BREAKING_CHANGES.md` and assess the impact on existing plugins.
2. `cd _tools/Gin && git fetch && git checkout <commit> && cd ../..`
3. `git add _tools/Gin && git commit -m "chore(tools): update Gin pin to <sha>"`
4. Build + test a plugin that uses Gin (`scripts/build-and-install.sh <Name>`) before considering the update valid.
5. Update the "pinned to" line at the top of this file.