"""Héros : Hexa (Maudisseuse). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_black", weapon=lambda m, x, z: wand(m, x, z, "shadow_glow"), hair="hair_black", hat=('witch', 'cloth_black'), hair_style="bob")
