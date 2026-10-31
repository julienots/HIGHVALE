"""Héros : Moss (Druide des champignons). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_green", "bark", weapon=lambda m, x, z: staff(m, x, z, "glow_teal", "bark"), hair="hair_brown", beard=True, hood="cloth_green", hair_style="long")
