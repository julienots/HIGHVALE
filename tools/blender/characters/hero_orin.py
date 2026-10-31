"""Héros : orin."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_blue", skin="skin", hair="hair_white", hair_style="spiky", beard=True, eyes="rune", cape="cloth_blue", skirt="cloth_white", weapon=lambda m, x, z: staff(m, x, z, orb="rune", top="steel"), offhand=lambda m, x, z: m.sphere(0.04, (x, -0.04, z + 0.03), "rune", seg=8, rings=5))
