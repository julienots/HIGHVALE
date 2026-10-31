"""Héros : Ruth (Gardienne des ruines). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_cream", "gold", weapon=lambda m, x, z: spear(m, x, z, "gold"), offhand=lambda m, x, z: shield(m, x, z, "cloth_cream", "gold"), skin="skin_dark", hair="hair_black", armor="gold", helmet="gold", hair_style="bun")
