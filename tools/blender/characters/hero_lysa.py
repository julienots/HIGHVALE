"""Héros : lysa."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "cloth_brown", hair="hair_blond", hair_style="ponytail", cape="cloth_teal", weapon=bow)
