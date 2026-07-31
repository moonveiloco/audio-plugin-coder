# DSP Architecture Specification: basic_synth_test

## Core Components

- **Wavetable Oscillator**: 4 band-limited wavetables (Sine, Saw, Square, Triangle) with linear interpolation
- **Polyphonic Voice Engine**: N-voice dynamic allocation (1-16 voices) with voice stealing
- **Resonant Low-Pass Filter**: 12 dB/oct state-variable filter
- **ADSR Envelope**: Per-voice amplitude envelope
- **LFO**: Modulation source targeting filter cutoff
- **Sub Oscillator**: Square wave one octave below with mix control

## Processing Chain

```
Mono Input (MIDI)
    ↓
Voice Allocation (per note-on)
    ↓
Per Voice:
  Oscillator (wavetable lookup + linear interpolation)
    ↓
  Sub Osc Mix (+1 octave down square)
    ↓
  ADSR Envelope (amplitude shaping)
    ↓
  Filter (12 dB/oct SVF, modulated by LFO + envelope)
    ↓
Voices Summed → Master Volume → Output
```

## Parameter Mapping

| Parameter | Component | Function | Range |
|-----------|-----------|----------|-------|
| master_volume | Master | Output level | 0.0 - 1.0 |
| voice_count | Voice Manager | Max polyphony | 1 - 16 |
| osc_waveform | Oscillator | Wavetable selection | 0=Sine, 1=Saw, 2=Square, 3=Triangle |
| osc_detune | Oscillator | Fine pitch offset | -50 - +50 cents |
| osc_sub_mix | Mixer | Sub oscillator level | 0.0 - 1.0 |
| filter_cutoff | Filter | Low-pass cutoff | 20 Hz - 20 kHz |
| filter_resonance | Filter | Resonance/Q | 0.0 - 1.0 |
| filter_envelope | Filter | Env → cutoff mod | -1.0 - 1.0 |
| env_attack | Envelope | Attack time | 0.001 - 10.0 s |
| env_decay | Envelope | Decay time | 0.001 - 10.0 s |
| env_sustain | Envelope | Sustain level | 0.0 - 1.0 |
| env_release | Envelope | Release time | 0.001 - 10.0 s |
| lfo_rate | LFO | Rate | 0.1 - 20.0 Hz |
| lfo_depth | LFO | Modulation depth | 0.0 - 1.0 |
| lfo_waveform | LFO | Wave shape | 0=Sine, 1=Triangle, 2=Square |

## Complexity Assessment

**Score: 5**

**Rationale:** Polyphonic voice engine with dynamic allocation, wavetable interpolation, per-voice ADSR, state-variable filter with envelope/LFO modulation. Requires careful voice management, click-free parameter smoothing, and real-time safe allocation.