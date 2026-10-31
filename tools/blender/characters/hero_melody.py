"""Héros : Mélodie (Chanteuse du Temple). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_cream", weapon=lambda m, x, z: lute(m, x, z), offhand=lambda m, x, z: fan(m, x, z, "cloth_white"), hair="hair_blond", hat=('flower', 'mushroom_pink'), skirt="cloth_white", hair_style="long")
