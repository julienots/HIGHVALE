"""Héros : ezra."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "cloth_white", skin="skin_dark", hair="hair_white", hair_style="long", beard=True, skirt="cloth_blue", weapon=lambda m, x, z: staff(m, x, z, orb="crystal_teal", top="gold"), offhand=lambda m, x, z: book(m, x, z, "cloth_blue"))
