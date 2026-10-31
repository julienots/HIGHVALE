"""Héros : Skye (Messagère ailée). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "cloth_blue", weapon=lambda m, x, z: wand(m, x, z, "glow_gold"), hair="hair_blond", wings="feather_white", hair_style="ponytail")
