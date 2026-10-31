"""Héros : nyx."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_black", skin="skin_pale", hood="cloth_purple", eyes="shadow_glow", cape="cloth_purple", weapon=lambda m, x, z: dagger(m, x, z), offhand=lambda m, x, z: dagger(m, x, z))
