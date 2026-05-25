"""
app.py — OrreryApp, the ShowBase subclass that ties everything together.

Responsibilities:
    * Build the scene graph (sun, planets, star field background)
    * Set up lighting (ambient + sun's point light)
    * Install the orbit camera
    * Drive the per-frame simulation tick
    * Handle keyboard input for time control and focus
"""

from __future__ import annotations

from direct.showbase.ShowBase import ShowBase
from panda3d.core import (
    AmbientLight,
    NodePath,
    Vec4,
    ClockObject,
    WindowProperties,
    loadPrcFileData,
)

import procedural
from celestial import Sun, Planet, default_system
from camera_rig import OrbitCamera
from hud import HUD


# Panda config done before ShowBase starts. Done via PRC string so the project
# stays single-file-runnable; in a larger codebase this would live in config.prc.
loadPrcFileData("", """
window-title Orrery — Procedural Solar System
win-size 1280 720
sync-video #t
framebuffer-multisample 1
multisamples 4
""")


class OrreryApp(ShowBase):

    def __init__(self):
        super().__init__()

        # Pleasant dark-navy background; the star field handles the actual texture.
        self.set_background_color(0.02, 0.02, 0.05, 1)
        self.disable_mouse()    # we use our own orbit camera

        # --- Scene root ---------------------------------------------------
        self.scene_root = self.render.attach_new_node("scene_root")

        # --- Star field (parented to camera so it never shifts on pan) ----
        stars = procedural.build_star_field(count=2500, radius=900)
        stars.reparent_to(self.camera)
        stars.set_light_off(1)
        stars.set_bin("background", 0)
        stars.set_depth_write(False)
        stars.set_depth_test(False)

        # --- Lighting -----------------------------------------------------
        ambient = AmbientLight("ambient")
        ambient.set_color(Vec4(0.06, 0.06, 0.08, 1))
        amb_np = self.render.attach_new_node(ambient)
        self.render.set_light(amb_np)

        # --- Sun and planets ---------------------------------------------
        self.sun = Sun(self.scene_root, radius=2.0)
        # The sun's PointLight illuminates the planets.
        self.render.set_light(self.sun.light_np)

        self.planets: list[Planet] = []
        for spec in default_system():
            self.planets.append(Planet(self.scene_root, spec))

        # --- Camera -------------------------------------------------------
        self.camera_rig = OrbitCamera(self, target=self.sun.node, distance=45.0)
        self._focus_name = "Sun"

        # --- HUD ---------------------------------------------------------
        self.hud = HUD(self)

        # --- Sim state ---------------------------------------------------
        self.time_scale = 1.0
        self.paused = False
        self.show_orbits = True

        # --- Input bindings ----------------------------------------------
        self._bind_inputs()

        # --- Main task ---------------------------------------------------
        self.taskMgr.add(self._tick, "OrreryApp.tick")

    # -------------------------------------------------------------------
    # Input
    # -------------------------------------------------------------------

    def _bind_inputs(self) -> None:
        self.accept("escape", self.userExit)

        self.accept("space", self._toggle_pause)
        self.accept("[", lambda: self._adjust_time_scale(0.5))
        self.accept("]", lambda: self._adjust_time_scale(2.0))
        self.accept("o", self._toggle_orbits)

        # Focus shortcuts.
        self.accept("0", lambda: self._focus("Sun", self.sun.node, 45.0))
        for i, planet in enumerate(self.planets, start=1):
            self.accept(str(i),
                       lambda p=planet: self._focus(p.spec.name, p.body, max(12.0, p.spec.body_radius * 8.0)))

    def _toggle_pause(self) -> None:
        self.paused = not self.paused

    def _adjust_time_scale(self, factor: float) -> None:
        self.time_scale = max(0.0625, min(64.0, self.time_scale * factor))

    def _toggle_orbits(self) -> None:
        self.show_orbits = not self.show_orbits
        for p in self.planets:
            (p.orbit_line.show() if self.show_orbits else p.orbit_line.hide())

    def _focus(self, name: str, node: NodePath, distance: float) -> None:
        self._focus_name = name
        self.camera_rig.focus_on(node, distance)

    # -------------------------------------------------------------------
    # Tick
    # -------------------------------------------------------------------

    def _tick(self, task):
        dt = ClockObject.get_global_clock().get_dt()
        if not self.paused:
            for p in self.planets:
                p.update(dt, self.time_scale)

        self.hud.update(self.time_scale, self.paused, self._focus_name)
        return task.cont
