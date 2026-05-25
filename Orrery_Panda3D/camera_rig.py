"""
camera_rig.py — orbit camera controller.

A pivot NodePath sits at the look-target. The camera is parented to it
at a local -Y offset equal to zoom distance. Yaw rotates the pivot;
pitch rotates the camera around the pivot's local X. This is the
cleanest setup in any scene-graph engine — no quaternion juggling, no
gimbal-lock worries for an inspector camera.

Inputs:
    * Right-mouse drag — orbit (yaw + pitch)
    * Wheel up/down    — zoom in/out
    * 'f' key          — focus on a body (caller wires this)
"""

from __future__ import annotations

from panda3d.core import NodePath, LVector3f, ClockObject


class OrbitCamera:

    def __init__(self, base, target: NodePath, distance: float = 35.0,
                 min_distance: float = 4.0, max_distance: float = 120.0):
        self.base = base
        self.target = target

        self.distance = distance
        self.min_distance = min_distance
        self.max_distance = max_distance
        self.yaw_deg = 35.0
        self.pitch_deg = -25.0   # negative tilts the camera down toward the plane

        # Pivot lives where we want to look. Camera hangs off it.
        self.pivot = base.render.attach_new_node("camera_pivot")
        self.pivot.set_pos(target.get_pos(base.render))

        base.camera.reparent_to(self.pivot)
        base.camera.set_pos(0, -self.distance, 0)
        base.camera.look_at(self.pivot)

        # Input state.
        self._orbiting = False
        self._last_mouse: tuple[float, float] | None = None
        self._sensitivity = 0.35   # degrees per pixel

        # Mouse buttons.
        base.accept("mouse3", self._begin_orbit)
        base.accept("mouse3-up", self._end_orbit)
        base.accept("wheel_up",   lambda: self._zoom(-0.85))
        base.accept("wheel_down", lambda: self._zoom( 0.85))

        # Driven each frame.
        base.taskMgr.add(self._update, "OrbitCamera.update")

    # ----- input handlers -----

    def _begin_orbit(self):
        self._orbiting = True
        self._last_mouse = None

    def _end_orbit(self):
        self._orbiting = False

    def _zoom(self, delta: float):
        self.distance = max(self.min_distance, min(self.max_distance, self.distance + delta))

    # ----- per-frame -----

    def _update(self, task):
        if self._orbiting and self.base.mouseWatcherNode.has_mouse():
            mx = self.base.mouseWatcherNode.get_mouse_x()
            my = self.base.mouseWatcherNode.get_mouse_y()
            if self._last_mouse is not None:
                dx = (mx - self._last_mouse[0]) * self.base.win.get_x_size()
                dy = (my - self._last_mouse[1]) * self.base.win.get_y_size()
                self.yaw_deg -= dx * self._sensitivity
                self.pitch_deg += dy * self._sensitivity
                self.pitch_deg = max(-85.0, min(85.0, self.pitch_deg))
            self._last_mouse = (mx, my)
        else:
            self._last_mouse = None

        # Smoothly follow the target if it's a moving body. Lerp is
        # frame-rate dependent here intentionally for inspector responsiveness;
        # for a gameplay camera you'd use the 1-exp(-k*dt) form instead.
        dt = ClockObject.get_global_clock().get_dt()
        target_pos = self.target.get_pos(self.base.render)
        current = self.pivot.get_pos()
        self.pivot.set_pos(current + (target_pos - current) * min(1.0, 8.0 * dt))

        self.pivot.set_hpr(self.yaw_deg, self.pitch_deg, 0)
        self.base.camera.set_pos(0, -self.distance, 0)
        self.base.camera.look_at(self.pivot)
        return task.cont

    # ----- public -----

    def focus_on(self, node: NodePath, distance: float | None = None) -> None:
        """Switch the camera target. Optional distance override."""
        self.target = node
        if distance is not None:
            self.distance = max(self.min_distance, min(self.max_distance, distance))
