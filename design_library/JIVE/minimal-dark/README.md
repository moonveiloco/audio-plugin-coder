# Minimal Dark — JIVE Design System (Example)

Minimalist dark UI for **JIVE** (declarative UI for JUCE): flat graphite surfaces,
hairline borders, a single cool-blue accent, generous whitespace. This folder is a
**reference example**: `layout.xml` contains **every component type registered in
`jive::ComponentFactory`** on the pinned commit (`_tools/JIVE` @ `89d5787`) — 15 types
plus the `ComboBox` child types.

## Palette

- **Background** `#16181D` — window base
- **Surface** `#1E2128` — panels, header/footer strips
- **Surface highlight** `#262B34` — hover/raised
- **Primary text** `#E8ECF1` — titles, values
- **Secondary text** `#8B93A1` — labels, captions
- **Disabled text** `#5C6572` — placeholder hints
- **Accent** `#4BB1D9` — links, active controls, waveform stroke
- **Border** `#2E3440` — hairline panel borders

## Component inventory (all verified against `jive_ComponentFactory.cpp`)

| Tag | Backing JUCE class | Used for |
|---|---|---|
| `Window` | IgnoredComponent | root, flex column |
| `Component` | IgnoredComponent | containers (header, rows, panels) |
| `Editor` | IgnoredComponent | placeholder (upstream TextEditor missing, issue #59) |
| `Text` | TextComponent | titles, captions |
| `Label` | juce::Label | status line |
| `Button` | juce::TextButton | Reset, Bypass (`toggleable`/`toggled`) |
| `Checkbox` | juce::ToggleButton | Auto-gain |
| `ComboBox` | juce::ComboBox | algorithm selector (+ `Header`, `Option` children with `selected`/`enabled`) |
| `Slider` | juce::Slider | vertical Mix |
| `Knob` | juce::Slider | Cutoff / Resonance / Drive |
| `Spinner` | juce::Slider | Voices |
| `ProgressBar` | NormalisedProgressBar | Output meter (`value` 0–1) |
| `Hyperlink` | juce::HyperlinkButton | docs link (`url`) |
| `Image` | Drawable | logo (`source` = inline SVG string, XML-escaped) |
| `svg` | Drawable | inline waveform (raw SVG child content) |

## JIVE rules honoured (agents/rules/jive-integration.md)

- Every element with children declares `display="flex"|"grid"|"block"` — without it
  children are **silently destroyed**.
- Styling **only** via `style='{"..."}'` JSON attributes (single-quoted XML attr,
  double-quoted JSON); no inline colour attributes exist.
- Colors are `#RRGGBB` — `0xAARRGGBB` renders silently transparent.
- `gap` is grid-only; flex spacing uses `justify-content` / `padding`.
- Widget chrome (knob arcs, toggle ticks, combo popup) follows the host
  `LookAndFeel`; JIVE styles control placement, size and text colours.
- **Widget text**: on this pin the `text` attribute of `Button`/`Hyperlink` sets
  only the accessible title, `Label` ignores it and `Checkbox` has no decorator —
  visible text requires a `<Text>` child (kept centered via flex on the widget;
  `padding="0px 0px 0px 24px"` clears the checkbox tick square). See
  `agents/troubleshooting/resolutions/ui-001-jive-widget-text.md`.

## Usage

Copy as the starting point for a JIVE plugin design:

```
cp design_library/JIVE/minimal-dark/layout.xml ${APC_PLUGINS_DIR}/<Name>/Design/v1-layout.xml
bash scripts/preview-jive.sh <Name>          # live-reload preview
bash scripts/preview-jive.sh <Name> v1       # explicit version
```

Headless verification (CI / agent checks):

```
cmake -S _tools/jive-preview -B _tools/jive-preview/build -DAPC_TOOLS_DIR="$(pwd)" -DCMAKE_BUILD_TYPE=Release
cmake --build _tools/jive-preview/build --config Release --target jive-preview
_tools/jive-preview/build/jive-preview_artefacts/Release/jive-preview layout.xml --screenshot out.png
```

Swap in your own layout and parameters — the mockup is illustrative of the style and
does not bind any specific plugin interface.
