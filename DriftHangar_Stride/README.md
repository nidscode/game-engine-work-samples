# Drift Hangar

A small 3D space-flight demo built in **Stride (Xenko)** with **C# / .NET 8**. Fly a ship around a procedurally placed asteroid field with a critically-damped chase camera. Built as a Stride 4.2 project; everything is wired through standard Stride component scripts.

This is a **work sample**. The point is to show how I structure a C#/Stride project, write idiomatic component scripts, and approach the math/feel pieces (chase camera, frame-rate-independent integration, procedural placement) — not to ship a complete game.

---

## How to run

1. Install **Stride 4.2+** ([https://stride3d.net/](https://stride3d.net/)) and the .NET 8 SDK.
2. In the Stride Launcher, click **Start** to open the editor.
3. **File → Open** → select `DriftHangar.sdpkg`.
4. Compile assets and press **Play**.

> **Note on assets:** the `.sdscene` and `.sdprefab` files in this sample reference `null` Model assets — the project doesn't ship with the ship mesh or asteroid rock. To see anything visible:
> - Drag any model asset (Stride ships several primitives + a sample ship) onto the `Model` field of the PlayerShip's `ModelComponent`.
> - Do the same for the Asteroid prefab.
> - The Lua-er — sorry, the C# — gameplay logic does not depend on which model you assign.

### Controls

| Action | Input |
|---|---|
| Thrust forward / back | `W` / `S` |
| Yaw left / right | `A` / `D` |
| Roll left / right | `Q` / `E` |
| Pitch / look | Hold right mouse + move |
| Pause | `Esc` |

---

## What's in it

- **6-DoF-ish ship controller.** Thrust along the ship's local forward; yaw/pitch/roll built up in the local frame so the controls compose correctly regardless of orientation (no gimbal lock). Exponentially-smoothed angular input, exponential linear drag so the ship coasts to a stop instead of skidding forever.
- **Critically-damped spring chase camera.** Position uses a second-order PD controller (overshoots slightly on sharp turns to sell mass; settles in finite time with no oscillation). Orientation slerps toward a "look-at-target with target's up" quaternion so the camera rolls with the ship. FOV widens with speed for a subtle "going fast" cue.
- **Procedural asteroid field.** Seeded RNG places `N` prefab instances in a spherical volume with a minimum spawn distance from the origin (so the player doesn't appear inside an asteroid) and a soft minimum separation between asteroids (cheap rejection sampling). Each gets a uniformly-random orientation via Shoemake's quaternion and a random uniform scale.
- **HUD.** Text controls for speed and distance, hooked from the editor by name.
- **Pause flow.** Esc toggles a shared `GameState.Paused` flag; other scripts cooperate by short-circuiting `Update`.
- **`GameState` service.** Registered once in the scene by `GameStateInstaller`, looked up by anyone who needs it via `Services.GetService<GameState>()`. No editor wiring of cross-script references required.

---

## Project layout

```
DriftHangar_Stride/
├── DriftHangar.sln                   # Visual Studio solution
├── DriftHangar.sdpkg                 # Stride package manifest
├── DriftHangar.Game/
│   ├── DriftHangar.Game.csproj       # .NET 8 project, references Stride.Engine etc.
│   ├── GlobalUsings.cs               # Project-wide using directives
│   └── Scripts/
│       ├── GameServices.cs           # Shared GameState + installer script
│       ├── ShipController.cs         # 6-DoF input + thrust + drag
│       ├── ChaseCamera.cs            # PD-spring follow camera with FOV kick
│       ├── AsteroidField.cs          # Seeded procedural prefab placement
│       ├── GameHud.cs                # Text bindings for speed / distance
│       └── PauseMenu.cs              # Esc toggles GameState.Paused
└── Assets/
    ├── Scenes/
    │   └── MainScene.sdscene         # Bootstrap, PlayerShip, Camera, Field, HUD, Pause
    └── Prefabs/
        └── Asteroid.sdprefab         # Single-entity prefab the field instantiates
```

See **DESIGN_NOTES.md** for the architecture writeup — why a PD spring instead of a lerp, why Shoemake's quaternion, the service-locator vs. editor-wiring tradeoff, etc.

---

## Tech

- **Engine:** Stride 4.2+
- **Language:** C# 12, .NET 8 (`<TargetFramework>net8.0</TargetFramework>`, nullable refs enabled)
- **Dependencies:** Stride.Engine + Stride.UI + Stride.Physics + Stride.Video (all standard meta-packages)

## Author

Agneya Kolhatkar — built as a portfolio piece for game-engine asset work.
