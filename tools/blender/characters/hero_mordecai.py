"""Héros : Mordecai (Nécromancien repenti). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_purple", weapon=lambda m, x, z: scythe(m, x, z), offhand=lambda m, x, z: tome(m, x, z, "cloth_black"), skin="skin_pale", hair="hair_white", hood="cloth_purple", eyes="shadow_glow", glow="shadow_glow", hair_style="long")
