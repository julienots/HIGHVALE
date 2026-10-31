"""Héros : Zircon (Lame prismatique). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_teal", "cloth_black", weapon=lambda m, x, z: katana(m, x, z, "crystal"), offhand=lambda m, x, z: dagger(m, x, z, "crystal"), hair="hair_blue", mask="cloth_teal", eyes="crystal", hair_style="spiky")
