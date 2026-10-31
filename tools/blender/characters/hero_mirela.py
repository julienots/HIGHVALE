"""Héros : mirela."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_cream", hair="hair_brown", hood="cloth_white", skirt="cloth_white", weapon=lambda m, x, z: staff(m, x, z, orb="glow_teal", top="gold"))
