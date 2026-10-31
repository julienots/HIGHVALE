"""Héros : kael."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_black", skin="skin_blue", hair="hair_silver", hair_style="long", eyes="shadow_glow", cape="cloth_black", skirt="cloth_purple", weapon=lambda m, x, z: staff(m, x, z, orb="crystal_violet", top="shadow_glow"), offhand=lambda m, x, z: book(m, x, z, "cloth_black"))
