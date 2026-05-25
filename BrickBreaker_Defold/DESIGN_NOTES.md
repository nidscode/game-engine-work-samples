# Design Notes — Brick Breaker (Defold)

The why behind the structure. Defold is opinionated — `msg.post` is the canonical inter-object communication, scripts can't directly call methods on other game objects' scripts, and the engine wants you to think in terms of *components on game objects* rather than OOP class hierarchies. The layout here leans into that grain instead of fighting it.

## 1. One module for message hashes

`modules/events.lua` centralizes every cross-module message name as a pre-hashed `hash("...")` value. Two wins:

- **Performance.** `hash()` returns the same value for the same string but does string interning on first call. Caching the result in a module table means `events.brick_destroyed` is a table lookup at runtime, not a re-hash.
- **Discoverability.** When a new contributor wants to know *what events flow between scripts*, the answer is one file long. No more grepping for `msg.post("...")` across the project.

The trade-off is one indirection — but in a project that adds events as it grows, the trade pays for itself by the third one.

## 2. GameController owns the canonical state

Score and lives live on `game_controller.script`. Nothing else stores them. The HUD has no idea what the score is — it gets `score_changed { score }` posted to it and displays whatever it received.

If I needed to add, say, a multiplier system or a high-score upload, the change is local to the controller — every other script keeps working unchanged.

## 3. Bricks are factory-spawned with per-instance HP

The `brick.go` defines the prototype. Spawn-time HP is set via `go.property("hp", 1)` and overridden in the factory call:

```lua
factory.create(self.brick_factory, vmath.vector3(x, y, 0), nil, { hp = spec.hp })
```

This is the Defold-correct way to do per-instance data without creating one prototype per variant. The sprite tint is then computed at `init()` time from HP, so a 3-HP brick automatically looks like a 3-HP brick without anyone setting it explicitly.

## 4. Ball state machine is two states only

`ATTACHED` (riding on the paddle) and `FREE` (moving under its own velocity). I considered an `EXPLODING` state for visual flair on death but it doesn't pay rent at this scope. The state lives on `self.state` and gets checked at the top of `update` — explicit and easy to extend.

## 5. Reflection on contact, not Box2D restitution alone

Even though Defold's Box2D-backed physics will reflect a kinematic ball off a static box for free, I'm doing the reflection manually in script (`reflect(v, n)`). Two reasons:

- **Predictable speed.** With pure physics, the ball's speed drifts as it loses or gains kinetic energy at glancing contacts. Manual reflection lets me re-normalize to a known speed magnitude after every bounce.
- **Per-surface effects.** A paddle hit needs "english" (the offset-from-center skew), a brick hit needs to post `brick_hit` and bump the global ball speed, a wall hit is a plain reflect. Branching on `message.other_group` in one place keeps the logic legible.

I also push the ball out of penetration by the contact `distance` to keep it from sticking — a classic kinematic-collision gotcha.

## 6. HUD is a `.gui_script`, not a regular `.script`

Defold separates rendered GUI from gameplay objects for good reasons. The GUI runs in its own coordinate space, has its own animation API (`gui.animate`), and isolates the HUD from the camera transform. The HUD script in this project never knows the paddle exists — it only listens to events.

## 7. Levels are ASCII tables

`modules/levels.lua`:

```lua
{
  "..1111111111..",
  "..1222222221..",
  "..1233333321..",
  "..1234444321..",
}
```

A designer can hand-paint a level in any text editor. Digits map to brick HP. Skipped cells (`.`) leave gaps. Adding a level is a one-list-entry change. For a small game this beats opening a level editor — for a big game it's the data format your in-editor tool would export to anyway.

## 8. What I'd add next

1. **Power-ups.** Drop-from-brick capsules (multi-ball, sticky paddle, lasers) — each is a new factory + a few lines on the controller.
2. **Audio.** An `AudioManager` script listening to the same events table, so hit/destroy/clear sounds attach without touching gameplay code.
3. **Particles.** Defold has a built-in particle component — wire a brick-destruction effect to `brick_destroyed`.
4. **Screen-shake.** Reusable camera shake driven by an `EventBus` event, identical pattern to the Godot sample in this repo.
5. **Pause menu.** Toggle a `.gui` overlay, post `input_focus` swaps to freeze gameplay input while the menu is up.

None of those require restructuring what's here — they all hook the existing event bus.
