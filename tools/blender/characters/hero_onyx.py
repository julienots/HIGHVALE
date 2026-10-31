"""Héros : Onyx (Gardien noir). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "steel_dark", "cloth_black", weapon=lambda m, x, z: mace(m, x, z, "steel_dark"), offhand=lambda m, x, z: shield(m, x, z, "cloth_black", "steel_dark"), skin="skin_dark", hair="hair_black", armor="steel_dark", pauldrons="steel_dark", helmet="steel_dark", hair_style="bald")
