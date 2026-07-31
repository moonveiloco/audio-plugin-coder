# Style Guide v1 — basic_synth_webview

## Theme: Minimal Dark Glass

A dark, sophisticated aesthetic with frosted glass surfaces, ice-blue accents, and clean typography. The UI evokes cool translucent crystal with subtle azure illumination.

---

## Color Palette

### Base Colors

| Token | Hex / Value | Preview | Usage |
|-------|-------------|---------|-------|
| `--bg-primary` | `#0B0B12` | ■ | Window background |
| `--bg-panel` | `rgba(18, 20, 30, 0.75)` | ■ | Section panels |
| `--bg-knob` | `rgba(30, 35, 50, 0.6)` | ■ | Knob base surface |
| `--bg-dropdown` | `rgba(25, 28, 42, 0.85)` | ■ | Dropdown background |

### Accent Colors

| Token | Hex | Preview | Usage |
|-------|-----|---------|-------|
| `--ice-blue` | `#7EC8E3` | ■ | Section headers, labels, secondary accents |
| `--azure` | `#0080FF` | ■ | Knob arc fill, active state, focus glow |
| `--azure-glow` | `rgba(0, 128, 255, 0.3)` | ■ | Hover/active outer glow |
| `--white` | `#FFFFFF` | ■ | Primary text, parameter values |

### Text & Utility Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `--text-primary` | `#FFFFFF` | Knob values, labels |
| `--text-secondary` | `rgba(255,255,255,0.6)` | Units, secondary info |
| `--text-muted` | `rgba(255,255,255,0.3)` | Placeholder, disabled |
| `--glass-border` | `rgba(255,255,255,0.08)` | Panel borders |
| `--glass-hover` | `rgba(126,200,227,0.2)` | Hover border highlight |
| `--knob-track` | `rgba(255,255,255,0.08)` | Knob empty arc track |

### Gradients

| Name | Gradient | Usage |
|------|----------|-------|
| `--knob-active` | `conic-gradient(...)` | Active knob arc from azure to ice-blue |
| `--glass-shine` | `linear-gradient(180deg, rgba(255,255,255,0.05) 0%, transparent 100%)` | Panel surface shine |
| `--glow-radial` | `radial-gradient(...)` | Hover glow behind knobs |

---

## Typography

| Element | Font | Size | Weight | Letter-spacing |
|---------|------|------|--------|---------------|
| Plugin Name | Inter / system-ui | 16px | 600 | 1px |
| Section Header | Inter / system-ui | 11px | 700 | 2px (uppercase) |
| Knob Label | Inter / system-ui | 10px | 500 | 0.5px |
| Knob Value | Inter / system-ui | 12px | 600 | — |
| Dropdown Text | Inter / system-ui | 11px | 500 | — |

**Fallback stack:** `system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`

---

## Spacing & Sizing

| Element | Size | Notes |
|---------|------|-------|
| Window | 800 × 500 px | Fixed, non-resizable |
| Top bar | 60px height | Name left, subtitle right |
| Section panel | 150–160px width, ~420px height | 5 panels |
| Knob diameter | 44px | Circular, with 4px arc track |
| Knob spacing | 6px gap between knobs | Within each section |
| Panel padding | 12px | Inner padding |
| Section header | 14px above knob grid | — |
| Dropdown width | 90px | Inline selectors |
| Corner radius | 10px | Panels, dropdowns |

---

## Component Styles

### Circular Knob

```
┌────────────────┐
│   ┌──────────┐ │
│   │  ╭──────╮ │ │  ← 44px diameter
│   │  │ ○    │ │ │  ← Arc shows value (azure)
│   │  ╰──────╯ │ │  ← Track: 2px faint line
│   └──────────┘ │
│   Label        │ │  ← 10px, white
│   0.50         │ │  ← 12px, white, bold
└────────────────┘
```

- **Base:** Circle with dark glass fill, 1px glass border
- **Track:** 2px arc track at `rgba(255,255,255,0.08)`, 270°
- **Active fill:** 2px arc from azure → ice-blue gradient
- **Indicator:** Small dot/tick at 12 o'clock position
- **Hover:** Outer glow `rgba(0,128,255,0.2)`, border transitions to `rgba(126,200,227,0.3)`
- **Active (drag):** Brighter glow, slight scale 1.05

### Dropdown Selector

```
┌──────────────────────┐
│  Sine              ▼ │  ← glass-bg, white text
└──────────────────────┘
```

- Minimal glass background
- Rounded corners 8px
- White text, 11px
- Chevron-down icon in ice-blue
- Hover: border glow transition

### Section Panel

```
┌────────────────────┐
│   OSCILLATOR       │  ← 11px uppercase, ice-blue, tracking 2px
│                    │
│  [knobs in grid]   │
│                    │
└────────────────────┘
```

- Background: `rgba(18, 20, 30, 0.75)`
- `backdrop-filter: blur(24px)`
- `-webkit-backdrop-filter: blur(24px)`
- Border: 1px `rgba(255,255,255,0.08)`
- Border-radius: 10px
- Subtle inner shine via pseudo-element gradient

### Top Bar

```
┌──────────────────────────────────────────────────────────────┐
│  🯬 basic_synth_webview           ambient pad machine         │
│  <ice-blue dot>  ●                                                                  │
└──────────────────────────────────────────────────────────────┘
```

- Plugin name in white, 16px semibold
- Subtitle in `--white-60`, 12px, right-aligned
- Bottom border: 1px glass border
- Small ice-blue status dot (midi activity indicator placeholder)

---

## Interaction States

| Component | Normal | Hover | Active/Drag |
|-----------|--------|-------|-------------|
| Knob | Dark glass, subtle border | Azure glow ring, brighter border | Scaled 1.05, max glow |
| Dropdown | Glass surface, muted chevron | Border → ice-blue | Open state with overlay |
| Panel | Glass border, blur | — | — |
| Label | White 60% | White 100% | — |

---

## Example UI Mock States

### Idle State
All controls at defaults, gentle glass reflection present, subtle ambient glow behind knob section.

### Active State  
User dragging cutoff knob: knob slightly enlarged, azure arc fills to 60%, labeled value updates in real-time, soft azure glow emanates from behind knob.

### Automation Write
DAW automating reverb mix: knob moves autonomously, a subtle ice-blue ring pulse indicates external modulation.
