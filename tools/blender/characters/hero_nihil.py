"""Héros : Nihil (Marcheur du Néant). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "void_skin", "cloth_black", weapon=lambda m, x, z: dagger(m, x, z, "glow_violet"), offhand=lambda m, x, z: dagger(m, x, z, "glow_violet"), skin="void_skin", hood="cloth_black", eyes="glow_violet", hair_style="bald")
