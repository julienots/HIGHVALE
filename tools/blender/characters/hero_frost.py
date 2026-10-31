"""Héros : Givre (Chasseuse des glaces). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_white", "fur_grey", weapon=lambda m, x, z: bow(m, x, z), skin="skin_pale", hair="hair_white", hood="fur_grey", eyes="crystal", hair_style="braids")
