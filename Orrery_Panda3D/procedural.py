"""
procedural.py — procedural geometry helpers for Panda3D.

Everything in here returns a `Geom` or a `NodePath`; callers parent the
result wherever they want. We deliberately avoid loading external assets
so the project runs from a clean checkout with no model files.

The icosphere builder is the most interesting piece — subdividing an
icosahedron gives a far more uniform vertex distribution than the
latitude/longitude "UV sphere" you get from spinning a half-circle.
"""

from __future__ import annotations

import math
import random
from typing import Iterable

from panda3d.core import (
    Geom,
    GeomNode,
    GeomTriangles,
    GeomVertexData,
    GeomVertexFormat,
    GeomVertexWriter,
    GeomLines,
    GeomPoints,
    NodePath,
    LVector3f,
    LVector4f,
)


# ---------------------------------------------------------------------------
# Icosphere
# ---------------------------------------------------------------------------

# 12 vertices of a unit icosahedron, derived from the golden ratio.
# These are normalized to lie on the unit sphere — subdivision keeps them
# there as long as we re-normalize every new midpoint we create.
_PHI = (1.0 + math.sqrt(5.0)) / 2.0


def _icosahedron_base():
    verts = [
        (-1,  _PHI, 0), ( 1,  _PHI, 0), (-1, -_PHI, 0), ( 1, -_PHI, 0),
        (0, -1,  _PHI), (0,  1,  _PHI), (0, -1, -_PHI), (0,  1, -_PHI),
        ( _PHI, 0, -1), ( _PHI, 0,  1), (-_PHI, 0, -1), (-_PHI, 0,  1),
    ]
    # Normalize to the unit sphere.
    verts = [_normalize(v) for v in verts]
    faces = [
        (0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11),
        (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
        (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9),
        (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1),
    ]
    return verts, faces


def _normalize(v):
    x, y, z = v
    inv = 1.0 / math.sqrt(x * x + y * y + z * z)
    return (x * inv, y * inv, z * inv)


def _midpoint(a, b, cache, verts):
    """Return the index of the unit-sphere midpoint of vertices a and b."""
    key = (min(a, b), max(a, b))
    if key in cache:
        return cache[key]
    va, vb = verts[a], verts[b]
    mid = _normalize(((va[0] + vb[0]) * 0.5,
                      (va[1] + vb[1]) * 0.5,
                      (va[2] + vb[2]) * 0.5))
    verts.append(mid)
    cache[key] = len(verts) - 1
    return cache[key]


def build_icosphere(radius: float = 1.0, subdivisions: int = 2,
                    color: tuple = (1, 1, 1, 1), name: str = "icosphere") -> NodePath:
    """
    Build a procedural unit sphere via icosahedron subdivision.

    `subdivisions=2` → 320 triangles, plenty smooth for a planet at this scale.
    `subdivisions=3` → 1280 triangles for the sun.
    """
    verts, faces = _icosahedron_base()
    cache: dict[tuple[int, int], int] = {}

    for _ in range(subdivisions):
        new_faces = []
        for a, b, c in faces:
            ab = _midpoint(a, b, cache, verts)
            bc = _midpoint(b, c, cache, verts)
            ca = _midpoint(c, a, cache, verts)
            new_faces.extend([
                (a, ab, ca),
                (b, bc, ab),
                (c, ca, bc),
                (ab, bc, ca),
            ])
        faces = new_faces

    return _build_indexed_mesh(verts, faces, radius, color, name)


def _build_indexed_mesh(verts, faces, radius, color, name) -> NodePath:
    fmt = GeomVertexFormat.get_v3n3c4()
    vdata = GeomVertexData(name, fmt, Geom.UH_static)
    vdata.set_num_rows(len(verts))

    vw = GeomVertexWriter(vdata, "vertex")
    nw = GeomVertexWriter(vdata, "normal")
    cw = GeomVertexWriter(vdata, "color")

    for v in verts:
        vw.add_data3(v[0] * radius, v[1] * radius, v[2] * radius)
        # Vertex normal is the unit position (since it's a sphere centered at origin).
        nw.add_data3(v[0], v[1], v[2])
        cw.add_data4(*color)

    tris = GeomTriangles(Geom.UH_static)
    for a, b, c in faces:
        tris.add_vertices(a, b, c)
    tris.close_primitive()

    geom = Geom(vdata)
    geom.add_primitive(tris)
    node = GeomNode(name)
    node.add_geom(geom)
    return NodePath(node)


# ---------------------------------------------------------------------------
# Ring (for Saturn-style planets)
# ---------------------------------------------------------------------------

def build_ring(inner_radius: float, outer_radius: float, segments: int = 64,
               color: tuple = (1, 0.9, 0.7, 0.55), name: str = "ring") -> NodePath:
    """
    Build a flat annulus in the XY plane. Two-sided would need both winding
    orders; for a ringed planet seen from a moderate angle one side is fine.
    """
    fmt = GeomVertexFormat.get_v3n3c4()
    vdata = GeomVertexData(name, fmt, Geom.UH_static)
    vdata.set_num_rows(segments * 2)

    vw = GeomVertexWriter(vdata, "vertex")
    nw = GeomVertexWriter(vdata, "normal")
    cw = GeomVertexWriter(vdata, "color")

    for i in range(segments):
        theta = (i / segments) * 2.0 * math.pi
        cx, cy = math.cos(theta), math.sin(theta)
        vw.add_data3(cx * inner_radius, cy * inner_radius, 0.0)
        nw.add_data3(0, 0, 1)
        cw.add_data4(*color)
        vw.add_data3(cx * outer_radius, cy * outer_radius, 0.0)
        nw.add_data3(0, 0, 1)
        cw.add_data4(*color)

    tris = GeomTriangles(Geom.UH_static)
    for i in range(segments):
        i0 = (i * 2) % (segments * 2)
        i1 = (i * 2 + 1) % (segments * 2)
        i2 = ((i + 1) * 2) % (segments * 2)
        i3 = ((i + 1) * 2 + 1) % (segments * 2)
        tris.add_vertices(i0, i2, i1)
        tris.add_vertices(i1, i2, i3)
    tris.close_primitive()

    geom = Geom(vdata)
    geom.add_primitive(tris)
    node = GeomNode(name)
    node.add_geom(geom)
    return NodePath(node)


# ---------------------------------------------------------------------------
# Star field background
# ---------------------------------------------------------------------------

def build_star_field(count: int = 2500, radius: float = 1200.0,
                     seed: int = 42, name: str = "stars") -> NodePath:
    """
    Build a sphere of point-sprite stars at a large radius. We use GeomPoints
    so the GPU draws each star as a single pixel/point — cheap and effective.
    """
    rng = random.Random(seed)

    fmt = GeomVertexFormat.get_v3c4()
    vdata = GeomVertexData(name, fmt, Geom.UH_static)
    vdata.set_num_rows(count)

    vw = GeomVertexWriter(vdata, "vertex")
    cw = GeomVertexWriter(vdata, "color")

    for _ in range(count):
        # Uniform point on the unit sphere via the Marsaglia method.
        while True:
            u = rng.uniform(-1, 1)
            v = rng.uniform(-1, 1)
            s = u * u + v * v
            if s < 1.0:
                break
        factor = 2.0 * math.sqrt(1.0 - s)
        x, y, z = u * factor, v * factor, 1.0 - 2.0 * s
        vw.add_data3(x * radius, y * radius, z * radius)

        # Most stars dim, a few bright — gives the field visual texture.
        brightness = rng.choices(
            [0.25, 0.45, 0.7, 1.0],
            weights=[40, 30, 20, 10],
        )[0]
        # Slight color tint so the field doesn't look flat-white.
        tint = rng.uniform(0.85, 1.0)
        cw.add_data4(brightness, brightness * tint, brightness * rng.uniform(0.85, 1.0), 1.0)

    pts = GeomPoints(Geom.UH_static)
    pts.add_consecutive_vertices(0, count)
    pts.close_primitive()

    geom = Geom(vdata)
    geom.add_primitive(pts)
    node = GeomNode(name)
    node.add_geom(geom)
    return NodePath(node)


# ---------------------------------------------------------------------------
# Orbit guide line (a thin circle in the XY plane)
# ---------------------------------------------------------------------------

def build_orbit_line(radius: float, segments: int = 96,
                     color: tuple = (1, 1, 1, 0.18), name: str = "orbit") -> NodePath:
    fmt = GeomVertexFormat.get_v3c4()
    vdata = GeomVertexData(name, fmt, Geom.UH_static)
    vdata.set_num_rows(segments)
    vw = GeomVertexWriter(vdata, "vertex")
    cw = GeomVertexWriter(vdata, "color")
    for i in range(segments):
        theta = (i / segments) * 2.0 * math.pi
        vw.add_data3(math.cos(theta) * radius, math.sin(theta) * radius, 0.0)
        cw.add_data4(*color)

    lines = GeomLines(Geom.UH_static)
    for i in range(segments):
        lines.add_vertices(i, (i + 1) % segments)
    lines.close_primitive()

    geom = Geom(vdata)
    geom.add_primitive(lines)
    node = GeomNode(name)
    node.add_geom(geom)
    return NodePath(node)
