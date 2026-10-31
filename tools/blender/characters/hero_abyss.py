"""Héros : Thalassa (Reine des profondeurs). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "gold", weapon=lambda m, x, z: trident(m, x, z, "gold"), offhand=lambda m, x, z: orb(m, x, z, "crystal_teal"), skin="skin_blue", hair="hair_blue", crown="gold", cape="cloth_blue", skirt="cloth_teal", eyes="glow_teal", glow="glow_teal", hair_style="long")
