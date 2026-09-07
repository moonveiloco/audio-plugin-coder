# jive-preview

Standalone renderer for [JIVE](https://github.com/ImJimmi/JIVE) markup files — preview a declarative UI without building a plugin.

Part of the **Audio Plugin Coder (APC)** toolchain, but the renderer itself is plugin-agnostic: it interprets any JIVE XML markup and displays it in a native window.

## Why

JIVE is a C++/JUCE UI library: there is no browser preview for its markup, and iterating on a layout usually means rebuilding the whole plugin. `jive-preview` closes that gap:

- **Interactive mode** — opens the markup in a window and **live-reloads** it on every file save (mtime poll, ~500 ms). Edit `Design/v1-layout.xml`, hit save, watch the UI update.
- **Headless mode** (`--screenshot`) — renders the markup off-screen to a PNG and exits. Deterministic geometry, no window manager interference: ideal for CI, agents, and pixel-exact design verification.

## Usage

```
jive-preview <file.xml> [--width N] [--height N] [--screenshot out.png] [--raw]
```

| Flag | Effect |
|---|---|
| *(none)* | Open a window showing the markup; live-reload on change |
| `--width N --height N` | Override the window/content size from the markup |
| `--screenshot out.png` | Off-screen render to PNG, then exit (no window at all) |
| `--raw` | Interpret the markup untouched (jive's own `Window` item manages the top-level window; its title-bar close does not quit — upstream limitation) |

Behaviour notes:

- The tool rewrites the markup root `<Window>` → `<Component>` and hosts it in its own `DocumentWindow`, so the native close button quits the app and avoids a window-in-window.
- Window size defaults to the markup root's `width`/`height` attributes.
- A **failed reload** (partial save, bad property, …) keeps the last good UI on screen and logs the problem on stderr — the tool never crashes mid-iteration.
- A **failed first load** shows an alert and exits non-silently.

### APC integration

```bash
bash scripts/preview-jive.sh <PluginName> [v<N>]   # interactive (Linux/macOS)
.\scripts\preview-jive.ps1 -PluginName <Name>       # Windows
```

Opt-in by design: the scripts **refuse non-JIVE plugins** (`ui_framework != "jive"`) with a hint towards the right preview path (Visage → `preview-design.*`, WebView → browser). Headless from any shell:

```bash
_tools/jive-preview/build/jive-preview_artefacts/Release/jive-preview \
    "${APC_PLUGINS_DIR}/<Name>/Design/v1-layout.xml" --screenshot preview.png
```

## Build

Standalone CMake project — it does **not** touch the APC root build or any plugin build.

```bash
cmake -S _tools/jive-preview -B _tools/jive-preview/build \
      -DAPC_TOOLS_DIR="$(pwd)" -DCMAKE_BUILD_TYPE=Release
cmake --build _tools/jive-preview/build --config Release --target jive-preview
```

- `APC_TOOLS_DIR` must point to the APC repo root (contains `_tools/JUCE` and `_tools/JIVE`).
- Requires C++20. Submodules must be initialised (`git submodule update --init --recursive`); JIVE needs its JUCE 9 compat patch (`scripts/apply-submodule-patches.sh` — applied automatically by APC build scripts).
- **No LTO**: `juce_recommended_lto_flags` is deliberately omitted — GCC 16 (Arch) hits an LTO internal compiler error linking JUCE, and LTO buys nothing for a preview tool.
- Build artifacts go to `_tools/jive-preview/build/` (gitignored) and are cached; `scripts/preview-jive.*` rebuilds only when `CMakeLists.txt` or `Source/` changes.

## Markup syntax (pin `89d5787`)

Common pitfalls that produce **silently empty/transparent rendering** — the full verified table lives in `agents/rules/jive-integration.md`:

- Every container with children needs an explicit `display="flex" | "grid" | "block"`, otherwise children are **dropped in silence**.
- Colours/styles live in the `style` attribute as a **JSON string** (`style='{"background": "#16181D"}'`); there are no inline `background-colour`/`colour` attributes.
- Colours are `#RRGGBB` (or `rgb()`, CSS names) — **not** `0xAARRGGBB`.
- No `Panel` type: use `Component` for generic containers.
- `gap` / `grid-template-*` exist only with `display="grid"`.

## Note on JIVE upstream runners

`JIVE_BUILD_DEMO_RUNNER` / `JIVE_BUILD_TEST_RUNNER` cannot be enabled inside a project that already includes JUCE (the demo runner pulls a second JUCE via CPM). That is why this dedicated tool exists.

## Files

```
_tools/jive-preview/
├── CMakeLists.txt      # standalone project (JUCE + JIVE from APC_TOOLS_DIR)
├── Source/Main.cpp     # the whole tool (~400 lines)
└── build/              # cached build dir (gitignored)
```
