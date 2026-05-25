# Pulse Arena

A neon twin-stick arena shooter built in **Godot 4.2** (GDScript). Compact in scope, but deliberately structured the way a shippable production project would be: autoloaded singletons, an event bus, base/derived enemy classes, pooled projectiles, and trauma-based camera shake.

This project is a **work sample** — its purpose is to show how I structure a small-to-mid Godot codebase, not to be a complete commercial game.

---

## How to run

1. Install Godot **4.2** or newer (standard build, not .NET).
2. Open the Godot project manager, click **Import**, and point it at the `project.godot` file in this folder.
3. Press **F5** (or the play button) to run. The main scene is preconfigured.

### Controls

| Action | Input |
|---|---|
| Move | `W` `A` `S` `D` |
| Aim  | Mouse |
| Fire | Left mouse button (hold) |
| Restart after death | Any key |

---

## What's in it

- **Twin-stick player controller** with smoothed acceleration, mouse aim, and a fire cooldown.
- **Two enemy types** sharing a common base class:
  - *Chaser* — seeks the player with a turning-rate cap so swarms don't snap-rotate.
  - *Shooter* — kites at a preferred range using hysteretic state transitions, fires aimed bullets.
- **Wave spawner** — perimeter spawning, gradually increasing wave size, shooters phased in from wave 3.
- **Event bus + GameManager** — gameplay events route through a global signal hub; the manager owns canonical run state.
- **HUD** — score / wave / lives readout plus a fade-in/out wave banner.
- **Trauma-based camera shake** with optional hitstop for big impacts.
- **ObjectPool** utility (included as a pattern reference; bullets in the sample use direct instancing for code clarity).
- **Game-over flow** with one-key restart.

---

## Project layout

```
PulseArena_Godot/
├── project.godot              # Input map, autoloads, layer names, display config
├── icon.svg
├── scenes/
│   ├── main.tscn              # Camera, player, spawner, HUD, game-over overlay
│   ├── player.tscn
│   ├── enemies/
│   │   ├── chaser.tscn
│   │   └── shooter.tscn
│   ├── projectiles/
│   │   └── bullet.tscn
│   └── ui/
│       └── hud.tscn
├── scripts/
│   ├── autoload/
│   │   ├── event_bus.gd       # Global signal hub
│   │   └── game_manager.gd    # Canonical run state (score, wave, lives)
│   ├── player/
│   │   └── player.gd
│   ├── enemies/
│   │   ├── enemy_base.gd
│   │   ├── chaser.gd
│   │   └── shooter.gd
│   ├── projectiles/
│   │   └── bullet.gd
│   ├── systems/
│   │   ├── main.gd
│   │   ├── wave_spawner.gd
│   │   ├── camera_shake.gd
│   │   └── object_pool.gd
│   └── ui/
│       └── hud.gd
├── README.md                  # ← you are here
└── DESIGN_NOTES.md            # Deeper writeup of architectural choices
```

See **DESIGN_NOTES.md** for the why behind the structure — event-bus rationale, enemy AI tradeoffs, the trauma-shake math, etc.

---

## Tech

- **Engine:** Godot 4.2 (Forward+ renderer, not strictly required at this scope)
- **Language:** GDScript with static typing throughout
- **Dependencies:** None — pure engine

## Author

Agneya Kolhatkar — built as a portfolio piece for game-engine asset work.
