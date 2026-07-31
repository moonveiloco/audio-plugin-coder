# Style Guide v1: basic_synth_test

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `bg` | `#0d0d1a` | Main background |
| `panel` | `#1a1a2e` | Section panel fills |
| `grid` | `#222244` | Section dividers |
| `neon-cyan` | `#00ccff` | Knob arcs, active elements, LFO indicator |
| `neon-pink` | `#ff0088` | Waveform display, ADSR curve |
| `neon-purple` | `#9900ff` | Section headers, glow accents |
| `text` | `#e0e0ff` | Primary labels |
| `text-dim` | `#666688` | Secondary labels, units |
| `knob-track` | `#333355` | Inactive knob arc background |
| `knob-bg` | `#1a1a2e` | Knob center fill |

## Typography
- **Font:** Lato (embedded via BinaryData)
- **Title:** 18px, bold
- **Section Header:** 12px, medium
- **Label:** 11px, regular
- **Value:** 10px, regular

## Spacing
- **Section padding:** 8px horizontal, 6px vertical
- **Knob spacing:** Centered, equidistant within section
- **Label-to-knob gap:** 6px
- **Knob-to-value gap:** 4px

## Control Visual Styles

### Arc Knob
- Radius: 28px (at 1x DPI)
- Track arc: 270° (-135° to +135°)
- Value arc: colored (neon-cyan), variable endpoint
- Center dot: 3px circle at arc endpoint
- Background: circular fill (knob-bg) + outer ring (knob-track)
- Glow: 1px outer halo with reduced alpha on active arcs

### Segmented Button
- Height: 22px, width: varies by label count
- Background: panel color
- Active segment: neon-cyan fill
- Inactive: dim text
- Separators: thin grid-color lines

### ADSR Envelope Curve
- Height: 50px, full width
- Background: panel color
- Curve: neon-pink, 1.5px stroke
- Stages: dashed lines at stage boundaries
- Labels: A/D/S/R in neon-purple at each inflection point

### Waveform Display
- Height: 60px, full width
- Background: panel color
- Wave: neon-cyan, 1.5px stroke
- Grid: subtle horizontal lines at quarter intervals

## Animation
- Knob value arcs update on parameter change
- Waveform display redraws at 60fps (oscillator phase visualization)  
- LFO indicator pulses at LFO rate with depth amplitude
- ADSR curve redraws on any envelope parameter change
- No easing/transitions (instant parameter updates)