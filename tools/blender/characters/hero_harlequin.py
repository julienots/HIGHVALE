"""Héros : Arlequin (Bouffon masqué). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_red", "cloth_black", weapon=lambda m, x, z: chakram(m, x, z, "gold"), offhand=lambda m, x, z: fan(m, x, z, "cloth_red"), hair="hair_black", hat=('bandana', 'cloth_purple'), mask="cloth_white", hair_style="short")
