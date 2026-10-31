"""Héros : Tobias (Élève mage). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.27
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "cloth_cream", weapon=lambda m, x, z: wand(m, x, z, "rune"), offhand=lambda m, x, z: tome(m, x, z, "cloth_blue"), hair="hair_blond", hat=('wizard', 'cloth_teal'), hair_style="spiky")
