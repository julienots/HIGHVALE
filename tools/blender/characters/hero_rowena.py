"""Héros : Rowena (Lancière de la Garde). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "steel", weapon=lambda m, x, z: spear(m, x, z, "gold"), hair="hair_red", armor="steel", pauldrons="steel", hair_style="ponytail")
