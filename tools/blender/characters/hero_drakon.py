"""Héros : Drakon (Dragonnier). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "scale_red", "steel_dark", weapon=lambda m, x, z: spear(m, x, z, "fire"), offhand=lambda m, x, z: gauntlet(m, x, z, "scale_red"), skin="skin_dark", hair="hair_black", armor="scale_red", pauldrons="scale_red", cape="cloth_black", glow="fire", eyes="fire", tail="scale_red", hair_style="mohawk")
