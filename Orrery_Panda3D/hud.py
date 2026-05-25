"""
hud.py — minimal on-screen overlay.

Uses Panda's DirectGui (`OnscreenText`) for simplicity. A real game would
likely use a custom layout system; for an inspector tool this is fine.
"""

from __future__ import annotations

from direct.gui.OnscreenText import OnscreenText
from panda3d.core import TextNode


class HUD:

    def __init__(self, base):
        self.base = base

        self.title = OnscreenText(
            text="Orrery — Procedural Solar System",
            pos=(-1.32, 0.92), scale=0.05, fg=(1, 1, 1, 0.9),
            align=TextNode.A_left, mayChange=False,
        )
        self.help = OnscreenText(
            text=(
                "Right-drag: orbit camera     Wheel: zoom\n"
                "[ / ] : time scale       Space: pause/play\n"
                "1-6 : focus planet       0 : focus sun\n"
                "O : toggle orbit lines"
            ),
            pos=(-1.32, -0.78), scale=0.04, fg=(1, 1, 1, 0.75),
            align=TextNode.A_left, mayChange=False,
        )
        self.status = OnscreenText(
            text="", pos=(1.32, 0.92), scale=0.045, fg=(1, 1, 1, 0.85),
            align=TextNode.A_right, mayChange=True,
        )
        self.focus_text = OnscreenText(
            text="", pos=(0, -0.92), scale=0.05, fg=(1, 1, 1, 0.85),
            align=TextNode.A_center, mayChange=True,
        )

    def update(self, time_scale: float, paused: bool, focus_name: str) -> None:
        rate = "PAUSED" if paused else f"time × {time_scale:0.2f}"
        self.status.setText(rate)
        self.focus_text.setText(f"focus: {focus_name}")
