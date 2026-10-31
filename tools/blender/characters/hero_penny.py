"""Héros : Penny (Marchande ambulante). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_brown", weapon=lambda m, x, z: lantern(m, x, z), offhand=lambda m, x, z: wand(m, x, z, "glow_gold"), hair="hair_brown", hat=('wide', 'straw'), pouch="leather", hair_style="braids")
