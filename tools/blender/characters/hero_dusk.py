"""Héros : Brune (Chasseresse du crépuscule). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "leather", weapon=lambda m, x, z: bow(m, x, z), skin="skin_dark", hair="hair_silver", ears="elf", hood="cloth_purple", eyes="shadow_glow", hair_style="ponytail")
