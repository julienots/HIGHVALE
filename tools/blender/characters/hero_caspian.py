"""Héros : Caspian (Prince des lacs). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "steel", weapon=lambda m, x, z: sword(m, x, z, "steel", "crystal_teal"), offhand=lambda m, x, z: shield(m, x, z, "cloth_teal", "gold"), skin="skin_pale", hair="hair_blond", crown="gold", armor="steel", cape="cloth_teal", hair_style="short")
