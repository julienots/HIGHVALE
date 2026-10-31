"""Héros : Épine (Chasseresse sylvestre). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "leaf_dark", "leather", weapon=lambda m, x, z: dagger(m, x, z, "leaf"), offhand=lambda m, x, z: dagger(m, x, z, "leaf"), skin="skin_green", hair="hair_black", ears="elf", hood="leaf_dark", hair_style="ponytail")
