# Brick Breaker

A classic Breakout / Arkanoid mini-game built in **Defold** (Lua). Small in scope, but written the way a real shippable Defold project should be structured: idiomatic message-passing, a factory-spawned brick grid, a controller game object that owns canonical run state, and a HUD that's a pure listener.

This is a **work sample**. The goal is to show how I structure a Defold codebase, not to be a complete commercial game.

---

## How to run

1. Install **Defold** ([https://defold.com/](https://defold.com/)). Tested against editor 1.7+.
2. Open the editor → **File → Open From Disk…** → select `game.project` in this folder.
3. Press **Project → Build** (or Cmd/Ctrl+B). The play window will open.

### Controls

| Action | Input |
|---|---|
| Move paddle | `A` / `D` or `←` / `→` |
| Launch ball | `Space` or left-click |
| Restart    | `R` |
| Quit       | `Esc` |

---

## What's in it

- **Player paddle** with frame-rate-independent exponential smoothing on its velocity.
- **Ball** with two-state lifecycle (`ATTACHED` → `FREE`), reflection-based bouncing off Defold's `contact_point_response`, paddle "english" (where you hit the paddle biases the angle), and a per-hit speed step that ramps difficulty over a long rally.
- **Bricks** spawned by a `factory`. HP is set per-brick at spawn via `go.property` overrides; each hit re-tints the sprite to reflect remaining HP and does a small squash-tween for feel.
- **Walls** as three static collision objects framing the play field.
- **GameController** as the single owner of score, lives, and level state. Reacts to `brick_destroyed` and `ball_lost` events, handles level transitions and game-over flow.
- **HUD** as a `.gui` overlay with a Lua `gui_script` that's a pure listener — it never touches gameplay objects directly.
- **Shared `events.lua` module** with pre-hashed message names — one place that defines the inter-system messaging contract.
- **Data-driven levels.** `modules/levels.lua` stores layouts as ASCII strings; designers add a new level by editing one table.

---

## Project layout

```
BrickBreaker_Defold/
├── game.project                  # Engine config (display, physics, bootstrap)
├── input/
│   └── game.input_binding        # Key + mouse action map
├── main/
│   ├── main.collection           # Scene: paddle, ball, walls, controller, HUD
│   ├── paddle.go / paddle.script
│   ├── ball.go   / ball.script
│   ├── brick.go  / brick.script
│   ├── walls.go
│   ├── game_controller.go / game_controller.script
│   ├── hud.gui   / hud.gui_script
│   └── (built-in materials referenced from /builtins)
├── modules/
│   ├── events.lua                # Shared message-hash table
│   └── levels.lua                # ASCII level layouts + helpers
├── README.md                     # ← you are here
└── DESIGN_NOTES.md               # Architecture writeup
```

> **Note on sprite atlases:** the `.go` files reference animations named `paddle`, `ball`, and `brick` from the default atlas. The provided files use placeholder names — you can either drop in a 16×16 ball, 112×16 paddle, and 52×18 brick sprite into a new atlas and point the `.go` `default_animation` fields at them, or rely on Defold's built-in colored quad debug renderer for first-run. The Lua gameplay code does not care which.

---

## Tech

- **Engine:** Defold 1.7+
- **Language:** Lua 5.1 (Defold's bundled runtime)
- **Dependencies:** None outside the engine

## Author

Agneya Kolhatkar — built as a portfolio piece for game-engine asset work.
