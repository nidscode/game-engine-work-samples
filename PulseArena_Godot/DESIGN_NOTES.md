# Design Notes — Pulse Arena

This document captures the reasoning behind the architectural choices in the sample. The intent is to show how I think about small-codebase tradeoffs, not to justify everything line by line.

## 1. Why an event bus

Even at this scope, three independent systems care when an enemy dies: the `GameManager` (to award points), the `HUD` (to refresh the score), and the `CameraShake` (to add trauma). Wiring those up with direct references would mean the enemy script has to know about all three, and any new listener would mean touching the enemy code again.

The `EventBus` autoload solves this with one indirection. The enemy fires `EventBus.enemy_killed.emit(points, position)` and walks away. Each system connects to that signal in its own `_ready()`. Adding a fourth listener (say, a combo meter) is a one-line change in the new system; the enemy file never moves.

The tradeoff is that the signal contract becomes a shared API surface. I keep the bus deliberately small and document each signal's payload at the top of the file so the contract stays legible.

## 2. Enemy base class, not a component system

For two enemy types, a full ECS or component-composition system would be over-engineering. Inheritance from `EnemyBase` gives me shared damage/death/reward in one place with a single `_ai_tick()` override per subclass. Total cost: ~30 lines of base class.

If the project grew to a dozen enemies with crosscutting concerns (status effects, modifiers, multi-phase attacks), I'd shift to composition. The point of this sample is to pick the right tool for the actual scope.

## 3. Shooter state machine: hysteresis

The shooter's "kite vs. attack" decision is a classic spot to get jitter. If you flip states purely on distance, an enemy hovering right at the threshold flips every frame, which looks twitchy and ruins fire cooldowns.

Hysteresis fixes it: you enter `ATTACK` when `|dist − preferred| ≤ band`, but you only leave it when `|dist − preferred| > band × 1.5`. The enter and exit conditions don't share a boundary, so the state has to commit before it can flip back. The visible result is a shooter that holds position cleanly.

## 4. Trauma-based shake

Camera shake is one of those things that looks cheap when it's done as a raw sine offset and great when it's trauma-driven. Pattern (credit: Squirrel Eiserloh's GDC talk):

- Trauma is a 0..1 scalar that decays linearly each frame.
- Shake magnitude is `trauma²`, so small hits are barely perceptible and big ones really land.
- Per-frame offset is `max_offset * shake_amount * random[-1, 1]`. Random per-axis, every frame.
- Multiple events stack into the same trauma value rather than fighting each other.

The result composes naturally with normal camera-follow logic because the shake is layered on top of `offset`, not the camera's actual position.

## 5. Frame-rate-independent smoothing

Player movement uses `velocity = velocity.lerp(target, clamp(weight * delta, 0, 1))`. This is the cheap-and-cheerful version of frame-rate-independent exponential smoothing. The mathematically clean form is `1 - exp(-weight * delta)`, but for the values we're using the `clamp(... * delta)` approximation is visually indistinguishable and a touch faster.

The reason it matters: I want a designer to be able to tune `accel_lerp_weight` in the inspector and have the feel be the same whether the game runs at 60 or 144 FPS.

## 6. Bullets: instanced, not pooled — but the pool's there

I included `ObjectPool` to show the pattern, but bullets in this sample are direct-instanced via `bullet_scene.instantiate()`. At this scope (a few dozen bullets at peak) allocation cost is invisible, and the direct-instance code is easier for a reviewer to follow. If wave counts climbed past where GC churn started showing in profiler frames, switching the bullet to acquire/release through the pool is a one-method swap on the player and shooter — the bullet itself already has a `launch()` reset method, which is the pattern the pool expects.

## 7. Layers and masks

Collision is set up so each interaction has exactly one path:

- Layer 1: World
- Layer 2: Player (mask: World)
- Layer 3: Player bullets (mask: Enemies)
- Layer 4: Enemies (mask: World)
- Layer 5: Enemy bullets (mask: Player)

Friendly-fire is impossible by construction — the bullet's mask is set at launch time, so a player bullet literally cannot register a hit against another player bullet, and likewise for enemies.

## 8. What I'd add next

If this sample expanded to a vertical slice, the next things in line:

1. **Audio:** an `AudioManager` autoload reacting to the same `EventBus` signals — fire, hit, death, wave-cleared — so audio attaches without touching gameplay code.
2. **Pickups:** health and weapon drops with weighted spawn on enemy death.
3. **Particles:** GPU particles for muzzle flash and enemy death bursts; the events already exist on the bus to trigger them.
4. **Tutorial / first-run polish:** a one-line "WASD to move, click to fire" prompt that fades out on first input.
5. **Settings menu:** persistent input remap and volume sliders.

None of those would require restructuring what's here.
