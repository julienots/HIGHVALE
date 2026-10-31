"""Héros : Cornebois (Faune). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "leaf", "fur_brown", weapon=lambda m, x, z: lute(m, x, z), offhand=lambda m, x, z: wand(m, x, z, "leaf"), hair="hair_brown", horns="bark", tail="fur_brown", hair_style="short")
