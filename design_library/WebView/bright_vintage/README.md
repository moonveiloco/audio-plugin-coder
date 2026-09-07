# BRIGHT VINTAGE - Design System

## Overview
A warm, light analog design system inspired by 70s hardware synthesizers. Brushed aluminum panels, walnut wooden knobs, silk-screened monospace labels, and glowing amber LEDs. Rooted in Korg MS-20 / Roland SH-1000 / ARP 2600 hardware with clean modern layout structure.

## Palette
- **Primary**: #D97706 (amber)
- **Secondary**: #F59E0B (amber bright)
- **Background**: #C6C6C6 (brushed aluminum)
- **Surface**: #DADADA
- **Text**: #3A3A3A (silkscreen serigraphy)

## Hardware Tokens
- **Wood:** #8B5A2B → #6B4226 → #3E2314 (walnut gradient)
- **LED on:** #E8590C with `0 0 6px 2px rgba(232,89,12,.6)` glow
- **Cream pointer:** #F2EDE3

## Mockup (illustrative only)
The `index.html` mockup is purely illustrative of the style — it shows generic building blocks (FILTER / ENVELOPE / MASTER sections) and does NOT define any specific plugin interface. Replace its content with your plugin's own layout while reusing the tokens and components below.

## Components
- Knob Style: vintage-wood (walnut radial gradient, cream pointer, -135°..+135°)
- Fader Style: vintage (brushed metal slot + handle, amber fill)
- Border Radius: 8px
- Panel: brushed aluminum `repeating-linear-gradient` + corner screws
- LED: amber glow `0 0 6px 2px rgba(232,89,12,.6)`
