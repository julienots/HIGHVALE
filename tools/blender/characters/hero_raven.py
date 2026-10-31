"""Héros : Corbeau (Espion). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_black", weapon=lambda m, x, z: whip(m, x, z, "cloth_black"), offhand=lambda m, x, z: dagger(m, x, z), hair="hair_black", hat=('wide', 'cloth_black'), scarf="cloth_purple", hair_style="spiky")
