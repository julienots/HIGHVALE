"""Héros : Léo (Roi-lion). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "gold", "leather", weapon=lambda m, x, z: claws(m, x, z, "gold"), offhand=lambda m, x, z: claws(m, x, z, "gold"), skin="skin_dark", hair="hair_blond", ears="hair_blond", tail="hair_blond", crown="gold", armor="gold", cape="cloth_red", glow="glow_gold", hair_style="mane")
