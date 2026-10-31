"""Héros : Grigri (Diablotin). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "scale_red", "cloth_black", weapon=lambda m, x, z: flame_hand(m, x, z), offhand=lambda m, x, z: flame_hand(m, x, z), skin="scale_red", hair="hair_black", horns="dark", tail="scale_red", eyes="glow_gold", hair_style="bald")
