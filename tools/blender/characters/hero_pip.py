"""Héros : pip."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_orange", "cloth_blue", hair="hair_blond", hair_style="spiky", weapon=wrench, offhand=lambda m, x, z: m.sphere(0.035, (x, -0.04, z + 0.02), "glow_gold", seg=8, rings=6))
