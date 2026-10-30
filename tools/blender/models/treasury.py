"""Trésorerie : salle en pierre chaude, portique à colonnes, dôme doré nervuré
avec lanterne, porte de coffre-fort, coffres et piles de pièces."""
import math

EXTENT = 3.0


def build(m):
    z = m.flagstone_plinth(2.94, 2.94, mat="marble", curb="stone_dark")
    m.ao_height = 1.0
    cx, cy, w, d, h = 0.0, 0.3, 1.9, 1.4, 0.95
    hw, hd = w / 2, d / 2
    m.box((w + 0.12, d + 0.12, 0.1), (cx, cy, z + 0.05), "stone_dark", bevel=0.02)
    for a, b in [((cx - hw, cy - hd), (cx + hw, cy - hd)), ((cx + hw, cy - hd), (cx + hw, cy + hd)),
                 ((cx + hw, cy + hd), (cx - hw, cy + hd)), ((cx - hw, cy + hd), (cx - hw, cy - hd))]:
        m.brick_wall(a, b, z + 0.1, h, thick=0.18, mat="stone_warm", course=0.16, brick=0.34)
    m.box((w - 0.2, d - 0.2, h), (cx, cy, z + 0.1 + h / 2), "stone_dark", bevel=0)
    top = z + 0.1 + h
    m.box((w + 0.16, d + 0.16, 0.1), (cx, cy, top + 0.05), "marble", bevel=0.03)
    m.box((w + 0.06, d + 0.06, 0.08), (cx, cy, top + 0.14), "stone_warm", bevel=0.02)
    # Pilastres
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.box((0.14, 0.14, h + 0.1), (cx + sx * hw, cy + sy * hd, z + 0.1 + h / 2), "marble", bevel=0.02)
    # Tambour et dôme nervuré
    dz = top + 0.18
    m.cyl(0.62, 0.24, (cx, cy, dz), "marble", seg=24)
    for i in range(12):
        a = 2 * math.pi * i / 12
        m.box((0.06, 0.06, 0.2), (cx + math.cos(a) * 0.63, cy + math.sin(a) * 0.63, dz + 0.12), "stone_warm", rot=(0, 0, math.degrees(a)), bevel=0.01)
    m.torus(0.63, 0.04, (cx, cy, dz + 0.25), "gold", seg=24, rseg=6)
    m.sphere(0.6, (cx, cy, dz + 0.25), "gold", seg=24, rings=10, hemi=True, scale=(1, 1, 0.95))
    for i in range(8):
        a = 2 * math.pi * i / 8
        for k in range(6):
            t0, t1 = k / 6 * math.pi / 2, (k + 1) / 6 * math.pi / 2
            p0 = (cx + math.cos(a) * math.cos(t0) * 0.61, cy + math.sin(a) * math.cos(t0) * 0.61, dz + 0.25 + math.sin(t0) * 0.58)
            p1 = (cx + math.cos(a) * math.cos(t1) * 0.61, cy + math.sin(a) * math.cos(t1) * 0.61, dz + 0.25 + math.sin(t1) * 0.58)
            m.rod(p0, p1, 0.025, "bronze", seg=5)
    # Lanterne sommitale
    lz = dz + 0.82
    for i in range(6):
        a = 2 * math.pi * i / 6
        m.cyl(0.02, 0.2, (cx + math.cos(a) * 0.13, cy + math.sin(a) * 0.13, lz), "marble", seg=6)
    m.cyl(0.11, 0.18, (cx, cy, lz), "window", seg=10)
    m.cyl(0.18, 0.04, (cx, cy, lz + 0.2), "marble", seg=12)
    m.cone_roof((cx, cy, lz + 0.24), 0.17, 0.22, "gold", rings=2, finial="gold")
    m.light((cx, cy, lz + 0.1), "ffd27a", 0.6, 2.5)
    # Portique
    py = cy - hd - 0.32
    m.box((1.3, 0.55, 0.08), (cx, py + 0.12, z + 0.04), "marble", bevel=0.02)
    m.box((1.1, 0.22, 0.06), (cx, py - 0.2, z + 0.03), "marble", bevel=0.02)
    for px in (-0.5, -0.17, 0.17, 0.5):
        m.column((cx + px, py, z + 0.08), 0.06, h + 0.02, "marble", "marble")
    m.box((1.32, 0.3, 0.1), (cx, py + 0.05, top + 0.05), "marble", bevel=0.02)
    m.prism(0.36, 1.36, 0.28, (cx, py + 0.05, top + 0.1), "stone_warm", rot=(0, 0, 90))
    m.poly([(-0.14, 0, 0.04), (0.14, 0, 0.04), (0, 0, 0.2)], [(0, 1, 2)], (cx, py - 0.135, top + 0.1), "gold")
    # Porte de coffre-fort
    m.cyl(0.3, 0.06, (cx, cy - hd - 0.01, z + 0.42), "iron", rot=(90, 0, 0), seg=20)
    m.torus(0.3, 0.035, (cx, cy - hd - 0.07, z + 0.42), "gold", rot=(90, 0, 0), seg=20, rseg=6)
    for i in range(6):
        a = 2 * math.pi * i / 6
        m.cyl(0.03, 0.04, (cx + math.cos(a) * 0.22, cy - hd - 0.06, z + 0.42 + math.sin(a) * 0.22), "gold", rot=(90, 0, 0), seg=8)
    m.cyl(0.07, 0.06, (cx, cy - hd - 0.09, z + 0.42), "gold", rot=(90, 0, 0), seg=10)
    # Fenêtres latérales
    for wy in (-0.25, 0.3):
        m.window((cx + hw + 0.1, cy + wy, z + 0.4), 90, w=0.2, h=0.34, frame="stone_dark", arch=True, sill="marble")
    # Coffres et pièces
    for (x, y, rz) in [(-1.05, -1.0, 10), (1.05, -0.95, -15)]:
        m.box((0.36, 0.24, 0.2), (x, y, z + 0.1), "wood", rot=(0, 0, rz), bevel=0.02)
        m.cyl(0.12, 0.36, (x - 0.18 * math.cos(math.radians(rz)), y - 0.18 * math.sin(math.radians(rz)), z + 0.2), "wood_dark", rot=(0, 90, rz), seg=10, scale=(1, 1, 1))
        m.box((0.05, 0.26, 0.32), (x, y, z + 0.17), "gold", rot=(0, 0, rz), bevel=0.01)
    for (x, y, n) in [(-0.75, -1.15, 6), (0.75, -1.2, 4), (-1.2, -0.65, 3)]:
        for k in range(n):
            m.cyl(0.07, 0.025, (x + m.rng.uniform(-0.01, 0.01), y + m.rng.uniform(-0.01, 0.01), z + k * 0.026), "gold", seg=12)
    for sx in (-1, 1):
        m.brazier((cx + sx * 0.78, py - 0.2, z))
    with m.tier(1):
        m.banner((-1.3, 0.2, z), 1.4, "cloth_red", rot_z=90)
        m.banner((1.3, 0.2, z), 1.4, "cloth_red", rot_z=90)
    with m.tier(2):
        for sx in (-1, 1):
            m.box((0.2, 0.2, 0.3), (cx + sx * 1.18, cy + 0.95, z + 0.15), "marble", bevel=0.03)
            m.sphere(0.12, (cx + sx * 1.18, cy + 0.95, z + 0.42), "gold", seg=12, rings=8)
    with m.tier(3):
        for i in range(8):
            a = 2 * math.pi * i / 8 + math.pi / 8
            m.crystal((cx + math.cos(a) * 0.64, cy + math.sin(a) * 0.64, dz + 0.24), 0.14, 0.035, "crystal_violet" if i % 2 else "crystal")
