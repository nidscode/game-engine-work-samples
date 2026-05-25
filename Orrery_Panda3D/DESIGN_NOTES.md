# Design Notes — Orrery

The why behind the how. This sample is intentionally small — the goal is to show how I structure a Panda 3D project, pick the right primitives, and avoid the common foot-guns rather than to ship a planetarium.

## 1. Scene-graph orbital mechanics

Every planet has a `pivot` `NodePath` parented to the scene root and a `body` `NodePath` parented to the pivot at local position `(orbit_radius, 0, 0)`. To advance an orbit, I only rotate the pivot. The planet's world position falls out of the transform cascade automatically — no per-frame `sin`/`cos` and no chance of drift over time.

This trick scales naturally: a moon's `pivot` is parented to the planet's `body`. When the planet's pivot rotates, the moon is carried along; when the moon's own pivot rotates, the moon orbits the planet. Two scalar updates per frame per body, no shared state, and the math is correct by construction. It's the same pattern an articulated-skeleton bone hierarchy uses, just applied to celestial bodies.

## 2. Icosphere, not UV sphere

Panda's built-in sphere primitive (and most engines' default) is a **UV sphere** — a stack of latitude rings. Vertices pile up at the poles and stretch out at the equator, and any non-uniform shading (specular, normal map) shows the seam.

An **icosphere** starts from a 20-face icosahedron and subdivides each triangle into four. Vertices stay roughly equidistant across the whole surface, so flat shading reads as the actual surface curvature rather than as latitude artifacts. The cost is a tiny bit more code to maintain a midpoint cache (so adjacent faces share the midpoint vertex they create), which I wrote in `procedural._midpoint`.

For this scale: subdivisions=2 gives 320 triangles per planet (plenty), subdivisions=3 gives 1280 for the sun (a touch more, looks smoother for the close-up).

## 3. The star field, parented to the camera

A common mistake with backdrop star fields: parent them to the scene root and they slide off-screen as the camera moves. Parenting to the camera (with depth-write off and assigned to the `"background"` bin) means they always render behind everything and never appear to move relative to the camera's translation — which is the correct illusion since real stars are effectively at infinity.

The points are placed using the **Marsaglia method** for uniform points on a sphere: sample `(u, v)` in the unit disk, then map to `(x, y, z)` on the unit sphere. This avoids the equator-bunching you get from naive `(rand_theta, rand_phi)`.

## 4. Procedural geometry uses `GeomVertexFormat.get_v3n3c4`

Vertex format: 3D position + 3D normal + 4D RGBA color. No UVs because there are no textures. Setting per-vertex colors lets me skip writing a custom material per planet — `set_light_off()` on the sun plus the per-vertex color gives the emissive look I want.

For the ring I used the same format with constant normals (`+Z`) and an alpha tint, then enabled transparency and two-sided rendering so it reads correctly when the camera's below the ring plane.

## 5. Orbit camera: pivot + offset, not free-look

The camera is parented to a pivot at the look target. Yaw rotates the pivot; pitch rotates the camera around the pivot's local X. The actual `panda3d.core` camera node lives at local `(0, -distance, 0)` from the pivot.

This is the standard inspector / orbit camera setup and is way simpler than maintaining yaw/pitch on the camera directly — the scene graph handles the composition for you. Pitch is clamped to ±85° so you can't flip upside down (free-look would need a different approach using quaternions; for an orbit camera the clamp is the right answer).

Target-follow uses a per-frame lerp toward the target's world position. The lerp weight is intentionally frame-rate dependent for this kind of inspector camera (it makes the camera *feel* responsive at high frame rates), but I noted in the file that a gameplay camera should use the `1 - exp(-k * dt)` form for true frame-rate independence.

## 6. Lighting: one PointLight on the sun

The sun's `PointLight` is parented to the sun's mesh node, so moving the sun moves the light. Ambient is kept very low so the dark side of planets actually goes dark — the contrast sells the depth far more than per-vertex color ever could on its own.

The sun itself has `set_light_off(1)` so the same `PointLight` doesn't shade it (which would look wrong — the sun is the *source*, not a lit object).

## 7. Why a `PlanetSpec` dataclass

The system definition lives in one function (`default_system`) that returns a list of `PlanetSpec` dataclasses. Anyone tweaking the system — sizes, colors, periods, ring/moons — only touches that one list, and the rest of the code consumes the spec generically. This is the procedural-content-friendly version of "data-driven design" without dragging in a JSON loader for a sample at this scope.

## 8. What I'd add next

Honest list of what's *not* in here that a real tool would have:

1. **Custom shaders.** The current setup uses fixed-function-style per-vertex coloring + ambient + point light. A real planet would want a fragment shader for atmosphere rim-lighting, normal maps, and a proper Fresnel falloff. Panda supports GLSL shaders directly; the hook would go on the planet's `body` NodePath.
2. **Mouse picking.** Click-to-focus would use `CollisionRay` + `CollisionTraverser` against per-planet collision spheres. The HUD focus-jump shortcuts work today, but mouse picking is the next ergonomic win.
3. **Time-of-year display.** With orbital periods defined, an in-HUD elapsed-time readout is a free add.
4. **Procedural variation.** The system definition is hand-tuned. A seeded generator producing a randomized but plausible system would be a nice toggle.
5. **Atmosphere shells.** A semi-transparent slightly-larger sphere per planet, fragment-shaded for haze, would give the planets visible atmospheres.

None of those would require touching the scene-graph or camera scaffolding.
