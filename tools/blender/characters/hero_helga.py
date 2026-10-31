"""Héros : Helga (Architecte du Temple). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_white", weapon=lambda m, x, z: staff(m, x, z, "crystal_teal", "gold"), offhand=lambda m, x, z: tome(m, x, z, "cloth_teal"), hair="hair_silver", goggles="gold", hair_style="bun")
