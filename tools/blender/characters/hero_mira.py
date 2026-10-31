"""Héros : mira."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_black", hair="hair_blue", hair_style="short", hood="cloth_teal", eyes="crystal", weapon=lambda m, x, z: dagger(m, x, z, "crystal"), offhand=lambda m, x, z: dagger(m, x, z, "crystal"))
