"""Héros : Delphine (Druidesse des marées). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_white", weapon=lambda m, x, z: staff(m, x, z, "water", "bark"), offhand=lambda m, x, z: orb(m, x, z, "water"), skin="skin_dark", hair="hair_blue", hood="cloth_teal", hair_style="braids")
