"""Héros : Sora (Moine du vent). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_orange", "cloth_cream", weapon=lambda m, x, z: gauntlet(m, x, z, "cloth_orange"), offhand=lambda m, x, z: gauntlet(m, x, z, "cloth_orange"), skin="skin_pale", hair="hair_black", scarf="cloth_orange", hair_style="bald")
