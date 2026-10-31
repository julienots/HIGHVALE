"""Héros : Viviane (Dame du lac). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_teal", weapon=lambda m, x, z: staff(m, x, z, "crystal_teal", "gold"), offhand=lambda m, x, z: orb(m, x, z, "water"), skin="skin_pale", hair="hair_blue", crown="crystal_teal", cape="cloth_teal", skirt="cloth_white", glow="glow_teal", eyes="crystal", hair_style="long")
