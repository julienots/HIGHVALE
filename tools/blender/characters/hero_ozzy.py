"""Héros : Ozzy (Dompteur de slimes). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "cloth_blue", weapon=lambda m, x, z: wand(m, x, z, "slime"), hair="hair_red", hat=('beret', 'slime'), pouch="leather", hair_style="spiky")
