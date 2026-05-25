# Design Notes — Drift Hangar (Stride)

The why behind the structure. Stride's C# component model is closer to Unity's than to any of the other engines in this work-sample set: every behavior is a `SyncScript` / `AsyncScript` / `StartupScript` attached to an `Entity`, and entities live in a scene graph. The layout below leans into that grain.

## 1. Local-frame rotation composition (no gimbal lock)

A common 6-DoF mistake is to track pitch/yaw/roll as separate scalars and rebuild the world rotation each frame from Euler angles. That gives you gimbal lock when pitch approaches ±90°, plus weird interactions on combined inputs.

`ShipController` instead applies each axis as a delta quaternion in the ship's *local* frame:

```csharp
Entity.Transform.Rotation = Entity.Transform.Rotation
                          * deltaRoll
                          * deltaPitch
                          * deltaYaw;
```

Right-multiplying the new rotation onto the current one applies it in the body frame regardless of orientation. The ship can be upside down, spinning, or pointed straight up — yaw input always rotates around the ship's own Y axis, not the world's. No Euler bookkeeping, no gimbal lock.

## 2. Critically-damped spring chase camera

The chase camera could be a constant lerp toward a fixed offset. It would work. It would look bad.

A second-order PD controller (position spring with damping) gives the camera apparent mass: it lags slightly behind the ship on hard direction changes, then settles. Set `damping = 2 * sqrt(stiffness)` and the response is **critically damped** — fastest possible settling with no oscillation. That's the math that distinguishes a "fancy camera" from a "broken bouncy camera."

```csharp
float omega   = MathF.Sqrt(PositionStiffness);
float damping = 2f * omega;
Vector3 disp  = currentPos - desiredPos;
Vector3 accel = -PositionStiffness * disp - damping * _posVelocity;
_posVelocity += accel * dt;
currentPos   += _posVelocity * dt;
```

The integration is plain semi-implicit Euler — at the stiffness/damping ratios I'm using and a 16ms timestep, the error is well below visual perception. If I were running this at 30ms timesteps I'd switch to the closed-form analytical solution for critical damping (it's a couple more lines and is exact).

## 3. FOV-on-speed

The camera nudges the projection's vertical FOV up when the ship is moving fast. It's the cheapest "feel" trick in flight games — wide FOV reads as speed to the eye because the periphery streaks past faster. Capped at +14° added to the base 60° so it never distorts unpleasantly.

## 4. Service locator over editor-wired references

The chase camera could expose a `Target` field that the editor user drags the player ship onto. That works for one-shot scenes, but it makes the camera fragile to scene reorganization — rename the ship, lose the reference.

Instead, `GameState` is registered as a service in the scene, and the camera asks for it: `Services.GetService<GameState>()?.PlayerShip`. The ship registers itself in `Start()`. Net result: drop the chase camera into any scene that has a `GameStateInstaller` + a ship, and it works. The `Target` field is still exposed for the cases where you want an explicit override.

## 5. Procedural asteroid placement

Three concerns:

1. **Don't spawn inside the player.** Reject any candidate closer than `MinSpawnDistance` from origin.
2. **Don't clip asteroids into each other.** Cheap rejection-sampling pass against already-placed positions (O(n) per candidate; fine up to ~200 with current params).
3. **Distribute orientation uniformly.** Shoemake's quaternion method samples uniformly on SO(3). The naive "random Euler angles" approach over-samples certain orientations — visible as a perceptible orientation bias when there are hundreds of objects.

Seeded RNG (`Seed: 1337` in the scene) means the layout is reproducible run-to-run, which matters during iteration — you want to know that a level looks different because *you* changed it, not because the RNG rolled differently.

## 6. Shared state via `GameState`, not statics

`GameState` is a plain POCO registered with the service registry. Player ship reference, elapsed time, distance, paused flag — all in one place. Anyone who needs them does `Services.GetService<GameState>()` once in `Start()` and caches the reference.

I could have used `public static` fields. I didn't because:

- Statics survive scene reloads with stale data.
- They prevent the same script from running in two scenes simultaneously (e.g., for split-screen).
- They make the data flow invisible — you can't grep for who reads/writes a field of `GameState` if it's hidden behind a static class.

Services scoped to a scene avoid all three.

## 7. `[DataMember]` on every tunable

Every magic number on every script is exposed via `[DataMember]` so designers can iterate in the inspector without recompiling. Defaults are sane — the scene's YAML overrides only the ones that differ from default — but everything is tweakable. The Stride editor renders `[DataMember]` properties automatically with the right widget per type (sliders for floats with ranges, dropdowns for enums, etc.).

## 8. What I'd add next

1. **Particles & trails.** Stride has a built-in particle component; thruster trails on the ship and dust on near-misses would be the highest-impact polish add.
2. **PBR materials.** The current scene leaves materials null. Stride's PBR pipeline is solid — a metallic asteroid material + an emissive ship engine would land immediately.
3. **Audio.** Spatialized engine hum + a stereo "near miss" whoosh hooked to a proximity check in the field manager.
4. **Procedural mesh asteroids.** Right now all asteroids share one mesh with random scale. Generating per-instance deformed icospheres at startup is a Stride-friendly C# task (vertex buffer + index buffer + commit).
5. **Collision.** Add rigidbodies to the asteroids and a collider to the ship; hook `OnCollisionEnter` for impact feedback. Stride's Bullet integration handles this cleanly.

None of those require changing the existing scripts — they all bolt on as new components on the same entities.
