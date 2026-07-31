# basic_synth_webview — Creative Brief

## Hook
*"Ethereal landscapes, shaped by glass."*

## Description
basic_synth_webview is a warm, polyphonic ambient pad synthesizer built for instant atmosphere. At its core lies a rich analog-modelled subtractive engine with dual detunable oscillators, a resonant low-pass filter, and a buttery ADSR envelope designed for slow swells and infinite decays. A built-in algorithmic reverb adds cavernous space — from shimmering halls to dark, infinite wells.

Gli oscillatori rispondono alle **note MIDI** in ingresso, con supporto per velocity, pitch bend, e voice stealing in modalità polifonica. Ogni nota MIDI attiva le voci degli oscillatori attraverso la catena filtro → envelope → riverbero.

The entire experience is presented through a **minimal dark glass** WebView interface: deep charcoal backgrounds, frosted glass panels, subtle translucency, and clean typography. The UI stays out of your way, letting you focus on sound.

## Key Characteristics
- **Tone:** Warm, soft, evolving — inspired by classic analog polysynths
- **Character:** Lush pads, slow attack swells, deep atmospheric washes
- **Motion:** Envelope follower modulates filter cutoff for organic movement
- **Space:** Algorithmic reverb with shimmer and decay controls

## Target Use Cases
- Ambient / drone music
- Cinematic soundscapes
- Background pads in electronic and pop production
- Meditation and sound therapy

## Architecture
| Component | Detail |
|-----------|--------|
| Oscillators | 2x detunable (Sine, Triangle, Saw, Square, PWM) |
| Filter | 4-pole resonant low-pass (12/24 dB) |
| MIDI Input | Note on/off, velocity, pitch bend, mod wheel |
| Envelope | ADSR routed to amp + filter cutoff |
| Effects | Algorithmic reverb (mix, size, decay, damping) |
| Voice Mode | Polyphonic (8 voices), Mono, Unison |
| UI | WebView (HTML/CSS/JS) — dark glass aesthetic |

## Inspiration
- TAL-U-NO-LX (warmth, simplicity)
- Valhalla Shimmer (reverb character)
- Serum (visual polish, but stripped to essentials)
