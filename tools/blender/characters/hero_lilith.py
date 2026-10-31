"""Héros : Lilith (Danseuse des lames). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_purple", "cloth_black", weapon=lambda m, x, z: chakram(m, x, z, "shadow_glow"), offhand=lambda m, x, z: chakram(m, x, z, "shadow_glow"), skin="skin_pale", hair="hair_black", eyes="shadow_glow", hair_style="twintails")
