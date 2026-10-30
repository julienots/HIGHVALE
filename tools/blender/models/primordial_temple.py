"""Temple Primordial (4 × 4) : pyramide à degrés, sanctuaire à colonnes,
toit bleu à tuiles et grand cristal flottant."""
import math

EXTENT = 4.0


def build(m):
    m.ao_height = 1.4
    z = m.flagstone_plinth(3.94, 3.94, mat="stone", curb="stone_dark")
    # Gradins en blocs de pierre
    tiers = [(3.5, 0.34), (2.86, 0.34), (2.3, 0.3)]
    for i, (s, h) in enumerate(tiers):
        half = s / 2
        mat = "stone" if i % 2 == 0 else "stone_warm"
        for a, b in [((-half, -half), (half, -half)), ((half, -half), (half, half)), ((half, half), (-half, half)), ((-half, half), (-half, -half))]:
            m.brick_wall(a, b, z, h, thick=0.3, mat=mat, course=h / 2, brick=0.5)
        m.box((s - 0.3, s - 0.3, h), (0, 0, z + h / 2), "stone_dark", bevel=0.0)
        m.box((s + 0.04, s + 0.04, 0.06), (0, 0, z + h + 0.03), "stone_dark", bevel=0.02)
        with m.tier(2):
            m.frame_ring(s + 0.06, z + h + 0.03)
        with m.tier(3):
            for k in (-1, 1):
                m.box((s * 0.3, 0.03, 0.05), (k * s * 0.25, -half - 0.03, z + h * 0.5), "rune", bevel=0.0)
                m.box((0.03, s * 0.3, 0.05), (half + 0.03, k * s * 0.25, z + h * 0.5), "rune", bevel=0.0)
        z += h + 0.06
    top = z
    # Grand escalier frontal (vers -Y)
    base = 0.13
    steps = 7
    back = -1.0
    for i in range(steps):
        sz = base + (top - base) * (i + 1) / steps
        y = -1.98 + i * 0.13
        m.box((0.95, back - y, sz - base), (0, (y + back) / 2, base + (sz - base) / 2), "marble", bevel=0.025)
    for sx in (-1, 1):
        for i in range(4):
            m.box((0.16, 0.24, 0.12 + i * 0.25), (sx * 0.56, -1.86 + i * 0.22, base + (0.12 + i * 0.25) / 2), "stone_dark", bevel=0.025)
        m.brazier((sx * 0.56, -1.86, base + 0.12))
    # Sanctuaire : colonnes, entablement et toit
    col_h = 1.25
    pos = [-0.85, -0.28, 0.28, 0.85]
    for px in pos:
        for py in pos:
            if abs(px) == 0.85 or abs(py) == 0.85:
                m.column((px, py, top), 0.085, col_h)
    ez = top + col_h
    m.box((2.15, 2.15, 0.16), (0, 0, ez + 0.08), "marble", bevel=0.03)
    for side in range(4):
        for k in range(7):
            t = -0.9 + k * 0.3
            p = [(t, -1.08), (1.08, t), (t, 1.08), (-1.08, t)][side]
            m.box((0.12, 0.12, 0.12), (p[0], p[1], ez + 0.22), "stone_warm", bevel=0.02)
    m.box((2.3, 2.3, 0.1), (0, 0, ez + 0.33), "marble", bevel=0.03)
    # Toit pyramidal tronqué à tuiles, ouvert au sommet sur le cristal
    rz = ez + 0.38
    m.hip_roof((0, 0, rz), 2.5, 0.75, "roof_blue", rows=5, hip_mat="gold")
    m.box((0.8, 0.8, 0.16), (0, 0, rz + 0.66), "marble", bevel=0.04)
    with m.tier(1):
        m.frame_ring(0.82, rz + 0.75)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        m.cyl(0.05, 0.4, (math.cos(a) * 0.36, math.sin(a) * 0.36, rz + 0.74), "gold", r2=0.02, seg=6,
              rot=(-math.sin(a) * 18, math.cos(a) * 18, 0))
    spire = rz + 0.74
    # Emblème doré sur l'entablement de façade
    m.box((0.5, 0.05, 0.18), (0, -1.13, ez + 0.22), "gold", bevel=0.02)
    m.crystal((0, -1.17, ez + 0.13), 0.18, 0.04, "crystal")
    # Autel et cristal flottant
    m.cyl(0.32, 0.18, (0, 0, top), "marble", r2=0.26, seg=8, smooth=False)
    m.cyl(0.2, 0.25, (0, 0, top + 0.18), "stone_warm", r2=0.28, seg=8, smooth=False)
    m.torus(0.27, 0.03, (0, 0, top + 0.43), "gold", seg=16, rseg=6)
    m.crystal((0, 0, top + 0.43), 0.45, 0.12, "crystal_teal")
    m.light((0, 0, top + 0.7), "7fdcff", 0.8, 3.0)
    # Grand cristal primordial flottant au-dessus du toit
    cz = spire + 0.55
    with m.anim("core", (0, 0, cz), spin=("Y", 30), bob=0.08):
        m.crystal((0, 0, cz - 0.05), 0.95, 0.24, "crystal", rz=0)
        m.crystal((0, 0, cz + 0.02), 0.42, 0.21, "crystal", tilt=(180, 0), rz=30)
        for i in range(3):
            a = 2 * math.pi * i / 3
            m.crystal((math.cos(a) * 0.3, math.sin(a) * 0.3, cz - 0.1), 0.35, 0.07, "crystal_teal", tilt=(-math.sin(a) * 28, math.cos(a) * 28))
    m.light((0, 0, cz + 0.4), "7fdcff", 1.1, 5.5)
    with m.tier(2):
        with m.anim("orbit", (0, 0, cz + 0.2), spin=("Y", -55)):
            for i in range(4):
                a = 2 * math.pi * i / 4
                m.sphere(0.07, (math.cos(a) * 0.62, math.sin(a) * 0.62, cz + 0.2), "rune", seg=8, rings=6)
    # Bannières entre les colonnes de façade
    with m.tier(1):
        for sx in (-1, 1):
            m.banner((sx * 1.62, -1.62, 0.13), h=1.5, cloth="cloth_blue", rot_z=0)
            m.banner((1.62, sx * 0.9, 0.13), h=1.3, cloth="cloth_blue", rot_z=90)
    # Obélisques d'angle
    with m.tier(2):
        for cx, cy in [(-1.62, 1.62), (1.62, 1.62)]:
            m.box((0.26, 0.26, 0.12), (cx, cy, 0.19), "stone_dark", bevel=0.03)
            m.cyl(0.1, 0.8, (cx, cy, 0.25), "stone", r2=0.06, seg=4, rot=(0, 0, 45), smooth=False)
            m.crystal((cx, cy, 1.03), 0.28, 0.06, "crystal")
    with m.tier(3):
        m.crystal_cluster((-1.55, -1.0, 0.13), 0.55, "crystal")
        m.crystal_cluster((1.0, 1.55, 0.13), 0.5, "crystal_violet")
        m.light((-1.5, -1.0, 0.6), "7fdcff", 0.8, 3.0, 3)
