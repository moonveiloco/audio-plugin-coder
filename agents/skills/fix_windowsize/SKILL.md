---
name: fix_windowsize
description: >
  Fix JUCE WebView UI with correct width but wrong/short height causing
  vertical scroll, on Linux/Wayland hosts with fractional display scaling
  (e.g. REAPER). Use when a WebView-based plugin UI renders the right X but
  the wrong Y, or the bottom of the panel is cut off and needs scrolling.
  Triggers: WebView, REAPER, window size, height, vertical scroll, scaling,
  devicePixelRatio, dpr, fractional HiDPI, Wayland, WebKitGTK, overflow.
---

# Skill: Fix WebView sizing under fractional display scaling

## When to use

Trigger symptoms:
- A JUCE plugin with a **WebView UI** (WebBrowserComponent + HTML/CSS/JS)
  shows the correct **width** but the wrong (too short) **height** in a DAW.
- The bottom of the panel is cut off / requires **vertical scrolling**.
- Occurs on **Linux + Wayland** with **fractional display scaling**
  (scale factor like 1.25 / 1.32), inside a host like **REAPER**.
- The **standalone** app looks fine (or the window-manager resizes it), but a
  host that locks the window to the plugin's reported size shows the bug.

## The root cause (one paragraph to remember)

The plugin editor reports a **logical** size (e.g. `setSize(700, 420)`) to the
host. The host (REAPER) creates the window at that **physical** size. But
**WebKitGTK divides the CSS viewport by the display `devicePixelRatio`** when
the scale factor is fractional (non-integer). So a 700x420 physical window
becomes a **530x318 CSS viewport** (700/1.32, 420/1.32). An HTML panel drawn
in fixed pixels (`700px x 420px`) is then larger than the CSS viewport, so it
**overflows and scrolls vertically** — even though the *width* happens to look
correct.

`getGlobalScaleFactor()` typically returns `1.0` even when `devicePixelRatio`
is `1.32` (Wayland fractional scaling), so the DPI-scaling path in the JUCE
VST3 wrapper does **not** compensate. This is why the symptom is asymmetric
(X ok, Y too short).

## How to confirm it's this bug

Add a one-shot diagnostic that evaluates JS in the WebView after ~3 s and logs:

```js
JSON.stringify({
  innerW: window.innerWidth,
  innerH: window.innerHeight,
  clientH: document.documentElement.clientHeight,
  scrollH: document.documentElement.scrollHeight,
  panelH: document.querySelector('.panel').offsetHeight,
  dpr: window.devicePixelRatio
})
```

Bug is confirmed when **`scrollH > clientH`** (content overflows) and
**`dpr` is non-integer** (e.g. `1.32`), while the panel design size
(`panelH == 420`) is larger than the CSS viewport (`innerH == 318`).

Example of the bug:
```json
{"innerH":318,"scrollH":420,"panelH":420,"dpr":1.32}
```

## The fix (dpr-agnostic, host-agnostic)

Keep the panel on its **fixed design grid** (e.g. 700x420) and wrap it in a
**stage** that is CSS-scaled to fill the *actual CSS viewport*, preserving
aspect ratio. This works regardless of host or scale factor, because it uses
`window.innerWidth/innerHeight` which WebKit already reports in CSS pixels.

### 1) HTML/CSS (`index.html`)

```css
body {
  width: 100vw;
  height: 100vh;
  overflow: hidden;            /* no scrollbars */
  display: flex;
  justify-content: center;
  align-items: center;
}

.stage {
  width: 700px;                /* design width  */
  height: 420px;               /* design height */
  flex-shrink: 0;
  transform: scale(var(--ui-scale, 1));
}
```

```html
<body>
  <div class="stage">
    <div class="panel"><!-- existing 700x420 UI --></div>
  </div>
  ...
```

Keep the `.panel` at its exact design size (700x420). CSS transforms affect
WebKit **hit-testing**, so knobs/buttons still receive the correct mouse
events at their scaled positions.

### 2) JS (`js/index.js`)

```js
const DESIGN_W = 700;
const DESIGN_H = 420;

function fitStageToViewport() {
  const stage = document.querySelector(".stage");
  if (!stage) return;
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  if (vw <= 0 || vh <= 0) return;
  const scale = Math.min(vw / DESIGN_W, vh / DESIGN_H);
  document.documentElement.style.setProperty("--ui-scale", String(scale));
}

window.addEventListener("resize", fitStageToViewport);
document.addEventListener("DOMContentLoaded", fitStageToViewport);
```

### 3) Verification

Re-run the JS diagnostic on a viewport reproducing the host (e.g. force the
standalone to 700x420 so WebKit yields a 530x318 CSS viewport). Confirm:

```json
{"innerH":318,"scrollH":318,"panelH":420,"panelRectH":318,"dpr":1.32}
```

`scrollH == clientH` (no vertical scroll) and `panelRectH == innerH` (the
scaled panel fills the viewport exactly) → **fixed**.

## Do NOT

- Do not try to compensate by reporting a scaled size to the host
  (e.g. `setSize(700 * dpr, 420 * dpr)`). It's host-specific, breaks autoresize,
  and REAPER may ignore it.
- Do not just add `overflow: hidden` to `body` alone — that hides the scrollbar
  but still clips the bottom of the panel.
- Do not rely on `Desktop::getGlobalScaleFactor()` being non-1.0 as a signal;
  it returns 1.0 under Wayland fractional scaling.

## Where the fix lives

- `Source/ui/public/index.html` — CSS (`body`, `.stage`, `.panel`) + markup.
- `Source/ui/public/js/index.js` — `fitStageToViewport()` + resize listener.
- Keep `setSize(700, 420)` in `PluginEditor.cpp` unchanged (that is correct).
