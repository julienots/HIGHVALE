"""Héros : Fen (Cueilleuse de spores). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leaf", "leather", weapon=lambda m, x, z: bow(m, x, z), hair="hair_blond", hat=('flower', 'mushroom_pink'), hair_style="twintails")
