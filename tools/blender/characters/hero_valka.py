"""Héros : Valka (Lancière des glaces). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_blue", weapon=lambda m, x, z: spear(m, x, z, "crystal"), hair="hair_white", armor="steel", pauldrons="fur_grey", hair_style="ponytail")
