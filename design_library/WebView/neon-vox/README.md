# Neon Vox - Design System

## Overview
A dark vocal-chain channel strip inspired by modern AI vocal processors. Four
switchable FX modules (Dynamics, Tone, Space, SFX) each carry their own neon
accent color and a glowing glyph; the detail area below swaps per module:
compression + de-ess, a live EQ analyzer with band faders, reverb/delay with
ducking meters, and a hero SFX knob with routing toggles.

## Palette
- **Background**: #0B0D12
- **Surface**: #14161D / highlight #1D2029
- **Dynamics (primary)**: #FF3D71
- **Tone (secondary)**: #35D0F5
- **Space (tertiary)**: #A855F7
- **SFX (quaternary)**: #FFB01F
- **Text**: #E8EAF0 / secondary #7A7F8E
- **Border**: #23262F

## Components
- Knob Style: neon-arc (SVG value arc with `drop-shadow` glow, rotating pointer, big 132px hero variant)
- Fader Style: line-handle (thin 3px track, 18px grip handle with accent line)
- Mini Meter: GATE/GR/DS vertical meters with floating handle
- Analyzer: canvas EQ curve, cyan glow stroke + gradient underfill, band nodes
- Duck Meters: animated 5-bar level groups (VRB/DLY duck percentages)
- I/O Meters: 44-segment footer meters (cyan → purple → pink zones)
- Border Radius: 8px (panels 10px, container 12px)

## Interactions (mockup)
- Drag knobs / faders / trims vertically (trims horizontally), double-click knob to reset
- BYPASS desaturates the whole UI; power buttons toggle module glow
- Module preset arrows cycle the preset dots; routing buttons toggle independently

## JUCE WebView notes
All assets are local (`style.css`, `script.js`); the only external request is
the Inter font from Google Fonts — bundle it or swap to a system stack for
offline use. Component model maps 1:1 to APVTS parameters via
`juce::WebBrowserComponent::Options` native functions.
