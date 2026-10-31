"""Héros : Mabel (Grand-mère sorcière). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_brown", weapon=lambda m, x, z: staff(m, x, z, "brew_violet", "wood_dark"), hair="hair_white", hat=('witch', 'cloth_purple'), scarf="cloth_red", hair_style="bun")
