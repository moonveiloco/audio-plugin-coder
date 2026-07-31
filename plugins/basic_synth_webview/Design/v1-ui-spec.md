# UI Specification v1 — basic_synth_webview

## Layout

| Property | Value |
|----------|-------|
| Window | 800 × 500 px |
| Layout | Horizontal strip — 5 section columns |
| Top Bar | 60px — plugin name + branding |
| Content | 440px — knobs arranged in rows within each section |
| Framework | WebView (HTML/CSS/JS) |

## Section Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  🯬 basic_synth_webview                    ambient pad machine   │  60px
├──────────┬──────────┬──────────┬──────────┬──────────────────────┤
│  OSC     │  FILTER  │  ENV     │  REV     │  MASTER              │
│          │          │          │          │                      │
│ [W1][D1] │ [C ][R ] │ [A ][D ] │ [M ][S ] │  [VOL]               │
│ [W2][D2] │ [EA][KT] │ [S ][R ] │ [Dc][Dp] │  [POLY]              │
│ [MX][NS] │          │          │ [SH]     │                      │
│ [VMODE]  │          │          │          │                      │
└──────────┴──────────┴──────────┴──────────┴──────────────────────┘
```

## Controls by Section

### OSCILLATOR (7 controls)

| # | ID | Name | Type | Notes |
|---|-----|------|------|-------|
| 1 | `osc1_waveform` | OSC 1 Waveform | Dropdown | Sine, Tri, Saw, Sqr, PWM |
| 2 | `osc1_detune` | Detune 1 | Knob | -50 – +50 cents |
| 3 | `osc2_waveform` | OSC 2 Waveform | Dropdown | Sine, Tri, Saw, Sqr, PWM |
| 4 | `osc2_detune` | Detune 2 | Knob | -50 – +50 cents |
| 5 | `osc_mix` | Mix | Knob | OSC1 ↔ OSC2 balance |
| 6 | `noise_level` | Noise | Knob | White noise texture |
| 7 | `voice_mode` | Voice Mode | Dropdown | Poly, Mono, Unison |

### FILTER (4 controls)

| # | ID | Name | Type | Notes |
|---|-----|------|------|-------|
| 8 | `filter_cutoff` | Cutoff | Knob | 20 Hz – 20 kHz |
| 9 | `filter_resonance` | Resonance | Knob | 0 – 100% |
| 10 | `filter_env_amount` | Env Amt | Knob | -100% – +100% |
| 11 | `filter_keytrack` | Key Trk | Knob | 0 – 100% |

### ENVELOPE (4 controls)

| # | ID | Name | Type | Notes |
|---|-----|------|------|-------|
| 12 | `attack` | Attack | Knob | 1 ms – 10 s |
| 13 | `decay` | Decay | Knob | 1 ms – 10 s |
| 14 | `sustain` | Sustain | Knob | 0 – 100% |
| 15 | `release` | Release | Knob | 1 ms – 15 s |

### REVERB (5 controls)

| # | ID | Name | Type | Notes |
|---|-----|------|------|-------|
| 16 | `reverb_mix` | Mix | Knob | Dry ↔ Wet |
| 17 | `reverb_size` | Size | Knob | Room size |
| 18 | `reverb_decay` | Decay | Knob | Tail length |
| 19 | `reverb_damping` | Damping | Knob | HF absorption |
| 20 | `reverb_shimmer` | Shimmer | Knob | Ethereal shimmer |

### MASTER (2 controls)

| # | ID | Name | Type | Notes |
|---|-----|------|------|-------|
| 21 | `volume` | Volume | Knob | Output level |
| 22 | `polyphony` | Polyphony | Dropdown | 1 – 16 voices |

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `--bg-primary` | `#0B0B12` | Deep background |
| `--bg-panel` | `rgba(18, 20, 30, 0.75)` | Frosted glass panels |
| `--bg-knob` | `rgba(30, 35, 50, 0.6)` | Knob surface |
| `--ice-blue` | `#7EC8E3` | Section headers, labels, accents |
| `--azure` | `#0080FF` | Active elements, knob arcs |
| `--white` | `#FFFFFF` | Primary text, values |
| `--white-60` | `rgba(255,255,255,0.6)` | Secondary text, units |
| `--glass-border` | `rgba(255,255,255,0.08)` | Panel borders |
| `--glass-border-hover` | `rgba(126,200,227,0.25)` | Hover state borders |

## Style Notes

- **Theme:** Minimal dark glass — deep translucent panels with blur backdrop
- **Knobs:** Circular rotary with arc indicator (azure fill), tick mark at top
- **Dropdowns:** Minimal inline selectors with glass styling
- **Typography:** Inter or system sans-serif, clean and modern
- **Section headers:** uppercase tracking (2px), ice blue, 11px
- **Hover:** Subtle glow on control hover (azure/ice blue border)
- **Active:** Brighter glow + slight scale on interaction
