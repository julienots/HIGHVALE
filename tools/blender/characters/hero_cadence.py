"""Héros : Cadence (Tambour de guerre). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_orange", "leather", weapon=lambda m, x, z: mace(m, x, z, "wood_light"), offhand=lambda m, x, z: gauntlet(m, x, z, "bronze"), skin="skin_dark", hair="hair_black", scarf="cloth_red", armor="leather", hair_style="braids")
