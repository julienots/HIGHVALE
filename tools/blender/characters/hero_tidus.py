"""Héros : Tidus (Gardien des écluses). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "steel", "cloth_blue", weapon=lambda m, x, z: trident(m, x, z, "steel"), offhand=lambda m, x, z: shield(m, x, z, "cloth_blue", "steel"), hair="hair_brown", armor="steel", helmet="steel", hair_style="short")
