"""Héros : Opaline (Voyante des géodes). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_white", weapon=lambda m, x, z: wand(m, x, z, "crystal_violet"), offhand=lambda m, x, z: orb(m, x, z, "crystal_violet"), skin="skin_pale", hair="hair_white", hood="cloth_purple", eyes="crystal", hair_style="long")
