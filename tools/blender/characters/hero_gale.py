"""Héros : Rafale (Pirate des airs). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "leather", weapon=lambda m, x, z: katana(m, x, z), offhand=lambda m, x, z: crossbow(m, x, z), hair="hair_red", hat=('wide', 'cloth_red'), scarf="cloth_white", hair_style="short")
