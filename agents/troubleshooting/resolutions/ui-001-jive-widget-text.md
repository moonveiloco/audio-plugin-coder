# ui-001 — JIVE widget text invisible (Button/Checkbox/Hyperlink/Label render empty)

**Date:** 2026-09-07
**Category:** ui (JIVE declarative markup)
**Severity:** high
**Status:** SOLVED
**Affected:** `_tools/JIVE` pin `89d5787` (all markup using widget text attributes)

## Symptoms

- `<Button text="Bypass"/>` renders as an empty rounded box — no label
- `<Checkbox text="Auto-gain"/>` renders the tick square only — no label
- `<Hyperlink text="docs" url="..."/>` renders nothing at all
- `<Label text="Ready"/>` renders nothing at all
- Meanwhile `<Text>` elements and `<Text>` children of `<Knob>`/`<Slider>` render fine
- No warnings, no jassert noise in release — silently empty

## Root Cause

Verified against `jive_ComponentFactory.cpp` + widget decorators on pin `89d5787`:

1. **Button** (`jive_Button.cpp:88-91`): applies the markup `text` attr via
   `getButton().setTitle(text)` — that sets the **accessible title only**.
   `juce::TextButton` paints `getButtonText()`, which is never set → empty.
2. **Hyperlink** extends `jive::Button` → same `setTitle` behaviour;
   `juce::HyperlinkButton` also paints `getButtonText()` → invisible.
3. **Label** (`jive_Label.cpp`): the decorator handles **only** `border-width`;
   `juce::Label::setText()` is never called → empty.
4. **Checkbox** has no decorator at all (factory returns a bare `juce::ToggleButton`);
   nothing maps `text` to `setButtonText()` → empty.

Why the `<Text>`-child workaround works: `jive_Interpreter.cpp:302/316` inserts a
child when `parent.isContainer() || child.isContent()`, and `Text`/`Image`/`svg`
override `isContent() == true` — so they attach inside **any** widget
(`GuiItem::insertChild` → `component->addChildComponent`).

## Solution

Give the widget a `<Text>` child; keep the `text` attribute for accessibility
(it still feeds `setTitle`):

```xml
<Button text="Bypass" toggleable="true" width="80" height="26"
        display="flex" align-items="centre" justify-content="centre">
    <Text text="Bypass" style='{"foreground": "#4BB1D9"}'/>
</Button>

<Checkbox width="120" height="24" padding="0px 0px 0px 24px"
          display="flex" align-items="centre">
    <Text text="Auto-gain" font-size="11"/>
</Checkbox>

<Hyperlink url="https://github.com/ImJimmi/JIVE" width="90" height="24"
           display="flex" align-items="centre">
    <Text text="jive docs" style='{"foreground": "#4BB1D9"}'/>
</Hyperlink>

<Label width="140" height="24" display="flex" align-items="centre">
    <Text text="Ready - 44.1 kHz" style='{"foreground": "#8B93A1", "font-size": 10}'/>
</Label>
```

Notes:
- `padding="0px 0px 0px 24px"` on the Checkbox clears the ToggleButton tick square.
- Ancestor style (e.g. Window `foreground`) is inherited by the child `Text`.
- Reference implementation: `design_library/JIVE/minimal-dark/layout.xml`.

## Verification

```bash
_tools/jive-preview/build/jive-preview_artefacts/Release/jive-preview layout.xml --screenshot out.png
```

Pixel-check (sum RGB > 300) of the four previously-empty regions went from 0 to
91 / 313 / 594 / 157 text pixels — all visible.

## Prevention

- In JIVE markup, **always** give `Button` / `Checkbox` / `Hyperlink` / `Label` a
  `<Text>` child for anything that must be *seen*; the `text` attr is a11y-only.
- Rule added to `agents/rules/jive-integration.md` (markup table).
- Watch upstream: if a future pin switches to `setButtonText`, the child-Text
  pattern still renders (text would appear twice only if both attr and child are set).
