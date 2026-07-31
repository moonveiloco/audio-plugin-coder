# Creative Brief: basic_synth_test

## Hook
*Four wavetables, infinite horizons. A cyberpunk polysynth for the code-fueled producer.*

## Description

**basic_synth_test** is a lightweight, polyphonic software synthesizer built for rapid sound design and plugin development validation. At its core are 4 handcrafted wavetables — Sine, Saw, Square, and Triangle — selectable per voice to cover classic subtractive synthesis territory. A resonant 12 dB/oct low-pass filter shapes the raw oscillator output, while a full ADSR amplitude envelope gives the user precise control over the sonic contour.

Designed as both a usable instrument and a reference implementation for the Visage UI framework, basic_synth_test demonstrates how a rich, cyberpunk-aesthetic interface can be driven entirely from C++. The plugin serves as a testbed for polyphonic voice allocation, wavetable interpolation, and real-time parameter modulation.

## Target Audience

- **Plugin developers & testers** — A clean, minimal codebase for validating the plugin build pipeline, audio thread safety, and UI framework integration.
- **Sound designers** — Quick sketching with classic waveforms; useful as a tonal foundation layer.
- **Music producers** — Straightforward polyphonic synth with no menu-diving; ideal for leads, pads, and bass.

## Platform Targets

| Platform | Format | Status |
| :--- | :--- | :--- |
| macOS | AUv2, VST3 | Planned |
| Windows | VST3 | Planned |
| Linux | VST3 | Planned |

## Unique Features

1. **4 Wavetable Oscillators** — Per-voice selection of Sine, Saw, Square, or Triangle with clean band-limited rendering.
2. **Polyphonic Voice Engine** — N-voice dynamic allocation with voice stealing and per-voice amplitude envelope.
3. **Resonant Low-Pass Filter** — Classic 12 dB/oct state-variable filter with cutoff and resonance control.
4. **Full ADSR Envelope** — Independent attack, decay, sustain, and release per voice for shaping dynamics.
5. **Visage UI Framework** — Cyberpunk neon aesthetic rendered entirely in C++ with real-time parameter feedback, animated waveforms, and low-latency interaction.
6. **Lightweight Footprint** — Minimal CPU and memory usage; designed to run dozens of instances.

## Design Constraints

- **UI Framework:** Visage (pure C++, no HTML/WebView)
- **DSP Style:** Single audio thread, lock-free parameter updates
- **Polyphony:** Dynamic allocation, up to 16 voices
- **Oscillator Quality:** Band-limited wavetables with anti-aliasing via oversampling

## Success Criteria

- Plugin compiles and runs on all 3 target platforms.
- Polyphonic playback is click-free and stable at 48 kHz / 256 sample buffer.
- Visage UI renders at 60 fps with no audio dropouts.
- All parameters automatable and persist in DAW project state.
