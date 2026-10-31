"""Dieux : héros divins plus grands, auréoles flottantes, parures lumineuses."""
import math
from characters._hero import hero, HEAD_Z


def halo(m, color, radius=0.13, z=HEAD_Z + 0.16):
    with m.anim("halo", (0, 0.02, z), spin=("Y", 40), bob=0.01):
        m.torus(radius, 0.012, (0, 0.02, z), color, rot=(80, 0, 0), seg=24, rseg=5)
        for i in range(6):
            a = math.tau * i / 6
            m.sphere(0.014, (math.cos(a) * radius, 0.02, z + math.sin(a) * radius * 0.2), color, seg=6, rings=4)


def wings(m, mat="cloth_white"):
    for side, name in ((-1, "wingl"), (1, "wingr")):
        with m.anim(name, (side * 0.05, 0.09, 0.3)):
            for k in range(5):
                m.sphere(0.05 - k * 0.004, (side * (0.08 + k * 0.05), 0.11, 0.33 + k * 0.03 - (k * k) * 0.006), mat, seg=8, rings=5,
                         scale=(1.6, 0.4, 0.8 + k * 0.1))
            for k in range(4):
                m.sphere(0.035, (side * (0.1 + k * 0.05), 0.1, 0.24 - k * 0.02), mat, seg=8, rings=5, scale=(1.2, 0.4, 1.8))
