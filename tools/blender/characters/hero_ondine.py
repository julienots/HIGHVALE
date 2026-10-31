"""Héros : ondine."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_blue", skin="skin_pale", hair="hair_blue", hair_style="long", skirt="cloth_teal", weapon=lambda m, x, z: staff(m, x, z, orb="crystal_teal", top="steel"))
