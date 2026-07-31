# Implementation Plan: basic_synth_test

## Complexity Assessment
**Score: 5**

**Rationale:** Polyphonic synth with wavetable oscillators, per-voice ADSR, resonant filter, LFO modulation, and Visage UI. Requires phased implementation.

## Implementation Strategy
Phased implementation — three phases to manage complexity.

## Processing Chain
MIDI In → Voice Allocator → Osc (Wavetable + Sub) → ADSR Env → Filter (SVF) → Sum → Master Vol → Output

## Parameters
15 parameters across 5 sections: Master (2), Oscillator (3), Filter (3), Envelope (4), LFO (3)

## Phases

### Phase 1 — Core DSP
- [ ] Wavetable oscillator with 4 tables (Sine, Saw, Square, Triangle) and linear interpolation
- [ ] Polyphonic voice manager (max 16 voices, dynamic allocation, voice stealing)
- [ ] ADSR envelope per voice
- [ ] 12 dB/oct state-variable filter
- [ ] LFO with 3 waveforms
- [ ] PluginProcessor with AudioProcessorValueTreeState
- [ ] Parameter smoothing via juce::SmoothedValue
- [ ] MIDI note on/off handling

### Phase 2 — Visage UI
- [ ] CMakeLists.txt with Visage integration
- [ ] VisageControls.h with cyberpunk neon theme
- [ ] PluginEditor with VisageJuceHost bridge
- [ ] Waveform selector (choice control with labels)
- [ ] Knob controls for all parameters
- [ ] ADSR envelope visualizer
- [ ] LFO rate/depth display

### Phase 3 — Polish & Test
- [ ] Click-free voice allocation and deallocation
- [ ] Parameter automation support
- [ ] State save/restore (getStateInformation/setStateInformation)
- [ ] Build validation on all platforms
- [ ] Performance profiling at 48 kHz / 256 samples

## Dependencies
- juce::dsp for SVF filter (juce::dsp::StateVariableTPTFilter)
- juce::AudioProcessorValueTreeState for parameter management
- juce::SmoothedValue for parameter smoothing
- visage::Frame + Canvas for UI rendering
- std::vector for voice pool
- std::array for wavetable storage

## Risk Assessment
Medium risk — voice allocation and wavetable interpolation must be click-free. Sub-oscillator phase coherence needs care.