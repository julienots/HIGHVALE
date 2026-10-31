"""Héros : Vesper (Succube repentie). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_black", weapon=lambda m, x, z: whip(m, x, z, "cloth_purple"), offhand=lambda m, x, z: orb(m, x, z, "glow_pink"), skin="skin_pale", hair="hair_black", horns="dark", wings="membrane", tail="cloth_purple", eyes="glow_pink", hair_style="long")
