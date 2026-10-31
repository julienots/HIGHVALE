"""Héros : Bruno (Ours guerrier). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "fur_brown", "leather", weapon=lambda m, x, z: hammer_big(m, x, z), hair="fur_brown", ears="fur_brown", armor="leather", pauldrons="fur_brown", hair_style="mane")
