"""Héros : Baldur (Juge du Temple). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "gold", weapon=lambda m, x, z: mace(m, x, z, "gold"), offhand=lambda m, x, z: tome(m, x, z, "cloth_white"), hair="hair_silver", beard=True, crown="gold", cape="cloth_white", glow="glow_gold", eyes="glow_gold", hair_style="short")
