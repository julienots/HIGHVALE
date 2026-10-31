"""Héros : aurelle."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_brown", hair="hair_red", hair_style="long", skirt="cloth_red", cape="cloth_orange", weapon=lambda m, x, z: staff(m, x, z, orb="fire"), offhand=flame_hand)
