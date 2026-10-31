"""Héros : Sable (Nomade des dunes). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_cream", "cloth_orange", weapon=lambda m, x, z: katana(m, x, z, "steel"), offhand=lambda m, x, z: dagger(m, x, z, "steel"), skin="skin_dark", hair="hair_black", hat=('bandana', 'cloth_cream'), mask="cloth_cream", hair_style="short")
