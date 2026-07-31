# UI Specification v1: basic_synth_test

## Layout
- **Window:** 800x500px (fixed, non-resizable)
- **Sections:** 5 horizontal columns: Master, Oscillator, Filter, Envelope, LFO
- **Top bar:** Plugin title + waveform visualization area (80px tall)
- **Bottom row:** ADSR envelope curve display spanning full width (60px tall)
- **Center:** Knob grid per section
- **Grid:** 5 equal columns, knobs centered within each column

## Controls

| Section | Parameter | Type | Position | Range | Default |
|---------|-----------|------|----------|-------|---------|
| Master | Volume | Arc Knob | Col 0, Row 1 | 0.0–1.0 | 0.75 |
| Master | Voices | Arc Knob | Col 0, Row 2 | 1–16 | 8 |
| Oscillator | Waveform | Segmented Button | Col 1, Row 1 | Sine/Saw/Square/Triangle | Sine |
| Oscillator | Detune | Arc Knob | Col 1, Row 2 | -50–+50 ct | 0 |
| Oscillator | Sub Mix | Arc Knob | Col 1, Row 3 | 0.0–1.0 | 0 |
| Filter | Cutoff | Arc Knob | Col 2, Row 1 | 20–20k Hz | 20k |
| Filter | Resonance | Arc Knob | Col 2, Row 2 | 0.0–1.0 | 0 |
| Filter | Env Amt | Arc Knob | Col 2, Row 3 | -1.0–1.0 | 0 |
| Envelope | Attack | Arc Knob | Col 3, Row 1 | 0.001–10s | 0.01 |
| Envelope | Decay | Arc Knob | Col 3, Row 2 | 0.001–10s | 0.3 |
| Envelope | Sustain | Arc Knob | Col 3, Row 3 | 0.0–1.0 | 0.7 |
| Envelope | Release | Arc Knob | Col 3, Row 4 | 0.001–10s | 0.5 |
| LFO | Rate | Arc Knob | Col 4, Row 1 | 0.1–20 Hz | 2.0 |
| LFO | Depth | Arc Knob | Col 4, Row 2 | 0.0–1.0 | 0 |
| LFO | Waveform | Segmented Button | Col 4, Row 3 | Sine/Triangle/Square | Sine |

## Color Palette
- **Background:** `#0d0d1a` (deep near-black blue)
- **Panel Background:** `#1a1a2e` (dark navy)
- **Grid Lines:** `#222244` (subtle separation)
- **Primary Accent:** `#00ccff` (neon cyan) — knobs, active elements
- **Secondary Accent:** `#ff0088` (neon pink) — waveform, ADSR curve
- **Tertiary Accent:** `#9900ff` (neon purple) — section headers
- **Text:** `#e0e0ff` (light periwinkle)
- **Text Dim:** `#666688` (muted labels)
- **Knob Track:** `#333355` (inactive arc)

## Style Notes
- **Cyberpunk neon** aesthetic with dark background and vibrant glow accents
- **Windowless rendering** via Visage Canvas (no OpenGL swap chain issues)
- **Animated waveform** display in top section showing current oscillator shape
- **ADSR envelope curve** at bottom, live-updating with parameter changes
- **Neon glow** effect on knob arcs using alpha layering in Visage
- **LFO indicator** — animated dot or wave showing LFO rate and depth
- **Lato font** for all text (embedded via binary data)
- **60fps rendering** via JUCE timer callback