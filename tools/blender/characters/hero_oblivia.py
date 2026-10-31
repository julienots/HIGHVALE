"""Héros : Oblivia (Mage du vide). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "cloth_purple", weapon=lambda m, x, z: staff(m, x, z, "glow_violet", "steel_dark"), offhand=lambda m, x, z: orb(m, x, z, "glow_violet"), skin="skin_blue", hair="hair_white", eyes="glow_violet", hat=('circlet', 'steel_dark'), hair_style="bob")
