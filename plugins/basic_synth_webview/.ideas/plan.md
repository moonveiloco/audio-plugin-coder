# Implementation Plan — basic_synth_webview

## Complexity Score: 4 / 5

## Implementation Strategy

### Phased Implementation (Score ≥ 3)

#### Phase 1: DSP Core
- [ ] PluginProcessor skeleton with JUCE APVTS and parameter layout (22 params)
- [ ] ParameterIDs.hpp defining all parameter IDs as string constants
- [ ] Oscillator class — waveform generation (Sine, Triangle, Saw, Square, PWM)
- [ ] Oscillator detune + pitch bend support
- [ ] Noise generator
- [ ] Voice Mixer (OSC1/OSC2/Noise balance)
- [ ] Mono test signal verification

#### Phase 2: Polyphony & Envelope
- [ ] Voice struct/class — per-voice state (osc state, filter state, env state)
- [ ] VoiceManager — allocation, voice stealing, Poly/Mono/Unison modes
- [ ] ADSR envelope generator (per-voice)
- [ ] Per-voice signal chain assembly
- [ ] Polyphonic test (play chords, verify voice count)

#### Phase 3: Filter & Reverb
- [ ] 4-pole resonant low-pass filter (state-variable or ladder topology)
- [ ] Filter envelope modulation (env_amount + keytrack)
- [ ] Algorithmic reverb (FDN — feedback delay network)
- [ ] Shimmer control (pitch-shifted feedback path)
- [ ] Master output with soft-clip limiter

#### Phase 4: WebView UI
- [ ] `Source/ui/public/index.html` — layout with dark glass CSS
- [ ] `Source/ui/public/js/index.js` — parameter binding via `juce/index.js`
- [ ] `Source/PluginEditor.h` — relays → WebView → attachments (CRITICAL member order)
- [ ] `Source/PluginEditor.cpp` — WebView setup, resource provider, MIME mapping
- [ ] `Source/PluginProcessor.cpp` — editor factory integration
- [ ] `CMakeLists.txt` — WebView config, binary data embedding, JUCE modules

#### Phase 5: Polish
- [ ] Parameter smoothing (avoid zipper noise)
- [ ] Preset state save/load
- [ ] Bypass handling
- [ ] Edge cases (zero voices, extreme mod values, silence when idle)
- [ ] Performance optimization (buffer reuse, SIMD where viable)

## Dependencies

### Required JUCE Modules
- juce_audio_basics
- juce_audio_devices
- juce_audio_formats
- juce_audio_plugin_client
- juce_audio_processors
- juce_audio_utils
- juce_core
- juce_data_structures
- juce_dsp
- juce_events
- juce_graphics
- juce_gui_basics
- juce_gui_extra

### External Dependencies
- WebView2 (Windows) / WKWebView (macOS) / WebKitGTK (Linux)

### Build System
- CMake ≥ 3.22
- JUCE 9 (via `juce_add_plugin` macro)

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|-----------|
| Voice stealing artifacts on fast note spam | 🔴 High | Test with rapid MIDI input; verify zero-click voice swapping |
| Reverb shimmer instability / runaway feedback | 🔴 High | Clamp shimmer gain; DC-block output |
| WebView member order → DAW crash on unload | 🔴 High | Follow relays → WebView → attachments declaration order exactly |
| Parameter zipper noise on fast automation | 🟡 Medium | Apply JUCE `SmoothedValue` with ramp on all float params |
| Cross-platform WebView differences | 🟡 Medium | Test Win/macOS/Linux; abstract resource loading per platform |
| Polyphony CPU at 16 voices | 🟡 Medium | Profile DSP chain; consider vectorized oscillator rendering |
