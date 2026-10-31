"""Héros : Barbe-Kraken (Capitaine des barques). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "leather", weapon=lambda m, x, z: greataxe(m, x, z), offhand=lambda m, x, z: gauntlet(m, x, z, "bronze"), skin="skin_dark", hair="hair_black", beard=True, hat=('wide', 'cloth_black'), cape="cloth_red", hair_style="short")
