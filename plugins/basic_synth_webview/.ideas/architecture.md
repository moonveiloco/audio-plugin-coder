# DSP Architecture Specification — basic_synth_webview

## Core Components

| Component | Scope | Responsibility |
|-----------|-------|---------------|
| MIDI Input Handler | Global | Receive note on/off, velocity, pitch bend, mod wheel → route to Voice Manager |
| Voice Manager | Global | 8-voice polyphonic allocation, voice stealing, mode switching (Poly/Mono/Unison) |
| Oscillator 1 | Per-voice | Waveform generation (Sine, Triangle, Saw, Square, PWM) with detune |
| Oscillator 2 | Per-voice | Waveform generation (Sine, Triangle, Saw, Square, PWM) with detune |
| Noise Generator | Per-voice | White noise source for texture/scatter layer |
| Voice Mixer | Per-voice | Balance OSC1 ↔ OSC2 ↔ Noise |
| ADSR Envelope | Per-voice | 4-stage envelope → amplitude (always) + filter cutoff (via env_amount) |
| 4-Pole Resonant LPF | Per-voice | State-variable filter, cutoff + resonance + env mod + keytrack |
| Algorithmic Reverb | Global | Feedback delay network (FDN) with mix, size, decay, damping, shimmer |
| Master Output | Global | Volume control + soft-clip limiter |

## Processing Chain

```
MIDI In → Voice Manager
              │
              ├─ Voice n:
              │     Osc1 ─┐
              │     Osc2 ─┤→ Voice Mixer → LPF → ADSR → ┐
              │     Noise ─┘                              │
              │                                           │
              └───────────────────────────────────────────┤
                                                          ▼
                                                  Reverb (global)
                                                          │
                                                          ▼
                                                  Volume → Soft-clip → Output
```

## Parameter Mapping

| ID | Component | Function | Range |
|:---|:---------|:---------|:------|
| `osc1_waveform` | Osc 1 | Select waveform shape | Sine, Triangle, Saw, Square, PWM |
| `osc1_detune` | Osc 1 | Fine pitch offset | -50 – +50 cents |
| `osc2_waveform` | Osc 2 | Select waveform shape | Sine, Triangle, Saw, Square, PWM |
| `osc2_detune` | Osc 2 | Fine pitch offset | -50 – +50 cents |
| `osc_mix` | Voice Mixer | Balance OSC1/OSC2 | 0.0 – 1.0 |
| `voice_mode` | Voice Manager | Poly/Mono/Unison | Poly, Mono, Unison |
| `noise_level` | Noise | White noise volume | 0.0 – 1.0 |
| `filter_cutoff` | LPF | Cutoff frequency | 20 – 20000 Hz |
| `filter_resonance` | LPF | Emphasis at cutoff | 0.0 – 1.0 |
| `filter_env_amount` | LPF | Envelope → cutoff depth | -1.0 – 1.0 |
| `filter_keytrack` | LPF | Keyboard pitch tracking | 0.0 – 1.0 |
| `attack` | ADSR | Rise time | 0.001 – 10.0 s |
| `decay` | ADSR | Fall to sustain level | 0.001 – 10.0 s |
| `sustain` | ADSR | Sustain level | 0.0 – 1.0 |
| `release` | ADSR | Release tail time | 0.001 – 15.0 s |
| `reverb_mix` | Reverb | Wet/dry balance | 0.0 – 1.0 |
| `reverb_size` | Reverb | Room/space size | 0.0 – 1.0 |
| `reverb_decay` | Reverb | Reverb tail length | 0.0 – 1.0 |
| `reverb_damping` | Reverb | High-frequency absorption | 0.0 – 1.0 |
| `reverb_shimmer` | Reverb | Pitch-shifted feedback | 0.0 – 1.0 |
| `volume` | Master | Output level | 0.0 – 1.0 |
| `polyphony` | Voice Manager | Max simultaneous voices | 1 – 16 |

## Complexity Assessment

**Score: 4 (Expert)**
**Rationale:** Full subtractive synthesis engine with polyphonic voice management, per-voice envelope & filter state, algorithmic reverb with shimmer (FDN), and WebView C++ ↔ JS bridge for UI.
