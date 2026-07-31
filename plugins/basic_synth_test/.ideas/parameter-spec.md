# Parameter Specification: basic_synth_test

## Master Controls

| ID | Name | Type | Range | Default | Unit | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `master_volume` | Volume | Float | 0.0 – 1.0 | 0.75 | dB gain | Master output level (scaled to dB) |
| `voice_count` | Voices | Int | 1 – 16 | 8 | voices | Maximum polyphony voice count |

## Oscillator Section

| ID | Name | Type | Range | Default | Unit | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `osc_waveform` | Waveform | Choice | 0–3 | 0 | — | Wavetable selection: 0=Sine, 1=Saw, 2=Square, 3=Triangle |
| `osc_detune` | Detune | Float | -50.0 – 50.0 | 0.0 | cents | Fine pitch detuning per oscillator |
| `osc_sub_mix` | Sub Mix | Float | 0.0 – 1.0 | 0.0 | — | Mix level of square wave one octave below (sub oscillator) |

## Filter Section

| ID | Name | Type | Range | Default | Unit | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `filter_cutoff` | Cutoff | Float | 20.0 – 20000.0 | 20000.0 | Hz | Low-pass filter cutoff frequency |
| `filter_resonance` | Resonance | Float | 0.0 – 1.0 | 0.0 | Q | Filter resonance/emphasis (0=none, 1=self-oscillating) |
| `filter_envelope` | Env Amt | Float | -1.0 – 1.0 | 0.0 | — | Envelope modulation amount to filter cutoff |

## Amplitude Envelope (ADSR)

| ID | Name | Type | Range | Default | Unit | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `env_attack` | Attack | Float | 0.001 – 10.0 | 0.01 | seconds | Time from note-on to peak amplitude |
| `env_decay` | Decay | Float | 0.001 – 10.0 | 0.3 | seconds | Time from peak to sustain level |
| `env_sustain` | Sustain | Float | 0.0 – 1.0 | 0.7 | — | Amplitude level held while key is pressed |
| `env_release` | Release | Float | 0.001 – 10.0 | 0.5 | seconds | Time from note-off to zero amplitude |

## Modulation (LFO)

| ID | Name | Type | Range | Default | Unit | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `lfo_rate` | LFO Rate | Float | 0.1 – 20.0 | 2.0 | Hz | Low-frequency oscillator rate |
| `lfo_depth` | LFO Depth | Float | 0.0 – 1.0 | 0.0 | — | LFO modulation depth (targets filter cutoff) |
| `lfo_waveform` | LFO Wave | Choice | 0–2 | 0 | — | LFO shape: 0=Sine, 1=Triangle, 2=Square |

## Parameter Summary

| Section | Parameter Count |
| :--- | :--- |
| Master | 2 |
| Oscillator | 3 |
| Filter | 3 |
| Envelope (ADSR) | 4 |
| LFO | 3 |
| **Total** | **15** |
