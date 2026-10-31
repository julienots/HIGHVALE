"""Héros : Marin (Pêcheur des abysses). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_blue", "cloth_cream", weapon=lambda m, x, z: trident(m, x, z, "steel"), skin="skin_dark", hair="hair_black", hat=('bandana', 'cloth_red'), beard=True, hair_style="short")
