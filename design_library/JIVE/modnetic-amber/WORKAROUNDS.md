# Workarounds — Modnetic Amber (JIVE pin `89d5787` + JUCE 9)

Practical fixes discovered while building this design. Each entry: **problem →
symptom → workaround**. Cross-references: `agents/rules/jive-integration.md`
(binding rules), `agents/troubleshooting/resolutions/ui-001-jive-widget-text.md`.

---

## 1. Knob label: `<Text>` child overlays the dial

- **Problem:** attaching a label as a `<Text>` *child* of `<Knob>` renders the
  text **on top of the dial** (the child is content placed inside the widget,
  which the rotary draws over). Present in the `minimal-dark` reference too.
- **Workaround:** label as a **sibling** — wrap in a column group:

```xml
<Component display="flex" flex-direction="column" align-items="centre">
    <Knob id="amount" value="0.45" width="80" height="80"/>
    <Component display="block" width="1" height="6"/>
    <Text text="Amount" style='{"foreground": "#9A968A", "font-size": 11}'/>
</Component>
```

## 2. ComboBox initial selection

- **Problem:** `<Option text="16" selected="true"/>` is **ignored** on this
  pin; the combo always opens on index 0 (rendered "2" instead of "16").
- **Workaround:** use the index attribute on the **ComboBox itself**:

```xml
<ComboBox id="beats" selected="3" width="80" height="26">
    <Option text="2"/> <Option text="4"/> <Option text="8"/>
    <Option text="16"/> <Option text="32"/>
</ComboBox>
```

## 3. `justify-content="space-evenly"` is uneven in nested flex columns

- **Problem:** sections distributed their children with irregular gaps
  (content packed towards the top, labels colliding at the bottom).
- **Workaround:** **explicit spacer blocks** — one `flex-grow` spacer before
  and after the content, fixed-size gap components between items:

```xml
<Component display="block" flex-grow="1" width="1"/>   <!-- leading -->
<Text text="Character" .../>
<Component display="block" width="1" height="14"/>     <!-- fixed gap -->
<Knob .../>
<Component display="block" flex-grow="1" width="1"/>   <!-- trailing -->
```

Anchors titles at the top (reference-style) and centres the content block.

## 4. Widget chrome is not stylable from markup → design LookAndFeel

- **Problem:** knob dial/arc colours, slider thumbs, combo popup, button chips
  are drawn by the JUCE `LookAndFeel`; JIVE `style` JSON cannot reach them
  (default chrome = steel-blue arcs, wrong for the reference).
- **Workaround:** **`ModneticLookAndFeel.h`** (this folder, header-only):
  grey gradient dials, pale pointer, amber value arc + end-dot, tick-dot ring
  on dials ≥ 90 px, amber slider fill, flat dark chips, amber checkbox.
  Applied via the `jive-preview` flag:

```
jive-preview layout.xml --laf modnetic --screenshot out.png
APC_JIVE_PREVIEW_ARGS="--laf modnetic" bash scripts/preview-jive.sh <Name> [vN]
```

  Tool wiring: `_tools/jive-preview/CMakeLists.txt` adds the design folder to
  the include path and defines `JIVE_PREVIEW_HAS_MODNETIC_LAF` when the header
  exists; `Source/Main.cpp` applies it in `initialise()` **before** any
  component exists (`LookAndFeel::setDefaultLookAndFeel`). In a real plugin:
  copy the header, hold it as an editor member, `setLookAndFeel(&laf)`.

### 4a. L&F authoring: vertical slider `sliderPos` is a Y coordinate

- **Problem (hit while writing the L&F):** in
  `drawLinearSliderThumb`, for `LinearVertical` the passed `sliderPos` is a
  **Y coordinate**, not an X. Using it as X made vertical fader thumbs vanish.
- **Workaround:** vertical thumb at `(x + width*0.5 - r, sliderPos - r)`.

### 4b. L&F authoring: `juce::TextButton::buttonTextColourId` does not exist

- **Symptom:** compile error on JUCE 9.
- **Workaround:** use `TextButton::textColourOffId` / `textColourOnId`.

## 5. Visible text on widgets requires `<Text>` children

- **Problem:** the `text` attribute of `Button`/`Hyperlink` only sets the
  accessible title (`setTitle`); `Label` ignores it; `Checkbox` draws no text.
  Silent: no error, just missing labels.
- **Workaround:** keep `text` for a11y **and** add a `<Text>` child
  (`Text`/`Image`/`svg` are `isContent()` and attach inside any widget).
  For `Checkbox`, pad the child clear of the tick square:
  `padding="0px 0px 0px 24px"`.

## 6. Unicode glyphs → inline `<svg>` icons

- **Problem:** `◀ ▶ →` rendering depends on host fonts (tofu risk on Linux CI).
- **Workaround:** draw icons as inline `svg` children of `Button`:

```xml
<Button id="preset-prev" width="26" height="24" text="Previous preset"
        display="flex" align-items="centre" justify-content="centre">
    <svg width="10" height="10"><polygon points="8,1 8,9 2,5" fill="#C8C4B8"/></svg>
</Button>
```

## 7. Flex spacing: `gap` is grid-only

- **Problem:** `gap`/`grid-template-*` silently do nothing under
  `display="flex"`.
- **Workaround:** spacer components (`<Component display="block" width="8"
  height="1"/>`) or `padding` attributes. Column separators are 4 px spacers.

## 8. Missing `display` silently destroys children

- **Problem:** any element **with children** lacking
  `display="flex"|"grid"|"block"` gets its children destroyed without warning.
- **Workaround:** every container in `layout.xml` declares `display`; even
  decorative squares carry `display="block"` for consistency.

## 9. Colours: `#RRGGBB` only

- **Problem:** `0xAARRGGBB` renders **silently transparent**.
- **Workaround:** `#RRGGBB` everywhere in `style` JSON (alpha is not needed;
  opacity is not stylable at all).

## 10. XML comments cannot contain `--`

- **Problem:** `--screenshot` inside an XML comment breaks strict parsers
  (`xmllint`: "Double hyphen within comment"); JUCE tolerates it, but the
  markup should stay well-formed.
- **Workaround:** write flags without double hyphens in comments
  (`(screenshot flag)`).

## 11. Iteration gotcha: stale screenshot reads

- **Problem:** while iterating, reading the **same** PNG path served a cached
  image — the render looked unchanged although the file had been rewritten.
- **Workaround:** when verifying programmatically, screenshot to a **fresh
  filename** each pass (`/tmp/opencode/modnetic-v3.png`, `-v4`, …), inspect,
  then copy the good one to `preview.png`.

---

**Verification loop used throughout:** edit → headless screenshot → inspect
PNG → fix. All widget claims above are verified on the pinned JIVE commit by
`preview.png` (rendered with `--laf modnetic`).
