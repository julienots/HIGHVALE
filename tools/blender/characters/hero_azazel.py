"""Héros : Azazel (Démon des forges). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "scale_red", "cloth_black", weapon=lambda m, x, z: trident(m, x, z, "fire"), skin="skin_dark", hair="hair_black", horns="dark", wings="membrane", tail="scale_red", eyes="fire", glow="fire", hair_style="spiky")
