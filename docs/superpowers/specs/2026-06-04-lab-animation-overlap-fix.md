# Lab Animation + Building Overlap Fix — Design Spec

**Date:** 2026-06-04

## Problem Summary

1. **All buildings overlap visually** — lab walls double up with corridor walls; upper castle floors share Y=14 boundary with no separation; all 5 upper floors are the same 116×94 footprint with no visual distinction between levels.
2. **Lab departments are unanimated and visually identical** — 5 dept rooms share the same generic coloured-box style.

---

## Fix 1: Overlap Resolution

### A — Stepped castle tower (ziggurat silhouette)
Each upper floor steps 3 studs inward per level. Floor widths/depths:
- Lab (ground): 116 × 94
- Floor 2 (Dungeon): 110 × 88
- Floor 3 (Great Hall): 104 × 82
- Floor 4 (Throne Room): 98 × 76
- Floor 5 (Treasury): 92 × 70
- Floor 6 (Battlements): 86 × 64

This creates a clear pyramid silhouette and eliminates the "same footprint stacked" visual merging.

### B — Parapet separator ring at Y=14
A 2-stud-tall crenellated stone ring sits at exactly Y=14 (the lab roof), marking the transition from lab to tower. Visible from outside as the castle's "first floor cornice."

### C — Corridor wall deduplication
Corridors between lab rooms connect through door-gap openings only. The shared wall between a corridor and a room will use the ROOM's wall (not both). Corridors will have a coloured floor stripe instead of full side walls, keeping the building open and non-claustrophobic.

---

## Fix 2: Animated Lab Departments

**Architecture:** New `AnimationManager.server.luau` script runs `TweenService` loops on specifically-named animated parts. WorldSetup creates animated parts as `hp()` (hidden until bought), tagged with `Attribute("AnimType", "bob"|"spin"|"pulse"|"strobe")` and `Attribute("AnimParam", speed_value)`.

**AnimationManager** listens for `Remotes.RoomBuilt` → starts animation loops for that room's parts.

### Per-Department Animations

#### ⚗ Chemistry (Green)
- **3 beaker cylinders** bob up 1.5 studs and down on 2/3/4-second offsets (staggered so they look independent)
- **Bubble spheres** (5 small green spheres) float upward from Y+0 to Y+4 then teleport back, over 3 seconds
- **Neon floor strip** pulses Transparency 0→0.4→0 on a 2-second sine wave

#### ⚡ Electronics (Blue)
- **Spinning fan disc** (flat cylinder) rotates 360° every 1.5 seconds
- **5 server light indicators** blink in sequence (one lights up, then next, cycling)
- **"Data stream" strip** on the back wall: a thin horizontal bar slides up the wall and resets every 2 seconds

#### 🧬 Biology (Cyan)
- **DNA helix** — two interleaved cylinder columns, each rotates 360° every 4 seconds (opposite directions)
- **Culture tank** neon glow pulses 0→1→0 Transparency on a 1.5-second cycle
- **Microscope arm** tilts up/down 15 degrees on a 3-second tween

#### ⚛ Physics (Violet)
- **3 particle rings** spin at 1×, 1.5×, 2× speed (different axes for variety)
- **Energy core** scales 0.9→1.1 on a 1-second pulse
- **Beam lines** (2 thin cylinders) fade in/out alternately every 0.8 seconds

#### 💥 Weapons (Red)
- **Targeting reticle** (flat ring) rotates 360° every 2 seconds
- **3 warning lights** strobe: on 0.3s, off 0.7s, offset so they don't all blink together
- **Crate stack** shakes X±0.3 studs on a 0.4-second tween (bounces back)

---

## Implementation Files

| File | Change |
|---|---|
| `WorldSetup.server.luau` | Stepped floor dimensions per floor, parapet ring, animated part creation with Attributes, corridor wall simplification |
| `AnimationManager.server.luau` | New — TweenService loops per AnimType, triggered by RoomBuilt |
| `Remotes.luau` | No change needed (already has RoomBuilt) |
