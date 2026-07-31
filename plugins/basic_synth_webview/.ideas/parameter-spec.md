# basic_synth_webview — Parameter Specification

## Oscillator Section (OSC)

| ID | Name | Type | Range | Default | Unit | Notes |
|:---|:---|:---|:---|:---|:---|:---|
| `osc1_waveform` | OSC 1 Waveform | Choice | Sine, Triangle, Saw, Square, PWM | Sine | — | Main oscillator shape |
| `osc1_detune` | OSC 1 Detune | Float | -50 – +50 | 0 | cents | Fine pitch offset |
| `osc2_waveform` | OSC 2 Waveform | Choice | Sine, Triangle, Saw, Square, PWM | Triangle | — | Second oscillator shape |
| `osc2_detune` | OSC 2 Detune | Float | -50 – +50 | 5 | cents | Slight detune for classic pad thickness |
| `osc_mix` | OSC Mix | Float | 0.0 – 1.0 | 0.5 | — | Balance between OSC 1 and OSC 2 |
| `voice_mode` | Voice Mode | Choice | Poly, Mono, Unison | Poly | — | Polyphonic (8), Mono, or Unison mode |
| `noise_level` | Noise Level | Float | 0.0 – 1.0 | 0.0 | — | White noise level for texture layer |

## Filter Section (FILTER)

| ID | Name | Type | Range | Default | Unit | Notes |
|:---|:---|:---|:---|:---|:---|:---|
| `filter_cutoff` | Cutoff | Float | 20 – 20000 | 18000 | Hz | 4-pole resonant low-pass cutoff |
| `filter_resonance` | Resonance | Float | 0.0 – 1.0 | 0.2 | — | Emphasis at cutoff frequency |
| `filter_env_amount` | Env Amount | Float | -1.0 – 1.0 | 0.5 | — | ADSR modulation depth to cutoff |
| `filter_keytrack` | Key Track | Float | 0.0 – 1.0 | 0.5 | — | Keyboard pitch tracking for filter |

## ADSR Envelope Section (ENV)

| ID | Name | Type | Range | Default | Unit | Notes |
|:---|:---|:---|:---|:---|:---|:---|
| `attack` | Attack | Float | 0.001 – 10.0 | 1.0 | s | Long attack for pad swells |
| `decay` | Decay | Float | 0.001 – 10.0 | 0.8 | s | Decay to sustain level |
| `sustain` | Sustain | Float | 0.0 – 1.0 | 0.7 | — | Sustain level (percentage) |
| `release` | Release | Float | 0.001 – 15.0 | 3.0 | s | Long release for ambient tails |

## Reverb Section (REV)

| ID | Name | Type | Range | Default | Unit | Notes |
|:---|:---|:---|:---|:---|:---|:---|
| `reverb_mix` | Mix | Float | 0.0 – 1.0 | 0.35 | — | Wet/dry balance |
| `reverb_size` | Size | Float | 0.0 – 1.0 | 0.65 | — | Room / space size |
| `reverb_decay` | Decay | Float | 0.0 – 1.0 | 0.6 | — | Reverb tail length |
| `reverb_damping` | Damping | Float | 0.0 – 1.0 | 0.5 | — | High-frequency absorption |
| `reverb_shimmer` | Shimmer | Float | 0.0 – 1.0 | 0.2 | — | Pitch-shifted feedback for ethereal highs |

## Master Section (MASTER)

| ID | Name | Type | Range | Default | Unit | Notes |
|:---|:---|:---|:---|:---|:---|:---|
| `volume` | Volume | Float | 0.0 – 1.0 | 0.75 | dB | Output level |
| `polyphony` | Polyphony | Int | 1 – 16 | 8 | voices | Max simultaneous voices (performance) |

## Summary

| Category | Parameters |
|----------|-----------|
| Oscillator | 7 (waveforms ×2, detune ×2, mix, voice mode, noise) |
| Filter | 4 (cutoff, resonance, env amount, keytrack) |
| Envelope | 4 (attack, decay, sustain, release) |
| Reverb | 5 (mix, size, decay, damping, shimmer) |
| Master | 2 (volume, polyphony) |
| **Total** | **22 parameters** |
