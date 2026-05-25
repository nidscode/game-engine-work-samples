# Drop Zone

A mobile-first vertical dodge game built in **Solar2D** (Lua). Drag anywhere on the screen to steer your craft; debris falls from the top, speeding up as you survive longer. High score is saved across runs.

This is a **work sample** — built to show how I structure a small Solar2D project the way a shippable mobile game should be: composer-driven scenes, object pooling so the GC doesn't hiccup mid-run, sandbox-safe high-score persistence, and per-class modules with clear lifetimes.

---

## How to run

1. Install **Solar2D** ([https://solar2d.com/](https://solar2d.com/)). The Simulator is free and ships for macOS / Windows / Linux.
2. Launch Solar2D Simulator → **File → Open Project…** → pick the `main.lua` in this folder.
3. The simulator window opens at the configured portrait resolution (720×1280). Drag your mouse on the simulator window to play.

To build for device (iOS / Android): **File → Build → iOS / Android** in the simulator. `build.settings` already declares orientation, supported SDK, and asset exclusions.

### Controls

| Action | Input |
|---|---|
| Move craft | Touch / drag anywhere on screen — craft follows your finger's X |
| Start / retry | Tap the on-screen buttons |

---

## What's in it

- **Three composer scenes**: `menu` → `game` → `gameover`, transitioning with crossfades. Each scene cleans itself up on `hide` / `destroy`, so navigation never leaks display objects.
- **Player craft** as a custom `Polygon` (no asset files required), with frame-rate-independent exponential smoothing on its movement and a small bank-into-motion lean.
- **Object-pooled obstacles** — a generic `pool.lua` module hands out reusable `display.newRect` instances. At 60 fps on mobile, the obstacle stream would otherwise churn the GC; the pool eliminates that.
- **Parallax starfield** with two layers moving at different speeds. The stars are pre-allocated; on wrap, they're snapped to the top edge instead of being re-created.
- **Difficulty curve** — obstacle speed and spawn rate both ramp with elapsed time, capped at sane upper bounds.
- **Persistent high score** — saved as JSON in `system.DocumentsDirectory` (the only writable location on iOS/Android). Includes graceful handling of corrupt or missing files.
- **HUD** — live score readout in-game; "NEW BEST!" pulse on the game-over screen if you beat your record.
- **Portrait-only build settings** with iOS / Android sections wired up.

---

## Project layout

```
DropZone_Solar2D/
├── config.lua              # Content scaling (720x1280, letterbox, 60fps)
├── build.settings          # Orientation, iOS plist, Android permissions
├── main.lua                # Bootstrap → composer.gotoScene("scenes.menu")
├── scenes/
│   ├── menu.lua            # Title + best score + Play
│   ├── game.lua            # Gameplay (spawn / tick / collide)
│   └── gameover.lua        # Score + Retry / Menu
├── classes/
│   ├── player.lua          # Player craft (Polygon, target-x smoothing)
│   ├── obstacle.lua        # Pool-friendly factory / spawn / update
│   └── parallax.lua        # Two-layer scrolling starfield
├── modules/
│   ├── pool.lua            # Generic display-object pool
│   └── highscore.lua       # JSON-on-disk best-score persistence
├── README.md               # ← you are here
└── DESIGN_NOTES.md         # Why the structure looks like this
```

See **DESIGN_NOTES.md** for the reasoning — composer choice, pool design, content-scaling rationale, mobile-specific tradeoffs.

---

## Tech

- **Engine:** Solar2D (any recent 2023+ release)
- **Language:** Lua 5.1 (Solar2D's bundled runtime)
- **Dependencies:** None outside the engine. `json` and `composer` ship with Solar2D.

## Author

Agneya Kolhatkar — built as a portfolio piece for game-engine asset work.
