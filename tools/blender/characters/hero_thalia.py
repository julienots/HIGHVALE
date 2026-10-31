"""Héros : thalia."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leaf", "bark", skin="skin_pale", hair="hair_red", hair_style="long", crown="leaf", skirt="leaf_dark", weapon=lambda m, x, z: staff(m, x, z, orb="glow_teal", top="bark"), offhand=lambda m, x, z: m.sphere(0.035, (x, -0.04, z + 0.03), "leaf", seg=8, rings=5))
