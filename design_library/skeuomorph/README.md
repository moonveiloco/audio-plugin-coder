# Skeuomorph — Design System

High-end studio hardware skeuomorphism: realistic, tactile interfaces that mimic premium outboard gear — polished machined-metal knobs, brushed graphite panels, brass accents, glass-face VU meters, and 7-segment LED displays. Deep shadows, specular highlights and layered gradients give every control physical affordance.

## Palette

- **Primary** `#E0E3E8` — polished steel, headings and values
- **Secondary** `#C9A24B` — brass, secondary accents
- **Accent** `#E8B339` — warm gold, lit LEDs, active glow, display digits
- **Background** `#1E1E22` — anodized graphite chassis
- **Surface** `#2A2A2F` — panel base
- **Surface highlight** `#3A3A40` — raised panels
- **Text primary** `#E8EAED` / **text secondary** `#9BA1A8`
- **Border** `#4A4A52`

## Hardware tokens

- **Metals** `#F2F4F7 → #B9BEC6 → #82888F → #565B62` — radial knob gradient, fader caps
- **Brass** `#E8B339 / #9A7424` — buttons ON state, switch engaged, VU yellow zone
- **Knurl** — `repeating-conic-gradient` ring on knob edges
- **Brushed graphite** — `repeating-linear-gradient` over panel base
- **LED gold** `#E8B339` glow `rgba(232,179,57,.55)`; **LED red** `#E2544B` glow `rgba(226,84,75,.55)`
- **Display** — `#0C0D0F` glass face, lit segments `#E8B339`, unlit `rgba(232,179,57,.09)`
- **Screws** — radial metal gradient with rotated slot

## Mockup (illustrative only)

The `index.html` mockup is purely illustrative of the style — it shows generic building blocks (FILTER / ENVELOPE / MASTER / CONTROL) and does **not** define any specific plugin interface. Swap in your own layout, parameters and labels while reusing the components below.

## Components

- **Knob style** — `machined-metal`: knurled ring, radial metal body, specular highlight, cap, dark pointer; -135°..+135° rotation
- **Fader style** — `metal-slot`: recessed dark track, brass fill, metal cap with grip groove
- **7-seg LED display** — 3-digit SVG display, lit segments glow
- **VU meter** — glass-face needle meter with green/yellow/red zones
- **Buttons** — glossy push; `:active` pressed inset; `.on` brass + glow
- **Rocker switch** — metal thumb slides to brass when engaged
- **LEDs** — gold power / red clip with halo glow
- **Typography** — Chakra Petch (headings 700 / body 500 / labels 8–10px uppercase)
