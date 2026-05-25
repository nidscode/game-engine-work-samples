# Game-Engine Work Samples

Five small game projects, one per engine, built as portfolio pieces for game-engine asset work.

The intent of this collection is not to ship five games — it's to show how I structure a project in each engine, pick the right primitives for the scope, and write code a teammate could reasonably extend. Each project is deliberately small but built the way a real shippable codebase would be: clean module boundaries, idiomatic engine usage, and a `DESIGN_NOTES.md` explaining the *why* behind every non-obvious decision.

## Overview

| # | Project | Engine | Language | What it is |
|---|---|---|---|---|
| 1 | [Pulse Arena](PulseArena_Godot/) | Godot 4 | GDScript | Neon twin-stick arena shooter with wave-based enemy spawning, trauma-based camera shake, and an event-bus architecture. |
| 2 | [Orrery](Orrery_Panda3D/) | Panda 3D | Python | Procedural solar-system viewer. Every mesh (planets, ring, star field, orbit guides) is generated at runtime from icospheres and indexed triangle buffers. |
| 3 | [Brick Breaker](BrickBreaker_Defold/) | Defold | Lua | Classic Arkanoid with factory-spawned bricks, ASCII-string level layouts, manual reflection for predictable ball physics, and a centralized message-hash table. |
| 4 | [Drop Zone](DropZone_Solar2D/) | Solar 2D | Lua | Portrait-orientation mobile dodge game with object-pooled obstacles, composer-driven scenes, JSON-on-disk high-score persistence, and drag-anywhere touch. |
| 5 | [Drift Hangar](DriftHangar_Stride/) | Stride (Xenko) | C# / .NET 8 | Third-person 3D space flight with 6-DoF local-frame rotation, a critically-damped spring chase camera, FOV-on-speed, and a procedurally placed asteroid field. |

Combined: ~3,400 lines of original code across five engines and four languages, ranging from 2D arcade to 3D procedural to mobile-first to physics-driven.

## How to evaluate this

Every project has the same structure:

- **`README.md`** — what it is, how to run it, controls, project layout.
- **`DESIGN_NOTES.md`** — the architectural reasoning. This is the part most worth reading. It explains why the trauma-shake math is squared, why bullets are reflected manually rather than left to Box2D restitution, why the camera uses a PD spring instead of a constant lerp, etc.
- **Source files** — heavily commented, statically typed where the language allows, organized by responsibility.

If you're short on time, the fastest tour is to skim each project's `DESIGN_NOTES.md` first, then dip into one or two source files per project that the notes point at.

## Project details

### 1. Pulse Arena — Godot 4 ([open](PulseArena_Godot/))

Twin-stick arena shooter. WASD + mouse, hold to fire. Waves of chasers and shooter enemies; shooters kite at a preferred range using **hysteretic state transitions** so they don't jitter at the boundary. Architecture leans on a global **EventBus autoload** so the HUD, GameManager, and camera shake all listen to the same `enemy_killed` signal without anyone needing direct references. **Trauma-based camera shake** (Squirrel Eiserloh's pattern) with squared trauma so small hits are subtle and big ones really land.

### 2. Orrery — Panda 3D ([open](Orrery_Panda3D/))

Procedural solar system. Every mesh is built at runtime — **icospheres** for the planets and sun (uniform vertex distribution, no UV-sphere polar pinching), a triangulated annulus for the ring, a **Marsaglia-uniform point cloud** for the 2,500-star background. Orbital mechanics are done by **rotating pivot NodePaths** rather than per-frame trig, so moons inherit their planet's transform for free. Right-drag to orbit, scroll to zoom, 1–6 to focus a planet.

### 3. Brick Breaker — Defold ([open](BrickBreaker_Defold/))

Arkanoid. Bricks are **factory-spawned with per-instance HP** via `go.property` overrides, then auto-tinted at `init` time so a 3-HP brick looks like a 3-HP brick without anyone setting it explicitly. Ball collisions use **manual reflection** instead of Box2D restitution so speed stays predictable, with paddle "english" so where you hit the paddle biases the launch angle. Levels are **ASCII strings** in `modules/levels.lua` — designers add a new level by editing one table.

### 4. Drop Zone — Solar 2D ([open](DropZone_Solar2D/))

Mobile-first vertical dodge game. Built around a **generic display-object pool** because allocating/freeing display objects per spawned obstacle is the largest avoidable cost in a 60-fps Solar2D game. Verified: pool of 3, 4 acquires forces 1 grow; 4 release+reacquire pairs cause zero new allocations. Player movement uses **`1 - exp(-k*dt)` smoothing** (the mathematically correct form, not the cheap `lerp(target, k*dt)` approximation) because mobile frame rates are variable. High scores persist as JSON in `system.DocumentsDirectory`.

### 5. Drift Hangar — Stride ([open](DriftHangar_Stride/))

Third-person space flight in C# on .NET 8. 6-DoF rotation is composed in the **ship's local frame** (right-multiply local quaternions onto the current orientation) so the controls compose correctly regardless of orientation — no gimbal lock. The chase camera is a **critically-damped PD spring** on position (`damping = 2 * sqrt(stiffness)`, fastest settling without oscillation), with slerp toward "look-at with the target's up" so it rolls with the ship. The asteroid field uses **Shoemake's quaternion** for uniform random orientation, seeded RNG for reproducibility, and rejection sampling for spawn placement.

## Tech notes

- Every project's README has a "How to run" section. Most engines just need an open-project + play.
- Code is statically typed where the language supports it: GDScript types, Python type hints, C# nullable refs enabled.
- No projects depend on external asset files — meshes are procedural, sprites are colored quads / polygons, fonts are system defaults. You can clone and run with no asset pipeline setup.
