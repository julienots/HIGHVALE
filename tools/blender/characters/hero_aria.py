"""Héros : aria."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "fur_brown", hair="hair_red", hair_style="ponytail", hood=None, cape="cloth_brown", pauldrons="fur_brown", weapon=bow)
