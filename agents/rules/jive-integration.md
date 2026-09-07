# JIVE Integration Protocol (ImJimmi/JIVE)

**Library:** [ImJimmi/JIVE](https://github.com/ImJimmi/JIVE) — declarative UI for JUCE inspired by the web: ValueTree/XML markup (HTML-style) + style sheets via `juce::var` (CSS-style).
**Location:** submodule `_tools/JIVE`, pinned to `main` @ `89d5787` (2026-06-26).
**License:** MIT. **Compatibility:** compiled and tested against JUCE 9 (`_tools/JUCE`) on Linux — build, link and runtime OK **with the mandatory patch** (see below).

> **Note on the pin:** the `v1.3.0` tag (2025-01-18) is **broken against JUCE 9** and the fix has not been verified against it. `main` is the project's de-facto stable (like `master` for Gin) and includes 6 more months of fixes — it is the pinned commit.

---

## ✅ What it is for (why it was integrated)

| Module | Value |
|---|---|
| `jive::jive_layouts` | Declarative UI: `jive::Interpreter{}.interpret(xmlString)` → tree of `GuiItem`; flexbox/grid layout via properties; `interpret(tree, AudioProcessor*)` for plugins |
| `jive::jive_style_sheets` | CSS-like style sheets (`background-colour`, `font-size`, …) with `JIVE_GUI_ITEMS_HAVE_STYLE_SHEETS=1` |
| `jive::jive_components` / `jive_core` | Widgets and core, pulled in by the dependencies of the modules above |

---

## ⚠️ KNOWN LIMITATIONS (read BEFORE choosing JIVE)

These points are **binding**, not suggestions. Verify them in the `/plan` phase and record the decision in `.ideas/architecture.md`.

| # | Limitation | Impact | Mandatory mitigation |
|---|---|---|---|
| 1 | **Broken against JUCE 9 upstream** (both `v1.3.0` and `main`): `Drawable::setTransformToFit` and `createFromSVG(XmlElement&)` removed in JUCE 9 | Compilation fails in `jive_Image.cpp` and `jive_Drawable.cpp` | **Mandatory patch** `patches/JIVE/juce9-drawable-compat.patch`, applied idempotently by `scripts/apply-submodule-patches.sh\|.ps1` and the hook in `build-and-install.sh\|.ps1`. If a build fails with `setTransformToFit` / `createFromSVG is not a member` → patch not applied: run the script |
| 2 | **Reduced upstream activity** | Last commit on `main` 2026-06-26 (renovate maintenance only); red CI (issue #196 open); `v2` branch = rewrite, not stable | Don't expect quick upstream fixes; test every pin update with a real build |
| 3 | **Third UI path (neither PATH A nor PATH B)** | JIVE replaces the entire Component layer: incompatible with Visage, concurrent with WebView | This is an **architectural decision** to state in `/plan` (`ui_framework`): treat it as a dedicated UI path, never mix it with the other two |
| 4 | **Incomplete plugin integration** | Issue #162 open (`interpret` does not return `AudioProcessorEditor`), #171 (demo plugin requires `juce_audio_plugin_client`) | For plugins use `interpret(tree, processor)` and verify the editor title/owner; test in a real DAW host in the `/test` phase |
| 5 | **Missing widgets** | `TextEditor` (#59), `PopupMenu` (#60), alert windows (#63), styled tooltips (#64), `Browser` (#62), `Video` (#61) | If the plugin needs these widgets, JIVE is not suitable (or you need custom nested JUCE components — not documented upstream) |
| 6 | **Gin interop not guaranteed** | `gin_gui` widgets are plain `juce::Component`; embedding them in the JIVE declarative tree is not supported upstream | **Do not combine** Gin UI and JIVE UI in the same plugin. Only non-UI layers (e.g. `gin_dsp`) under a JIVE UI |

---

## 🔧 Usage protocol (CMake)

In the plugin `CMakeLists.txt` **after** the JUCE bootstrap:

```cmake
# JIVE (root: the runner/demo/example options are OFF by default, so safe)
add_subdirectory("${APC_TOOLS_DIR}/_tools/JIVE" "${CMAKE_BINARY_DIR}/_tools/JIVE")

target_link_libraries({PLUGIN_NAME} PRIVATE
    jive::jive_layouts
    jive::jive_style_sheets
)
target_compile_definitions({PLUGIN_NAME} PRIVATE
    JIVE_GUI_ITEMS_HAVE_STYLE_SHEETS=1
)
```

Typical runtime usage (plugin editor):

```cpp
item = jive::Interpreter{}.interpret(R"JIVE(
<Window width="480" height="320" display="flex"
        style='{"background": "#1a1a1a", "foreground": "#e8ecf1"}'>
    <Text text="Hello" font-size="18" justify="centred"/>
</Window>
)JIVE", processor);
setContentNonOwned(item->getComponent().get(), true);   // item: std::unique_ptr<jive::GuiItem>, keep alive
```

### Markup syntax verified on pin `89d5787` (⚠️ upstream examples and old documents use no-longer-valid properties)

| Rule | Details |
|---|---|
| **`display` required** | Every element with children to arrange MUST have `display="flex"\|"grid"\|"block"`: without it, children are **silently destroyed** (`decorateWithHereditaryBehaviour` returns nullptr) |
| **Styles in `style` (JSON)** | Colors/fonts/borders live in the `style='{"background": "#16181D", "font-size": 11}'` attribute (JSON string → `jive::Object` via `parseJSON`); **NO** inline attributes like `background-colour`/`colour` exist |
| **Colors** | `#RRGGBB` (or `rgb()`, CSS names). **NOT** `0xAARRGGBB` (silently transparent) |
| **Valid style names** | `background`, `foreground`, `border`, `border-radius`, `font-family`, `font-size`, `font-stretch`, `font-style`, `font-weight`, `letter-spacing`, `text-decoration` |
| **No `Panel`** | Valid types: `Button, Checkbox, ComboBox, Component, Editor, Hyperlink, Image, Knob, Label, ProgressBar, Slider, Spinner, svg, Text, Window` — use `Component` for a generic container |
| **`gap` only for grid** | `gap`/`grid-template-*` exist only with `display="grid"`; use padding/margins for flex |
| **Slider** | `value`, `min`, `max`, `interval`, `orientation="vertical"\|"horizontal"` |
| **ComboBox** | Children `<Item text="..."/>` + `selected="<index>"` attribute |
| **Flex items** | `flex-grow`, `flex-shrink`, `flex-basis`, `align-self` on children of a flex container |
| **Inherited style** | The Window `style` propagates to descendants; `#id` selectors inside the `style` for targeting |

**Preview without building the plugin:** use the `jive-preview` tool (section below) — without these constraints the typical error is empty/transparent rendering with no warning.

## 🔍 Preview tool: `jive-preview` (APC)

Standalone GUI app in `_tools/jive-preview/` (separate CMake project, bootstraps JUCE+JIVE from `APC_TOOLS_DIR`; does **not** touch the plugin build):

```bash
# Interactive with live-reload (updates at every file save):
bash scripts/preview-jive.sh <PluginName> [v<N>]

# Headless (render offscreen to PNG, ideal for CI and agent verification):
_tools/jive-preview/build/jive-preview_artefacts/Release/jive-preview Design/v1-layout.xml --screenshot out.png
```

- Default mode: interprets the markup and opens a native host window (close→quit), live-reload with ~500 ms mtime polling.
- `--screenshot out.png`: **no window** (immune to WM tiling), deterministic render at the markup size.
- `--raw`: interprets the markup *as-is* (JIVE handles its own `Window`); useful for debugging, but closing via the titlebar doesn't quit (upstream `closeButtonPressed` limitation).
- The tool rewrites the root `<Window>` → `<Component>` and provides the host window: avoids window-in-window and gives clean closing.
- Load failure during live-reload → keeps the last valid UI and logs to stderr.

**Standalone build (cache in `_tools/jive-preview/build/`, doesn't affect plugins):**
```bash
cmake -S _tools/jive-preview -B _tools/jive-preview/build -DAPC_TOOLS_DIR="$(pwd)" -DCMAKE_BUILD_TYPE=Release
cmake --build _tools/jive-preview/build --config Release --target jive-preview
```

**Known limitation (Hyprland/tiling):** JUCE windows under tiling WMs are resized by the WM ignoring the requested size — for interactive preview, place/float the window beside it; for deterministic checks use `--screenshot`.

**Note on upstream runners:** `JIVE_BUILD_DEMO_RUNNER`/`JIVE_BUILD_TEST_RUNNER` cannot be used inside a project that already includes JUCE (the demo runner tries to pull a second JUCE via CPM) — hence the dedicated tool.

**Note on `--fresh`:** `build-and-install.sh|.ps1` configures with `--fresh`, so the working tree of the submodule must be **already patched** when configure starts — that's exactly what the (idempotent) hook inserted before configure does.

---

## 🩹 Patch protocol (JUCE 9 compat)

**Fresh clone:**

```bash
git submodule update --init --recursive
bash scripts/apply-submodule-patches.sh        # .ps1 on Windows
```

Usually **not needed**: `build-and-install.sh|.ps1` applies the patch on its own at every build.

**Patch content** (`patches/JIVE/juce9-drawable-compat.patch`, 3 files, ~10 lines):
- `jive_Image.cpp/.h`: `dynamic_cast<juce::Drawable*>` → `juce::DrawableComponent*`; `createSVG()` uses `juce::OwningDrawableComponent::createFromSVGString()`; updated auto-size casts
- `jive_Drawable.cpp`: `createFromSVG(XmlElement&)` → `createFromSVGString(xmlElement.toString())`

**Patch conflict** (`ERROR: ... does not apply`): the pin changed upstream and the patched files were modified → regenerate the patch (see update protocol).

---

## 🔄 Pin update protocol

1. Read the upstream changelog/commits between the current pin and the new target.
2. `cd _tools/JIVE && git fetch && git checkout <commit> && cd ../..`
3. `bash scripts/apply-submodule-patches.sh JIVE` — if it fails, the patched files changed: evaluate/rebase the patch on the new base.
4. Build + test a plugin with a JIVE UI before considering the update valid.
5. `git add _tools/JIVE && git commit` (optionally with the regenerated patch).

## 🪦 Patch retirement protocol (when upstream fixes JUCE 9)

1. Update the pin to the upstream commit that includes the fix.
2. Delete `patches/JIVE/juce9-drawable-compat.patch`.
3. `git submodule update --force _tools/JIVE` (clean working tree) + verification build.
4. Update this file (remove the patch section) and the "pinned to" line at the top.