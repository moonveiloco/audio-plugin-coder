# Modnetic Amber — JIVE Design System

Dark modular multi-FX rack for **JIVE** (declarative UI for JUCE), inspired by a
Modnetic-style reference shot (`~/Pictures/inspo_vst_design_minimal.jpg`):
near-black panels, hairline borders, amber/mustard accents, sectioned columns
with a large central tape-echo module, amber routing diagram and vertical
output faders.

All widgets are **real interactive JIVE components** (Knob, Slider, ComboBox,
Button, Checkbox) — ready to be bound to `AudioProcessor` parameters via
`jive::Interpreter{}.interpret(tree, processor)`.

## LookAndFeel (widget chrome)

JIVE markup cannot style widget chrome (knob arcs, dial gradients, combo
popups). This design ships **`ModneticLookAndFeel.h`** (header-only, JUCE 9):

- Rotary knobs: grey gradient dial, pale pointer, **amber value arc** + amber
  end-dot, tick-dot ring on large dials (≥ 90 px, e.g. Repeat).
- Linear sliders: hairline track, amber fill, pale bar thumb on wide sliders
  (Spread) / round dot on narrow ones (Noise, Width) and on vertical faders.
- Buttons: flat dark chips, brighter when toggled; ComboBox: dark chip +
  chevron, dark popup with amber highlight; Checkbox: amber square when ticked.

**In a plugin** (after the JIVE bootstrap, e.g. `Source/PluginEditor.h`):

```cpp
#include "ModneticLookAndFeel.h"   // copy the header into your plugin

class PluginEditor : public juce::AudioProcessorEditor
{
    ModneticLookAndFeel laf;        // member: must outlive the editor's children
    // ...
};
// in the constructor:  setLookAndFeel(&laf);
// in the destructor:   setLookAndFeel(nullptr);
```

**In jive-preview** (the flag is compiled in only when the header exists):

```
jive-preview layout.xml --laf modnetic [--screenshot out.png]
# live preview:
APC_JIVE_PREVIEW_ARGS="--laf modnetic" bash scripts/preview-jive.sh <Name> [v<N>]
```

`preview.png` in this folder is rendered **with** the LookAndFeel applied.

## Palette

- **Window** `#0D0D0D` — base background
- **Panel** `#161616` — module sections
- **Panel inset** `#101010` — routing diagram well
- **Primary text** `#F2EFE6` — brand, section titles, value readouts
- **Secondary text** `#C8C4B8` — checkbox/button labels
- **Muted text** `#9A968A` — control labels, logo stroke
- **Faint text** `#6A675F` — license line, "Dry" label
- **Accent** `#E8A33D` — section bullets, routing boxes/lines, Heads LEDs
- **Text on accent** `#141414` — M/E/R glyphs
- **Border** `#262626` — hairline panel borders

## Layout

```
┌ Header: Modnetic · preset ▾ · ◀ ▶ · A B · Mix Lock · license · logo ┐
├──────────┬────────────┬──────────────────────────┬─────────┬───┤
│ Character│ Modulation │          Echo            │   Mix   │ F │
│   501 ▾  │ Chorus ▾ Analog ▾                      │ Bass Treble│ e │
│  Amount  │ Rate Amount · Spread ──                │  Noise ── │ d │
├──────────┼────────────┤  Repeat(122)      ●●●    │  Width ── │ e │
│  Reverb  │  Routing   │  2/16  Beats[16▾]  Heads │ Input Mix │ r │
│ Stereo ▾ │ Parallel ▾ │  Intensity(106)  Wow     │           │ s │
│  Spring  │ Pre Wet  ▾ │  Playback →·Tape  Level  │           │   │
│  Level   │  [M][E]    │                   Hold   │           │   │
│          │  [R]→x     │                          │           │   │
└──────────┴────────────┴──────────────────────────┴─────────┴───┘
```

Window `1200×760`; body is a flex row of 4 module columns + a 52 px output
strip with two vertical faders. Sections use **leading/trailing `flex-grow`
spacer blocks + fixed gap components** for vertical centring.

## Component inventory (verified on pin 89d5787)

| Tag | Used for |
|---|---|
| `Window` | root, flex column |
| `Component` | header bar, columns, sections, knob groups, spacer blocks, routing nodes/sum |
| `Text` | brand, section titles, labels, `2/16` readout, license, widget label children |
| `Button` | preset prev/next (svg triangles), A/B slots (`toggleable`), Tape, playback arrow, Hold |
| `Checkbox` | Mix Lock (tick square + `<Text>` child, `padding` clears the box) |
| `ComboBox` | preset, Character 501, Reverb Stereo, Chorus/Analog, Parallel/Pre Wet, Beats |
| `Slider` | Spread/Noise/Width (horizontal), output faders (vertical) |
| `Knob` | Amount, Level ×2, Rate, Repeat(122), Intensity(106), Heads, Wow, Bass, Treble, Input, Mix |
| `svg` | transport triangles, playback arrow, logo diamond, routing lines, Heads LEDs (via Components) |

## JIVE rules honoured & discovered

> Full fix-by-fix list with code snippets: **[WORKAROUNDS.md](WORKAROUNDS.md)**. (agents/rules/jive-integration.md)

- Every element with children declares `display="flex"|"grid"|"block"`.
- Styling **only** via `style='{...}'` JSON attributes; colors `#RRGGBB`.
- `gap` is grid-only — flex spacing via padding + spacer components.
- Widget text: visible labels are `<Text>` children/siblings; `text` attr kept
  for accessibility (a11y) only.
- **Knob labels are siblings, not children**: a `<Text>` child of `Knob`
  *overlays the dial* on this pin (also visible in the `minimal-dark`
  reference render). The sibling pattern (`Knob` + gap + `Text` in a column
  group) renders the label below — verified via headless screenshot.
- **ComboBox selection**: use `selected="<index>"` on the `ComboBox`;
  `Option selected="true"` is ignored on this pin.
- **Vertical distribution**: `justify-content="space-evenly"` distributes
  unevenly in nested flex columns — use explicit `flex-grow` spacer blocks.
- Icons are inline `<svg>` (triangles, arrow, logo) — no unicode glyph
  dependency.

## Usage

Copy as the starting point for a JIVE plugin design:

```
cp design_library/JIVE/modnetic-amber/layout.xml ${APC_PLUGINS_DIR}/<Name>/Design/v1-layout.xml
bash scripts/preview-jive.sh <Name>          # live-reload preview
bash scripts/preview-jive.sh <Name> v1       # explicit version
```

Headless verification (CI / agent checks):

```
_tools/jive-preview/build/jive-preview_artefacts/Release/jive-preview layout.xml --screenshot out.png
```

Best for: multi-FX, delay/echo, reverb, modulation racks. Swap in your own
parameters — control IDs (`character-amount`, `echo-repeat`, …) are the
binding points.
