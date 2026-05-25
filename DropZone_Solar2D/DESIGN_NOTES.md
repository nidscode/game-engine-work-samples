# Design Notes — Drop Zone (Solar2D)

The why behind the structure. Solar2D is a different beast from Defold even though both are Lua — there's no message bus, no `.go` scenes, no protobuf project files. Instead you build display objects imperatively, structure scenes with `composer`, and connect listeners to events. The layout here is shaped by Solar2D's grain.

## 1. Composer for scenes, not a homegrown state machine

`composer` is Solar2D's bundled scene manager. It gives you a lifecycle (`create` → `show` → `hide` → `destroy`) and crossfade transitions for free. I considered a custom state machine but couldn't justify it — composer already does the bookkeeping correctly, and `composer.recycleOnSceneChange = true` in `main.lua` ensures display objects from a scene get freed when you navigate away.

The scene-transition contract is: scenes receive params from the previous scene via `event.params`. `game.lua` uses this to pass the final score to `gameover.lua`. This keeps scenes loosely coupled — `gameover.lua` doesn't know what scene preceded it, only that it got a `params.score`.

## 2. The object pool

This is the single most important thing in a 60-fps mobile game with churn. Without a pool, every spawned obstacle is a fresh `display.newRect` call (allocates a Lua table + a native rendering primitive), and every off-screen obstacle is a `removeSelf` call. At ~3 obstacles/second peak, that's ~6 allocs/frees per second — small in isolation, but in a frame budget of 16ms on a mid-range Android device, it's the kind of thing that causes intermittent stutter when the GC fires.

`modules/pool.lua` keeps an internal `display.newGroup` (the "stash") to hold inactive objects. The stash has `isVisible = false`, so its contents don't render. `acquire()` pops one and returns it; `release()` puts it back. Net allocations during gameplay: zero (after the initial pool warm-up).

Designed so the pool is *generic* over a factory function rather than baking in obstacle knowledge — same pool would serve bullets, particles, or pickups if the project grew.

## 3. Obstacles are free functions over a display object, not OO wrappers

`classes/obstacle.lua` exposes `factory`, `spawn`, `update`, `bounds` as plain module functions that operate on a `display.newRect`. There's no `Obstacle.new(...)` table-with-display-child wrapper. Two wins:

- The pool can store the display object directly without an extra Lua table per instance.
- The functions read like an API for an existing engine object, which is exactly what they are.

I went the more conventional OO route on `Player` because a player carries more state (target_x, alive flag) and there's only one — wrapping it as a single instance is cleaner. The right answer for each entity depends on cardinality.

## 4. Frame-rate-independent smoothing on player movement

```lua
local k = 1 - math.exp(-SMOOTH_K * dt)
self.body.x = self.body.x + (target_x - self.body.x) * k
```

The `1 - exp(-k*dt)` form is mathematically correct exponential smoothing — the response curve is identical whether the game runs at 30 fps or 120 fps. It's worth more than the simpler `lerp(target, k * dt)` because mobile frame rates are *variable*. iOS will happily drop you from 60 to 30 fps under thermal load, and the response curve has to feel the same when it happens.

## 5. Drag-anywhere touch, not zone tapping

I considered split-screen "tap left half / right half" controls. Drag-anywhere is better here because:

- It's lower precision per tap but higher resolution overall — you can micro-correct mid-dodge.
- It works equally well for thumb-on-screen and finger-glued-to-glass play styles.
- It avoids the "where exactly is the left/right boundary" learning curve that zone controls have.

The cost is that you can't see where you're aiming when your finger covers it — fine here because the craft is above the touch point at rest, but worth noting.

## 6. High-score persistence: JSON, not key-value

Solar2D doesn't have `NSUserDefaults` / `SharedPreferences` wrappers built in. The community-standard choice is `system.pathForFile` into `DocumentsDirectory` + `io.open`. I picked JSON over plain text because:

- It's trivial to extend — settings, unlocks, multiple game modes, all in the same file.
- It survives schema changes (extra keys are ignored on load).
- `json` ships in Solar2D's core.

`highscore.load()` returns a default table on any read error, so callers never have to nil-check. `submit(score)` is the only write path and returns the new best plus an `is_new` flag so the UI can flair on a record.

## 7. Content scaling: 720×1280 + letterbox

Solar2D's "content area" is a logical coordinate space; the engine rescales it to fit the device. `720×1280` (9:16 portrait) is a clean target — it divides evenly by typical asset DPI tiers, and `letterbox` mode means a wider device gets margins rather than warping (which would skew the player's hitbox).

`imageSuffix` is configured for `@2x` (1.5×) and `@4x` (3.0×) — drop `image@2x.png` and `image@4x.png` next to `image.png` and Solar2D picks the right one per device.

## 8. What I'd add next

1. **Sound.** Solar2D has `audio.loadSound` for short effects and `audio.loadStream` for music. The events to hook (dodge, hit, game-over) already exist as clear points in the code.
2. **Particles.** On-hit explosion + faint thruster trail. The pool pattern reapplies directly.
3. **Power-ups.** Shields, slow-time, score multipliers. New obstacle subtype + a UI badge.
4. **Vibration on death.** `system.vibrate()` is one line and adds a lot of feel on phones.
5. **Pause menu.** Toggle an overlay scene, freeze the `enterFrame` listener while it's up.
6. **GDPR-friendly analytics.** A real shipping game wants funnel data; the hook would be a single `analytics:track(event, props)` call wired at the same points as the audio hooks.

None of those require restructuring what's here.
