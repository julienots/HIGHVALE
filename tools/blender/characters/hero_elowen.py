"""Héros : Elowen (Elfe des cavernes). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "leather", weapon=lambda m, x, z: bow(m, x, z), skin="skin_pale", hair="hair_silver", ears="elf", cape="cloth_teal", eyes="crystal", hair_style="long")
