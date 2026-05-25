"""
celestial.py — Sun, Planet, Moon classes.

The pattern: every orbiting body has a parent "pivot" NodePath that we
rotate around the origin. The body itself hangs off the pivot at a fixed
local position equal to its orbital radius. To advance the orbit we just
rotate the pivot — no per-frame trigonometry on individual bodies, and
moons inherit their planet's transform for free.

This is exactly the scene-graph approach you'd use in any 3D engine; in
Panda it's especially natural because NodePath transforms cascade.
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass, field
from typing import Optional

from panda3d.core import NodePath, LVector3f, PointLight, Vec4

import procedural


# ---------------------------------------------------------------------------
# Tunables / data
# ---------------------------------------------------------------------------

@dataclass
class PlanetSpec:
    """Designer-facing description of a planet. Easy to tweak in one place."""
    name: str
    orbit_radius: float
    body_radius: float
    color: tuple              # RGBA 0..1
    orbital_period: float     # seconds for a full orbit at time_scale = 1
    spin_period: float        # seconds for a full self-rotation
    has_ring: bool = False
    moons: list[float] = field(default_factory=list)   # list of moon orbit radii (rel to planet)


def default_system() -> list[PlanetSpec]:
    """A small, hand-tuned set of planets. Not a literal solar system —
    distances and sizes are picked to read clearly on screen."""
    return [
        PlanetSpec("Ferro",   8.0,  0.45, (0.85, 0.55, 0.40, 1), orbital_period=6.0,  spin_period=3.0),
        PlanetSpec("Vesta",  11.5,  0.70, (0.95, 0.78, 0.55, 1), orbital_period=10.0, spin_period=4.5),
        PlanetSpec("Cerul",  15.0,  0.80, (0.35, 0.55, 0.95, 1), orbital_period=15.0, spin_period=2.0,
                   moons=[1.4]),
        PlanetSpec("Rusk",   19.5,  0.65, (0.80, 0.35, 0.30, 1), orbital_period=22.0, spin_period=2.4,
                   moons=[1.2, 1.9]),
        PlanetSpec("Halcyon", 25.0, 1.40, (0.85, 0.70, 0.45, 1), orbital_period=38.0, spin_period=1.0,
                   has_ring=True),
        PlanetSpec("Thule",  31.0,  1.10, (0.45, 0.80, 0.85, 1), orbital_period=55.0, spin_period=1.6),
    ]


# ---------------------------------------------------------------------------
# Bodies
# ---------------------------------------------------------------------------

class Sun:
    """The system's light source. Emissive-colored sphere + a PointLight."""

    def __init__(self, parent: NodePath, radius: float = 2.0):
        self.node = procedural.build_icosphere(
            radius=radius, subdivisions=3,
            color=(1.0, 0.85, 0.5, 1.0), name="sun",
        )
        # Emissive look without a custom shader: turn lighting off for the
        # sun itself and ramp its vertex color via an additive material trick.
        self.node.set_light_off(1)
        self.node.reparent_to(parent)

        self.light = PointLight("sun_light")
        self.light.set_color(Vec4(1.0, 0.95, 0.85, 1.0))
        self.light.attenuation = (1, 0, 0.0008)  # gentle distance falloff
        self.light_np = self.node.attach_new_node(self.light)


class Moon:
    def __init__(self, parent: NodePath, orbit_radius: float,
                 body_radius: float = 0.18, rng: Optional[random.Random] = None):
        self.orbit_radius = orbit_radius
        rng = rng or random.Random()
        self.angular_speed = rng.uniform(0.6, 1.4)   # radians / sec at time_scale=1
        self.angle = rng.uniform(0, math.tau)

        self.pivot = parent.attach_new_node("moon_pivot")
        self.body = procedural.build_icosphere(
            radius=body_radius, subdivisions=1,
            color=(0.8, 0.8, 0.85, 1), name="moon",
        )
        self.body.reparent_to(self.pivot)
        self.body.set_pos(orbit_radius, 0, 0)

    def update(self, dt: float, time_scale: float) -> None:
        self.angle += self.angular_speed * dt * time_scale
        self.pivot.set_h(math.degrees(self.angle))


class Planet:
    """A planet, its orbit pivot, optional ring, and child moons."""

    def __init__(self, parent: NodePath, spec: PlanetSpec,
                 rng: Optional[random.Random] = None):
        self.spec = spec
        rng = rng or random.Random()

        # The pivot lives at the origin; rotating it carries the planet
        # around its orbit. The planet sits at `orbit_radius` along local X.
        self.pivot = parent.attach_new_node(f"{spec.name}_pivot")
        self.angle = rng.uniform(0, math.tau)          # start at a random phase
        self.spin_angle = rng.uniform(0, math.tau)

        self.body = procedural.build_icosphere(
            radius=spec.body_radius, subdivisions=2,
            color=spec.color, name=spec.name,
        )
        self.body.reparent_to(self.pivot)
        self.body.set_pos(spec.orbit_radius, 0, 0)

        # A faint guide ring along the orbital path — easy to toggle later.
        self.orbit_line = procedural.build_orbit_line(spec.orbit_radius)
        self.orbit_line.reparent_to(parent)
        self.orbit_line.set_light_off(1)
        self.orbit_line.set_transparency(True)
        self.orbit_line.set_two_sided(True)

        # Optional ring system, tilted so it reads in 3D.
        if spec.has_ring:
            ring = procedural.build_ring(
                spec.body_radius * 1.7, spec.body_radius * 2.7,
                color=(*spec.color[:3], 0.5),
            )
            ring.reparent_to(self.body)
            ring.set_p(75)   # tilt the ring off the equator
            ring.set_transparency(True)
            ring.set_two_sided(True)

        self.moons: list[Moon] = []
        for moon_r in spec.moons:
            self.moons.append(Moon(self.body, moon_r, rng=rng))

    # ----- per-frame -----

    def update(self, dt: float, time_scale: float) -> None:
        # Orbit: angular velocity from period.
        if self.spec.orbital_period > 0:
            self.angle += (math.tau / self.spec.orbital_period) * dt * time_scale
            self.pivot.set_h(math.degrees(self.angle))

        # Self-rotation, applied to the body itself so the ring spins with it.
        if self.spec.spin_period > 0:
            self.spin_angle += (math.tau / self.spec.spin_period) * dt * time_scale
            self.body.set_h(math.degrees(self.spin_angle))

        for m in self.moons:
            m.update(dt, time_scale)

    # ----- helpers -----

    def world_position(self) -> LVector3f:
        return self.body.get_pos(self.body.get_top())
