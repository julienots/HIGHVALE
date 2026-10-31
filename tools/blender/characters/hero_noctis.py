"""Héros : Noctis (Prince des ombres). Généré par tools/data/gen_collection.py."""
from characters._hero import *  # noqa: F401,F403

EXTENT = 0.24
FLAT_PALETTE = True


def build(m):
    hero(m, "cloth_black", "steel_dark", weapon=lambda m, x, z: katana(m, x, z, "shadow_glow"), offhand=lambda m, x, z: dagger(m, x, z, "shadow_glow"), skin="skin_pale", hair="hair_silver", crown="steel_dark", cape="cloth_black", eyes="shadow_glow", glow="shadow_glow", hair_style="spiky")
