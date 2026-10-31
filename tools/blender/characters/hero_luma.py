"""Héros : luma."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_white", skin="skin_pale", hair="hair_silver", hair_style="long", eyes="crystal", crown="crystal_violet", cape="cloth_purple", skirt="cloth_purple", glow="rune", weapon=lambda m, x, z: staff(m, x, z, orb="crystal_violet", top="crystal"), offhand=lambda m, x, z: m.crystal((x, -0.04, z + 0.02), 0.07, 0.02, "crystal_violet"))
