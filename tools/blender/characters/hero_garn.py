"""Héros : Garn (Contremaître des galeries). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_brown", "leather", weapon=lambda m, x, z: pickaxe(m, x, z), offhand=lambda m, x, z: shield(m, x, z, "cloth_brown", "iron"), hair="hair_brown", beard=True, helmet="helmet_yellow", hair_style="bald")
