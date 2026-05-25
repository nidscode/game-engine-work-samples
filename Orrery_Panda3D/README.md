# Orrery

A procedural solar-system viewer built in **Panda 3D** (Python). Spins up an interactive 3D scene from zero external assets — every mesh (planets, ring, star field, orbit guides) is generated at runtime.

This is a **work sample**. It's deliberately small but built the way a real Panda 3D tool / inspector would be structured: a `ShowBase` subclass at the top, separate modules for procedural geometry, scene-graph entities, camera, and HUD.

---

## How to run

```bash
pip install -r requirements.txt
python main.py
```

Tested on Panda 3D 1.10.13 with Python 3.10–3.12.

### Controls

| Action | Input |
|---|---|
| Orbit camera | Right-mouse drag |
| Zoom | Mouse wheel |
| Pause / play | `Space` |
| Slow / fast time | `[` / `]` (halves / doubles) |
| Toggle orbit guides | `O` |
| Focus the Sun | `0` |
| Focus a planet | `1`–`6` |
| Quit | `Escape` |

---

## What's in it

- **All geometry is procedural.** No `.egg` or `.bam` files in the repo.
  - Planets and the sun are **icospheres** built by subdividing an icosahedron. Vertex distribution is far more uniform than a UV sphere.
  - Saturn-style **ring** is a triangulated annulus.
  - **Star field** is 2,500 GPU points placed uniformly on a sphere via the Marsaglia method, parented to the camera so it never drifts.
  - **Orbit guides** are thin line circles.
- **Scene-graph orbital mechanics.** Each planet rides on a pivot `NodePath` parented to the scene root; spinning the pivot carries the planet around its orbit. Moons are pivoted off the planet body — they inherit the orbital transform automatically.
- **Sun is the light source.** A `PointLight` is parented to the sun mesh. Move the sun and the lighting follows.
- **Orbit camera rig** with right-drag rotate, scroll zoom, smooth target-follow, pitch clamping.
- **HUD** with title, controls, time-scale readout, and current focus.
- **Time control:** pause, half/double rate, focus-jump to any body.

---

## Project layout

```
Orrery_Panda3D/
├── requirements.txt
├── main.py              # Entry point — just instantiates OrreryApp
├── app.py               # OrreryApp(ShowBase): scene wiring, input, tick
├── procedural.py        # Icosphere, ring, star field, orbit-line builders
├── celestial.py         # Sun, Planet, Moon classes + PlanetSpec dataclass
├── camera_rig.py        # OrbitCamera controller
├── hud.py               # On-screen overlay
├── README.md            # ← you are here
└── DESIGN_NOTES.md      # Architecture / math writeup
```

See **DESIGN_NOTES.md** for the reasoning behind each module — scene-graph choices, why icosphere beats UV-sphere, the camera rig math, etc.

---

## Tech

- **Engine:** Panda 3D 1.10+
- **Language:** Python 3.10+ (type hints throughout, `from __future__ import annotations`)
- **Dependencies:** `panda3d` only

## Author

Agneya Kolhatkar — built as a portfolio piece for game-engine asset work.
